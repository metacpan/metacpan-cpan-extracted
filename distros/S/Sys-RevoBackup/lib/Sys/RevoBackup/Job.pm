package Sys::RevoBackup::Job;
{
  $Sys::RevoBackup::Job::VERSION = '0.27';
}
BEGIN {
  $Sys::RevoBackup::Job::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: an Revobackup job, spawns a worker

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;

use Sys::RevoBackup::Worker;

extends 'Sys::Bprsync::Job';

foreach my $key (qw(bank vault)) {
    has $key => (
        'is'       => 'ro',
        'isa'      => 'Str',
        'required' => 1,
    );
}

sub _startup {
    my $self = shift;

    # DGR: I really want the global effect this assignment has!
    ## no critic (RequireLocalizedPunctuationVars)
    $0 = 'revobackup - ' . $self->name();
    ## use critic

    return 1;
}

sub _init_worker {
    my $self = shift;

    my $Worker = Sys::RevoBackup::Worker::->new(
        {
            'config'  => $self->config(),
            'logger'  => $self->logger(),
            'parent'  => $self->parent(),
            'name'    => $self->name(),
            'verbose' => $self->verbose(),
            'bank'    => $self->bank(),
            'vault'   => $self->vault(),
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

Sys::RevoBackup::Job - an Revobackup job, spawns a worker

=head1 NAME

Sys::RevoBackup::Job - a RevoBackup job

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
