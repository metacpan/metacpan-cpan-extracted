package ScriptX::DisablePlugin;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-01'; # DATE
our $DIST = 'ScriptX'; # DIST
our $VERSION = '0.000004'; # VERSION

# IFUNBUILT
# use strict;
# use warnings;
# END IFUNBUILT
use Log::ger;

use parent 'ScriptX_Base';

sub meta {
    return {
        summary => 'Prevent the loading (activation) of other plugins',
        conf => {
            plugins => {
                summary => 'List of plugin names or regexes',
                description => <<'_',

Plugins should be an array of plugin names or regexes, e.g.:

    ['Foo', 'Bar', qr/baz/]

To make it easier to specify via environment variable (SCRIPTX_IMPORT), a
semicolon-separated string is also accepted. A regex should be enclosed in
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
    my ($self, $stash) = @_;

    for my $el (@{ $self->{plugins} }) {
        if (ref $el eq 'Regexp') {
            next unless $stash->{plugin_name} =~ $el;
        } else {
            next unless $stash->{plugin_name} eq $el;
        }
        log_info "[ScriptX::DisablePlugin] Disabling loading of ScriptX plugin '$stash->{plugin_name}'";
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

ScriptX::DisablePlugin - Prevent the loading (activation) of other plugins

=head1 VERSION

This document describes version 0.000004 of ScriptX::DisablePlugin (from Perl distribution ScriptX), released on 2020-10-01.

=head1 SYNOPSIS

 use ScriptX DisablePlugin => {plugins => ['Foo', qr/^Bar/]};

=head1 DESCRIPTION

=head1 SCRIPTX PLUGIN CONFIGURATION

=head2 plugins

Any. Required. List of plugin names or regexes.

Plugins should be an array of plugin names or regexes, e.g.:

 ['Foo', 'Bar', qr/baz/]

To make it easier to specify via environment variable (SCRIPTX_IMPORT), a
semicolon-separated string is also accepted. A regex should be enclosed in
"/.../". For example:

 Foo;Bar;/baz/

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ScriptX>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ScriptX>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ScriptX>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
