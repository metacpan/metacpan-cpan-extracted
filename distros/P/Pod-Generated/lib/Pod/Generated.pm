package Pod::Generated;
use 5.008;
use warnings;
use strict;
our $VERSION = '0.05';
use base 'Exporter';
our %EXPORT_TAGS = (util => [qw(add_doc doc)],);
our @EXPORT_OK = @{ $EXPORT_TAGS{all} = [ map { @$_ } values %EXPORT_TAGS ] };

sub add_doc {
    my ($package, $glob_slot, $symbol_name, $doc_type, $doc) = @_;

    # $glob_slot is CODE, SCALAR etc.
    my %interpolate = (
        p   => $package,
        '%' => '%',
    );
    if (defined $doc) {
        $doc =~ s/%(.)/ $interpolate{$1} || "%$1" /ge;
    }
    our %doc;
    push @{ $doc{$package}{$glob_slot}{$symbol_name}{$doc_type} } => $doc;
}

sub doc {
    our %doc;
    wantarray ? %doc : \%doc;
}
1;
__END__

=head1 NAME

Pod::Generated - Generate POD documentation during "make" time

=head1 SYNOPSIS

    use Pod::Generated 'add_doc';

    my $pkg = __PACKAGE__;
    add_doc($pkg, CODE   => 'new',   purpose => 'A constructor.');
    add_doc($pkg, SCALAR => 'count', purpose => 'Number of flurbles.');

=head1 DESCRIPTION

This module provides support for generating POD documentation for your modules
during C<make> time. It does not itself generate the documentation - the
combination of L<Module::Install::Template> and
L<Template::Plugin::PodGenerated> does that.

Also see L<Pod::Generated::Attributes>.

Modules that generate methods - such as L<Class::Accessor> - might want to use
this module. L<Class::Accessor::Complex>, L<Class::Accessor::Constructor> and
L<Class::Accessor::FactoryTyped> do support generated documentation, or will
do so shortly.

This modules exports two functions on request:

=over 4

=item C<add_doc>

    add_doc($pkg, $glob_type, $symbol_name, $doc_type, $doc);

Adds documentation. Takes as arguments the package for which to add
documentation, a glob type (C<CODE>, C<SCALAR>, C<ARRAY>, C<HASH>), the symbol
name for which to add documentation (i.e., the subroutine name or variable
name), the documentation type (e.g., C<purpose>, C<example>) and the
documentation string.

The symbol name alone is insufficient to determine what is being documented -
does C<new> refer to the subroutine C<new()> or any of the variables C<$new>,
C@new> or C<%new>? Therefore you also need to pass the glob type.

The documentation type is freely definable, but the code that actually
generates the documentation (for example, L<Template::Plugin::PodGenerated>)
needs to understand these documentation types.

Documentation is stored in a nested hash.

=item C<doc >

Returns the documentation hash. This can be used by modules that actually
generate the documentation to inspect which documentation has been defined.

=back

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

