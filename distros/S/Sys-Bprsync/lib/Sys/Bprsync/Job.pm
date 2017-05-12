package Sys::Bprsync::Job;
{
  $Sys::Bprsync::Job::VERSION = '0.25';
}
BEGIN {
  $Sys::Bprsync::Job::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: an bprsync job, spawns a worker

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;

use Sys::Bprsync::Worker;

extends 'Job::Manager::Job';

has 'parent' => (
    'is'       => 'ro',
    'isa'      => 'Sys::Bprsync',
    'required' => 1,
);

has 'name' => (
    'is'       => 'ro',
    'isa'      => 'Str',
    'required' => 1,
);

has 'verbose' => (
    'is'      => 'rw',
    'isa'     => 'Bool',
    'default' => 0,
);

has 'dry' => (
    'is'      => 'ro',
    'isa'     => 'Bool',
    'default' => 0,
);

sub _init_worker {
    my $self = shift;

    my $Worker = Sys::Bprsync::Worker::->new(
        {
            'config'  => $self->config(),
            'logger'  => $self->logger(),
            'parent'  => $self->parent(),
            'name'    => $self->name(),
            'verbose' => $self->verbose(),
            'dry'     => $self->dry(),
        }
    );

    return $Worker;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Sys::Bprsync::Job - an bprsync job, spawns a worker

=head1 NAME

Sys::Bprsync::Job - a BPrsync job

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
