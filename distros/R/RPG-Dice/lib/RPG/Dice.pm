package RPG::Dice;
use strict;
use warnings;
use Carp;

# ABSTRACT: emulate rolling dice

our $VERSION = "1.2";

sub new {
    shift;
    my $pat = shift;
    confess "Bad pattern: $pat\nShould be in the form of 'xdy' where"
      . "\n\tx = number of dice \n\ty = number of sides."
      unless $pat =~ m/^\d+[dD]\d+$/;

    my $self = {
        sides => 0,
        num   => 0
    };

    bless $self, "RPG::Dice";

    $pat =~ m@^(\d+)[dD](\d+)$@;

    $self->{num}   = $1;
    $self->{sides} = $2;

    return $self;
}

sub roll {
    my $self = shift;
    my $ret  = 0;

    foreach ( 1 .. $self->{num} ) {
        $ret += int( rand( $self->{sides} ) ) + 1;
    }
    return $ret;
}
1;

__END__

=pod

=head1 NAME

RPG::Dice - emulate rolling dice

=head1 VERSION

version 1.201

=head1 SYNOPSIS

	use RPG::Dice;
	# Single six sided dice
	my $d1 = RPG::Dice->new('1d6');
	# Two six sided dice
	my $d2 = RPG::Dice->new('2d6');

	#
	# 1 <= $x <= 6
	my $x = $d1->roll();

=head1 METHODS

=head2 new

This is the constructor method for this module.  You pass a string constant
to the module in the form of XdY where X is the number of dice and Y is the
number of sides to the dice.

=head2 roll

This performs the actual dice roll

=head1 AUTHOR

Peter L. Berghold <cpan@berghold.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Peter L. Berghold.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
