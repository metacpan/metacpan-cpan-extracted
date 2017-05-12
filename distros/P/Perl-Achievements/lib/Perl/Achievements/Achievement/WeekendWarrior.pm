package Perl::Achievements::Achievement::WeekendWarrior;
BEGIN {
  $Perl::Achievements::Achievement::WeekendWarrior::AUTHORITY = 'cpan:YANICK';
}
{
  $Perl::Achievements::Achievement::WeekendWarrior::VERSION = '0.4.0';
}
# ABSTRACT: code over the week-end

use strict;
use warnings;

use Moose;
use MooseX::SemiAffordanceAccessor;

no warnings qw/ uninitialized /;

with 'Perl::Achievements::Achievement';

has days => (
    traits => [ qw/ Counter Perl::Achievements::Role::ConfigItem / ],
    isa     => 'Num',
    is      => 'rw',
    default => 0,
    handles => {
        inc_days => 'inc',
    },
);

sub scan {
    my $self = shift;

    my $wday = (localtime)[6];

    return unless $wday == 0 or $wday == 6;

    $self->inc_days;

    return unless $self->days >= 2**$self->level; 

    $self->inc_level;
    $self->unlock( 
        sprintf "Was at the computer %d days during week-ends", $self->days
    );
}

1;

__END__
=pod

=head1 NAME

Perl::Achievements::Achievement::WeekendWarrior - code over the week-end

=head1 VERSION

version 0.4.0

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

