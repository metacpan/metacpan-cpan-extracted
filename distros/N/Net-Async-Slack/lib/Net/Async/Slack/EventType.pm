package Net::Async::Slack::EventType;

use strict;
use warnings;

our $VERSION = '0.007'; # VERSION

use Log::Any qw($log);

use Check::UnitCheck;
our %REGISTERED_TYPES;

sub import {
    my ($class, @args) = @_;
    my ($pkg) = caller;

    # Bail out unless we're called directly, we don't want the import to propagate
    # to subclasses.
    return unless $class eq __PACKAGE__;

    # Register and set up inheritance for things that import us directly,
    # deferring the type registration until the module has been fully compiled.
    Check::UnitCheck::unitcheckify(sub {
        die 'Already registered ' . $pkg->type if exists $REGISTERED_TYPES{$pkg->type};
        $REGISTERED_TYPES{$pkg->type} = $pkg;
        { no strict 'refs'; push @{$pkg . '::ISA'}, __PACKAGE__; }
    }) ;
    return;
}

sub from_json {
    my ($self, $data) = @_;
    $log->tracef('Looking for type %s with available %s', $data->{type}, join ',', sort keys %REGISTERED_TYPES);
    return undef unless my $class = $REGISTERED_TYPES{$data->{type}};
    for (qw(user channel team source_team)) {
        if(my $item = delete $data->{$_}) {
            $data->{$_ . '_id'} = ref($item) ? $item->{id} : $item;
            $data->{$_} = $item if ref($item);
        }
    }
    return $class->new(%$data);
}

sub new { bless { @_[1..$#_] }, $_[0] }

1;

