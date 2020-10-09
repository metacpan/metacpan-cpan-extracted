package PPIx::QuoteLike::Token;

use 5.006;

use strict;
use warnings;

use Carp;
use PPIx::QuoteLike::Constant qw{ MINIMUM_PERL @CARP_NOT };
use PPIx::QuoteLike::Utils qw{
    column_number
    line_number
    logical_filename
    logical_line_number
    statement
    visual_column_number
};

our $VERSION = '0.013';

# Private to this package.
sub __new {
    my ( $self, %arg ) = @_;
    defined $arg{content}
	or croak 'Content required';
    return bless \%arg, ref $self || $self;
}

sub content {
    my ( $self ) = @_;
    return $self->{content};
}

sub error {
    my ( $self ) = @_;
    return $self->{error};
}

sub location {
    my ( $self ) = @_;
    return $self->{location} ? [ @{ $self->{location} } ] : undef;
}

sub parent {
    my ( $self ) = @_;
    return $self->{parent};
}

sub next_sibling {
    my ( $self ) = @_;
    $self->{next_sibling}
	or return;
    return $self->{next_sibling};
}

sub perl_version_introduced {
    my ( $self ) = @_;
    # TODO use '//' when we can require Perl 5.10.
    defined $self->{perl_version_introduced}
	and return $self->{perl_version_introduced};
    my $vers = $self->__perl_version_introduced();
    defined $vers
	or $vers = MINIMUM_PERL;
    return ( $self->{perl_version_introduced} = $vers );
}

sub __perl_version_introduced {
    return;
}

sub perl_version_removed {
    return undef;	## no critic (ProhibitExplicitReturnUndef)
}

sub previous_sibling {
    my ( $self ) = @_;
    $self->{previous_sibling}
	or return;
    return $self->{previous_sibling};
}

sub significant {
    return 1;
}

sub snext_sibling {
    my ( $sib ) = @_;
    while ( $sib = $sib->next_sibling() ) {
	$sib->significant()
	    and return $sib;
    }
    return;
}

sub sprevious_sibling {
    my ( $sib ) = @_;
    while ( $sib = $sib->previous_sibling() ) {
	$sib->significant()
	    and return $sib;
    }
    return;
}

sub top {
    my ( $self ) = @_;
    my $kid = $self;
    while ( defined ( my $parent = $kid->parent() ) ) {
	$kid = $parent;
    }
    return $kid;
}

sub variables {
    return;
}

1;

__END__

=head1 NAME

PPIx::QuoteLike::Token - Represent any token.

=head1 SYNOPSIS

This is an abstract class, and should not be instantiated by the user.

=head1 DESCRIPTION

This Perl module represents the base of the token hierarchy.

=head1 INHERITANCE

C<PPIx::QuoteLike::Token> is not descended from any other class.

C<PPIx::QuoteLike::Token> is the parent of
L<PPIx::QuoteLike::Token::Control|PPIx::QuoteLike::Token::Control>,
L<PPIx::QuoteLike::Token::Interpolation|PPIx::QuoteLike::Token::Interpolation>,
L<PPIx::QuoteLike::Token::String|PPIx::QuoteLike::Token::String>,
L<PPIx::QuoteLike::Token::Structure|PPIx::QuoteLike::Token::Structure>,
L<PPIx::QuoteLike::Token::Unknown|PPIx::QuoteLike::Token::Unknown> and
L<PPIx::QuoteLike::Token::Whitespace|PPIx::QuoteLike::Token::Whitespace>.

=head1 METHODS

This class supports the following public methods:

=head2 column_number

This method returns the column number of the first character in the
element, or C<undef> if that can not be determined.

=head2 content

 say $token->content();

This method returns the text that makes up the token.

=head2 error

 say $token->error();

This method returns the error text. This will be C<undef> unless the
token actually represents an error.

=head2 line_number

This method returns the line number of the first character in the
element, or C<undef> if that can not be determined.

=head2 location

This method returns a reference to an array describing the position of
the element in the string, or C<undef> if the location is unavailable.

The array is compatible with the corresponding
L<PPI::Element|PPI::Element> method.

=head2 logical_filename

This method returns the logical file name (taking C<#line> directives
into account) of the file containing first character in the element, or
C<undef> if that can not be determined.

=head2 logical_line_number

This method returns the logical line number (taking C<#line> directives
into account) of the first character in the element, or C<undef> if that
can not be determined.

=head2 parent

 my $parent = $token->parent();

This method returns the token's parent, which will be the
L<PPIx::QuoteLike|PPIx::QuoteLike> object that contains it.

=head2 next_sibling

 my $next = $token->next_sibling();

This method returns the token after the invocant, or nothing if there is
none.

=head2 perl_version_introduced

This method returns the version of Perl in which the element was
introduced. This will be at least 5.000. Before 5.006 I am relying on
the F<perldelta>, F<perlre>, and F<perlop> documentation, since I have
been unable to build earlier Perls. Since I have found no documentation
before 5.003, I assume that anything found in 5.003 is also in 5.000.

Since this all depends on my ability to read and understand masses of
documentation, the results of this method should be viewed with caution,
if not downright skepticism.

There are also cases which are ambiguous in various ways. For those see
L<PPIx::Regexp/RESTRICTIONS>, and especially
L<PPIx::Regexp/Changes in Syntax>.

=head2 perl_version_removed

This method returns the version of Perl in which the element was
removed. If the element is still valid the return is C<undef>.

All the I<caveats> to
L<perl_version_introduced()|/perl_version_introduced> apply here also,
though perhaps less severely since although many features have been
introduced since 5.0, few have been removed.

=head2 previous_sibling

 my $prev = $token->previous_sibling();

This method returns the token before the invocant, or nothing if there
is none.

=head2 significant

 $token->significant()
     and say 'significant';

This Boolean method returns a true value if the token is significant,
and a false one otherwise.

=head2 snext_sibling

 my $next = $token->snext_sibling();

This method returns the significant token after the invocant, or nothing
if there is none.

=head2 sprevious_sibling

 my $prev = $token->sprevious_sibling();

This method returns the significant token before the invocant, or
nothing if there is none.

=head2 statement

This method returns the L<PPI::Statement|PPI::Statement> that
contains this token, or nothing if the statement can not be
determined.

In general this method will return something only under the following
conditions:

=over

=item * The token is contained in a L<PPIx::QuoteLike|PPIx::QuoteLike> object;

=item * That object was initialized from a L<PPI::Element|PPI::Element>;

=item * The L<PPI::Element|PPI::Element> is contained in a statement.

=back

=head2 top

This method returns the top of the hierarchy.

=head2 variables

 say "Interpolates $_" for $elem->variables();

B<NOTE> that this method is discouraged, and may well be deprecated and
removed. My problem with it is that it returns variable names rather
than L<PPI::Element|PPI::Element> objects, leaving you no idea how the
variables are used. It was originally written for the benefit of
L<Perl::Critic::Policy::Variables::ProhibitUnusedVarsStricter|Perl::Critic::Policy::Variables::ProhibitUnusedVarsStricter>,
but has proven inadequate to that policy's needs.

This convenience method returns all interpolated variables. Each is
returned only once, and they are returned in no particular order.

B<NOTE> that because this class does not represent an interpolation,
this method returns nothing.

=head2 visual_column_number

This method returns the visual column number (taking tabs into account)
of the first character in the element, or C<undef> if that can not be
determined.

=head1 SEE ALSO

L<PPIx::QuoteLike|PPIx::QuoteLike>.

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
