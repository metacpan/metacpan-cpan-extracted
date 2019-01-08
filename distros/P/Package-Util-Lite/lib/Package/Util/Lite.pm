package Package::Util::Lite;

our $DATE = '2019-01-06'; # DATE
our $VERSION = '0.001'; # VERSION

use strict 'subs', 'vars';
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       package_exists
                       list_subpackages
               );

sub package_exists {
    no strict 'refs';

    my $pkg = shift;

    # opt
    #return unless $pkg =~ /\A\w+(::\w+)*\z/;

    if ($pkg =~ s/::(\w+)\z//) {
        return !!${$pkg . "::"}{$1 . "::"};
    } else {
        return !!$::{$pkg . "::"};
    }
}

sub list_subpackages {
    my ($pkg, $recursive, $cur_res, $ref_mem) = @_;

    return () unless !length($pkg) || package_exists($pkg);

    # this is used to avoid deep recursion. for example (the only one?) %:: and
    # %main:: point to the same thing.
    $ref_mem ||= {};

    my $symtbl = \%{$pkg . "::"};
    return () if $ref_mem->{"$symtbl"}++;

    my $res = $cur_res || [];
    for (sort keys %$symtbl) {
        next unless s/::$//;
        my $name = (length($pkg) ? "$pkg\::" : "" ) . $_;
        push @$res, $name;
        list_subpackages($name, 1, $res, $ref_mem) if $recursive;
    }

    @$res;
}

1;
# ABSTRACT: Package-related utilities

__END__

=pod

=encoding UTF-8

=head1 NAME

Package::Util::Lite - Package-related utilities

=head1 VERSION

This document describes version 0.001 of Package::Util::Lite (from Perl distribution Package-Util-Lite), released on 2019-01-06.

=head1 SYNOPSIS

 use Package::Util::Lite qw(
     package_exists
     list_subpackages
 );

 print "Package Foo::Bar exists" if package_exists("Foo::Bar");

 my @subpkg    = list_subpackages("Foo::Bar");
 my @allsubpkg = list_subpackages("Foo::Bar", 1); # recursive

=head1 DESCRIPTION

This module provides package-related utilities. You should check
L<Package::Stash> first, then here.

=head1 FUNCTIONS

=head2 package_exists

Usage:

 package_exists($name) => bool

Return true if package "exists". By "exists", it means that the package has been
defined by C<package> statement or some entries have been created in the symbol
table (e.g. C<$Foo::var = 1;> will make the C<Foo> package "exist").

This function can be used e.g. for checking before aliasing one package to
another. Or to casually check whether a module has been loaded.

=head2 list_subpackages($name[, $recursive]) => @res

List subpackages, e.g.:

 (
     "Foo::Bar::Baz",
     "Foo::Bar::Qux",
     ...
 )

If $recursive is true, will also list subpackages of subpackages, and so on.

=head1 FAQ

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Package-Util-Lite>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Package-Util-Lite>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Package-Util-Lite>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Package::Stash>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
