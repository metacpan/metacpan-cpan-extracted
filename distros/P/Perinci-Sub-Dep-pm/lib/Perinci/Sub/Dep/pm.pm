package Perinci::Sub::Dep::pm;

use 5.010001;
use strict;
use warnings;

use Perinci::Sub::DepUtil qw(declare_function_dep);

our $VERSION = '0.30'; # VERSION

declare_function_dep(
    name => 'pm',
    schema => ['str*' => {}],
    check => sub {
        my ($val) = @_;
        my $m = $val;
        my $wv; # wanted version
        $m =~ s/\s*(?:>=)\s*([0-9]\S*)$// and $wv = $1;
        $m =~ s!::!/!g;
        $m .= ".pm";
        eval { require $m };
        my $e = $@;
        return "Can't load module $val" if $e;
        no strict 'refs';
        if (defined $wv) {
            require Sort::Versions;
            my $mv = ${"$m\::VERSION"};
            defined($mv) or return "Can't get version from $m";
            return "Version of $m too old ($mv, wanted $wv)"
                if Sort::Versions::versioncmp($wv, $mv) < 0;
        }
        "";
    }
);

1;
# ABSTRACT: Depend on a Perl module

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::Dep::pm - Depend on a Perl module

=head1 VERSION

This document describes version 0.30 of Perinci::Sub::Dep::pm (from Perl distribution Perinci-Sub-Dep-pm), released on 2015-09-03.

=head1 SYNOPSIS

 # in function metadata
 deps => {
     ...
     pm => 'Foo::Bar',
 }

 # specify version requirement
 deps => {
     ...
     pm => 'Foo::Bar >= 0.123',
 }

 # specify multiple modules
 deps => {
     all => [
         {pm => 'Foo'},
         {pm => 'Bar >= 1.23'},
         {pm => 'Baz'},
     ],
 }

 # specify alternatives
 deps => {
     any => [
         {pm => 'Qux'},
         {pm => 'Quux'},
     ],
 }

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-Dep-pm>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-Dep-pm>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-Dep-pm>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
