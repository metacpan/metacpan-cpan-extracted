package Perl::Achievements::Achievement::PerlAchiever;
BEGIN {
  $Perl::Achievements::Achievement::PerlAchiever::AUTHORITY = 'cpan:YANICK';
}
{
  $Perl::Achievements::Achievement::PerlAchiever::VERSION = '0.4.0';
}
# ABSTRACT: feeds code to perl-achiever

use strict;
use warnings;

use Moose;
use MooseX::SemiAffordanceAccessor;

no warnings qw/ uninitialized /;

with 'Perl::Achievements::Achievement';

has runs => (
    traits => [ qw/ Counter Perl::Achievements::Role::ConfigItem / ],
    isa     => 'Num',
    is      => 'rw',
    default => 0,
    handles => {
        inc_runs => 'inc',
    },
);

sub scan {
    my $self = shift;

    $self->inc_runs;

    return unless $self->runs >= 2** $self->level;

    $self->inc_level;
    $self->unlock( 
        sprintf "ran perl-achievements against %d scripts/modules",
                2 ** ( $self->level - 1 ) 
    );
}

1;

__END__
=pod

=head1 NAME

Perl::Achievements::Achievement::PerlAchiever - feeds code to perl-achiever

=head1 VERSION

version 0.4.0

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

