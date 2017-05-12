# Copyrights 2013-2015 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package Net::Domain::SMD;
use vars '$VERSION';
$VERSION = '0.18';

use Log::Report   'net-domain-smd';

use MIME::Base64       qw/decode_base64/;
use XML::LibXML        ();
use POSIX              qw/mktime tzset/;
use XML::Compile::Util qw/type_of_node/;
use List::Util         qw/first/;
use Scalar::Util       qw/blessed/;
use DateTime           ();


sub new($%) { my ($class, %args) = @_; (bless {}, $class)->init(\%args) }
sub init($)
{   my ($self, $args) = @_;
    $self->{NDS_data}    = $args->{data}    or panic;
    $self->{NDS_payload} = $args->{payload} or panic;
    $self;
}


sub fromNode($%)
{   my ($class, $node, %args) = @_;
    my $schemas = delete $args{schemas} or panic;

    $node = $node->documentElement
        if $node->isa('XML::LibXML::Document');

    my $type = type_of_node $node;
    my $data = $schemas->reader($type)->($node);

    $class->new(payload => $node, data => $data, %args);
}

#----------------

sub payload()   {shift->{NDS_payload}}
sub data()      {shift->{NDS_data}}      # avoid, undocumented
sub _mark()     {shift->data->{mark}}    # hidden

#----------------

sub courts()  { @{shift->_mark->{court} || []} }


sub trademarks()  { @{shift->_mark->{trademark} || []} }


sub treaties()  { @{shift->_mark->{treatyOrStatute} || []} }


sub certificates(%)
{   my ($self, %args) = @_;

    my $tokens = $self->data->{ds_Signature}{ds_KeyInfo}{__TOKENS} || [];
    my @certs  = map $_->certificate, @$tokens;

    my $issuer = $args{issuer};
    $issuer ? (grep $_->issuer eq $issuer, @certs) : @certs;
}


sub issuer()
{   my $i = shift->data->{smd_issuerInfo} or return;
    # remove smd namespace prefixes
    my %issuer;
    while(my($k, $v) = each %$i)
    {   $k =~ s/smd_//;
        $issuer{$k} = $v;
    }
    \%issuer;
}


sub from()      {shift->data->{smd_notBefore}}
sub until()     {shift->data->{smd_notAfter}}
sub fromTime()  {my $s = shift; $s->date2time($s->from)->hires_epoch}
sub untilTime() {my $s = shift; $s->date2time($s->until)->hires_epoch}


sub smdID()     {shift->data->{smd_id}}


#----------------

sub date2time($)
{   my ($thing, $date) = @_;

    return $date
        if blessed $date && $date->isa('DateTime');

    # For now, I only support Zulu time: 2013-07-12T12:53:48.408Z
    $date =~ m/^ ([0-9]{4})\-([0-1]?[0-9])\-([0-3]?[0-9])
               T ([0-2]?[0-9])\:([0-5]?[0-9])\:([0-6]?[0-9])(\.[0-9]+)?
               ([+-][0-9]?[0-9]\:[0-9][0-9]|Z)? $/x
        or return;

    DateTime->new
      ( year => $1, month => $2, day => $3
      , hour => $4, minute => $5, second => $6, 
      , nanosecond => int(1_000_000_000 * ($7 || 0))
      , time_zone  => ($8 || 'UTC')
      );
}

1;
