package Proc::Safetynet::ProgramStatus;
use strict;
use warnings;
use Carp;

use Moose;

has 'is_running' => (
    is          => 'rw',
    isa         => 'Bool',
    required    => 1,
    default     => 0,
);

has 'started_since' => (
    is          => 'rw',
    isa         => 'Int',
    required    => 0,
);

has 'stopped_since' => (
    is          => 'rw',
    isa         => 'Int',
    required    => 0,
);

has 'pid'       => (
    is          => 'rw',
    isa         => 'Int',
    required    => 0,
);

sub TO_JSON {
    my $self = shift;
    my $o = { };
    foreach my $k (keys %$self) {
        next if ($k =~ /^_/);
        $o->{$k} = $self->{$k};
    }
    return $o;
}

no Moose;


1;

__END__
