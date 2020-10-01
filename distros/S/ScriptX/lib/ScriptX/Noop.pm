package ScriptX::Noop;

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
require ScriptX;

sub meta {
    return {
        summary => 'A plugin that does nothing, for testing',
        description => <<'_',

This plugin does nothing useful. It is mostly for testing purposes.

It installs a handler for the `run` event, but simply logs an info message
"Hello ...".

_
        conf => {
            foo => {
                summary => 'Some useless configuration',
                schema => ['str*'],
            },
        },
    };
}

sub meta_on_run {
    +{
        prio => 90, # low
    };
}

sub on_run {
    my ($self, $stash) = @_;

    log_info "[ScriptX::Noop] Hello from the Noop plugin";
    [200, "OK"];
}

1;
# ABSTRACT: A plugin that does nothing, for testing

__END__

=pod

=encoding UTF-8

=head1 NAME

ScriptX::Noop - A plugin that does nothing, for testing

=head1 VERSION

This document describes version 0.000004 of ScriptX::Noop (from Perl distribution ScriptX), released on 2020-10-01.

=head1 SYNOPSIS

 use ScriptX 'Noop';

Another example:

 use ScriptX Noop => {foo => 'bar'};

=head1 DESCRIPTION

=head1 SCRIPTX PLUGIN CONFIGURATION

=head2 foo

Str. Optional. Some useless configuration.

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
