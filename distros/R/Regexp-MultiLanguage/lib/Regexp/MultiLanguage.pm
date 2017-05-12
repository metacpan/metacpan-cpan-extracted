package Regexp::MultiLanguage;

use Parse::RecDescent;

use warnings;
use strict;

our $parser;

=head1 NAME

Regexp::MultiLanguage - Convert common regular expressions checks
in to Perl, PHP, and JavaScript code.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

Given a set of regular expressions in a simple format, this module writes
code for Perl, PHP, and JavaScript that uses those regular expressions.

    use Regexp::MultiLanguage qw(Perl JavaScript PHP);

    my $snippet = <<'END';
    number : integer || binary
    
    integer : /\d+/
    binary : /0b[01]+/i
    END
    
    print "Perl: \n";
	 print Regexp::MultiLanguage->compile( $snippet, 'Perl', 'isa_' );
	 
	 print "\nJavaScript: \n";
	 print Regexp::MultiLanguage->compile( $snippet, 'JavaScript', 'isa_' );
	 
	 print "\nPHP: \n";
	 print Regexp::MultiLanguage->compile( $snippet, 'PHP', 'isa_' );
	 
=head1 FORMAT

The format used is similar to L<Parse::RecDescent>:

	name : expr
	
where C<expr> is a boolean expression where each term is either another C<name> or
a regular expression.

=head1 FUNCTIONS

=head2 compile

Usage: Regexp::MultiLanguage->compile( $code, $language, [$function_prefix] );

For each C<name> in the L<code/"FORMAT">, generates one function whose name is
C<[$function_prefix]name>.  These functions will compile in the language specified
(must be C<Perl>, C<PHP>, or C<JavaScript>).

=cut

sub compile {
	my $class = shift;
	my $script = shift;
	my $dialect = shift;
	my $prefix = shift || '';
	
	my $di_obj = ('Regexp::MultiLanguage::'.$dialect)->new( 'prefix' => $prefix );
	
	unless ( $parser ) {

		$::RD_AUTOACTION = q
		| my $d = $thisparser->{'local'}->{'dialect'};
		  #print $item[0], "\n";
		  if ( my $f = $d->can( $item[0] ) ) { $return = $d->$f( \%item ); }
		  else { $return = $item[ $#item ]; }
		  1; |;

		# see the __DATA__ section below for the grammar definition
		my $fh;
		{
			no strict "refs";
			$fh = \*{"Regexp::MultiLanguage::DATA"};
		}
		my $grammar = ''; my $line;
		while ( defined( $line = <$fh> ) and $line !~ m/^__END__/ ) {
			$grammar .= $line;
		}
		close Regexp::MultiLanguage::DATA;

		$parser = Parse::RecDescent->new( $grammar );	
	}
	
	$parser->{'local'}->{'dialect'} = $di_obj;
	
	return $parser->regex_file( $script );
}

# import the following languages
sub import {
	my $class = shift;
	my $prefix = 'Regexp::MultiLanguage::';
	
	foreach ( @_ ) {
		eval "require ${prefix}$_";
		die $@ if $@;
	}
}

=head1 AUTHOR

Robby Walker, robwalker@cpan.org

=head1 BUGS

Please report any bugs or feature requests to
C<bug-regexp-multilanguage at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Regexp-MultiLanguage>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 TODO

=over

=item More tests.

=item Allow named captures 

=item Allow matching against captures

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Regexp::MultiLanguage

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Regexp-MultiLanguage>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Regexp-MultiLanguage>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Regexp-MultiLanguage>

=item * Search CPAN

L<http://search.cpan.org/dist/Regexp-MultiLanguage>

=back

=head1 ACKNOWLEDGEMENTS

The development of this module was supported by L<http://www.e-tutor.com>.

=head1 SEE ALSO

This module was developed for use in L<REV> - the multi-language validation solution.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Robby Walker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Regexp::MultiLanguage

__DATA__

regex_file : sequence eofile | <error>

sequence : component(s)

component : comment | statement

statement : identifier ':' expr

comment : /((\/\/)|#)[^\n]*/

eofile: /^\Z/

empty : {''}

# expressions

expr: or_expr

or_expr : and_expr or_expr_i
or_expr_i : or_op and_expr or_expr_i | empty
or_op : '||'

and_expr : not_expr and_expr_i
and_expr_i : and_op not_expr and_expr_i | empty
and_op : '&&'

not_expr : '!' <commit> brack_expr | brack_expr

brack_expr : '(' expr ')' | operand

operand : identifier | regex

identifier : /[_a-z]\w*/i

regex : '/' <commit> 
        { 
				my @result = extract_quotelike('m/'.$text); 
				$text = $result[1];
				$return = $result[0];
		  } 
		  | # try without implicit 'm'		  
		  { 
				my @result = extract_quotelike($text);
				$text = $result[1];
				return undef unless ( $result[3] =~ /m|(qr)|\// );
				$return = $result[0];
		  }
        

