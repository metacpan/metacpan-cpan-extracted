package Proc::Safetynet::Program;
use strict;
use warnings;
use Carp;

use Moose;
use Moose::Util::TypeConstraints;

subtype 'ProgramName'
    => as 'Str'
    => where { ($_ =~ /^[\w\-\_]+$/) ? 1 : 0 };


has 'name' => (
    is          => 'rw',
    isa         => 'ProgramName',
    required    => 1,
);

has 'command' => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
);

has 'autostart' => (
    is          => 'rw',
    isa         => 'Bool',
    required    => 1,
    default     => 0,
);

has 'autorestart' => (
    is          => 'rw',
    isa         => 'Bool',
    required    => 1,
    default     => 0,
);

has 'autorestart_wait' => (
    is          => 'rw',
    isa         => 'Int',
    required    => 1,
    default     => 10,
);

has 'priority' => (
    is          => 'rw',
    isa         => 'Int',
    required    => 0,
);

has 'eventlistener' => (
    is          => 'rw',
    isa         => 'Bool',
    required    => 0,
);

sub TO_JSON {
    my $self = shift;
    my $o = { };
    foreach my $k (keys %$self) {
        $o->{$k} = $self->{$k};
    }
    return $o;
}

no Moose;

1;

__END__
