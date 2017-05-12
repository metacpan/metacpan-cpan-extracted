# Copyrights 2013-2014 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use warnings;
use strict;
use utf8;

package Payment::Sisow;
use vars '$VERSION';
$VERSION = '0.13';


use Log::Report 'sisow';

use Digest::SHA1   qw(sha1_hex);

# documentation calls this "alfanumerical characters"
my $valid_purchase_chars = q{ A-Za-z0-9=%*+,./&@"':;?()$-};
my $valid_descr_chars    = q{ A-Za-z0-9=%*+,./&@"':;?()$-};
my $purchase_become_star = q{"':;?()$};    # accepted but replaced by Sisow

# documentation calls this "strict alfanumerical characters"
my $valid_entrance_chars = q{A-Za-z0-9};


sub new(%)
{   my $class = shift;
    $class ne __PACKAGE__ or panic "instantiate an extension of ".__PACKAGE__;
    (bless {}, $class)->init( {@_} );
}

sub init($)
{   my ($self, $args) = @_;
    $self->{PS_m_id}  = $args->{merchant_id}  or panic "merchant_id required";
    $self->{PS_m_key} = $args->{merchant_key} or panic "merchant_key required";
    $self->{PS_test}  = $args->{test} || 0;
    $self;
}

#--------------

sub merchantId()  {shift->{PS_m_id}}
sub merchantKey() {shift->{PS_m_key}}
sub isTest()      {shift->{PS_test}}

#--------------


sub listIdealBanks(%)
{   my ($self, %args) = @_;
    my $b = $self->_list_ideal_banks(%args);
    $b ? @$b : ();
}


sub transactionStatus($)
{   my ($self, $tid) = @_;

    my $p = $self->_transaction_status
      ( transaction => $tid
      , merchantid  => $self->merchantId
      , merchantkey => $self->merchantKey
      ) or return undef;

    $p->{status};
}



sub transactionInfo($)
{   my ($self, $tid) = @_;

    my $p = $self->_transaction_info
      ( transaction => $tid
      , merchantid  => $self->merchantId
      , merchantkey => $self->merchantKey
      ) or return undef;

    $p->{stamp} =~ s/ /T/;  # timestamp lacks 'T' between date and time
    $p;
}


sub startTransaction(%)
{   my ($self, %args) = @_;
    my $bank_id     = $args{bank_id};
    my $amount_euro = $args{amount}  // panic;
    my $amount_cent = int($amount_euro*100 + 0.5); # float euro -> int cents

    my $purchase_id = $args{purchase_id} or panic;
    if(length $purchase_id > 16)
    {   # max 16 chars alphanum
        $purchase_id =~ s/[^$valid_purchase_chars]/ /g;
        warning __x"purchase_id shortened: {id}", id => $purchase_id;
        $purchase_id = substr $purchase_id, 0, 16;
    }

    my $description;
    if(my $d = $args{description})
    {   # max 32 alphanumerical. '_' allowed?
        for($d)
        {   s/[^$valid_descr_chars]/ /g;
            s/\s+/ /gs;
            s/\s+$//s;
        }
        if(length $d > 32)
        {   warning __x"description shortened for {id}: {descr}"
              , id => $purchase_id, descr => $d;
        }
        $description = $d;
    }

    my $entrance = $args{entrance_code} || $purchase_id;
    $entrance    =~ s/[^$valid_entrance_chars]//g;
    if(length $entrance > 40)
    {   # max 40 chars, defaults to purchaseid
        warning __x"entrance code shortened for {id}: {code}"
          , id => $purchase_id, code => $entrance;
        $entrance = substr $entrance, 0, 40;
    }
    $entrance    = ''
        if $entrance eq $purchase_id;

    my $payment = $args{payment} || 'ideal';
    error __x"payment via iDEAL requires bank id"
        if $payment eq 'ideal' && !$bank_id;

    my $return   = $args{return_url} or panic;
    my $cancel   = $args{cancel_url};
    my $callback = $args{callback_url};
    my $notify   = $args{notify_url} || $return;
    undef $cancel   if defined $cancel   && $cancel eq $return;
    undef $callback if defined $callback && $callback eq $return;

    my $p        = $self->_start_transaction
      ( merchantid  => $self->merchantId
      , merchantkey => $self->merchantKey
      , payment     => ($payment eq 'ideal' ? '' : $payment)
      , issuerid    => $bank_id
      , amount      => $amount_cent
      , purchaseid  => $purchase_id
      , description => $description
      , entrancecode=> $entrance
      , returnurl   => $return
      , cancelurl   => $cancel
      , callbackurl => $callback
      , notifyurl   => $notify
      ) or return;

    my $bank_page = $p->{issuerurl};
    my $tid       = $p->{trxid};
    info __x"redirecting user for purchase {id} to {url}, transaction {tid}"
      , id => $purchase_id, url => $bank_page, tid => $tid;

    ($tid, $bank_page);
}

#----------------

sub securedPayment(@)
{   my $self   = shift;
    my $qs     = @_ > 1 ? {@_} : shift;
    my $ec     = $qs->{ec};
    my $trxid  = $qs->{trxid};
    my $status = $qs->{status};
    # docs say separated by '/', but isn't in practice
    my $checksum = sha1_hex
        (join '', $trxid, $ec, $status, $self->merchantId, $self->merchantKey);

    return 1
        if $checksum eq $qs->{sha1};

    alert "checksum of reply failed: $ec/$trxid/$status sum is $checksum";
    0;
}


sub isValidPurchaseId($)  { $_[1] =~ /^[$valid_purchase_chars]{1,16}$/o }
sub isValidDescription($) { $_[1] =~ /^[$valid_descr_chars]{0,32}$/o    }


#--------------

1;
