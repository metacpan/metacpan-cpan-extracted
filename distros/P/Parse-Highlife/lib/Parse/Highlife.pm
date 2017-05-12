package Parse::Highlife;

use 5.014002;
use strict;
use warnings;

our $VERSION = '0.02';

use Parse::Highlife::Tokenizer;
use Parse::Highlife::Parser;
use Parse::Highlife::Transformer;
use Parse::Highlife::Compiler;

sub Compiler
{
	return Parse::Highlife::Compiler -> new( @_ );
}

1;
__END__

=head1 NAME

Parse::Highlife - Perl extension for grammar based parsing and transformation of data.

=head1 SYNOPSIS

  use Parse::Highlife;
  
  # define grammar (grammar for DEC format as an example)
	my $grammar = q{
		space ignored: /\s\n\r\t+/;
		multiline-comment ignored: "/*" .. "*/";
		singleline-comment ignored: /\#[^\n\r]*/;
		file: { declaration 0..* };	
			declaration: [ "@" identifier ] literal;
				literal: < map string real number identifier >;
					map: [ symbol ] "[" { pair 0..* } "]";
						pair: [ symbol ":" ] declaration;
					string: < double-quoted-string single-quoted-string >;
						double-quoted-string: '"' .. '"';
						single-quoted-string: "'" .. "'";
					real: /\d+\.\d+/;
					number: /\d+/;
					identifier: symbol { "." symbol 0..* };
						symbol: /[\w\d]+(\-[\w\d]+)*/;
	};
  
	# setup compiler
	my $compiler = Parse::Highlife -> Compiler;
	$compiler->grammar( $Grammar );
	$compiler->toprule( -name => 'file' );
  
	# compile document
	$compiler -> compile( 'myfile.txt' );

=head1 DESCRIPTION

Parse::Highlife is used to parse and transform string data. You can define
a grammar and a tokenizer, parser and transformer are generated. By
defining transformers for some you non-terminals.

This documentation is incomplete and will be expanded soon.

=head2 EXPORT

coming soon.

=head1 SEE ALSO

None.

=head1 AUTHOR

Tom Kirchner, E<lt>tom@kirchner.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Tom Kirchner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut

