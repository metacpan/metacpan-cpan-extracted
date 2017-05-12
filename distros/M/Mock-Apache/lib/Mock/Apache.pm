# Mock::Apache - a package to mock the mod_perl 1.x environment
#
# Method descriptions are taken from my book: "Mod_perl Pocket Reference",
# Andrew Ford, O'Reilly & Associates, 2001, 0-596-00047-2.
# Page references in the comments (marked "MPPR pNN") refer to the book.
#
# Copyright (C) 2013, Andrew Ford.  All rights reserved.
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.

package Mock::Apache;

use strict;

use Apache::ConfigParser;
use Carp;
use Cwd;
use HTTP::Headers;
use HTTP::Response;
use IO::Scalar;
use Module::Loaded;
use Readonly;

use parent 'Class::Accessor';

__PACKAGE__->mk_accessors(qw(server));

our $VERSION = "0.09";
our $DEBUG;

BEGIN {
    Readonly our @APACHE_CLASSES
        => qw( Apache  Apache::SubRequest  Apache::Server  Apache::Connection
               Apache::File  Apache::Log  Apache::Table  Apache::URI  Apache::Util
               Apache::Constants  Apache::ModuleConfig  Apache::Symbol
               Apache::Request  Apache::Upload  Apache::Cookie );

    # Lie about the Apache::* modules being loaded
    mark_as_loaded($_)
        for @APACHE_CLASSES;

    # alias the DEBUG() and NYI_DEBUG() functions into each class
    no strict 'refs';
    *{"${_}::DEBUG"}     = \&DEBUG     for @APACHE_CLASSES;
    *{"${_}::NYI_DEBUG"} = \&NYI_DEBUG for @APACHE_CLASSES;

    $ENV{MOD_PERL} = 'CGI-Perl/1.1';
}

# These packages need to come after the Apache::* modules have been
# marked as loaded, to avoid the real Apache::* classes being dragged
# in.
use Mock::Apache::Emulation;
use Mock::Apache::RemoteClient;


Readonly our $DEFAULT_HOSTNAME => 'server.example.com';
Readonly our $DEFAULT_ADDR     => '22.22.22.22';
Readonly our $DEFAULT_ADMIN    => 'webmaster';

# Default locations (RedHat-inspired)

Readonly our $DEFAULT_SERVER_ROOT   => '/etc/httpd';
Readonly our $DEFAULT_DOCUMENT_ROOT => '/var/www/html';

# I am still playing with the API to Mock::Apache.
# I envisage having methods to:
#   * set up the mock server
#   * run a request through the server
#   * create an apache request object

# Set up a mock Apache server

sub setup_server {
    my ($class, %params) = @_;

    my $cfg = Apache::ConfigParser->new;

    if (my $config_file = $params{config_file}) {
        $cfg->parse_file($config_file);
    }

    $DEBUG = delete $params{DEBUG};

    $params{document_root}   ||= _get_config_value($cfg, 'DocumentRoot', $DEFAULT_DOCUMENT_ROOT);
    $params{server_root}     ||= _get_config_value($cfg, 'ServerRoot',   $DEFAULT_SERVER_ROOT);
    $params{server_hostname} ||= $DEFAULT_HOSTNAME;
    $params{server_port}     ||= 80;
    $params{server_admin}    ||= _get_config_value($cfg, 'ServerAdmin', 
                                                   $DEFAULT_ADMIN . '@' . $params{server_hostname});
    $params{gid}             ||= getgrnam('apache') || 48;
    $params{uid}             ||= getpwnam('apache') || 48;


    my $self = bless { %params }, $class;

    $self->{server} = $Apache::server = Apache::Server->new($self, %params);

    return $self;
}

sub _get_config_value {
    my ($config, $directive, $default) = @_;

    if ($config and my @dirs = $config->find_down_directive_names($directive)) {
        return $dirs[0]->value;
    }
    return $default;
}

sub mock_client {
    my ($self, %params) = @_;

    return Mock::Apache::RemoteClient->new(%params, mock_apache => $self);
}


# $mock_apache->execute_handler($handler, $request)
# $mock_apache->execute_handler($handler, $client, $request)

sub execute_handler {
    my ($self, $handler, $client) = (shift, shift, shift);

    my $request;
    if (ref $client and $client->isa('Apache')) {
        $request = $client;
        $client  = $client->_mock_client;
    }
    croak "no mock client specified"
        unless ref $client and $client->isa('Mock::Apache::RemoteClient');

    if (!ref $handler) {
        no strict 'refs';
        $handler = \&{$handler};
    }

    $request ||= $client->new_request(@_);

    my $saved_debug = $Mock::Apache::DEBUG;
    local $Mock::Apache::DEBUG = 0;

    local($ENV{REMOTE_ADDR}) = $request->subprocess_env('REMOTE_ADDR');
    local($ENV{REMOTE_HOST}) = $request->subprocess_env('REMOTE_HOST');

    local $Apache::request = $request;

    my $rc = eval {
        local $Mock::Apache::DEBUG = $saved_debug;
        local *STDOUT;
        tie *STDOUT, 'IO::Scalar', \$request->{_output};
        $handler->($request);
    };
    if ($@) {
        printf STDERR "handler failed: $@\n";
        $request->status_line('500 Internal server error');
    }

    my $status  = $request->status;
    if (!$status) {
        if ($rc == &Apache::Constants::OK) {
            $request->status_line(($status = &Apache::Constants::HTTP_OK) . ' ok');
        }
        elsif ($rc == &Apache::Constants::MOVED) {
            $request->status_line(($status = &Apache::Constants::HTTP_MOVED_PERMANENTLY) . ' moved permanently');
        }
    }
    (my $message = $request->status_line || '') =~ s/^... //;
    my $headers = HTTP::Headers->new;
    if (!$request->header_out('content-length')) {
        $request->header_out('content-length', length($request->_output));
    }
    while (my($field, $value) = each %{$request->headers_out}) {
        $headers->push_header($field, $value);
    }
    my $output = $request->_output;

    return HTTP::Response->new( $status, $message, $headers, $output );
}

sub DEBUG {
    my ($message, @args) = @_;

    return unless $Mock::Apache::DEBUG;
    $message .= "\n" unless $message =~ qr{\n$};
    printf STDERR "DEBUG: $message", @args;
    if ($DEBUG > 1) {
	my ($package, $file, $line, $subr) = ((caller(1))[0..2], (caller(2))[3]);
	if ($file eq __FILE__) {
	    ($package, $file, $line, $subr) = ((caller(2))[0..2], (caller(3))[3]);
	}
	my $dir = getcwd;
	$file =~ s{^$dir/}{};
	print STDERR "       from $subr at line $line of $file\n";
    }

    return;
}

sub NYI_DEBUG {
    my ($message, @args) = @_;

    $message .= "\n" unless $message =~ qr{\n$};
    printf STDERR "DEBUG: $message", @args;

    my $carp_level = 1;
    my ($package, $file, $line, $subr) = ((caller(1))[0..2], (caller(2))[3]);
    if ($file eq __FILE__) {
	$carp_level++;
	($package, $file, $line, $subr) = ((caller(2))[0..2], (caller(3))[3]);
    }
    if ($DEBUG > 1) {
	my $dir = getcwd;
	$file =~ s{^$dir/}{};
	print STDERR "       from $subr at line $line of $file";
    }
    $DB::single = 1;
    local $Carp::CarpLevel = $carp_level;
    croak((caller(1))[3] . " - NOT YET IMPLEMENTED");
}

1;

__END__

=head1 NAME

Mock::Apache - mock Apache environment for testing and debugging

=head1 SYNOPSIS

    use Mock::Apache;

    my $server  = Mock::Apache->setup_server(param => 'value', ...);
    my $request = $server->new_request(method_name => 'value', ...);

    $server->

=head1 DESCRIPTION

C<Mock::Apache> is a mock framework for testing and debugging mod_perl
1.x applications.  Although that version of mod_perl is obsolete, there
is still a lot of legacy code that uses it.  The framework is intended
to assist in understanding such code, by enabling it to be run and
debugged outside of the web server environment.  The framework
provides a tracing facility that prints all methods called, optionally
with caller information.

C<Mock::Apache> is based on C<Apache::FakeRequest> but goes beyond
that module, attempting to provide a relatively comprehensive mocking
of the mod_perl environment.

NOTE: the module is still very much at an alpha stage, with much of
the Apache::* classes missing, and much of the emulation incomplete or
probably just wrong.

I am aiming to provide top-level methods to "process a request", by
giving the mock apache object enough information about the
configuration to identify handlers, etc.  Perhaps passing the
server_setup method the pathname of an Apache configuration file even
and minimally "parsing" it.


=head1 METHODS

=head2 setup_server

=head2 new_request

=head2 execute_handler

localizes elements of the %ENV hash


=head1 DEPENDENCIES

=over 4

=item L<Apache::FakeTable>

for emulation of C<Apache::Table> (but this is subclassed to emulate
pnotes tables, which can store references)

=item L<Module::Loaded>

to pretend that the C<Apache::*> modules are loaded.

=item L<IO::Scalar>

for tieing C<STDOUT> to the Apache response

=back


=head1 BUGS AND LIMITATIONS

The intent of this package is to provide an emulation of C<mod_perl>
1.3 that that will allow straightforward handlers to be unit-tested
outside the Apache/mod_perl environment.  However it will probably
never provide perfect emulation.

The package is still in an early alpha stage and is known to be
incomplete.  Feedback and patches to improve the software are most
welcome.


=head1 SEE ALSO

https://github.com/fordmason/Mock-Apache

I<mod_perl Pocket Reference> by Andrew Ford, O'Reilly & Associates,
Inc, Sebastapol, 2001, ISBN: 0-596-00047-2


=head1 ACKNOWLEDGEMENTS

Inspired by C<Apache::FakeRequest> by Doug MacEachern, with contributions
from Andrew Ford <andrew@ford-mason.co.uk>.


=head1 AUTHORS

Andrew Ford <andrew@ford-mason.co.uk>


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2013 Andrew Ford (<andrew@ford-mason.co.uk>). All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
