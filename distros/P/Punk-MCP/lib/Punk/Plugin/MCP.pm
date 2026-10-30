package Punk::Plugin::MCP;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Punk::Plugin::MCP', $VERSION);

1;

__END__

=head1 NAME

Punk::Plugin::MCP - the Punk plugin that serves the Model Context Protocol

=head1 SYNOPSIS

    package MyApp;
    use Punk;
    use Punk::Plugin::MCP;

    plugin 'MCP' => { path => '/mcp' };

=head1 DESCRIPTION

The plugin behind L<Punk::MCP>. See L<Punk::MCP> for the whole picture.

=head1 METHODS

=head2 resource_updated

    Punk::Plugin::MCP->resource_updated('MyApp', 'books://7');

Tells every session subscribed to the URI that the resource changed, from
anywhere, with no request: a queue job, a cron. The in-request form is
C<< $c->mcp_resource_updated($uri) >>. Returns what Punk's bus said: 1 when
the worker pool will see it, 0 when there is no pool and only this worker
did, -1 when the URI is too long for a bus slot. Sessions off, it does
nothing and returns 0. See L<Punk::MCP/The server stream and subscriptions>.

=head2 state_for

    my $state = Punk::Plugin::MCP->state_for('MyApp');

What an application declared and froze, as a plain hash, or undef when it
does not use the plugin. A copy: changing it changes nothing.

    registered    1 once plugin 'MCP' ran
    frozen        1 after to_app
    opts          the options, defaults filled in
    tools         tool names, in declaration order
    resources     resource URIs, in declaration order
    prompts       prompt names, in declaration order
    declarations  [{ kind, key, spec, target }], target a code ref after to_app
    server        what initialize will advertise, after to_app

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
