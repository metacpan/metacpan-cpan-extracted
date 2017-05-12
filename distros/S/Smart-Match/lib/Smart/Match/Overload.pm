package Smart::Match::Overload;
$Smart::Match::Overload::VERSION = '0.008';
use strict;
use warnings;
use XSLoader;

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

use overload
	'~~' => sub {
		my ($self, undef, $rev) = @_;
		return if not $rev;
		return $self->() for $_[1];
	},
	bool => \&_boolean;

sub new {
	my ($class, $sub) = @_;
	return bless $sub, $class;
}

1;

# ABSTRACT: An internal class for closure based matcher objects.

__END__

=pod

=encoding UTF-8

=head1 NAME

Smart::Match::Overload - An internal class for closure based matcher objects.

=head1 VERSION

version 0.008

=head1 METHODS

=head2 new($sub)

Creates a new matcher based on C<$sub>. $sub will be called with the left hand side in C<$_>.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
