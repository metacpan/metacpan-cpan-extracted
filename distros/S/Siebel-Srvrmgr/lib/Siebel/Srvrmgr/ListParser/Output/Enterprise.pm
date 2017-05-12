package Siebel::Srvrmgr::ListParser::Output::Enterprise;

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::Enterprise - subclass that represents the initial information from a Siebel server when connected through srvrmgr program.

=head1 SYNOPSIS

See L<Siebel::Srvrmgr::ListParser::Output>.

=cut

use Moose 2.0401;
use Siebel::Srvrmgr::Regexes qw(CONN_GREET);
use Carp;
use List::Util 1.42 qw(sum);

extends 'Siebel::Srvrmgr::ListParser::Output';
our $VERSION = '0.29'; # VERSION

=pod

=head1 DESCRIPTION

C<Siebel::Srvrmgr::ListParser::Output::Greetings> extends C<Siebel::Srvrmgr::ListParser::Output>.

Normally this class would be created by L<Siebel::Srvrmgr::ListParser::OutputFactory> C<create> static method. See the automated tests for examples of direct 
instatiation.

It is possible to recover some useful information from the object methods but most of it is simple copyrigh information.

=head1 ATTRIBUTES

=head2 version

A string that represents the version of the Siebel enterprise where the connection was stablished. This is a read-only attribute.

=cut

has 'version' => (
    is     => 'ro',
    isa    => 'Str',
    reader => 'get_version',
    writer => '_set_version'
);

=pod

=head2 patch

A string that represents the patch version of the Siebel enterprise where the connection was stablished. This is a read-only attribute.

=cut

has 'patch' =>
  ( is => 'ro', isa => 'Int', reader => 'get_patch', writer => '_set_patch' );

=pod

=head2 copyright

An array reference that represents the copyright information of the Siebel enterprise where the connection was stablished. This is a read-only attribute.

=cut

has 'copyright' => (
    is     => 'ro',
    isa    => 'ArrayRef[Str]',
    reader => 'get_copyright'
);

=pod

=head2 total_servers

A integer that represents the total number of servers configured in the enterprise where the connection was stablished. This is a read-only attribute.

=cut

has 'total_servers' => (
    is     => 'ro',
    isa    => 'Int',
    reader => 'get_total_servers',
    writer => '_set_total_servers'
);

=pod

=head2 total_connected 

A integer that represents the total number of servers available in the enterprise where the connection was stablished. This is a read-only attribute.

=cut

has 'total_connected' => (
    is     => 'ro',
    isa    => 'Int',
    reader => 'get_total_conn',
    writer => '_set_total_conn'
);

=pod

=head2 help

A string representing how to invoke online help within C<srvrmgr> program. This is a read-only attribute.

=cut

has 'help' => (
    is     => 'ro',
    isa    => 'Str',
    reader => 'get_help',
    writer => '_set_help'
);

=pod

=head1 METHODS

See L<Siebel::Srvrmgr::ListParser::Output> class for inherited methods.

=head2 get_version

Returns a string as the value of version attribute.

=head2 get_patch

Returns a string as the value of patch attribute.

=head2 get_copyright

Returns a string as the value of copyright attribute.

=head2 get_total_servers

Returns a integer as the value of total_servers attribute.

=head2 get_total_conn

Returns a integer as the value of total_connected attribute.

=head2 parse

This method overrides the superclass.

=cut

override 'parse' => sub {

    my $self = shift;

    my $data_ref = $self->get_raw_data();

    my %data_parsed;

    #Copyright (c) 2001 Siebel Systems, Inc.  All rights reserved.
    my $copyright_regex = qr/^Copyright\s\(c\)/;
    my $more_copyright  = qr/^[\w\(]+/;
    my $help_regex      = qr/^Type\s\"help\"/;

    #Connected to 1 server(s) out of a total of 1 server(s) in the enterprise
    #Connected to 2 server(s) out of a total of 2 server(s) in the enterprise
    my $connected_regex = qr/^Connected\sto\s\d+\sserver\(s\)/;

    my %check = (
        conn_greet     => 0,
        copyright      => 0,
        help           => 0,
        connected      => 0,
        more_copyright => 0
    );

    foreach my $line ( @{$data_ref} ) {

        chomp($line);

      SWITCH: {

            if ( $line eq '' ) {

                # do nothing
                last SWITCH;
            }

            if ( $line =~ CONN_GREET ) {

#Siebel Enterprise Applications Siebel Server Manager, Version 7.5.3 [16157] LANG_INDEPENDENT
                my @words = split( /\s/, $line );

                $self->_set_version( $words[7] );
                $data_parsed{version} = $words[7];

                $words[8] =~ tr/[]//d;
                $self->_set_patch( $words[8] );
                $data_parsed{patch} = $words[8];
                $check{conn_greet}  = 1;
                last SWITCH;

            }

            if ( $line =~ $copyright_regex ) {

                $self->_set_copyright($line);
                $data_parsed{copyright} = $line;
                $check{copyright}       = 1;
                last SWITCH;

            }

            if ( $line =~ $help_regex ) {

                $self->_set_help($line);
                $data_parsed{help} = $line;
                $check{help}       = 1;
                last SWITCH;

            }

            if ( $line =~ $connected_regex ) {

                my @words = split( /\s/, $line );

                $self->_set_total_servers( $words[9] );
                $self->_set_total_conn( $words[2] );
                $data_parsed{total_servers} = $words[9];
                $data_parsed{total_conn}    = $words[2];
                $check{connected}           = 1;
                last SWITCH;

            }

            if ( $line =~ $more_copyright ) {

                $self->_set_copyright($line) if ( $check{copyright} );
                $data_parsed{copyright} = $line;
                $check{more_copyright}  = 1;
                last SWITCH;

            }
            else {

                confess 'Do not know how to deal with line content "' . $line
                  . '"';

            }

        }

    }

    $self->set_data_parsed( \%data_parsed );
    $self->set_raw_data( [] );

    if ( ( keys(%check) ) == ( sum( values(%check) ) ) ) {

        return 1;

    }
    else {

        foreach my $key ( keys(%check) ) {

            warn "$key was not matched" unless ( $check{$key} );

        }
        return 0;

    }

};

=pod

=head2 _set_copyright

"Private" method to set the copyright information.

=cut

sub _set_copyright {

    my $self = shift;
    my $line = shift;

    push( @{ $self->{copyright} }, $line );

    return 1;

}

=pod

=head1 CAVEATS

Beware that the parse method is called automatically as soon as the object is created.

=head1 SEE ALSO

=over 2

=item *

L<Siebel::Srvrmgr::Regexes>

=item *

L<Siebel::Srvrmgr::ListParser::Output>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>.

This file is part of Siebel Monitoring Tools.

Siebel Monitoring Tools is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Siebel Monitoring Tools is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Siebel Monitoring Tools.  If not, see L<http://www.gnu.org/licenses/>.

=cut

__PACKAGE__->meta->make_immutable;
no Moose;
