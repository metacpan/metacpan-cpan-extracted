package Pod::Generated::Attributes;
use warnings;
use strict;
use Attribute::Handlers;
use Pod::Generated 'add_doc';
our $VERSION = '0.05';

sub add_attr_doc {
    my ($type, $package, $symbol, $referent, $attr, $data, $phase) = @_;

    # Work around an API change in Attribute::Handlers 0.79, shipped with perl
    # 5.10, where a single scalar value is returned as an array ref when
    # ATTR(SCALAR) is used. Not in the other ATTR cases though...  We can't
    # just require A::H 0.79 though because as of this writing it only exists
    # as part of perl 5.10; the most recent standalone distribution on CPAN is
    # 0.78.
    $data = $data->[0] if ref($data) eq 'ARRAY' && @$data == 1;
    add_doc($package, ref($referent), *{$symbol}{NAME}, $type, $data);
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

=head1 NAME

Pod::Generated::Attributes - use attributes to declare documentation

=head1 SYNOPSIS

    use Pod::Generated::Attributes;

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

More documentation will follow.

=head1 TAGS

If you talk about this module in blogs, on L<delicious.com> or anywhere else,
please use the C<podgenerated> tag.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-pod-generated@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit <http://www.perl.com/CPAN/> to find a CPAN
site near you. Or see L<http://search.cpan.org/dist/Pod-Generated/>.

=head1 AUTHOR

Marcel GrE<uuml>nauer, C<< <marcel@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2009 by Marcel GrE<uuml>nauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

