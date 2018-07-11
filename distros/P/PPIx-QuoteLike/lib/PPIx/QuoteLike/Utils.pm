package PPIx::QuoteLike::Utils;

use 5.006;

use strict;
use warnings;

use base qw{ Exporter };

use Carp;
use PPIx::QuoteLike::Constant qw{ VARIABLE_RE @CARP_NOT };
use Scalar::Util ();

use constant LEFT_CURLY		=> q<{>;
use constant RIGHT_CURLY	=> q<}>;

our @EXPORT_OK = qw{ __variables };

our $VERSION = '0.006';

require PPIx::QuoteLike;

# We can't depend on PPIx::Regexp without getting into a circular
# dependency. I think. But we can sure use it if we can come by it.
my $have_ppix_regexp = eval {
    require PPIx::Regexp;
    1;
};

{

    # TODO make these state varables one we can require Perl 5.10.
    my $postderef = { map { $_ => 1 } qw{ @* %* } };

    my $cast_allowed_for_bare_bracketed_variable = {
	map { $_ => 1 } qw{ @ $ % } };

    sub __variables {
	my ( $ppi ) = @_;

	Scalar::Util::blessed( $ppi )
	    and $ppi->isa( 'PPI::Node' )
	    or croak 'Argument must be a PPI::Node';

	my %var;

	foreach my $sym ( @{ $ppi->find( 'PPI::Token::Symbol' ) || [] } ) {
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
        foreach my $elem (
            @{ $ppi->find( 'PPI::Token::ArrayIndex' ) || [] }
        ) {
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
        foreach my $elem (
            @{ $ppi->find( 'PPI::Structure::Block' ) || [] }
        ) {

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
	foreach my $class ( qw{
		PPI::Token::Quote
		PPI::Token::QuoteLike::Backtick
		PPI::Token::QuoteLike::Command
		PPI::Token::QuoteLike::Readline
		PPI::Token::HereDoc
	    } ) {
	    foreach my $elem ( @{ $ppi->find( $class ) || [] } ) {

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
	if ( $have_ppix_regexp ) {
	    foreach my $class ( qw{
		    PPI::Token::QuoteLike::Regexp
		    PPI::Token::Regexp::Match
		    PPI::Token::Regexp::Substitute
		} ) {
		foreach my $elem ( @{ $ppi->find( $class ) || [] } ) {
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

=head2 __variables

 say for __variables( PPI::Document->new( \'$foo' );

Despite the leading underscores, this exportable subroutine is public
and supported. The underscores are so it will not appear to be public
code to various tools when imported into other code.

This subroutine takes as its only argument a L<PPI::Node|PPI::Node>, and
returns the names of all variables found in that node, in no particular
order. Scope is not taken into account.

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
L<http://rt.cpan.org>, or in electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016-2018 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
