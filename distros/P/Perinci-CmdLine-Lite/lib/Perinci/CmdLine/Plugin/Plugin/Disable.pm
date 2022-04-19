package Perinci::CmdLine::Plugin::Plugin::Disable;

# put pragmas + Log::ger here
use strict;
use warnings;
use parent 'Perinci::CmdLine::PluginBase';
use Log::ger;

# put other modules alphabetically here

# put global variables alphabetically here
our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-04-15'; # DATE
our $DIST = 'Perinci-CmdLine-Lite'; # DIST
our $VERSION = '1.918'; # VERSION

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
        tags => ['category:plugin'],
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
        log_info "[pericmd Plugin::Disable] Disabling loading of Perinci::CmdLine plugin '$r->{plugin_name}'";
        return [601, "Cancel"];
    }
    [200, "OK"];
}

1;
# ABSTRACT: Prevent the loading (activation) of other plugins

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CmdLine::Plugin::Plugin::Disable - Prevent the loading (activation) of other plugins

=head1 VERSION

This document describes version 1.918 of Perinci::CmdLine::Plugin::Plugin::Disable (from Perl distribution Perinci-CmdLine-Lite), released on 2022-04-15.

=head1 SYNOPSIS

To use, either specify in environment variable:

 PERINCI_CMDLINE_PLUGINS='-Plugin::Disable,plugins,Foo;/^Bar/'

or in code instantiating L<Perinci::CmdLine>:

 my $app = Perinci::CmdLine::Any->new(
     ...
     plugins => ["Plugin::Disable" => {plugins=>["Foo", qr/^Bar/]}],
 );

For list of plugin events available, see L<Perinci::CmdLine::Base/"Plugin
events">.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-CmdLine-Lite>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-CmdLine-Lite>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015, 2014 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-CmdLine-Lite>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
