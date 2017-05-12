package Perinci::Sub::Util::DepModule;

our $DATE = '2016-09-29'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(
                       get_required_dep_modules
               );

sub _find {
    my ($deps, $res) = @_;

    return unless $deps;
    $res->{"Perinci::Sub::DepChecker"} = 0;
    for my $k (keys %$deps) {
        if ($k =~ /\A(any|all|none)\z/) {
            my $v = $deps->{$k};
            _find($_, $res) for @$v;
        } elsif ($k =~ /\A(env|code|prog|pkg|func|exec|tmp_dir|trash_dir|undo_trash_dir)\z/) {
            # skip builtin deps supported by Perinci::Sub::DepChecker
        } else {
            $res->{"Perinci::Sub::Dep::$k"} = 0;
        }
    }
}

sub get_required_dep_modules {
    my $meta = shift;

    my %res;
    _find($meta->{deps}, \%res);
    \%res;
}

1;
# ABSTRACT: Given a Rinci function metadata, find what dep modules are required

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::Util::DepModule - Given a Rinci function metadata, find what dep modules are required

=head1 VERSION

This document describes version 0.001 of Perinci::Sub::Util::DepModule (from Perl distribution Perinci-Sub-Util-DepModule), released on 2016-09-29.

=head1 SYNOPSIS

 use Perinci::Sub::Util::DepModule qw(get_required_dep_modules);

 my $meta = {
     v => 1.1,
     deps => {
         prog => 'git',
         any => [
             {pm => 'Foo::Bar'},
             {pm => 'Foo::Baz'},
         ],
     },
     ...
 };
 my $mods = get_required_dep_modules($meta);

Result:

 {
     'Perinci::Sub::DepChecker' => 0,
     'Perinci::Sub::Dep::pm' => 0,
 }

=head1 FUNCTIONS

=head2 get_required_dep_modules($meta) => array

Dpendencies are checked by L<Perinci::Sub::DepChecker> as well as other
C<Perinci::Sub::Dep::*> modules for custom types of dependencies.

This function can detect which modules are used.

This function can be used during distribution building to automatically add
those modules as prerequisites.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-Util-DepModule>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-Util-DepModule>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-Util-DepModule>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
