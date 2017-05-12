package Net::Amazon::MechanicalTurk::Transport;
use strict;
use warnings;
use Carp;
use Net::Amazon::MechanicalTurk::BaseObject;
use Net::Amazon::MechanicalTurk::ModuleUtil;

our $VERSION = '1.00';

our @ISA = qw{ Net::Amazon::MechanicalTurk::BaseObject };

use constant DEFAULT_TRANSPORT => "REST";

sub create {
    my $class = shift;
    my $transport = shift || $ENV{MTURK_TRANSPORT} || DEFAULT_TRANSPORT;
    my $module = "Net::Amazon::MechanicalTurk::Transport::${transport}Transport";
    if (!Net::Amazon::MechanicalTurk::ModuleUtil->tryRequire($module)) {
        Carp::croak "Could not load transport $transport - $@";
    }
    return $module->new(@_);
}

sub call {
    my ($self, $client, $operation, $params) = @_; 
}

return 1;
