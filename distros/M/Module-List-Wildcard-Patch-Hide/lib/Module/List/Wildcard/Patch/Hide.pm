package Module::List::Wildcard::Patch::Hide;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-09-21'; # DATE
our $DIST = 'Module-List-Wildcard-Patch-Hide'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
no warnings;

use Module::Patch ();
use base qw(Module::Patch);

our %config;

my $w_list_modules = sub {
    my $ctx  = shift;

    my @mods = split /\s*[;,]\s*/, $config{-module};

    my ($prefix, $opts) = @_;

    my $res = $ctx->{orig}->(@_);
    if ($opts->{list_modules}) {
        for my $mod (keys %$res) {
            if (grep {$mod eq $_} @mods) {
                delete $res->{$mod};
            }
        }
    }
    $res;
};

sub patch_data {
    return {
        v => 3,
        config => {
            -module => {
                summary => 'A string containing semicolon-separated list '.
                    'of module names to hide',
                schema => 'str*',
            },
        },
        patches => [
            {
                action => 'wrap',
                sub_name => 'list_modules',
                code => $w_list_modules,
            },
        ],
    };
}

1;
# ABSTRACT: Hide some modules from Module::List::Wildcard

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::List::Wildcard::Patch::Hide - Hide some modules from Module::List::Wildcard

=head1 VERSION

This document describes version 0.002 of Module::List::Wildcard::Patch::Hide (from Perl distribution Module-List-Wildcard-Patch-Hide), released on 2020-09-21.

=head1 SYNOPSIS

 % PERL5OPT=-MModule::List::Wildcard::Patch::Hide=-module,'Foo::Bar;Baz' app.pl

In the above example C<app.pl> will think that C<Foo::Bar> and C<Baz> are not
installed even though they might actually be installed.

=head1 DESCRIPTION

This module can be used to simulate the absence of certain modules. This only
works if the application uses L<Module::List::Wildcard>'s C<list_modules()> to
check the availability of modules.

This module works by patching C<list_modules()> and strip the target modules
from the result.

=head1 PATCH CONTENTS

=over

=item * wrap C<list_modules>

=back

=head1 PATCH CONFIGURATION

=over

=item * -module => str

A string containing semicolon-separated list of module names to hide.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Module-List-Wildcard-Patch-Hide>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Module-List-Wildcard-Patch-Hide>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Module-List-Wildcard-Patch-Hide>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Module::Patch>

L<Module::List::Wildcard>

L<Module::List::Patch::Hide>, L<Module::List::Tiny::Patch::Hide>,
L<Module::List::More::Patch::Hide>

L<Module::Path::Patch::Hide>, L<Module::Path::More::Patch::Hide>.

If the application checks he availability of modules by actually trying to
C<require()> them, you can try: L<lib::filter>, L<lib::disallow>,
L<Devel::Hide>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
