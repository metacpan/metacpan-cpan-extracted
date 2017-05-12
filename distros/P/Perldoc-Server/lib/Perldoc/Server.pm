package Perldoc::Server;

use strict;
use warnings;
use 5.010;

use Catalyst::Runtime '5.70';
use Sys::Hostname;
use Config::General;
use NEXT;

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use parent qw/Catalyst/;
use Catalyst qw/
                ConfigLoader
                Session
                Session::State::Cookie
                Session::Store::File
                Static::Simple/;
our $VERSION = '0.10';

# Configure the application.
#
# Note that settings in perldoc_server.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

my $host = (split('\.',hostname))[0];

__PACKAGE__->config( name             => 'Perldoc::Server',
                     version          => $VERSION,
                     host             => $host, 
                     perl             => $ENV{PERLDOC_SERVER_PERL} || $^X,
                     perl_version     => $ENV{PERLDOC_SERVER_PERL_VERSION} || sprintf("%vd",$^V),
                     search_path      => $ENV{PERLDOC_SERVER_SEARCH_PATH} ? [split /\r\n|\n/,$ENV{PERLDOC_SERVER_SEARCH_PATH}] : \@INC,
                     'View::TT'       => { INCLUDE_PATH => __PACKAGE__->path_to('root','templates')},
                     'View::Pod2HTML' => { INCLUDE_PATH => __PACKAGE__->path_to('root','templates')},
                    );

# Set default view to TT
__PACKAGE__->config->{default_view} = 'TT';

# Configure default session expiry time
__PACKAGE__->config->{'session'} = {
    expires => 30*24*60*60  # 30 days
};

# Start the application
__PACKAGE__->setup();


=head1 NAME

Perldoc::Server - Local Perl documentation server

=head1 SYNOPSIS

 perldoc-server [options]
 
 Options:
 --perl /path/to/perl   Show documentation for this Perl installation
 --port 1234            Set server port number
 --public               Run as a public server (defaults to private)
 --help                 Display help

=head1 DESCRIPTION

Perldoc::Server is a Catalyst application to serve local Perl documentation
in the same style as L<http://perldoc.perl.org>.

In addition to keeping the same look and feel of L<http://perldoc.perl.org>,
Perldoc::Server offer the following features:

=over

=item * View source of any installed module

=item * Improved syntax highlighting

=over

=item * Line numbering

=item * C<use> and C<require> statements linked to modules

=back

=item * Sidebar shows links to your 10 most viewed documentation pages

=back

=head1 CONFIGURATION

=over

=item --perl

By default, Perldoc::Server will show documentation for the Perl installation
used to run the server.

However, using the C<--perl> command-line option, it is also possible to
serve documentation for a different Perl installation, e.g.

 perldoc-server --perl /usr/bin/perl

Note that while Perldoc::Server requires Perl 5.10.0 or newer, the C<--perl>
option can be used to display documentation for older Perls.

=item --port

Sets the server's port number - defaults to 7375 ("PERL" on a phone keypad).

=item --public

Runs as a public server. If this option is not set, the server will default
to private mode, i.e. only accepting connections from localhost.

=back

=head1 SEE ALSO

L<http://perldoc.perl.org>

L<http://perl.jonallen.info/projects/perldoc>

Penny's Arcade Open Source - L<http://www.pennysarcade.co.uk/opensource>

=head1 AUTHOR

Jon Allen (JJ) <jj@jonallen.info>

Perldoc::Server was developed at the 2009 QA Hackathon L<http://qa-hackathon.org>
supported by Birmingham Perl Mongers L<http://birmingham.pm.org>

=head1 CONTRIBUTORS

Thanks to Andreas Koenig and Barbie for help in rendering Unicode characters
in Pod.

Thanks to Varyanick I. Alex for bugfix patches for RT tickets #49486, #49488,
#49491, and #49492.

Thanks to Eduard Wulff, Tomas Doran, and Colin Newell for parches, help, and support.

=head1 COPYRIGHT and LICENSE

Copyright (C) 2011 Penny's Arcade Limited - L<http://www.pennysarcade.co.uk>

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
