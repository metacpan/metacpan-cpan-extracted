package Parse::Token::Lite::Rule;
use Moose;

our $VERSION = '0.200'; # VERSION
# ABSTRACT: Rule class



has name=>(is=>'rw');


has re=>(is=>'rw', required=>1);


has func=>(is=>'rw');

has state=>(is=>'rw');



has flags=>(is=>'rw');


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Parse::Token::Lite::Rule - Rule class

=head1 VERSION

version 0.200

=head1 ATTRIBUTES

=head2 name

A name of the rule object. It is called also as 'type' or 'tag'.

=head2 re

A regexp to match on text for extract token.

=head2 func

A callback function for beging executed after re matching.

	sub{
		my ($parser, $token) = @_;
		...
		return @somevalues;
	}

The return values are passed by L<Parse::Token::Lite>::nextToken(), after token object.

=head2 state

Describe an array reference of chanined actions for changing a state of a parser.
Actions are invoked when the rule which contains them is matched.

An action begins '+' or '-'.
'+' means start().
'-' means end().

	{ state=>['+INTAG'], ...} # start INTAG; push()
	{ state=>['-INTAG'], ...} # end INTAG; pop()
	{ state=>['+PROP','+PROP_NAME'], ...} # start PROP, start PROP_NAME; push()->push()
	{ state=>['-INTAG','+CONTENT'], ...} # end INTAG, start CONTENT; pop()->push()

=head1 AUTHOR

khs <sng2nara@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by khs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
