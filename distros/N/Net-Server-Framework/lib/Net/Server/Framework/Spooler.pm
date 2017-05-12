#!/usr/bin/perl -w -Ilib

package Net::Server::Framework::Spooler;

use strict;
use warnings;
use Carp;
use Net::Server::Framework::Client;

our ($VERSION) = '1.0';

sub put {
    my $data = shift;
    my $hash = {
        command => 'put',
        user    => $data->{user},
        body    => $data->{body},
    };
    return(_chat($hash));
}

sub get {
    my $data = shift;
    my $hash = {
        command => 'get',
        user    => $data->{user},
        ID    => $data->{ID},
    };
    my $res = _chat($hash);
    return(Net::Server::Framework::Client::decode($res->{hash}));
}

sub virgin {
    my $data = shift;
    my $hash = {
        command => 'virgin',
        user    => $data->{user},
        ID    => $data->{ID},
    };
    my $res = _chat($hash);
    my $r = Net::Server::Framework::Client::decode($res->{$data->{ID}}->{hash});
    return $r->{body};
}

sub mod {
    my $data = shift;
    my $hash = {
        command => 'mod',
        user    => $data->{user},
        ID    => $data->{ID},
        body    => $data,
	status => "modified",
    };
    return(_chat($hash));
}

sub del {
    my $data = shift;
    my $hash = {
        command => 'del',
        user    => $data->{user},
        ID    => $data->{ID},
    };
    return(_chat($hash));
}

sub archive {
    my $data = shift;
    my $hash = {
        command => 'archive',
        user    => $data->{user},
        ID    => $data->{ID},
    };
    return(_chat($hash));
}

sub _chat {
    my $data = shift;
    # TODO: can we use UDP datagrams to speed things up here?
    my $remote = Net::Server::Framework::Client::c_connect('queue')
      or carp( "cannot connect to spooler, check the config section in your program");

    # send the hash to the daemon
    print $remote Net::Server::Framework::Client::encode($data);
    shutdown $remote, 1;
    my $resp = <$remote>;
    return Net::Server::Framework::Client::decode($resp);
}

1;

=head1 NAME

Net::Server::Framework::Spooler - asynchronous interface for Net::Server::Framework
based daemons


=head1 VERSION

This documentation refers to Net::Server::Framework::Spooler version 1.0.


=head1 SYNOPSIS

A typical invocation looks like this:

    my $put = {body => $c, user => $c->{user}};
    $c->{ID} = Net::Server::Framework::Spooler::put($put);

=head1 DESCRIPTION

This interface is used to process asynchronous requests for daemons. It
relies on a spooler daemon and a spool database. If present this lib
handles the interaction of clients and server that need to process
things in a asynchronous way.

=head1 BASIC METHODS

The commands accepted by the lib are: 

=head2 put

Insert a hash into the spooler

=head2 get

Retrieve a hash from the spooler

=head2 mod

Update a hash in the spooler (normally this is done when a response is
processed)

=head2 del

Remove a hash from the spooler

=head2 virgin

Test if a hash is updated in the spooler. This function is called in
async mode to test if we have a response or not (basic polling)

=head2 archive

This archives a hash into a archive location.

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
