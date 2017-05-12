#!/usr/bin/perl
# this defines all the valid commands for the frontend spooler. if you
# add more commands you have to define them in _is_valid_command

package Net::Server::Framework::Validate;

use strict;
use warnings;
use Carp;
use Data::FormValidator;
use Data::Dumper;

our ($VERSION) = '1.1';

sub verify_command {
    my $data = shift;

    my $rules = {
        required    => [qw/command user pass/],
        optional    => [qw/data format options/],
        filters     => ['trim'],
        constraints => {
            'command' => \&_is_valid_command,
            'user'    => qr/^[\w-]{3,100}/,
            'format'  => qr/^[yaml|xml|json]/,
            'pass'    => qr/^[\w]{10,100}$/,
        },

    };

    my $dfv = Data::FormValidator->check( $data, $rules );
    #print STDERR Dumper($dfv);
    if ( $dfv->has_unknown ) {
        return 2306;
    }
    elsif ( $dfv->has_missing ) {
        return 2003;
    }
    elsif ( $dfv->has_invalid ) {
        if ( defined $dfv->{invalid}->{command} ) {
            return 2000;
        }
        else {
            return 2005;
        }
    }
    return $dfv->valid;
}

sub _is_valid_command {
    my $command  = pop;
    $command = lc($command);
    # add your commands below to enable them in the frontend spooler
    my @commands = qw{login};
    if ( my $hit = grep( /$command/, @commands ) ) {
        return 1;
    }
    return 0;
}

1;

=head1 NAME

Net::Server::Framework::Validate - validation library for Net::Server::Framework
based daemons


=head1 VERSION

This documentation refers to Net::Server::Framework::Validate version 1.1.


=head1 SYNOPSIS

A typical invocation looks like this:

        $c = Net::Server::Framework::Validate::verify_command($c);
        if ($c =~ /^\d+$/){
            print STDERR "Validation failed - dodgy command!";
            return $c;
        }

=head1 DESCRIPTION

This interface is used to validate commands sent to the daemon. You have
to provide valid commands in the array defined in _is_valid_command.

    my @commands = qw{login MORE COMMANDS};

=head1 BASIC METHODS

The commands accepted by the lib are: 

=head2 verify_command

This tests for the validity of a command

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
