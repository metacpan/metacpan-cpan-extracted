package PPIx::Regexp::Util;

use 5.006;

use strict;
use warnings;

use Carp;
use PPIx::Regexp::Constant qw{
    INFINITY
    MINIMUM_PERL
    @CARP_NOT
};
use Scalar::Util qw{ blessed };

use base qw{ Exporter };

our @EXPORT_OK = qw{
    is_ppi_regexp_element
    __choose_tokenizer_class
    __instance
    __is_ppi_regexp_element
    __merge_perl_requirements
    __ns_can
    __post_rebless_error
    raw_width
    __to_ordinal_en
    width
};

our %EXPORT_TAGS = (
    all		=> \@EXPORT_OK,
    width_one	=> [ qw{ raw_width width } ],
);

our $VERSION = '0.090';

sub is_ppi_regexp_element {
    my ( $elem ) = @_;
    __instance( $elem, 'PPI::Element' )
	or return;
    return $elem->isa( 'PPI::Token::Regexp' ) ||
	$elem->isa( 'PPI::Token::QuoteLike::Regexp' );
}

sub __is_ppi_regexp_element {
    Carp::cluck(
	'__is_ppi_regexp_element is deprecated. Use is_ppi_regexp_element'
    );
    goto &is_ppi_regexp_element;
}

# TODO ditch this once the deprecation period ends
sub __choose_tokenizer_class {
    # my ( $content, $arg ) = @_;
    my ( undef, $arg ) = @_;
    if ( defined $arg->{parse} ) {
	my $warning = q<The 'parse' argument is deprecated.>;
	{ guess => 1, string => 1 }->{$arg->{parse}}
	    and $warning = join ' ', $warning,
		q<You should use PPIx::QuoteLike on quotish things>;
	croak $warning;
    }
    return 'PPIx::Regexp::Tokenizer';
}

sub __instance {
    my ( $object, $class ) = @_;
    blessed( $object ) or return;
    return $object->isa( $class );
}

sub __merge_perl_requirements {	## no critic (RequireArgUnpacking)
    my @work =
    sort { $a->[0] <=> $b->[0] || $b->[1] <=> $a->[1] }
    map { ( [ $_->[0], 1 ], [ $_->[1], 0 ] ) }
    map { [ $_->{introduced}, defined $_->{removed} ? $_->{removed} : INFINITY ] } @_;
    my @rslt;
    while ( @work ) {
	my ( $intro, $rem );
	$intro = ( shift @work )->[0] while @work && $work[0][1];
	if ( @work ) {
	    $rem = $work[0][0];
	    shift @work while @work && ! $work[0][1];
	}
	defined $intro
	    or $intro = MINIMUM_PERL;
	defined $rem
	    or $rem = INFINITY;
	$intro != $rem
	    and push @rslt, {
		introduced	=> $intro,
		removed	=> $rem,
	    };
    }
    @rslt
	and $rslt[-1]{removed} == INFINITY
	and delete $rslt[-1]{removed};
    return @rslt;
}

sub __ns_can {
    my ( $class, $name ) = @_;
    my $fqn = join '::', ref $class || $class, $name;
    no strict qw{ refs };
    return defined &$fqn ? \&$fqn : undef;
}

sub __post_rebless_error {
    my ( $self, %arg ) = @_;
    my $rslt = 0;
    unless ( defined( $self->{error} = $arg{error} ) ) {
	my $class = ref $self;
	Carp::cluck( "Making $class with no error message" );
	$self->{error} = 'Unspecified error';
	$rslt++;
    }
    $self->{explanation} = defined $arg{explanation} ?
	$arg{explanation} :
	$arg{error};
    return $rslt;

}

# Unquantified number of characters matched.
sub raw_width {
    return ( 1, 1 );
}

sub __to_ordinal_en {
    my ( $num ) = @_;
    $num += 0;
    1 == int( ( $num % 100 ) / 10 )	# teens
	and return "${num}th";
    1 == $num % 10
	and return "${num}st";
    2 == $num % 10
	and return "${num}nd";
    3 == $num % 10
	and return "${num}rd";
    return "${num}th";
}

sub width {
    my ( $self ) = @_;
    my @raw_width = $self->raw_width();
    my ( $code, $next_sib );
    $next_sib = $self->snext_sibling()
	and $code = $next_sib->can( '__quantified_width' )
	or return @raw_width;
    return $code->( $next_sib, @raw_width );
}

1;

__END__

=head1 NAME

PPIx::Regexp::Util - Utility functions for PPIx::Regexp;

=head1 SYNOPSIS

 use PPIx::Regexp::Util qw{ __instance };
     .
     .
     .
 __instance( $foo, 'Bar' )
     or die '$foo is not a Bar';

=head1 DESCRIPTION

This module contains utility functions for L<PPIx::Regexp|PPIx::Regexp>
which it is convenient to centralize.

Double-underscore subroutines are B<private> to the C<PPIx-Regexp>
package. Their documentation is provided for the author's convenience
only, and they are subject to change without notice. I<Caveat user.>

This module exports nothing by default.

=head1 SUBROUTINES

This module can export the following subroutines:

=head2 is_ppi_regexp_element

 is_ppi_regexp_element( $elem )
   and print "$elem is a regexp of some sort\n";

This subroutine is public and supported.

This subroutine takes as its argument a L<PPI::Element|PPI::Element>. It
returns a true value if the argument represents a regular expression of
some sort, and a false value otherwise.

=head2 __instance

 __instance( $foo, 'Bar' )
     and print '$foo isa Bar', "\n";

This subroutine is B<private> to the C<PPIx-Regexp> package.

This subroutine returns true if its first argument is an instance of the
class specified by its second argument. Unlike C<UNIVERSAL::isa>, the
result is always false unless the first argument is a reference.

=head2 __is_ppi_regexp_element

 __is_ppi_regexp_element( $elem )
   and print "$elem is a regexp of some sort\n";

This subroutine is B<private> to the C<PPIx-Regexp> package.

This is a synonym for L<is_ppi_regexp_element()|/is_ppi_regexp_element>,
and is deprecated in favor of it. If called, it will complain via
C<Carp::cluck()> and then C<goto &is_ppi_regexp_element>.

=head2 __merge_perl_requirements

This subroutine is B<private> to the C<PPIx-Regexp> package.

This subroutine merges perl requirements as returned by the various
C<__perl_requirements()> methods.

=head2 __ns_can

This subroutine is B<private> to the C<PPIx-Regexp> package.

This method is analogous to C<can()>, but returns a reference to the
code only if it is actually implemented by the invoking name space.

=head2 __post_rebless_error

This method is B<private> to the C<PPIx-Regexp> package. The intended
use is to alias it to C<__PPIX_ELEM__post_reblessing()>.

It takes arguments as name/value pairs. Argument C<{error}> is the error
message; if it is omitted you get a warning with stack trace. Argument
C<{explanation}> defaults to C<{error}>.

It returns the number of errors to add to the parse.

=head2 raw_width

This public method returns the minimum and maximum width matched by the
element before taking into account such details as what the element
actually is and how it is quantified.

This implementation is appropriate to things that match exactly one
character -- i.e. it returns C<( 1, 1 )>.

=head2 __to_ordinal_en

This subroutine is B<private> to the C<PPIx-Regexp> package.

This subroutine takes as its argument an integer and returns a string
representing its ordinal in English. For example

 say __to_ordinal_en( 17 );
 # 17th

=head2 width

 my ( $min_wid, $max_wid ) = $self->width();

This public method (well, mixin) returns the minimum and maximum width
of the text matched by the element.

Elements which import this method must also implement a C<raw_width()>
method which returns the unquantified width of the element.

=head1 EXPORT TAGS

The following export tags are defined by this module. All are private to
the C<PPIx-Regexp> package unless otherwise documented.

=head2 all

This tag exports everything exportable by this module.

=head2 width_one

This tag is appropriate to an element which, when unquantified, matches
exactly one character. It exports C<raw_width()> and C<width()>.

=head1 SEE ALSO

L<Params::Util|Params::Util>, which I recommend, but in the case of
C<PPIx::Regexp> I did not want to introduce a dependency on an XS module
when all I really wanted was the function of that module's
C<_INSTANCE()> subroutine.

=head1 SUPPORT

Support is by the author. Please file bug reports at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=PPIx-Regexp>,
L<https://github.com/trwyant/perl-PPIx-Regexp/issues>, or in
electronic mail to the author.

=head1 AUTHOR

Thomas R. Wyant, III F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2023, 2025 by Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
