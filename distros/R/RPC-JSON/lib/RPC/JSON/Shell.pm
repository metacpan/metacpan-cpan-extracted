package RPC::JSON::Shell;

use warnings;
use strict;

use vars qw|$VERSION @EXPORT $DEBUG $META $AUTOLOAD|;

$VERSION = '0.02';

@RPC::JSON::Shell = qw|Exporter|;

use RPC::JSON;
use Term::ReadLine;
use Data::Dumper;

my $rpcInstance;

=head1 NAME

RPC::JSON::Shell - Interactive JSON-RPC Shell

=head1 SYNOPSIS

    perl -MRPC::JSON -e "RPC::JSON::shell"

    Not connected> connect http://www.dev.simplymapped.com/services/geocode/json.smd
    GeocodeService > geocode "1600 Pennsylvania Ave Washington DC"
    $VAR1 = [
          {
            'administrativearea' => 'DC',
            'country' => 'US',
            'longitude' => '-77.037691',
            'subadministrativearea' => 'District of Columbia',
            'locality' => 'Washington',
            'latitude' => '38.898758',
            'thoroughfare' => '1600 Pennsylvania Ave NW',
            'postalcode' => 20004,
            'address' => '1600 Pennsylvania Ave NW, Washington, DC 20004, USA'
          }
    ];

=head1 DESCRIPTION

This module is an interactive client to a JSON-RPC service.  It is currently
in its infancy and is likely to be very unstable.  There are many bugs in this
package.

=cut

=item shell

Initiate a shell session

=cut

sub shell {
    my ( $service ) = @_;
    my $term   = new Term::ReadLine 'RPC::JSON::Shell';
    my $prompt = "Not connected > ";
    my $out    = $term->OUT || \*STDOUT;

    if ( $service ) {
        __PACKAGE__->connect($out, $service);
        if ( $rpcInstance and $rpcInstance->service ) {
            $prompt = sprintf("%s > ", $rpcInstance->service);
        }
    }

    while ( defined ( $_ = $term->readline($prompt) ) ) {
        s/^\s+|\s+$//g;
        my ( $method, @args ) = split(/\s+/, $_);
        my @d = (); my $curArg;
        foreach my $arg ( @args ) {
            if ( $curArg and $arg =~ /"\s*$/ ) {
                $curArg .= " $arg";
                $curArg =~ s/^(\s*")|("\s*)$//g;
                push @d, $curArg;
                $curArg = '';
            }
            elsif ( $arg =~ /^\s*"/ and not $curArg ) {
                $curArg = $arg;
            }
            elsif ( $curArg ) {
                $curArg .= " $arg";
            }
            else {
                push @d, $arg;
            }
        }

        if ( __PACKAGE__->can(lc($method)) ) {
            my $l = lc($method);
            __PACKAGE__->$l($out, @d);
        }
        elsif ( $method =~ /^quit|exit$/i ) {
            return 1;
        }
        elsif ( $rpcInstance->methods->{$method} ) {
            __PACKAGE__->method($out, $method, @d);
        } else {
            print Dumper $rpcInstance->methods->{$method};
            print $out "Unrecognized command $method, type help for a list of commands\n";
        }
        if ( $rpcInstance and $rpcInstance->service ) {
            $prompt = sprintf("%s > ", $rpcInstance->service);
        } else {
            $prompt = "Not connected > ";
        }
    }
}

=item help

Display the help text.

=cut

sub help {
    my ( $class, $out, @args ) = @_;
    print $out qq|
RPC::JSON::Shell Help
---------------------
Below is a full listing of commands, and how they can be used:
    connect <URI> - Connect to a URI, must be an SMD.
    disconnect    - Close connection to a specific URI (if connected)

    ls            - List available methods
    <method> LIST - Call method with parameters LIST 

    quit          - Exit RPC::JSON::Shell
|;

}

=item connect smdUrl

Connect to the specified SMD URL

=cut

sub connect {
    my ( $class, $out, @args ) = @_;
    if ( @args == 1 ) {
        print $out "Connecting to $args[0]\n";
        if ( $rpcInstance ) {
            print $out "Closing previous RPC connection\n";
        }
        $rpcInstance = new RPC::JSON({ smd => $args[0] });
        unless ( $rpcInstance ) {
            print $out "Can't connect to $args[0], check specified URI\n";
            return 0;
        }
    } else {
        print $out "Usage: connect <URI>\n";
    }
}

=item disconnect

If connected, will disconnect from the existing service.  This doesn't
necessarily mean that it will disconnect the socket (it will if the socket is
still open), because JSON-RPC does not require a dedicated connection.

=cut

sub disconnect {
    my ( $class, $out, @args ) = @_;
    if ( $rpcInstance and $rpcInstance->service ) {
        print $out "Disconnecting from " . $rpcInstance->serviceURI . "\n";
        $rpcInstance = undef;
    }
}

=item quit

Aliased to disconnected

=cut

=item ls

List available methods

=cut

sub ls {
    my ( $class, $out, @args ) = @_;
    if ( $rpcInstance and $rpcInstance->service ) {
        my $methods = $rpcInstance->methods;
        if ( $methods and ref $methods eq 'HASH' and %$methods ) {
            foreach my $method ( keys %$methods ) {
                my $params = join(" ",
                    map { "$_->{name}:$_->{type}" }
                    @{$methods->{$method}});
                print $out "\t$method: $params\n";
            }
        } else {
            print $out "Service seems empty (No Methods?)\n";
        }
    } else {
        print $out "Connect first (use connect <uri>)\n";
    }
}

=item method Caller

By entering <method> [parameters] the shell will query the Service and display
results

=cut

sub method {
    my ( $self, $out, $method, @args ) = @_;

    if ( $rpcInstance and $rpcInstance->service and $method ) {
        if ( ( my $result = $rpcInstance->$method(@args) ) ) {
            print $out Dumper($result);
        } else {
            print $out "Can't call method $method\n";
        }
    } else {
        print $out "Connect first (use connect <uri>)\n";
    }
}

=head1 AUTHORS

Copyright 2006 J. Shirley <jshirley@gmail.com>

This program is free software;  you can redistribute it and/or modify it under
the same terms as Perl itself.  That means either (a) the GNU General Public
License or (b) the Artistic License.

=cut

1;
