package Perinci::CmdLine::Plugin::DisablePlugin;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-06'; # DATE
our $DIST = 'Perinci-CmdLine-Lite'; # DIST
our $VERSION = '1.907'; # VERSION

# IFUNBUILT
# use strict;
# use warnings;
# END IFUNBUILT
use Log::ger;

use parent 'Perinci::CmdLine::PluginBase';

sub meta {
    return {
        summary => 'Prevent the loading (activation) of other plugins',
        conf => {
            plugins => {
                summary => 'List of plugin names or regexes',
                description => <<'_',

Plugins should be an array of plugin names or regexes, e.g.:

    ['Foo', 'Bar', qr/baz/]

To make it easier to specify via environment variable (PERINCI_CMDLINE_PLUGINS),
a semicolon-separated string is also accepted. A regex should be enclosed in
"/.../". For example:

    Foo;Bar;/baz/

_
                schema => ['any*', of=>[
                    'str*',
                    ['array*', of=>['any*', of=>['str*', 're*']]],
                ]],
                req => 1,
            },
        },
    };
}

sub new {
    my ($class, %args) = (shift, @_);
    $args{plugins} or die "Please specify plugins to disable";
    unless (ref $args{plugins} eq 'ARRAY') {
        $args{plugins} =
            [map { m!\A/(.*)/\z! ? qr/$1/ : $_ } split /;/, $args{plugins}];
    }
    $class->SUPER::new(%args);
}

sub before_activate_plugin {
    my ($self, $r) = @_;

    for my $el (@{ $self->{plugins} }) {
        if (ref $el eq 'Regexp') {
            next unless $r->{plugin_name} =~ $el;
        } else {
            next unless $r->{plugin_name} eq $el;
        }
        log_info "[pericmd DisablePlugin] Disabling loading of Perinci::CmdLine plugin '$r->{plugin_name}'";
        return [601, "Cancel"];
    }
    [200, "OK"];
}

1;
# ABSTRACT:

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CmdLine::Plugin::DisablePlugin

=head1 VERSION

This document describes version 1.907 of Perinci::CmdLine::Plugin::DisablePlugin (from Perl distribution Perinci-CmdLine-Lite), released on 2021-08-06.

=head1 SYNOPSIS

To use, either specify in environment variable:

 PERINCI_CMDLINE_PLUGINS='-DisablePlugin,plugins,Foo;/^Bar/'

or in code instantiating L<Perinci::CmdLine>:

 my $app = Perinci::CmdLine::Any->new(
     ...
     plugins => [DisablePlugin => {plugins=>["Foo", qr/^Bar/]}],
 );

=head1 DESCRIPTION

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-CmdLine-Lite>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-CmdLine-Lite>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-CmdLine-Lite>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018, 2017, 2016, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
