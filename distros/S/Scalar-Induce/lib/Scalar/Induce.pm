package Scalar::Induce;
{
  $Scalar::Induce::VERSION = '0.05';
}

use 5.006;
use strict;
use warnings;

##no critic (ProhibitAutomaticExportation)
use Exporter 5.57 'import';
use XSLoader;
our @EXPORT  = qw/induce void/;
if (!(not our $pure_perl and eval { XSLoader::load('Scalar::Induce', __PACKAGE__->VERSION); 1 })) {
	require Carp;
	eval <<'END' or Carp::croak("Could not load pure-perl induce: $@");    ##no critic (ProhibitStringyEval)
	sub induce (&$) {
		my ( $c, $v ) = @_;
		my @r;
		for ( $v ) { push @r, $c->() while defined }
		@r;
	}
	sub void { return; }
	1;
END
}

1;

#ABSTRACT: Unfolding scalars



=pod

=head1 NAME

Scalar::Induce - Unfolding scalars

=head1 VERSION

version 0.05

=head1 SYNOPSIS

	my @reversed = induce { @$_ ? pop @$_ : void undef $_ } [ 1 .. 10 ];

	my @chunks = induce { (length) ? substr $_, 0, 3, '' : void undef $_ } "foobarbaz";

=head1 FUNCTIONS

All functions are exported by default.

=head2 induce

This function takes a block and a scalar as arguments and then repeatedly applies the block to the value, accumulating the return values to eventually return them as a list. It does the opposite of reduce, hence its name. It's called unfold in some other languages.

=head2 void

This is a utility function that always returns an empty list (or undefined in scalar context). This makes a lot of inductions simpler.

=head1 ACKNOWLEDGEMENTS

Aristotle Pagaltzis came up with this idea (L<http://use.perl.org/~Aristotle/journal/37831>). Leon Timmermans re-implemented it in XS and uploaded it to CPAN.

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


