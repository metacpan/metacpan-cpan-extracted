#!/usr/bin/perl

package Net::Server::Framework::Config;

use strict;
use warnings;
use Carp;

our ($VERSION) = '1.3';

sub file2hash {
    my $file = shift;

    open( my $FILE, q{<}, $file ) or croak "Could not open $file: $!";
    my $hash;
    while (<$FILE>) {
        if (
            my ( $key, $value ) =
            $_ =~ m{\A                  # beginning of string
                       ^\s*             # trailing spaces are ignored
                       ([^#/]           # match any string
                       \S+)             # not starting with # or /
                                        # and not beeing a space
                      \s+               # any number of spaces
                      (.*)              # any character
                      \n                # newlines at end of line 
                      \z                # end of string
                    }sxm
          )
        {
            $hash->{$key} = $value;
        }
    }
    return $hash;
}

1;

=head1 NAME

Net::Server::Framework::Config - this lib is deprecated and only here
for compatibility


=head1 VERSION

This documentation refers to C<Net::Server::Framework::Config> version 1.3.

=head1 DESCRIPTION

This library is only listed for compatibility and needs to be replaced
by one of the established configuration parser.

=head1 BASIC METHODS

=head2 file2hash

This converts a INI style file into a hash

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
