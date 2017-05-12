package Perl::Achievements::Achievement::PerlHacker;
BEGIN {
  $Perl::Achievements::Achievement::PerlHacker::AUTHORITY = 'cpan:YANICK';
}
{
  $Perl::Achievements::Achievement::PerlHacker::VERSION = '0.4.0';
}
# ABSTRACT: just another Perl hacker

use strict;
use warnings;

use Moose;

no warnings qw/ uninitialized /;

with 'Perl::Achievements::Achievement';

has locs => (
    traits => [ qw/ Number Perl::Achievements::Role::ConfigItem / ],
    isa     => 'Num',
    is      => 'rw',
    handles => { add_locs => 'add', },
);

sub scan {
    my $self = shift;

    my @lines = split "\n", $self->ppi->serialize;
    $self->add_locs( scalar @lines );

    if ( $self->locs > 10 ** (1+$self->level) ) {
        $self->inc_level;
        $self->unlock;
    }

}

1;

__END__
=pod

=head1 NAME

Perl::Achievements::Achievement::PerlHacker - just another Perl hacker

=head1 VERSION

version 0.4.0

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

