package PPIx::QuoteLike::Utils;

use 5.006;

use strict;
use warnings;

use base qw{ Exporter };

use Carp;
use PPIx::QuoteLike::Constant qw{
    HAVE_PPIX_REGEXP
    LOCATION_LINE
    LOCATION_CHARACTER
    LOCATION_COLUMN
    LOCATION_LOGICAL_LINE
    LOCATION_LOGICAL_FILE
    VARIABLE_RE
    @CARP_NOT
};
use Readonly;
use Scalar::Util ();

use constant LEFT_CURLY		=> q<{>;
use constant RIGHT_CURLY	=> q<}>;

our @EXPORT_OK = qw{
    column_number
    is_ppi_quotelike_element
    line_number
    logical_filename
    logical_line_number
    statement
    visual_column_number
    __instance
    __match_enclosed
    __matching_delimiter
    __normalize_interpolation_for_ppi
    __variables
};

our $VERSION = '0.013';

# Readonly::Scalar my $BRACED_RE	=> __match_enclosed( LEFT_CURLY );
Readonly::Scalar my $BRACKETED_RE	=> __match_enclosed( '[' ); # ]
Readonly::Scalar my $PARENTHESIZED_RE	=> __match_enclosed( '(' ); # )

Readonly::Scalar my $SIGIL_AND_CAST_RE	=> qr/ \$ \# \$* | [\@\$] \$* /smx;
# The following is an interpretation of perldata Identifier Parsing for
# Perls before 5.10.
Readonly::Scalar my $SYMBOL_NAME_RE	=> qr/
    \^? (?:
	(?: :: )* '?
	    \w+ (?: (?: (?: :: )+ '? | (?: :: )* ' ) \w+ )*
	    (?: :: )* |
	[[:punct:]]
    )
/smx;


sub column_number {
    my ( $self ) = @_;
    return ( $self->location() || [] )->[LOCATION_CHARACTER];
}

{

    my @relevant_ppi_classes = qw{
	PPI::Token::Quote
	PPI::Token::QuoteLike::Backtick
	PPI::Token::QuoteLike::Command
	PPI::Token::QuoteLike::Readline
	PPI::Token::HereDoc
    };

    sub is_ppi_quotelike_element {
	my ( $elem ) = @_;

	ref $elem
	    or return;

	Scalar::Util::blessed( $elem )
	    or return;

	foreach my $class ( @relevant_ppi_classes ) {
	    $elem->isa( $class )
		and return 1;
	}

	return;
    }

    # TODO make these state varables once we can require Perl 5.10.
    my $postderef = { map { $_ => 1 } qw{ @* %* } };

    my $cast_allowed_for_bare_bracketed_variable = {
	map { $_ => 1 } qw{ @ $ % } };

    sub __variables {
	my ( $ppi ) = @_;

	# In case we need to manufacture any.
	require PPIx::QuoteLike;

	Scalar::Util::blessed( $ppi )
	    or croak 'Argument must be an object';

	# TODO the following two lines are a crock, but there does not
	# seem to be a good alternative. Bad alternatives:
	# * Introduce PPIx::QuoteLike::Element. But it seems stupid to
	#   introduce a class simply to mark these as members of the
	#   PPIx::QuoteLike family.
	#   If I go this way at all, PPIx::QuoteLike::Element should be
	#   analogous to PPIx::Regexp::Element in that it carries at
	#   least the navigational and Perl version methods.
	# * Use DOES(). But that was not introduced until 5.10. So I
	#   could:
	#   - Depend on UNIVERSAL::DOES. This kindly steps aside if
	#     UNIVERSAL::DOES() exists, but it seems stupid to introduce
	#     a dependency that is only needed under really old Perls.
	#   - Same as above, only make the dependence conditional on the
	#     version of Perl. This may actually be the best
	#     alternative, but it's still pretty crufty.
	$ppi->isa( 'PPIx::QuoteLike' )
	    and return $ppi->variables();
	$ppi->isa( 'PPIx::QuoteLike::Token' )
	    and return $ppi->variables();

	my %var;

	$ppi->isa( 'PPIx::Regexp::Element' )
	    and do {
		foreach my $code ( @{ $ppi->find(
		    'PPIx::Regexp::Token::Code' ) || [] } ) {
		    foreach my $name ( __variables( $code->ppi() ) ) {
			$var{ $name } = 1;
		    }
		}
		return keys %var;
	    };


	$ppi->isa( 'PPI::Element' )
	    or croak 'Argument must be a PPI::Element, ',
		'PPIx::Regexp::Element, PPIx::QuoteLike, or ',
		'PPIx::QuoteLike::Token';

	foreach my $sym ( _find( $ppi, 'PPI::Token::Symbol' ) ) {
	    # The problem we're solving here is that PPI parses postfix
	    # dereference as though it makes reference to non-existent
	    # punctuation variables '@*' or '%*'. The following
	    # statement omits these from output if they are preceded by
	    # the '->' operator.
	    my $prev;
	    $postderef->{ $sym->content() }
		and $prev = $sym->sprevious_sibling()
		and $prev->isa( 'PPI::Token::Operator' )
		and '->' eq $prev->content()
		and next;
	    # Eliminate rogue subscripts
	    _is_bareword_subscript( $sym )
		and next;
	    if ( defined( my $name = _name_from_misparsed_magic( $sym ) )
	    ) {
		# We're $${name}, which is a dereference of $name
		$var{$name} = 1;
	    } else {
		# PPI got it right.
		$var{ $sym->symbol() } = 1;
	    }
	}

        # For some reason, PPI parses '$#foo' as a
        # PPI::Token::ArrayIndex.  $#$foo is parsed as a Cast followed
        # by a Symbol, so as long as nobody decides the '$#' cast causes
        # $elem->symbol() to return something other than '$foo', we're
        # cool.
        foreach my $elem ( _find( $ppi, 'PPI::Token::ArrayIndex' ) ) {
            my $name = $elem->content();
            $name =~ s/ \A \$ [#] /@/smx or next;
	    $var{$name} = 1;
        }

        # Occasionally you see something like ${foo} outside quotes.
        # This is legitimate, though PPI parses it as a cast followed by
        # a block. On the assumption that there are fewer blocks than
        # words in most Perl, we start at the top and work down. Perl
        # also handles punctuation variables specified this way, but
        # since PPI goes berserk when it sees this, we won't bother.
        foreach my $elem ( _find( $ppi, 'PPI::Structure::Block' ) ) {

            my $previous = $elem->sprevious_sibling()
                or next;
            $previous->isa( 'PPI::Token::Cast' )
                or next;
            my $sigil = $previous->content();
            $cast_allowed_for_bare_bracketed_variable->{ $sigil }
                or next;

	    if ( my @kids = $elem->schildren() ) {
		# The simple case: we parsed a block whose contents,
		# however they were parsed, are the contents of the
		# token.
		1 == @kids
		    or next;
		$kids[0]->isa( 'PPI::Statement' )
		    or next;

		( my $name = join '', map { $_->content() }
		    $kids[0]->children() ) =~ m/ \A @{[ VARIABLE_RE ]} \z /smxo
		    or next;

		$var{ "$sigil$name" } = 1;
	    } else {
		# The downright ugly case. We have something like ${]}
		# where PPI can't find the terminator. To solve this we
		# need to go blundering through the parse until we find
		# the closing terminator.
		my $stmt = $elem->statement()
		    or next;
		if ( my $finish = $elem->finish() ) {
		    # If we appear to have a terminated block, we may # {{
		    # have ${}}, which is the same as $}
		    my $next = $stmt->next_sibling()
			or next;
		    $next->isa( 'PPI::Statement::UnmatchedBrace' )
			and RIGHT_CURLY eq $next->content()
			or next;
		    $var{ $sigil . $finish->content() } = 1;
		} else {
		    # Otherwise we have something like # [
		    # ${]}
		    my $next = $stmt->next_sibling()
			or next;
		    my $finish = $next->next_sibling()
			or next;
		    $finish->isa( 'PPI::Statement::UnmatchedBrace' )
			and RIGHT_CURLY eq $finish->content()
			or next;
		    $var{ $sigil . $next->content() } = 1;
		}
	    }
        }

	# Yes, we might have nested string literals, like
	# "... @{[ qq<$foo> ]} ..."
	foreach my $class ( @relevant_ppi_classes ) {
	    foreach my $elem ( _find( $ppi, $class ) ) {

		my $ql = PPIx::QuoteLike->new( $elem )
		    or next;
		$ql->interpolates()
		    or next;
		foreach my $sym ( $ql->variables() ) {
		    $var{ $sym } = 1;
		}
	    }
	}

	# By the same token we might have a regexp
	# TODO for consistency's sake, give PPIx::Regexp a variables()
	# method.
	if ( HAVE_PPIX_REGEXP ) {
	    foreach my $class ( qw{
		    PPI::Token::QuoteLike::Regexp
		    PPI::Token::Regexp::Match
		    PPI::Token::Regexp::Substitute
		} ) {
		foreach my $elem ( _find( $ppi, $class ) ) {
		    my $re = PPIx::Regexp->new( $elem )
			or next;
		    foreach my $code ( @{ $re->find(
			'PPIx::Regexp::Token::Code' ) || [] } ) {
			foreach my $name ( __variables( $code->ppi() ) ) {
			    $var{ $name } = 1;
			}
		    }
		}
	    }
	}

	return ( keys %var );
    }
}

# We want __variables to work when passed a single token. So we go
# through this to do what we wish PPI did -- return an array for a
# PPI::Node, or return either the element itself or nothing otherwise.
sub _find {
    my ( $elem, $class ) = @_;
    $elem->isa( 'PPI::Node' )
	and return @{ $elem->find( $class ) || [] };
    $elem->isa( $class )
	and return $elem;
    return;
}

sub __instance {
    my ( $object, $class ) = @_;
    Scalar::Util::blessed( $object ) or return;
    return $object->isa( $class );
}

# The problem this solves is that PPI can parse '{_}' as containing a
# PPI::Token::Magic (which is a PPI::Token::Symbol), not a
# PPI::Token::Word. This code also returns true for '${_}', which is not
# a subscript but has the same basic problem. The latter gets caught
# later.
sub _is_bareword_subscript {
    my ( $elem ) = @_;
    $elem->content() =~ m/ \A \w+ \z /smx
	or return;
    my $parent;
    $parent = $elem->parent()
	and $parent->isa( 'PPI::Statement' )
	and 1 == $parent->children()
	or return;
    $parent = $parent->parent()
	and ( $parent->isa( 'PPI::Structure::Subscript' )
	    or $parent->isa( 'PPI::Structure::Block' ) )
	and 1 == $parent->children()
	or return;
    my $start;
    $start = $parent->start()
	and $start->isa( 'PPI::Token::Structure' )
	and q<{> eq $start->content()
	or return;
    return 1;
}

sub line_number {
    my ( $self ) = @_;
    return ( $self->location() || [] )->[LOCATION_LINE];
}

sub logical_filename {
    my ( $self ) = @_;
    return ( $self->location() || [] )->[LOCATION_LOGICAL_FILE];
}

sub logical_line_number {
    my ( $self ) = @_;
    return ( $self->location() || [] )->[LOCATION_LOGICAL_LINE];
}

{
    our %REGEXP_CACHE;

    my %matching_bracket;

    BEGIN {
	%matching_bracket = qw/ ( ) [ ] { } < > /;
    }

    sub __match_enclosed {
	my ( $left ) = @_;
	my $ql = quotemeta $left;

	$REGEXP_CACHE{$ql}
	    and return $REGEXP_CACHE{$ql};

	if ( my $right = $matching_bracket{$left} ) {

	    # Based on Regexp::Common $RE{balanced} 2.113 (because I
	    # can't use (?-1)

	    my $ql = quotemeta $left;
	    my $qr = quotemeta $right;
	    my $pkg = __PACKAGE__;
	    my $r  = "(??{ \$${pkg}::REGEXP_CACHE{'$ql'} })";

	    my @parts = (
		"(?>[^\\\\$ql$qr]+)",
		"(?>\\\$[$ql$qr])",
		'(?>\\\\.)',
		$r,
	    );

	    {
		use re qw{ eval };
		local $" = '|';
		$REGEXP_CACHE{$ql} = qr/($ql(?:@parts)*$qr)/sm;
	    }

	    return $REGEXP_CACHE{$ql};

	} else {

	    # Based on Regexp::Common $RE{delimited}{-delim=>'`'}
	    return ( $REGEXP_CACHE{$ql} ||=
		qr< (?:
		    (?: \Q$left\E )
		    (?: [^\\\Q$left\E]* (?: \\ . [^\\\Q$left\E]* )* )
		    (?: \Q$left\E )
		) >smx
	    );
	}
    }

    sub __matching_delimiter {
	my ( $left ) = @_;
	my $right = $matching_bracket{$left}
	    or return $left;
	return $right;
    }
}

sub __normalize_interpolation_for_ppi {
    ( local $_ ) = @_;

    # "@{[ foo() ]}" => 'foo()'
    if ( m/ \A \@ [{] \s* ( $BRACKETED_RE ) \s* [}] \z /smx ) {
	$_ = $1;
	s/ \A [[] \s* //smx;
	s/ \s* []] \z //smx;
	return "$_";
    }

    # "${\( foo() )}" => 'foo()'
    if ( m/ \A \$ [{] \s* \\ \s* ( $PARENTHESIZED_RE ) \s* [}] \z /smx ) {
	$_ = $1;
	s/ \A [(] \s* //smx;
	s/ \s* [)] \z //smx;
	return "$_";
    }

    # "${foo}" => '$foo'
    m/ \A ( $SIGIL_AND_CAST_RE ) \s* [{] \s* ( $SYMBOL_NAME_RE ) \s* [}] \z /smx
	and return "$1$2";

    # "${foo{bar}}" => '$foo{bar}'
    # NOTE that this is a warning, and so not done.
#    if ( m/ \A ( $SIGIL_AND_CAST_RE ) (?= [{] ) ( $BRACED_RE ) /smx ) {
#	( my $sigil, local $_ ) = ( $1, $2 );
#	s/ \A [{] \s* //smx;
#	s/ \s* [}] \z //smx;
#	return "$sigil$_";
#    }

    # "$ foo->{bar}" => '$foo->{bar}'
    if ( m/ \A ( $SIGIL_AND_CAST_RE ) \s+ ( $SYMBOL_NAME_RE ) ( .* ) /smx ) {
	return "$1$2$3";
    }

    # Everything else
    return "$_";
}

sub statement {
    my ( $self ) = @_;
    my $top = $self->top()
	or return;
    $top->can( 'source' )
	or return;
    my $source = $top->source()
	or return;
    $source->can( 'statement' )
	or return;
    return $source->statement();
}

sub visual_column_number {
    my ( $self ) = @_;
    return ( $self->location() || [] )->[LOCATION_COLUMN];
}

# This handles two known cases where PPI misparses bracketed variable
# names.
# * $${foo} is parsed as '$$' when it is really a dereference of $foo.
#   The argument is the '$$'
# * ${$} is parsed as an unterminated block followed by '$}'. The
#   argument is the '$}'.

{
    my $special = {
	'$$'	=> sub {	# $${foo},$${$_[0]}
	    my ( $elem ) = @_;
	    my $next;
	    $next = $elem->snext_sibling()
		and $next->isa( 'PPI::Structure::Subscript' )
		or return;
	    my $start;
	    $start = $next->start()
		and LEFT_CURLY eq $start->content()
		or return;
	    my @kids = $next->schildren();
	    1 == @kids
		and $kids[0]->isa( 'PPI::Statement' )
		and @kids = $kids[0]->schildren();
	    if ( 1 == @kids ) {
		# The $${foo} case
		return join '', '$', map { $_->content() } @kids;
	    } else {
		# The $${$_[0]} case. In this case the curly brackets
		# are really a block, as
		# $ perl -MO=Deparse -e '$${$_[0]}' makes clear. So we
		# just return the '$$', since the '$_' will turn up in
		# the course of things.
		return $elem->content();
	    }
	},
	# {
	'$}'	=> sub {	# ${$}
	    my ( $elem ) = @_;
	    my $stmt;
	    $stmt = $elem->parent()
		and $stmt->isa( 'PPI::Statement' )
		or return;
	    my $block;
	    $block = $stmt->parent()
		and $block->isa( 'PPI::Structure::Block' )
		and not $block->finish()
		or return;
	    my $sigil;
	    $sigil = $block->sprevious_sibling()
		and $sigil->isa( 'PPI::Token::Cast' )
		or return;
	    my $name = join '', map { $_->content() } $sigil,
		$stmt->children();
	    chop $name;
	    return $name;
	},
    };

    sub _name_from_misparsed_magic {
	my ( $elem ) = @_;
	$elem->isa( 'PPI::Token::Magic' )
	    or return;
	my $code = $special->{ $elem->content() }
	    or return;
	return $code->( $elem );
    }
}

1;

__END__

=head1 NAME

PPIx::QuoteLike::Utils - Utility subroutines for PPIx::QuoteLike;

=head1 SYNOPSIS

 use PPIx::QuoteLike::Utils qw{ __variables };
 
 say for __variables( PPI::Document->new( \'$foo' );


=head1 DESCRIPTION

This Perl module holds code for L<PPIx::QuoteLike|PPIx::QuoteLike> that
did not seem to fit anywhere else.

=head1 SUBROUTINES

This module supports the following public subroutines:

=head2 column_number

This subroutine/method returns the column number of the first character
in the element, or C<undef> if that can not be determined.

=head2 is_ppi_quotelike_element

This subroutine returns true if its argument is a
L<PPI::Element|PPI::Element> that this package is capable of dealing
with. That is, one of the following:

    PPI::Token::Quote
    PPI::Token::QuoteLike::Backtick
    PPI::Token::QuoteLike::Command
    PPI::Token::QuoteLike::Readline
    PPI::Token::HereDoc

It returns false for unblessed references and for non-references.

=head2 line_number

This subroutine/method returns the line number of the first character in
the element, or C<undef> if that can not be determined.

=head2 logical_filename

This subroutine/method returns the logical file name (taking C<#line>
directives into account) of the file containing first character in the
element, or C<undef> if that can not be determined.

=head2 logical_line_number

This subroutine/method returns the logical line number (taking C<#line>
directives into account) of the first character in the element, or
C<undef> if that can not be determined.

=head2 __normalize_interpolation_for_ppi

Despite the leading underscores, this exportable subroutine is public
and supported. The underscores are so it will not appear to be public
code to various tools when imported into other code.

This subroutine takes as its argument a string representing an
interpolation. It removes such things as braces around variable names to
make it into more normal Perl -- which is to say Perl that produces a
more normal L<PPI|PPI> parse. Sample transformations are:

 '${foo}'        => '$foo'
 '@{[ foo() ]}'  => 'foo()'
 '${\( foo() )}' => 'foo()'

B<NOTE> that this is not intended for general code cleanup.
Specifically, it assumes that its argument is an interpolation and
B<only> an interpolation. Feeding it anything else is unsupported, and
probably will not return anything useful.

=head2 statement

This subroutine/method returns the L<PPI::Statement|PPI::Statement> that
contains this element, or nothing if the statement can not be
determined.

In general this method will return something only under the following
conditions:

=over

=item * The element is contained in a L<PPIx::Regexp|PPIx::Regexp> object;

=item * That object was initialized from a L<PPI::Element|PPI::Element>;

=item * The L<PPI::Element|PPI::Element> is contained in a statement.

=back

=head2 visual_column_number

This subroutine/method returns the visual column number (taking tabs
into account) of the first character in the element, or C<undef> if that
can not be determined.

=head2 __variables

 say for __variables( PPI::Document->new( \'$foo' );

B<NOTE> that this subroutine is discouraged, and may well be deprecated
and removed. My problem with it is that it returns variable names rather
than L<PPI::Element|PPI::Element> objects, leaving you no idea how the
variables are used. It was originally written for the benefit of
L<Perl::Critic::Policy::Variables::ProhibitUnusedVarsStricter|Perl::Critic::Policy::Variables::ProhibitUnusedVarsStricter>,
but has proven inadequate to that policy's needs.

Despite the leading underscores, this exportable subroutine is public
and supported. The underscores are so it will not appear to be public
code to various tools when imported into other code.

This subroutine takes as its only argument a
L<PPI::Element|PPI::Element>, and returns the names of all variables
found in that element, in no particular order. Scope is not taken into
account.

In addition to reporting variables parsed as such by L<PPI|PPI>, and
various corner cases such as C<${]}> where PPI is blind to the use of
the variable, this subroutine looks inside the following PPI classes:

    PPI::Token::Quote
    PPI::Token::QuoteLike::Backtick
    PPI::Token::QuoteLike::Command
    PPI::Token::QuoteLike::Readline
    PPI::Token::HereDoc

If L<PPIx::Regexp|PPIx::Regexp> is installed, it will also look inside

    PPI::Token::QuoteLike::Regexp
    PPI::Token::Regexp::Match
    PPI::Token::Regexp::Substitute

Unfortunately I can not make C<PPIx::Regexp> a requirement for this
module, because of the possibility of a circular dependency.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016-2020 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
