use 5.008;
use strict;
use warnings;

package Sub::Documentation::Attributes;
our $VERSION = '1.100880';

# ABSTRACT: Use attributes to declare documentation
use Attribute::Handlers;
use Sub::Documentation 'add_documentation';

sub add_attr_doc {
    my ($type, $package, $symbol, $referent, $data) = @_[0..3,5];

    # Work around an API change in Attribute::Handlers 0.79, shipped with perl
    # 5.10, where a single scalar value is returned as an array ref when
    # ATTR(SCALAR) is used. Not in the other ATTR cases though...  We can't
    # just require A::H 0.79 though because as of this writing it only exists
    # as part of perl 5.10; the most recent standalone distribution on CPAN is
    # 0.78.
    $data = $data->[0] if ref($data) eq 'ARRAY' && @$data == 1;
    add_documentation(
        package       => $package,
        glob_type     => ref($referent),
        name          => *{$symbol}{NAME},
        type          => $type,
        documentation => $data,
    );
}
no warnings 'redefine';

sub UNIVERSAL::Purpose : ATTR {
    add_attr_doc(purpose => @_);
}

sub UNIVERSAL::Id : ATTR {
    add_attr_doc(id => @_);
}

sub UNIVERSAL::Author : ATTR {
    add_attr_doc(author => @_);
}

sub UNIVERSAL::Param : ATTR(CODE) {
    add_attr_doc(param => @_);
}

sub UNIVERSAL::Returns : ATTR(CODE) {
    add_attr_doc(returns => @_);
}

sub UNIVERSAL::Throws : ATTR(CODE) {
    add_attr_doc(throws => @_);
}

sub UNIVERSAL::Example : ATTR {
    add_attr_doc(example => @_);
}

sub UNIVERSAL::Deprecated : ATTR {
    add_attr_doc(deprecated => @_);
}

sub UNIVERSAL::Default : ATTR(SCALAR) {
    add_attr_doc(default => @_);
}

sub UNIVERSAL::Default : ATTR(ARRAY) {
    add_attr_doc(default => @_);
}

sub UNIVERSAL::Default : ATTR(HASH) {
    add_attr_doc(default => @_);
}
1;


__END__
=pod

=head1 NAME

Sub::Documentation::Attributes - Use attributes to declare documentation

=head1 VERSION

version 1.100880

=head1 SYNOPSIS

    use Sub::Documentation::Attributes;

    sub say
        : Purpose(prints its arguments, appending a newline)
        : Param(@text; the text to be printed)
        : Deprecated(use Perl6::Say instead)
    {
        my $self = shift;
        print @_, "\n";
    }

=head1 DESCRIPTION

This module provides attributes so you can declare documentation with the
subroutine or variable you are documenting.

The following attributes are provided:

=over 4

=item C<Purpose>

=item C<Id>

=item C<Author>

=item C<Param>

=item C<Returns>

=item C<Throws>

=item C<Example>

=item C<Default>

=back

=head1 FUNCTIONS

=head2 add_attr_doc

This is the attribute handler for all attributes.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Sub-Documentation>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Sub-Documentation/>.

The development version lives at
L<http://github.com/hanekomu/Sub-Documentation/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

