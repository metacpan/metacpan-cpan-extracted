#!/usr/bin/perl -Ilib -w

# a formating lib for response processing

package Net::Server::Framework::Format;

use strict;
use warnings;
use Carp;
use Net::Server::Framework::Errorcodes;

our ($VERSION) = '1.1';

#
# the hash expected looks like that:
# {
#     timing => delta seconds
#     ID => unique hash
#     code => error code
#     data => {
#       key1 => val1
#       key2 => val2
#       ...
#     }
# }
#

sub format {
    my $hash = shift;
    delete $hash->{pass};
    $hash->{meta}->{duration}    = delete $hash->{TIME};
    $hash->{meta}->{transaction} = delete $hash->{ID};
    $hash->{meta}->{code}        = delete $hash->{code};
    $hash->{meta}->{user}        = delete $hash->{user};
    $hash->{meta}->{message}     = c2m( $hash->{meta}->{code} );
    return $hash;
}

sub c2m {
    my $code = shift;
    carp "No error code defined" unless defined $code;

    # find the message
    my $message = Net::Server::Framework::Errorcodes::c2m($code);
    return $message;
}

1;

=head1 NAME

Net::Server::Framework::Fromat - response formatter Net::Server::Framework
based daemons


=head1 VERSION

This documentation refers to Net::Server::Framework::Format version 1.1.


=head1 SYNOPSIS

A typical invocation looks like this:

    my $answer = Net::Server::Framework::Format::format( $c->{data} );

=head1 DESCRIPTION

This library is used for formatting responses from daemons to a format
understood by the client lib. It is meant for mapping error codes to
error messages and formatting out debug output oder output not meant for
the customer on the other side of the API.

=head1 BASIC METHODS

The commands accepted by the lib are: 

=head2 format

Formating of responses before returning to the requester.

=head2 c2m

A wrapper function around error mapping. This can be replaced with your
own error mapping functions.

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
