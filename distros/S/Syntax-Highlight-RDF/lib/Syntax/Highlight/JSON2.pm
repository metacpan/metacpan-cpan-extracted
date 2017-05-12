use 5.008;
use strict;
use warnings;

{
	package Syntax::Highlight::JSON2;

	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.003';
	
	use MooX::Struct -retain, -rw,
		Feature                   => [],
		Token                     => [-extends => [qw<Feature>], qw($spelling!)],
		Brace                     => [-extends => [qw<Token>]],
		Bracket                   => [-extends => [qw<Token>]],
		String                    => [-extends => [qw<Token>]],
		Number                    => [-extends => [qw<Token>]],
		Number_Double             => [-extends => [qw<Number>]],
		Number_Decimal            => [-extends => [qw<Number>]],
		Number_Integer            => [-extends => [qw<Number>]],
		Punctuation               => [-extends => [qw<Token>]],
		Keyword                   => [-extends => [qw<Token>]],
		Boolean                   => [-extends => [qw<Keyword>]],
		Whitespace                => [-extends => [qw<Token>]],
		Unknown                   => [-extends => [qw<Token>]],
	;

	use Throwable::Factory
		Tokenization              => [qw( $remaining -caller )],
		NotImplemented            => [qw( -notimplemented )],
		WTF                       => [],
		WrongInvocant             => [qw( -caller )],
	;

	{
		use HTML::HTML5::Entities qw/encode_entities/;
		
		no strict 'refs';
		*{Feature    . "::tok"}        = sub { sprintf "%s~", $_[0]->TYPE };
		*{Token      . "::tok"}        = sub { sprintf "%s[%s]", $_[0]->TYPE, $_[0]->spelling };
		*{Whitespace . "::tok"}        = sub { $_[0]->TYPE };
		*{Feature    . "::TO_STRING"}  = sub { "" };
		*{Token      . "::TO_STRING"}  = sub { $_[0]->spelling };
		*{Token      . "::TO_HTML"}    = sub {
			sprintf "<span class=\"json_%s\">%s</span>", lc $_[0]->TYPE, encode_entities($_[0]->spelling)
		};
		*{Whitespace . "::TO_HTML"}  = sub { $_[0]->spelling };
	}

	our %STYLE = (
		json_brace       => 'color:#990000;font-weight:bold',
		json_bracket     => 'color:#990000;font-weight:bold',
		json_punctuation => 'color:#990000;font-weight:bold',
		json_string      => 'color:#cc00cc',
		json_keyword     => 'color:#cc00cc;font-weight:bold;font-style:italic',
		json_boolean     => 'color:#cc00cc;font-weight:bold;font-style:italic',
		json_unknown     => 'color:#ffff00;background-color:#660000;font-weight:bold',
		json_number_double     => 'color:#cc00cc;font-weight:bold',
		json_number_decimal    => 'color:#cc00cc;font-weight:bold',
		json_number_integer    => 'color:#cc00cc;font-weight:bold',
	);

	use Moo;

	has _tokens     => (is => 'rw');
	has _remaining  => (is => 'rw');
	
	use IO::Detect qw( as_filehandle );
	use Scalar::Util qw( blessed );
		
	sub _peek
	{
		my $self = shift;
		my ($regexp) = @_;
		$regexp = qr{^(\Q$regexp\E)} unless ref $regexp;
		
		if (my @m = (${$self->_remaining} =~ $regexp))
		{
			return \@m;
		}
		
		return;
	}

	sub _pull_token
	{
		my $self = shift;
		my ($spelling, $class, %more) = @_;
		defined $spelling or WTF->throw("Tried to pull undef token!");
		substr(${$self->_remaining}, 0, length $spelling, "");
		push @{$self->_tokens}, $class->new(spelling => $spelling, %more);
	}

	sub _pull_whitespace
	{
		my $self = shift;
		$self->_pull_token($1, Whitespace)
			if ${$self->_remaining} =~ m/^(\s*)/sm;
	}
	
	sub _pull_string
	{
		my $self = shift;
		# Extract string with escaped characters
		${$self->_remaining} =~ m#^("((?:[^\x00-\x1F\\"]|\\(?:["\\/bfnrt]|u[[:xdigit:]]{4})){0,32766})*")#
			? $self->_pull_token($1, String)
			: $self->_pull_token('"', Unknown);
	}
	
	sub _serializer
	{
		require RDF::Trine::Serializer::RDFJSON;
		return "RDF::Trine::Serializer::RDFJSON";
	}
	
	sub _scalarref
	{
		my $self = shift;
		my ($thing) = @_;
		
		if (blessed $thing and $thing->isa("RDF::Trine::Model"))
		{
			$thing = $thing->as_hashref;
		}
		
		if (blessed $thing and $thing->isa("RDF::Trine::Iterator") and $thing->can("as_json"))
		{
			my $t = $thing->as_json;
			$thing = \$t
		}
		
		if (blessed $thing and $thing->isa("RDF::Trine::Iterator") and $self->can("_serializer"))
		{
			my $t = $self->_serializer->new->serialize_iterator_to_string($thing);
			$thing = \$t
		}
		
		if (!blessed $thing and ref $thing =~ /^(HASH|ARRAY)$/)
		{
			require JSON;
			my $t = JSON::to_json($thing, { pretty => 1, canonical => 1 });
			$thing = \$t;
		}
		
		unless (ref $thing eq 'SCALAR')
		{
			my $fh = as_filehandle($thing);
			local $/;
			my $t = <$fh>;
			$thing = \$t;
		}
		
		return $thing;
	}
	
	sub tokenize
	{
		my $self = shift;
		ref $self or WrongInvocant->throw("this is an object method!");
		
		$self->_remaining( $self->_scalarref(@_) );
		$self->_tokens([]);
		
		# Declare this ahead of time for use in the big elsif!
		my $matches;
		
		while (length ${ $self->_remaining })
		{
			$self->_pull_whitespace if $self->_peek(qr{^\s+});
			
			if ($matches = $self->_peek(qr!^([\,\:])!))
			{
				$self->_pull_token($matches->[0], Punctuation);
			}
			elsif ($matches = $self->_peek(qr!^([\[\]])!))
			{
				$self->_pull_token($matches->[0], Bracket);
			}
			elsif ($matches = $self->_peek(qr!^( \{ | \} )!x))
			{
				$self->_pull_token($matches->[0], Brace);
			}
			elsif ($self->_peek("null"))
			{
				$self->_pull_token("null", Keyword);
			}
			elsif ($matches = $self->_peek(qr!^(true|false)!))
			{
				$self->_pull_token($matches->[0], Boolean);
			}
			elsif ($self->_peek('"'))
			{
				$self->_pull_string;
			}
			elsif ($matches = $self->_peek(qr!^([-]?(?:0|[1-9][0-9]*)(?:\.[0-9]*)?(?:[eE][+-]?[0-9]+)?)!))
			{
				my $n = $matches->[0];
				if ($n =~ /e/i)    { $self->_pull_token($n, Number_Double) }
				elsif ($n =~ /\./) { $self->_pull_token($n, Number_Decimal) }
				else               { $self->_pull_token($n, Number_Integer) }
			}
			elsif ($matches = $self->_peek(qr/^([^\s\r\n]+)[\s\r\n]/ms))
			{
				$self->_pull_token($matches->[0], Unknown);
			}
			elsif ($matches = $self->_peek(qr/^([^\s\r\n]+)$/ms))
			{
				$self->_pull_token($matches->[0], Unknown);
			}
			else
			{
				Tokenization->throw(
					"Could not tokenise string!",
					remaining => ${ $self->_remaining },
				);
			}
			
			$self->_pull_whitespace if $self->_peek(qr{^\s+});
		}
		
		return $self->_tokens;
	}
	
	sub highlight
	{
		my $self = shift;
		ref $self or WrongInvocant->throw("this is an object method!");
		
		$self->tokenize(@_);
		return join "", map $_->TO_HTML, @{$self->_tokens};
	}
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Syntax::Highlight::JSON2 - syntax highlighting for JSON

=head1 SYNOPSIS

  use Syntax::Highlight::JSON2;
  my $syntax = "Syntax::Highlight::JSON2"->new;
  print $syntax->highlight($filehandle);

=head1 DESCRIPTION

Outputs pretty syntax-highlighted HTML for JSON. (Actually just
adds C<< <span> >> elements with C<< class >> attributes. You're expected to
bring your own CSS.)

There's nothing significant in the number "2" in the name of this module.
There was just already a L<Syntax::Highlight::JSON> on CPAN, which seems
completely undocumented so I'm a little scared to use it!

=head2 Methods

=over

=item C<< highlight($input) >>

Highlight some JSON.

C<< $input >> may be a file handle, filename or a scalar ref of text.

Returns a string of HTML.

=item C<< tokenize($input) >>

This is mostly intended for subclassing Syntax::Highlight::JSON.

C<< $input >> may be a file handle, filename or a scalar ref of text.

Returns an arrayref of token objects. The exact API for the token objects
is subject to change, but currently they support C<< TYPE >> and
C<< spelling >> methods.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Syntax-Highlight-RDF>.

=head1 SEE ALSO

L<Syntax::Highlight::RDF>,
L<Syntax::Highlight::XML>.

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

