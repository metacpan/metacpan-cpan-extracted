## no critic: Modules::ProhibitAutomaticExportation
package Perinci::Package::CopyContents;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-16'; # DATE
our $DIST = 'Perinci-Package-CopyContents'; # DIST
our $VERSION = '0.002'; # VERSION

use strict 'subs', 'vars';
use warnings;
use Log::ger;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(copy_contents_from);

use Package::CopyContents ();

sub copy_contents_from {
    my $opts = ref $_[0] eq 'HASH' ? shift : {};
    my $src_pkg = shift;

    $opts->{to} = caller unless defined $opts->{to};

    $opts->{_before_copy} = sub {
        my ($name, $src_pkg, $target_pkg, $opts, $overwrite) = @_;
        return 1 if $name eq '%SPEC';
        0;
    };
    $opts->{_after_copy} = sub {
        my ($name, $src_pkg, $target_pkg, $opts, $overwrite) = @_;
        ${"$target_pkg\::SPEC"}{$name} = ${"$src_pkg\::SPEC"}{$name}
            if defined ${"$src_pkg\::SPEC"}{$name};
    };
    Package::CopyContents::copy_contents_from($opts, $src_pkg);
}

1;
# ABSTRACT: Copy (some) contents from another package (with Rinci metadata awareness)

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Package::CopyContents - Copy (some) contents from another package (with Rinci metadata awareness)

=head1 VERSION

This document describes version 0.002 of Perinci::Package::CopyContents (from Perl distribution Perinci-Package-CopyContents), released on 2020-02-16.

=head1 SYNOPSIS

 package My::Source;
 our %SPEC;
 $SPEC{func1} = {...}
 sub func1 { ... }
 $SPEC{func2} = {...}
 sub func2 { ... }
 $SPEC{func3} = {...}
 sub func3 { ... }
 1;

 package My::Modified;
 use Package::CopyContents; # exports copy_contents_from()
 BEGIN { copy_contents_from 'My::Source' } # copies 'func1', 'func2', 'func3' as well as their Rinci metadata
 our %SPEC;

 # provide our own modification to 'func2'
 $SPEC{func2} = { ... }
 sub func2 { ... }

 # provide our own modification to 'func3', using some helper from
 # Perinci::Sub::Util
 use Perinci::Sub::Util qw(gen_modified_sub);
 gen_modified_sub(...);

 # add a new function 'func4'
 $SPEC{func4} = { ... }
 sub func4 { ... }
 1;

=head1 DESCRIPTION

This is a variant of L<Package::CopyContents> that can also copy Rinci metadata
for you.

=head1 FUNCTIONS

=head2 copy_contents_from

See L<Package::CopyContents/copy_contents_from>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Package-CopyContents>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Package-CopyContents>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Package-CopyContents>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Rinci>, L<Perinci>, L<Package::CopyContents>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
