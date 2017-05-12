# Copyrights 2013-2015 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package Net::Domain::TMCH::CRL;
use vars '$VERSION';
$VERSION = '0.18';

use base 'Exporter';

use Log::Report    'net-domain-smd';
use MIME::Base64   qw(decode_base64);
use Convert::X509  ();
use Scalar::Util   qw(blessed);



sub new($%) { my ($class, %args) = @_; (bless {}, $class)->init(\%args) }

sub init($)
{   my ($self, $args) = @_;
    $self->{NDTC_source}  = $args->{source} or panic;

    my $rev =  $args->{revoked} || [];
    $rev = +{ map +($_ => 1), @$rev} if ref $rev eq 'ARRAY';
    $self->{NDTC_revoked} = $rev;
    $self;
}


sub fromFile($%)
{   my ($class, $fn) = (shift, shift);

    open my($fh), '<:raw', $fn
        or fault __x"cannot read CRL file {fn}", fn => $fn;

    my $crl = Convert::X509::CRL->new(join '', $fh->getlines);
    $class->new(source => $fn, revoked => $crl->{crl}, @_);
}


sub fromString($%)
{   my $class = shift;
    my $crl = Convert::X509::CRL->new(shift);
    $class->new(source => 'string', revoked => $crl->{crl}, @_);
}


my $ua;
sub fromURI($%)
{   my ($class, $uri) = (shift, shift);

    eval "require LWP::UserAgent";
    $@ and error __x"need LWP::UserAgent to fetch CRL: {err}", err => $@;

    $ua ||= LWP::UserAgent->new;
    my $resp = $ua->get($uri);
    $resp->is_success
        or error __x"could not collect CRL from {source}: {err}"
             , source => $uri, err => $resp->status_line;

    my $crl = Convert::X509::CRL->new($resp->decoded_content);
    $class->new(source => $uri, revoked => $crl->{crl}, @_);
}

#-------------------------


sub source() {shift->{NDTC_source}}

#-------------------------



sub isRevoked($)
{   my ($self, $cert) = @_;
    my $serial = blessed $cert ? $cert->serial : $cert;
    exists $self->{NDTC_revoked}{lc $serial};
}

1;
