## no critic: Modules::ProhibitAutomaticExportation
package Perinci::Package::CopyFrom;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-16'; # DATE
our $DIST = 'Perinci-Package-CopyFrom'; # DIST
our $VERSION = '0.001'; # VERSION

use strict 'subs', 'vars';
use warnings;
use Log::ger;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(copy_from);

use Package::CopyFrom ();

sub copy_from {
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
    Package::CopyFrom::copy_from($opts, $src_pkg);
}

1;
# ABSTRACT: Copy (some) contents from another package (with Rinci metadata awareness)

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Package::CopyFrom - Copy (some) contents from another package (with Rinci metadata awareness)

=head1 VERSION

This document describes version 0.001 of Perinci::Package::CopyFrom (from Perl distribution Perinci-Package-CopyFrom), released on 2020-02-16.

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
 use Package::CopyFrom; # exports copy_from()
 BEGIN { copy_from 'My::Source' } # copies 'func1', 'func2', 'func3' as well as their Rinci metadata
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

This is a variant of L<Package::CopyFrom> that can also copy Rinci metadata for
you.

=head1 FUNCTIONS

=head2 copy_from

See L<Package::CopyFrom/copy_from>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Package-CopyFrom>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Package-CopyFrom>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Package-CopyFrom>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Rinci>, L<Perinci>, L<Package::CopyFrom>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
