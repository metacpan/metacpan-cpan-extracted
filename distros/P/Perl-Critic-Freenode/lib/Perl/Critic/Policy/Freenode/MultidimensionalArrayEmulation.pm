package Perl::Critic::Policy::Freenode::MultidimensionalArrayEmulation;

use strict;
use warnings;

use Perl::Critic::Utils qw(:severities :classification :ppi);
use parent 'Perl::Critic::Policy';

use List::Util 'any';

our $VERSION = '0.033';

use constant DESC => 'Use of multidimensional array emulation in hash subscript';
use constant EXPL => 'A list in a hash subscript used with the $ sigil triggers Perl 4 multidimensional array emulation. Nest structures using references instead.';

sub supported_parameters { () }
sub default_severity { $SEVERITY_LOW }
sub default_themes { 'freenode' }
sub applies_to { 'PPI::Structure::Subscript' }

sub violates {
	my ($self, $elem) = @_;
	return () unless $elem->complete and $elem->braces eq '{}';
	
	my @contents = $elem->schildren;
	@contents = $contents[0]->schildren if @contents == 1 and $contents[0]->isa('PPI::Statement::Expression');
	
	# check for function call with no parentheses; following args won't trigger MAE
	if (@contents > 1 and $contents[0]->isa('PPI::Token::Word') and !$contents[1]->isa('PPI::Structure::List')
		and !($contents[1]->isa('PPI::Token::Operator') and ($contents[1] eq ',' or $contents[1] eq '=>'))) {
		return ();
	}
	
	# check if contains top level , or multi-word qw
	return () unless any {
		($_->isa('PPI::Token::Operator') and ($_ eq ',' or $_ eq '=>')) or
		($_->isa('PPI::Token::QuoteLike::Words') and (my @words = $_->literal) > 1)
	} @contents;
	
	# check if it's a postderef slice
	my $prev = $elem->sprevious_sibling;
	return () if $prev and $prev->isa('PPI::Token::Cast') and ($prev eq '@' or $prev eq '%');
	
	# check if it's a slice
	my ($cast, $found_symbol);
	$prev = $elem;
	while ($prev = $prev->sprevious_sibling) {
		last if $found_symbol and !$prev->isa('PPI::Token::Cast');
		if ($prev->isa('PPI::Token::Symbol')) {
			$cast = $prev->raw_type;
			$found_symbol = 1;
		} elsif ($prev->isa('PPI::Structure::Block')) {
			$found_symbol = 1;
		} elsif ($found_symbol and $prev->isa('PPI::Token::Cast')) {
			$cast = $prev;
		} else {
			last unless $prev->isa('PPI::Structure::Subscript')
				or ($prev->isa('PPI::Token::Operator') and $prev eq '->');
		}
	}
	return () if $cast and ($cast eq '@' or $cast eq '%');
	
	return $self->violation(DESC, EXPL, $elem);
}

1;

=head1 NAME

Perl::Critic::Policy::Freenode::MultidimensionalArrayEmulation - Don't use
multidimensional array emulation

=head1 DESCRIPTION

When used with the C<@> or C<%> sigils, a list in a hash subscript (C<{}>) will
access multiple elements of the hash as a slice. With the C<$> sigil however,
it accesses the single element at the key defined by joining the list with the
subscript separator C<$;>. This feature is known as
L<perldata/"Multi-dimensional array emulation"> and provided a way to emulate
a multidimensional structure before Perl 5 introduced references. Perl now
supports true multidimensional structures, so this feature is now unnecessary
in most cases.

  $foo{$x,$y,$z}   # not ok
  $foo{qw(a b c)}  # not ok
  $foo{$x}{$y}{$z} # ok
  @foo{$x,$y,$z}   # ok

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Freenode>.

=head1 CONFIGURATION

This policy is not configurable except for the standard options.

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Perl::Critic>
