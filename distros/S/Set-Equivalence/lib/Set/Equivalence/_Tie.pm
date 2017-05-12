use 5.008;
use strict;
use warnings;

package Set::Equivalence::_Tie;

BEGIN {
	$Set::Equivalence::_Tie::AUTHORITY = 'cpan:TOBYINK';
	$Set::Equivalence::_Tie::VERSION   = '0.003';
}

require Tie::Array;
our @ISA = qw(Tie::Array);

sub TIEARRAY {
	my ($class, $set) = @_;
	bless \$set, $class;
}

sub FETCH {
	my $set = ${+shift};
	($set->members)[$_[0]];
}

sub FETCHSIZE {
	my $set = ${+shift};
	$set->size;
}

sub CLEAR {
	my $set = ${+shift};
	$set->clear;
}

sub PUSH {
	my $set = ${+shift};
	$set->insert(@_);
}

sub UNSHIFT {
	my $set = ${+shift};
	$set->_unshift(@_);
}

sub POP {
	my $set = ${+shift};
	$set->pop(@_);
}

sub SHIFT {
	my $set = ${+shift};
	$set->_shift(@_);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Set::Equivalence::_Tie - tied array implementation for Set::Equivalence's C<to_array> method

=head1 DESCRIPTION

No user-serviceable parts within.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Set-Equivalence>.

=head1 SEE ALSO

L<Set::Equivalence>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

