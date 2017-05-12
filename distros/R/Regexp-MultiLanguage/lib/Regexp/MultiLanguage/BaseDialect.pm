package Regexp::MultiLanguage::BaseDialect;

use Carp;
use strict;
use warnings;

=head1 NAME

Regexp::MultiLanguage::BaseDialect - Takes care of most
of the work of writing a dialect for Regexp::MultiLanguage

=head1 VERSION

Version 0.03

=cut

our $VERSION = 0.03;

=head1 SYNOPSIS

Handles interfacing with the Parse::RecDescent grammar to simplify
the code that must be written for a dialect of Regexp::MultiLanguage.

Dialect writers only need write the following functions: 

=over

=item C<wrap>

=item C<match_regex>

=item C<comment_start>

=item C<make_function>

=item C<function_call>

=back

=head1 TODO

Better describe the process of building a new dialect.

=cut

sub new {
	my $class = shift;
	bless { @_ }, $class;
}

# subclasses need to override
# wrap, match_regex, comment_start, make_function, function_call

sub wrap { croak "wrap is abstract" }
sub match_regex { croak "regex is abstract" }
sub comment_start { croak "comment is abstract" }
sub make_function { croak "make_function is abstract" }
sub function_call { croak "function_call is abstract" }

# and now, the meat

sub regex_file {
	my ($this,$item) = @_;
	
	return $this->wrap( $item->{'sequence'} );	
}

sub sequence {	
	return join "\n", @{ $_[1]->{'component(s)' } };
}

sub statement {
	my ($this,$item) = @_;
	
	$this->make_function( $item->{'identifier'}, $item->{'expr'} );	
}

sub comment { 
	my ($this,$item) = @_;
	
	my $comment = $item->{'__PATTERN1__'};
	$comment =~ s/^(\/\/|#)//;
	
	return $this->comment_start . $comment;
}

# expression handling

sub left_assoc {
	my $item = shift;
	my $cur = shift;
	my $next = shift;
	
	my $x = $item->{$cur.'_expr_i'} == 0 ? 1 : 0;
	return ( '(' x ($item->{$cur.'_expr_i'}->[1]+$x)) . $item->{$next.'_expr'} . (' ' x $x) . $item->{$cur.'_expr_i'}->[0] . (')' x $x);
}

sub left_assoc_i {
	my $item = shift;
	my $cur = shift;
	my $next = shift;
	my $child = shift || $next . '_expr';
	
	if ( exists $item->{$cur.'_op'} ) {
		return [' ' . $item->{$cur.'_op'} . ' ' . $item->{$child} . ')' . $item->{$cur.'_expr_i'}->[0], $item->{$cur.'_expr_i'}->[1] + 1 ];	
	} else {
		return ['',0];
	}
}	

sub or_expr {
	return left_assoc( $_[1], 'or', 'and' );
}

sub or_expr_i {
	return left_assoc_i( $_[1], 'or', 'and' );
}

sub and_expr { 
	return left_assoc( $_[1], 'and', 'not' );
}

sub and_expr_i {
	return left_assoc_i( $_[1], 'and', 'not' );
}

sub not_expr {
	my ( $this, $item ) = @_;
	
   return (exists $item->{'__STRING1__'} ? '!' : '') . $item->{'brack_expr'};
}

sub brack_expr {
	my ( $this, $item ) = @_;
	
	return '(' . $item->{'expr'} . ')' if exists $item->{'expr'};
	return $item->{'operand'}
}

sub operand {
	my ( $this, $item ) = @_;
	
	if ( exists $item->{'identifier'} ) {
		return $this->function_call( $item->{'identifier'} );
		
	} else {
		return $this->match_regex( $item->{'regex'} );
	}
}

=head1 SEE ALSO

L<Regexp::MultiLanguage>

=head1 AUTHOR

Robby Walker, robwalker@cpan.org

=head1 COPYRIGHT & LICENSE

Copyright 2006 Robby Walker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;