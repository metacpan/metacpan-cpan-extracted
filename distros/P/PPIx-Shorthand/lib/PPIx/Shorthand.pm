package PPIx::Shorthand;

use utf8;
use 5.008001;

use strict;
use warnings;

use Readonly;
use Carp;

use version; our $VERSION = qv('v1.2.0');

use Exporter qw< import >;

our @EXPORT_OK =
    qw<
        get_ppi_class
    >;
our %EXPORT_TAGS    = (
    all => [@EXPORT_OK],
);


Readonly my $EMPTY_STRING => q<>;

Readonly my @PPI_TOKEN_CLASSES => qw<
   PPI::Element
      PPI::Node
         PPI::Document
            PPI::Document::Fragment
         PPI::Statement
            PPI::Statement::Package
            PPI::Statement::Include
            PPI::Statement::Sub
               PPI::Statement::Scheduled
            PPI::Statement::Compound
            PPI::Statement::Break
            PPI::Statement::Given
            PPI::Statement::When
            PPI::Statement::Data
            PPI::Statement::End
            PPI::Statement::Expression
               PPI::Statement::Variable
            PPI::Statement::Null
            PPI::Statement::UnmatchedBrace
            PPI::Statement::Unknown
         PPI::Structure
            PPI::Structure::Block
            PPI::Structure::Subscript
            PPI::Structure::Constructor
            PPI::Structure::Condition
            PPI::Structure::List
            PPI::Structure::For
            PPI::Structure::Given
            PPI::Structure::When
            PPI::Structure::Unknown
      PPI::Token
         PPI::Token::Whitespace
         PPI::Token::Comment
         PPI::Token::Pod
         PPI::Token::Number
            PPI::Token::Number::Binary
            PPI::Token::Number::Octal
            PPI::Token::Number::Hex
            PPI::Token::Number::Float
               PPI::Token::Number::Exp
            PPI::Token::Number::Version
         PPI::Token::Word
         PPI::Token::DashedWord
         PPI::Token::Symbol
            PPI::Token::Magic
         PPI::Token::ArrayIndex
         PPI::Token::Operator
         PPI::Token::Quote
            PPI::Token::Quote::Single
            PPI::Token::Quote::Double
            PPI::Token::Quote::Literal
            PPI::Token::Quote::Interpolate
         PPI::Token::QuoteLike
            PPI::Token::QuoteLike::Backtick
            PPI::Token::QuoteLike::Command
            PPI::Token::QuoteLike::Regexp
            PPI::Token::QuoteLike::Words
            PPI::Token::QuoteLike::Readline
         PPI::Token::Regexp
            PPI::Token::Regexp::Match
            PPI::Token::Regexp::Substitute
            PPI::Token::Regexp::Transliterate
         PPI::Token::HereDoc
         PPI::Token::Cast
         PPI::Token::Structure
         PPI::Token::Label
         PPI::Token::Separator
         PPI::Token::Data
         PPI::Token::End
         PPI::Token::Prototype
         PPI::Token::Attribute
         PPI::Token::Unknown
>;

Readonly my %PPI_TOKEN_CLASSES => map { $_ => 1 } @PPI_TOKEN_CLASSES;

Readonly my $PPI_PREFIX_LENGTH => length 'PPI::';

Readonly my @NON_UNIQUE_BASENAME_CLASSES => qw<
   Data
   End
   Given
   Regexp
   Structure
   Unknown
   When
>;

Readonly my $GLOBAL_INSTANCE => PPIx::Shorthand->new();


sub get_ppi_class {
    my ($name) = @_;

    return $GLOBAL_INSTANCE->get_class($name);
} # end get_ppi_class()


sub new {
    my ($class) = @_;

    my $self = bless {}, $class;

    foreach my $ppi_class (@PPI_TOKEN_CLASSES) {
        $self->{lc $ppi_class} = $ppi_class;
        $self->_add_plural($ppi_class, $ppi_class);

        my $no_prefix = lc substr $ppi_class, $PPI_PREFIX_LENGTH;
        $self->{$no_prefix} = $ppi_class;
        $self->_add_plural($no_prefix, $ppi_class);

        my @components = split m/::/xms, $no_prefix;
        foreach my $separator ( qw< _ - . : >, $EMPTY_STRING ) {
            my $shorthand = join $separator, @components;
            $self->{$shorthand} = $ppi_class;
            $self->_add_plural($shorthand, $ppi_class);
        } # end foreach

        $self->{ $components[-1] } = $ppi_class;
        $self->_add_plural($components[-1], $ppi_class);
    } # end foreach

    foreach my $basename_class (@NON_UNIQUE_BASENAME_CLASSES) {
        my $fullname = "PPI::Token::$basename_class";

        $self->{ lc $basename_class } = $fullname;
        $self->_add_plural($basename_class, $fullname);
    } # end foreach

    return $self;
} # end new()

sub _add_plural {
    my ($self, $basename_class, $ppi_class) = @_;
    my $plural = lc $basename_class;

    return if $plural =~ m/ \b word \z /xms; # What a wonderous exception.

    $plural =~ s< ( [^sy] ) \z ><${1}s>xms;
    $plural =~ s< y \z ><ies>xms;

    $self->{$plural} = $ppi_class;

    return;
}


sub get_class {
    my ($self, $name) = @_;

    croak 'Must specify name.' if not $name;

    return $self->{ lc $name };
} # end get_class()


sub add_class_translation {
    my ($self, $name, $ppi_class) = @_;

    croak 'Must specify name.' if not $name;
    croak 'Must specify PPI class.' if not $ppi_class;
    croak qq<"$ppi_class" is not a known subclass of PPI::Element.>
        if not $PPI_TOKEN_CLASSES{$ppi_class};


    $self->{lc $name} = $ppi_class;

    return;
} # end add_class_translation()


sub remove_class_translation {
    my ($self, $name) = @_;

    croak 'Must specify name.' if not $name;
    croak qq<"$name" is not a known translation.>
        if not delete $self->{lc $name};

    return;
} # end remove_class_translation()


1;

__END__

=encoding utf8

=for stopwords PPI

=head1 NAME

PPIx::Shorthand - Translation of short names to L<PPI::Element> classes.


=head1 VERSION

This document describes PPIx::Shorthand version 1.2.0.


=head1 SYNOPSIS

    use PPIx::Shorthand qw< get_ppi_class >;

    # All of these assign 'PPI::Statement::Include' to $class_name.
    my $class_name = get_ppi_class('include');
    my $class_name = get_ppi_class('statementinclude');
    my $class_name = get_ppi_class('statement-include');
    my $class_name = get_ppi_class('sTatEMenT::inclUde');
    my $class_name = get_ppi_class('PPI::Statement::Include');

    my $shorthand = PPIx::Shorthand->new();
    $shorthand->remove_class_translation('token');
    $shorthand->add_class_translation( t => 'PPI::Token' );
    my $other_class_name = $shorthand->get_class('t');


=head1 DESCRIPTION

When developing tools that allow a user to specify a subclass of
L<PPI::Element>, the long names of the classes don't make for ease of
use.  This module exists to provide common short names for these
classes so that users don't need to learn different ones for different
tools.


=head1 TRANSLATIONS

All translations are case-insensitive.

The translations include the identity ones, i.e.
C<'PPI::Token::Number::Float'> maps to C<'PPI::Token::Number::Float'>.

The translations include the class names without the "PPI::" prefix,
i.e.  C<'Token::Number::Float'> maps to
C<'PPI::Token::Number::Float'>.

The translations include the class names without the "PPI::" prefix
and with the following delimiters instead of double colons: C<_>,
C<->, C<.>, C<:>, and the empty string.  So C<'statement_variable'>,
C<'statement-variable'>, C<'statement.variable'>,
C<'statement:variable'>, and C<'statementvariable'> all map to
C<'PPI::Statement::Variable'>.

The translations include the base name of the classes.  The non-unique
base names translate to the corresponding C<'PPI::Token::'> subclass;
presently the non-unique names are C<'Data'>, C<'End'>, C<'Regexp'>,
C<'Structure'>, and C<'Unknown'>.  So, C<'exp'> translates to
C<'PPI::Token::Number::Float::Exp'> and C<'regexp'> translates to
C<'PPI::Token::Regexp'>.

The translations include all of the above, pluralized, with the
exception of "PPI::Token::Word" because it conflicts with
"PPI::Token::QuoteLike::Words".

The translations are based upon the classes in L<PPI> v1.208.  While
currently supported, the translations for L<PPI::Token::DashedWord>
may disappear in the future based upon the evolution of PPI itself.


=head1 INTERFACE

=head2 Procedural

=over

=item C<< get_ppi_class($name) >>

Attempts to find a PPI::Element subclass for the given string, in a
case-insensitive manner.  Returns nothing if no matching value is
found.


=back


The translation is read-only via the procedural interface.  If you
want to modify the translation, use the object-oriented interface.


=head2 Object-Oriented

=over

=item C<< new() >>

Create a new PPIx::Shorthand instance.


=item C<< get_class($name) >>

Attempts to find a PPI::Element subclass for the given string, in a
case-insensitive manner.  Returns nothing if no matching value is
found.


=item C<< add_class_translation( $name => $ppi_element_subclass ) >>

Give an alternative name for the class.  If you specify a name that
already has a translation, this method will overwrite it.


=item C<< remove_class_translation( $name ) >>

Stop translating the specified name.


=back


=head1 DIAGNOSTICS

=over

=item "%s" is not a known subclass of PPI::Element.

An attempt was made via C<add_class_translation()> to create a
translation to a L<PPI::Element> subclass that this module doesn't
know about.


=item "%s" is not a known translation.

An attempt was made via C<remove_class_translation()> to delete a
translation that does not exist.


=item Must specify PPI class.

A subroutine/method was invoked without a value for the PPI class
parameter.


=item Must specify name.

A subroutine/method was invoked without a value for the name
parameter.


=back


=head1 CONFIGURATION AND ENVIRONMENT

PPIx::Shorthand requires no configuration files or environment
variables.


=head1 DEPENDENCIES

L<Readonly>,
L<version>


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-ppix-shorthand@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 SEE ALSO

L<App::Grepl>,
L<PPIx::Grep>


=head1 AUTHOR

Elliot Shank  C<< <perl@galumph.com> >>


=head1 LICENSE AND COPYRIGHT

Copyright ©2008-2010, Elliot Shank C<< <perl@galumph.com> >>.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic> and
L<perlgpl>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.


=cut

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
