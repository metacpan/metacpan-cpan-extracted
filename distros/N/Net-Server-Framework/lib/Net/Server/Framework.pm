#!/usr/bin/perl -w

package Net::Server::Framework;

use strict;
use warnings;
use Carp;
use Data::Serializer;
use Net::Server::Framework::DB;
use Net::Server::Framework::Crypt;
use Net::Server::Framework::Auth;
use Net::Server::Framework::Format;
use base qw/Exporter Net::Server::PreFork/;
use vars qw(@EXPORT $VERSION);

our ($VERSION) = '1.2';
@EXPORT = qw/options encode decode register/;

sub options {
    my $self     = shift;
    my $prop     = $self->{server};
    my $template = shift;

    $self->SUPER::options($template);
    $prop->{daemon_name} ||= undef;
    $template->{daemon_name} = \$prop->{daemon_name};
    $prop->{node_name} ||= undef;
    $template->{node_name} = \$prop->{node_name};
}

sub encode {
    my ( $self, $data ) = @_;
    my $s = Data::Serializer->new( compress => '1' );
    return $s->serialize($data);
}

sub decode {
    my ( $self, $data ) = @_;
    my $s = Data::Serializer->new( compress => '1' );
    return $s->deserialize($data);
}

sub register {
    my $self  = shift;
    my $dereg = shift;
    my $status;
    if (defined $dereg) {
        $status = $dereg;
    } else {
        $status = 'running';
    }
    my $dbh   = Net::Server::Framework::DB::dbconnect('registry');
    my ( $host, $port );
    foreach my $p ( @{ $self->{server}->{port} } ) {
        $port .= $p . ',';
    }
    $port =~ s/,$//;
    foreach my $h ( @{ $self->{server}->{host} } ) {
        $host .= $h . ',';
    }
    $host =~ s/,$//;
    my $data = {
        service   => $self->{server}->{daemon_name},
        port      => $port,
        host      => $host,
        lastcheck => time(),
        startup   => time(),
        status    => $status,
    };
    Net::Server::Framework::DB::put( { dbh => $dbh, data => $data, table => 'services' , replace_into => 'true'} );
    $self->log(2,"Registered successfuly\n");
}


1;

=head1 NAME

Net::Server::Framework - an event driven infrastructure around Net::Server


=head1 VERSION

This documentation refers to C<Net::Server::Framework> version 1.0.


=head1 SYNOPSIS

In order to use this codebase you have to subclass this class. To get an
idea of how this looks like have a look at the C<Net::Server>
documentation.

A typical invocation looks like this:

    use base qw/Net::Server::Framework/;
    use strict;
    use warnings;

    __PACKAGE__->run;
    exit;

=head1 DESCRIPTION

C<Net::Server::Framework> is the result of many iterations of backend
daemon programming. I use the C<Net::Server::PreFork> code for some years
now and wrote some libs around it. This is an attempt to take those libs
and release them. The challenge for me is to isolate all the additions,
clean them up and pack them into one framework that installs nicely.

The purpose of this framework is an easy to use event driven and
scalable infrastructure that you can use to run multiple daemons doing
specific things. There are some key parts in this setup.

The central registry is used to register each daemon with its connection
info (UNIX socket or IP/port). The client library resolves daemon names
with this registry to connection information. The client lib supports
both, synchronous and asynchronous connection handling via a cache
daemon.

This version uses SQLite as the standard DB. Most parameters in the
system (including the database type) are configurable via INI style
config files.

This framework is used in some quite busy environments and some things
might look strange but are the result of optimization or problems we ran
into when scaling. One such thing is the DB abstraction which is tuned
for the least possible overhead (memory and cpu wise).

The source code and some working examples can be found on github:
http://github.com/norbu09/net--server--framework/tree/master

=head1 BASIC METHODS

=head2 options

This function overrides the standard options function in C<Net::Server>

=head2 encode

This is a generic wrapper for transport encodings. This function can be
overridden to use transports like JSON or XML. The standard is a
compressed Data::Serialiser stream.

=head2 decode

The reverse of encode.

=head2 register

This registers the daemon in the registry and has to be called in the
startup phase. It is also used to unregister the daemon in the tear down
phase.

=head1 DIAGNOSTICS

The framework normally logs to a central logfile under /var/log but can
log directly to syslog as well. Have a look at the C<Net::Server> options.

=head1 CONFIGURATION AND ENVIRONMENT

The framework expects a etc/ directory with a config file containing a
C<Net::Server> conform structure with some extra fields. Have a look at the
github repository for more reference.

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Please report problems to 
Lenz Gschwendtner ( <lenz@springtimesoft.com> )
Patches are welcome.

=head1 AUTHOR

Lenz Gschwendtner ( <lenz@springtimesoft.com> )



=head1 LICENCE AND COPYRIGHT

Copyright (c) 
2007 Lenz Gschwerndtner ( <lenz@springtimesoft.comn> )
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.


