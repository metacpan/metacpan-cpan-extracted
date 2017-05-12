#!/usr/bin/perl -Ilib -w

# error codes - derived from RFC4930 (EPP)

package Net::Server::Framework::Errorcodes;

use strict;
use warnings;
use Carp;

our ($VERSION) = '1.1';

sub c2m {
    my $code = shift;
    carp "No error code defined" unless defined $code;

    my $errors = {
        1000 => "Command completed successfully",
        1001 => "Command completed successfully; action pending",
        1300 => "Command completed successfully; no messages",
        1301 => "Command completed successfully; ack to dequeue",
        1500 => "Command completed successfully; ending session",
        2000 => "Unknown command",
        2001 => "Command syntax error",
        2002 => "Command use error",
        2003 => "Required parameter missing",
        2004 => "Parameter value range error",
        2005 => "Parameter value syntax error",
        2100 => "Unimplemented protocol version",
        2101 => "Unimplemented command",
        2102 => "Unimplemented option",
        2103 => "Unimplemented extension",
        2104 => "Billing failure",
        2105 => "Object is not eligible for renewal",
        2106 => "Object is not eligible for transfer",
        2200 => "Authentication error",
        2201 => "Authorization error",
        2202 => "Invalid authorization information",
        2300 => "Object pending transfer",
        2301 => "Object not pending transfer",
        2302 => "Object exists",
        2303 => "Object does not exist",
        2304 => "Object status prohibits operation",
        2305 => "Object association prohibits operation",
        2306 => "Parameter value policy error",
        2307 => "Unimplemented object service",
        2308 => "Data management policy violation",
        2400 => "Command failed",
        2500 => "Command failed; server closing connection",
        2501 => "Authentication error; server closing connection",
        2502 => "Session limit exceeded; server closing connection",
    };
    return 'Undefined Error'
      unless defined $errors->{$code};
    return $errors->{$code};
}

1;

=head1 NAME

Net::Server::Framework::Errorcodes - Mapping lib for error codes to
messages


=head1 VERSION

This documentation refers to Net::Server::Framework::Errorcodes version 1.1.


=head1 SYNOPSIS

A typical invocation looks like this:

    my $message = Net::Server::Framework::Errorcodes::c2m($code);

=head1 DESCRIPTION

This is a lib for matching error codes to human readable error messages.
it is used by the C<Net::Server::framework::Format> lib. The error codes
are based on the EPP error codes common in the domain name industry.

=head1 BASIC METHODS

The commands accepted by the lib are: 

=head2 c2m

Takes an error code and returns a error message in human readable form.

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
