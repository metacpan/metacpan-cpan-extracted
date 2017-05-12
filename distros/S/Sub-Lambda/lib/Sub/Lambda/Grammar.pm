package Sub::Lambda::Grammar;

use warnings;
use strict;
use Parse::RecDescent;

use base qw(Exporter);
our @EXPORT_OK = qw(parse);

my $grammar = q{

Parse       : /^/ Expression /$/ { $item[2] }

Expression  : Unit(s)
              { (join "->", map {qq(($_))} @{$item[1]}) }

Unit        : Code | Lambda | Parens | Symbol

Parens      : '(' Expression ')' { $item[2] }

Lambda      : /[\\\\]/ Pattern /\-\>/ Expression
              { qq( sub { my $item[2] = \@_; $item[4] } ) }

Pattern     : (PWords | Words) { qq(($item[1])) }
Symbol      : DWord | Word

Code        : '{' Block(s?) '}' 
              { my $x = join ' ', @{$item[2]}; "do {$x}" }
NoBlock     : /[^{}]+/
Block       : NoBlock | '{' Block(s?) '}' 
              { my $x = join ' ', @{$item[2]}; "{$x}" }

PWords      : '(' Words ')' { $item[2] }
Words       : DWord | MWords
MWords      : Word(s) DWord(?) { join ',', @{$item[1]}, @{$item[2]} }
Word        : /[a-zA-Z]\w*/ { '$' . $item[1] }
DWord       :  '-' Word { '@' . substr($item[2],1) }

};

our $parser = new Parse::RecDescent($grammar);

=head1 NAME

Sub::Lambda::Grammar

=head1 DESCRIPTION

Defines the lambda grammar for L<Sub::Lambda::Filter>.

=head2 METHODS

=over

=item parse($string)

Runs a L<Parse::RecDescent> parser on its in put with a grammar defined in this 
module. In effect, translates embedded lambda expressions to Perl code.

=cut

sub parse ($) { $parser->Parse($_[0]) }

1;

__END__

=back 

=head1 AUTHOR

Anton Tayanovskyy <name.surname@gmail.com>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Anton Tayanovskyy. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Sub::Lambda::Filter>

=cut
