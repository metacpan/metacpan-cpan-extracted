package PPIx::Regexp::StringTokenizer;

use 5.006;

use strict;
use warnings;

use base qw{ PPIx::Regexp::Tokenizer };

use Carp;
use PPIx::Regexp::Constant qw{
    TOKEN_UNKNOWN
    @CARP_NOT
};

our $VERSION = '0.063';

{
    # Names of classes containing tokenization machinery. There are few
    # known ordering requirements, since each class recognizes its own,
    # and I have tried to prevent overlap. Absent such constraints, the
    # order is in perceived frequency of acceptance, to keep the search
    # as short as possible. If I were conscientious I would gather
    # statistics on this.
    my @classes = (	# TODO make readonly when acceptable way appears
	'PPIx::Regexp::Token::Literal',
	'PPIx::Regexp::Token::Interpolation',
	'PPIx::Regexp::Token::Control',			# Note 1
#	'PPIx::Regexp::Token::CharClass::Simple',	# Note 2
#	'PPIx::Regexp::Token::Quantifier',
#	'PPIx::Regexp::Token::Greediness',
#	'PPIx::Regexp::Token::CharClass::POSIX',	# Note 3
#	'PPIx::Regexp::Token::Structure',
#	'PPIx::Regexp::Token::Assertion',
#	'PPIx::Regexp::Token::Backreference',
#	'PPIx::Regexp::Token::Operator',		# Note 4
    );

    # Note 1: If we are in quote mode ( \Q ... \E ), Control makes a
    #		literal out of anything it sees other than \E. So it
    #		needs to come before almost all other tokenizers. Not
    #		Literal, which already makes literals, and not
    #		Interpolation, which is legal in quote mode, but
    #		everything else.

    # Note 2: CharClass::Simple must come after Literal, because it
    #		relies on Literal to recognize a Unicode named character
    #		( \N{something} ), so any \N that comes through to it
    #		must be the \N simple character class (which represents
    #		anything but a newline, and was introduced in Perl
    #		5.11.0.

    # Note 3: CharClass::POSIX has to come before Structure, since both
    #		look for square brackets, and CharClass::POSIX is the
    #		more particular.

    # Note 4: Operator relies on Literal making the characters literal
    #		if they appear in a context where they can not be
    #		operators, and Control making them literals if quoting,
    #		so it must come after both.

    # Return the declared tokenizer classes.
    sub __tokenizer_classes {
	return @classes;
    }

}

my %bare_delim = map { $_ => 1 } qw{ ' " ` };

sub __PPIX_TOKENIZER__init {
    my ( $self ) = @_;

    my @tokens;

    if ( $self->find_regexp( qr{ \A \s* << }smx ) ) {

	my ( $leading_white, $next_white, $delim );
	if ( $self->find_regexp( qr{ \A ( \s* ) << ( \w+ \n ) }smx ) ) {
	    ( $leading_white, $delim ) = $self->capture();
	    $next_white = '';
	} elsif ( $self->find_regexp(
		qr{ \A ( \s* ) << ( \s+ ) ( ( ["'] ) .*? \4 \n ) }smx )
	    ) {
	    ( $leading_white, $next_white, $delim ) = $self->capture();
	} else {
	    return $self->__init_error();
	}

	$self->{type} = '<<';

	$self->{delimiter_start} = $delim;
	if ( $delim =~ s/ \A ( ["'] ) ( .* ) \1 \n \z /$2\n/smx ) {
	    my $quote = $1;
	    $delim =~ s/ \\ (?= \Q$quote\E ) //smxg;
	}

	'' ne $leading_white
	    and push @tokens, $self->make_token( length $leading_white,
	    'PPIx::Regexp::Token::Whitespace' );
	push @tokens, $self->make_token( length $self->{type},
	    'PPIx::Regexp::Token::Structure' );
	'' ne $next_white
	    and push @tokens, $self->make_token( length $next_white,
	    'PPIx::Regexp::Token::Whitespace' );
	push @tokens, $self->make_token( length $self->{delimiter_start},
	    'PPIx::Regexp::Token::Delimiter' );

	my ( $offset ) = $self->find_regexp( qr{ \Q$delim\E }smx )
	    or return $self->__init_error();
	my $cursor_limit = $self->{cursor_curr} + $offset;
	$self->{trace}
	    and warn "Tokenizer found here doc end delimiter at $cursor_limit\n";
	$self->{cursor_limit} = $cursor_limit;
	$self->{cursor_modifiers} = $cursor_limit + length $delim;
	$self->{delimiter_finish} = $delim;

    } elsif ( $self->find_regexp(
	    qr{ \A ( \s* ) ( qq | q | qx )? ( \s* ) ( [^\w\s] ) }smx ) )
    {

	my ( $leading_white, $type, $next_white, $delim ) = $self->capture();

	unless ( defined $type ) {
	    $bare_delim{$delim}
		or return $self->__init_error();
	    $type = '';
	}

	$self->{type} = $type;

	'' ne $leading_white
	    and push @tokens, $self->make_token( length $leading_white,
	    'PPIx::Regexp::Token::Whitespace' );
	push @tokens, $self->make_token( length $type,
	    'PPIx::Regexp::Token::Structure' );
	'' ne $next_white
	    and push @tokens, $self->make_token( length $next_white,
	    'PPIx::Regexp::Token::Whitespace' );

	$self->{delimiter_start} = substr
	    $self->{content},
	    $self->{cursor_curr},
	    1;

	$self->{trace}
	    and warn "Tokenizer found string start delimiter '$self->{delimiter_start}' at $self->{cursor_curr}\n";

	my $offset = $self->find_matching_delimiter()
	    or return $self->__init_error(
	    'Tokenizer found mismatched string delimiters' );

	my $cursor_limit = $self->{cursor_curr} + $offset;
	$self->{trace}
	    and warn "Tokenizer found string end delimiter at $cursor_limit\n";
	$self->{cursor_limit} = $cursor_limit;
	$self->{cursor_modifiers} = $cursor_limit + 1;
	$self->{delimiter_finish} = substr
	    $self->{content},
	    $self->{cursor_limit},
	    1;

	push @tokens, $self->make_token( 1,
	    'PPIx::Regexp::Token::Delimiter' );


    } else {
	return $self->__init_error();
    }

    {
	pos $self->{content} = $self->{cursor_modifiers};
	local $self->{cursor_curr} = $self->{cursor_modifiers};
	local $self->{cursor_limit} = length $self->{content};
	my @trailing;
	if ( my $len = $self->find_regexp( qr{ \A \s+ }smx ) ) {
	    push @trailing, $self->make_token( $len,
		'PPIx::Regexp::Token::Whitespace' );
	}
	if ( my $len = $self->find_regexp( qr{ \A .+ }smx ) ) {
	    push @trailing, $self->make_token( $len, TOKEN_UNKNOWN, {
		    error	=> 'Trailing characters after expression',
		} );
	}
	$self->{trailing_tokens} = \@trailing;
	$self->{effective_modifiers} = undef;
	$self->{modifiers} = [ {} ];
    }

    $self->{find} = undef;

    $self->_set_mode( 'repl' );

    return @tokens;
}

# Return the number of extra delimited parts. This will be 0 for all
# strings.
sub __number_of_extra_parts {
    return 0;
}

# Return the classes for the parts of the expression.
sub __part_classes {
    return ( 'PPIx::Regexp::Structure::Replacement' );
}

{
    my %from_delim = map { $_ => 1 } '', 'qx', '<<';
    my %from_type = map { $_ => 1 } qw{ qq qx };

    sub interpolates {
	my ( $self ) = @_;
	$from_delim{$self->{type}}
	    and return $self->{delimiter_start} !~ m/ \A ' /smx;
	return $from_type{$self->{type}};
    }
}

1;

__END__

=head1 NAME

PPIx::Regexp::StringTokenizer - Tokenize a string literal

=head1 SYNOPSIS

 use PPIx::Regexp::Dumper;
 PPIx::Regexp::Dumper->new( 'qq{foo$bar}', parse => 'string' )
     ->print();

C<PPIx::Regexp::StringTokenizer> is a
L<PPIx::Regexp::Tokenizer|PPIx::Regexp::Tokenizer>.

C<PPIx::Regexp::StringTokenizer> has no descendants.

=head1 DESCRIPTION

This class provides tokenization of string literals. It is deprecated in
favor of the use of L<PPIx::QuoteLike|PPIx::QuoteLike>.

=head1 METHODS

This class supports no public methods over and above those of the
superclass.

=head1 SEE ALSO

L<PPIx::Regexp::Tokenizer|PPIx::Regexp::Tokenizer>.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Tom Wyant F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015-2018 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
