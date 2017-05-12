package Module::Path::More::Patch::Hide;

our $DATE = '2016-07-10'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
no warnings;

use Module::Patch 0.12 qw();
use base qw(Module::Patch);

our %config;

my $w_module_path = sub {
    my $ctx  = shift;
    my $orig = $ctx->{orig};

    my @mods = split /\s*[;,]\s*/, $config{-module};

    my %args = @_;
    if (grep { $args{module} eq $_ } @mods) {
        return $args{all} ? () : undef;
    } else {
        return $orig->(@_);
    }
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
                sub_name => 'module_path',
                code => $w_module_path,
            },
        ],
    };
}

1;
# ABSTRACT: Hide some modules from Module::Path::More

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Path::More::Patch::Hide - Hide some modules from Module::Path::More

=head1 VERSION

This document describes version 0.002 of Module::Path::More::Patch::Hide (from Perl distribution Module-Path-More-Patch-Hide), released on 2016-07-10.

=head1 SYNOPSIS

 % PERL5OPT=-MModule::Path::More::Patch::Hide=-module,'Foo::Bar;Baz' app.pl

In the above example C<app.pl> will think that C<Foo::Bar> and C<Baz> are not
installed even though they might actually be installed.

=head1 DESCRIPTION

This module can be used to simulate the absence of certain modules. This only
works if the application uses L<Module::Path::More>'s C<module_path()> to
check the availability of modules.

This module works by patching C<module_path()> to return empty result if user
asks the modules that happen to be hidden.

=head1 PATCH CONTENTS

=over

=item * wrap C<module_path>

=back

=head1 PATCH CONFIGURATION

=over

=item * -module => str

A string containing semicolon-separated list of module names to hide.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Module-Path-More-Patch-Hide>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Module-Path-More-Patch-Hide>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Module-Path-More-Patch-Hide>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Module::Patch>

L<Module::Path::More>

If the application checks he availability of modules by actually trying to
C<require()> them, you can try: L<lib::filter>, L<lib::disallow>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
