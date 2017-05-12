# ABSTRACT: POE Component for reading eris events

package POE::Component::Client::eris;

use warnings;
use strict;
use Carp;
use Parse::Syslog::Line;

use POE qw(
    Component::Client::TCP
    Filter::Stream
);

our $VERSION = '1.4';


sub spawn {
    my $type = shift;

    #
    # Param Setup
    my %args = (
        RemoteAddress   => 'localhost',
        RemotePort      => 9514,
        Alias           => 'eris_client',
        ReturnType      => 'hash',
        Subscribe       => undef,
        Match           => undef,
        MessageHandler  => undef,
        @_
    );

    my $block = $args{ReturnType} eq 'block';
    my $separator = $block ? "\n" : '';

    #
    # Build the client connection
    my $tcp_sessid = POE::Component::Client::TCP->new(
        Alias           => $args{Alias},
        RemoteAddress   => $args{RemoteAddress},
        RemotePort      => $args{RemotePort},
        Filter          => $block ? 'POE::Filter::Stream' : 'POE::Filter::Line',
        Connected       => sub {
            my ($kernel,$heap) = @_[KERNEL,HEAP];
            $heap->{readyState} = 0;
            $heap->{connected} = 0;
            $heap->{buffer} = '';
            $kernel->delay( 'do_setup_pipe' => 1 );
        },
        ConnectError    => sub {
            my ($kernel,$syscall,$errid,$errstr) = @_[KERNEL,ARG0,ARG1,ARG2];
            carp "Connection Error ($errid) at $syscall: $errstr\n";
            $kernel->delay('reconnect' => 10);
        },
        Disconnected    => sub {
            my ($kernel,$heap) = @_[KERNEL,HEAP];
            $kernel->delay('reconnect' => 10);
        },
        ServerError     => sub  {
            my ($kernel,$syscall,$errid,$errstr) = @_[KERNEL,ARG0,ARG1,ARG2];
            carp "Server Error ($errid) at $syscall: $errstr\n";
            $kernel->delay('reconnect' => 5);
        },
        #
        # Handle messages from the server.
        #  Set readyState = 1 if applicable
        #  Call the inline states:
        #   handle_message (successful)
        #   handle_unknown (out of order input)
        ServerInput     => sub {
            my ($kernel,$heap,$instr) = @_[KERNEL,HEAP,ARG0];
            chomp $instr unless $block;
            if( $heap->{readyState} == 1 ) {
                $kernel->yield('handle_message' => $instr);
            }
            elsif( $heap->{connected} == 1 ) {
                if( $instr =~ /^Subscribed to \:/ ) {
                    $heap->{readyState} = 1;
                }
                elsif( $instr =~ /^Receiving / )  {
                    $heap->{readyState} = 1;
                }
                elsif( $instr =~ /^Full feed enabled/ )  {
                    $heap->{readyState} = 1;
                }
                else {
                    $kernel->yield( 'handle_unknown' => $instr );
                }
            }
            elsif( $instr =~ /^EHLO Streamer/ ) {
                $heap->{connected} = 1;
            }
            else {
                $kernel->yield( 'handle_unknown' => $instr );
            }
        },
        #
        # Inline States
        InlineStates => {
            do_setup_pipe   => sub {
                my ($kernel,$heap) = @_[KERNEL,HEAP];

                # Parse for Subscriptions or Matches
                my %data = ();
                foreach my $target (qw(Subscribe Match)) {
                    if( exists $args{$target} && defined $args{$target} ) {
                        my @data = ref $args{$target} eq 'ARRAY' ? @{ $args{$target} } : $args{$target};
                        @data = map { lc } @data if $target eq 'Subscribe';
                        next unless scalar @data > 0;
                        $data{$target} = \@data;
                    }
                }

                # Check to make sure we're doing something
                croak "Must specify a subscription or a match parameter!\n" unless keys %data;

                # Send the Subscription
                foreach my $target (sort { $a cmp $b } keys %data) {
                    my $subname = "do_" . lc $target;
                    $kernel->yield( $subname => $data{$target} );
                }
            },
            do_subscribe    => sub {
                my ($kernel,$heap,$subs) = @_[KERNEL,HEAP,ARG0];

                if( grep /^fullfeed$/, @{ $subs } ) {
                    $heap->{server}->put('fullfeed' . $separator);
                }
                else {
                    $heap->{server}->put('sub ' . join(', ', @{ $subs }) . $separator );
                }
            },
            do_match    => sub {
                my ($kernel,$heap,$matches) = @_[KERNEL,HEAP,ARG0];

                $heap->{server}->put('match ' . join(', ', @{ $matches }) . $separator );
            },
            handle_message  => sub {
                my ($kernel,$heap,$instr) = @_[KERNEL,HEAP,ARG0];

                my $msg = undef;
                if( $args{ReturnType} eq 'string' ) {
                    $msg = $instr;
                }
                elsif( $args{ReturnType} eq 'block' ) {
                    my $index = rindex $instr, "\n";

                    if( $index == -1 ) {
                        $heap->{buffer} .= $instr;
                        return;
                    }
                    else {
                        $msg = $heap->{buffer} . substr $instr, 0, $index + 1;
                        $heap->{buffer} = substr $instr, $index + 1;
                    }
                }
                else {
                    eval {
                        no warnings;
                        $msg = parse_syslog_line($instr);
                    };
                    if($@ || !defined $msg) {
                        return;
                    }
                }

                if( ref $args{MessageHandler} ne 'CODE' ) {
                    croak "You need to specify a subroutine reference to the 'MessageHandler' parameter.\n";
                }
                # Try the Message Handler, eventually we can do statistics here.
                eval {
                    $args{MessageHandler}->( $msg );
                };
            },
            handle_unknown  => sub {
                my ($kernel,$heap,$msg) = @_[KERNEL,HEAP,ARG0];

                carp "UNKNOWN INPUT: $msg\n";
            },
        },
    );

    #
    # Return the TCP Session ID
    return $tcp_sessid;
}


1; # End of POE::Component::Client::eris

__END__

=pod

=head1 NAME

POE::Component::Client::eris - POE Component for reading eris events

=head1 VERSION

version 1.4

=head1 SYNOPSIS

POE session for integration with the eris event correlation engine.

    use POE::Component::Client::eris;

    my $eris_sess_id = POE::Component::Client::eris->spawn(
            RemoteAddress       => 'localhost',     #default
            RemotePort          => '9514',          #default
            Alias               => 'eris_client',   #default
            Subscribe           => [qw(snort dhcpd)],               # REQUIRED (and/or Match)
            Match               => [qw(devbox1 myusername error)],  # REQUIRED (and/or Subscribe)
            MessageHandler      => sub { ... },      # REQUIRED
    );
    ...
    POE::Kernel->run();

For use with a server running the POE::Component::Server::eris output.

=head1 EXPORT

POE::Component::Client::eris does not export any symbols.

=head1 FUNCTIONS

=head2 spawn

Creates the POE::Session for the eris correlator.

Parameters:
    RemoteAddress       => 'localhost',     #default
    RemotePort          => '9514',          #default
    Alias               => 'eris_client',   #default
    Subscribe           => [qw(snort dhcpd)],               # REQUIRED (and/or Match)
    Match               => [qw(devbox1 myusername error)],  # REQUIRED (and/or Subscribe)
    MessageHandler      => sub { ... },      # REQUIRED
    ReturnType          => 'hash',           # default, or 'string'

=head1 BUGS

Please report any bugs or feature requests to
C<bug-poe-component-client-eris at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=POE-Component-Client-eris>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc POE::Component::Client::eris

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/POE-Component-Client-eris>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/POE-Component-Client-eris>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=POE-Component-Client-eris>

=item * Search CPAN

L<http://search.cpan.org/dist/POE-Component-Client-eris>

=item * See also

L<http://search.cpan.org/dist/POE-Component-Server-eris>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Brad Lhotsky, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
