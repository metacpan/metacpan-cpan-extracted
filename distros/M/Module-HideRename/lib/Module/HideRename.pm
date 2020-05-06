package Module::HideRename;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-13'; # DATE
our $DIST = 'Module-HideRename'; # DIST
our $VERSION = '0.003'; # VERSION

use strict;
use warnings;
use Log::ger;

our %SPEC;

use Exporter qw(import);
our @EXPORT_OK = qw(hiderename_modules unhiderename_modules);

use Module::Path::More;
# XXX check whether Module::Path::More::Patch::Hide has been loaded?

our %args0_modules = (
    modules => {
        schema => ['array*', of=>'perl::modname*'],
        req => 1,
        pos => 0,
        slurpy => 1,
    },
);

my $unhide;
sub _hiderename_modules {
    my %args = @_;

    for my $module (@{ $args{modules} }) {
        my $paths = Module::Path::More::module_path(
            module => $unhide ? "${module}_hidden" : $module,
            all => 1,
        );
        for my $path (@$paths) {
            my $new_path = $path;
            if ($unhide) {
                $new_path =~ s/_hidden(\.pmc?\z)/$1/;
            } else {
                $new_path =~ s/(\.pmc?\z)/_hidden$1/;
            }
            log_debug "%s module: %s -> %s",
                ($unhide ? "Unhide-renaming" : "Hide-renaming"),
                $path, $new_path;
            rename $path, $new_path
                or warn "Can't rename $path -> $new_path: $!";
        }
    }
    [200];
}

$SPEC{hiderename_modules} = {
    v => 1.1,
    args => {
        %args0_modules,
    },
};
sub hiderename_modules {
    $unhide = 0;
    goto &_hiderename_modules;
}

$SPEC{unhiderename_modules} = {
    v => 1.1,
    args => {
        %args0_modules,
    },
};
sub unhiderename_modules {
    $unhide = 1;
    goto &_hiderename_modules;
}

1;
# ABSTRACT: Hide modules by renaming them

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::HideRename - Hide modules by renaming them

=head1 VERSION

This document describes version 0.003 of Module::HideRename (from Perl distribution Module-HideRename), released on 2020-02-13.

=head1 SYNOPSIS

 use Module::HideRename qw(
     hiderename_modules
     unhiderename_modules
 );

 hiderename_modules(modules => ['Foo', 'Foo::Bar']);
 # this will rename Foo.pm to Foo_hidden.pm and Foo/Bar.pm to Foo/Bar_hidden.pm

 unhiderename_modules(modules => ['Foo', 'Foo::Bar']);
 # this will rename back Foo_hidden.pm to Foo.pm and Foo/Bar_hidden.pm to Foo/Bar.pm

=head1 DESCRIPTION

Sometimes all you need to do to hide a module from a Perl code is install an
C<@INC> hook (e.g. like what L<Devel::Hide> or L<Test::Without::Module> does).
But sometimes you actually need to hide (rename) the module files.

=head1 FUNCTIONS


=head2 hiderename_modules

Usage:

 hiderename_modules(%args) -> [status, msg, payload, meta]

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<modules>* => I<array[perl::modname]>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 unhiderename_modules

Usage:

 unhiderename_modules(%args) -> [status, msg, payload, meta]

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<modules>* => I<array[perl::modname]>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Module-HideRename>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Module-HideRename>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Module-HideRename>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::pmhiderename>, CLI for hiderenaming

L<lib::hiderename>, pragma for hiderenaming

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
