# Copyrights 2013-2015 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
use warnings;
use strict;

package Net::Domain::SMD::RL;
use vars '$VERSION';
$VERSION = '0.18';

use base 'Exporter';

use Log::Report                  'net-domain-smd';
use Scalar::Util        qw(blessed);



sub new($%) { my ($class, %args) = @_; (bless {}, $class)->init(\%args) }

sub init($)
{   my ($self, $args) = @_;
    $self->{NDSR_source}  = $args->{source} or panic;

    my $rev =  $args->{revoked} || [];
    $rev = +{map +($_ => 1), @$rev} if ref $rev eq 'ARRAY';
    $self->{NDSR_revoked} = $rev;
    $self;
}


sub _process(@)
{   my $self = shift;
    my $revoked = $self->{NDSR_revoked} ||= {};

    # Compact code: needs to be fast.
    # be warned: \n may end line, but last element not used (yet).
    my ($version, $timestamp) = shift;
    my $header  = shift;
    $revoked->{lc +(split /\,/, $_, 2)[0]} = 1 for @_;
    $self;
}

sub fromFile($%)
{   my ($class, $fn) = (shift, shift);

    open my($fh), '<:raw', $fn
        or fault "cannot read RL file {fn}", fn => $fn;

    my $self = $class->new(source => $fn, @_);
    $self->_process($fh->getlines);
}


my $ua;
sub fromURI($%)
{   my ($class, $uri) = (shift, shift);

    eval "require LWP::UserAgent";
    $@ and error __x"need LWP::UserAgent to fetch RL: {err}", err => $@;

    $ua ||= LWP::UserAgent->new;
    my $resp = $ua->get($uri);
    $resp->is_success
        or error __x"could not collect RL from {source}: {err}"
              , $resp->status_line;

    my $self = $class->new(source => $uri, @_);
    $self->_process(split /\r?\n/, $resp->decoded_content);
}

#-------------------------


sub source() {shift->{NDSR_source}}

#-------------------------


sub isRevoked($)
{   my ($self, $smd) = @_;
    my $smdid = blessed $smd ? $smd->smdID : $smd;
    exists $self->{NDSR_revoked}{lc $smdid};
}

1;
