package Net::Analysis;

use 5.008000;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(main);
our $VERSION = '0.41';

use Data::Dumper;

use Net::Analysis::Dispatcher;
use Net::Analysis::EventLoop;

# {{{ usage

sub usage {
    print <<EO;
usage: perl -MNet::Analysis -e main (Protocol)* tcpdump.file

Parses the packet capture file 'filename', and runs one or more protocol
analysers over it. Each analyser module takes some arguments; they all take an
integer 'v' for verbosity. Each protocol module documents any additional
srguments it supports.

There's no need to specify the TCP module; it is loaded by default. Only
specify it if you want to increase the verbosity.

E.g.:

 perl -MNet::Analysis -e main TCP,v=1  dump.tcp    # basic TCP info
 perl -MNet::Analysis -e main HTTP,v=1 dump.tcp    # simple HTTP summary

Only the TCP and HTTP protocols are present in the base distribution; a few
others are available as separate modules.

EXPERIMENTAL: You can also use live network capture, if you provide a tcpdump
compatible capture filter instead of a filename:

 perl -MNet::Analysis -e main TCP,v=1  "port 80"

Live capture requires a space in the final argument; else it will be assumed
to be a file to load.

Live capture has the same permissions issues as running tcpdump; you'll
probably need to run it as root, which you do at your own risk.

EO
    exit 0;
}

# }}}

# {{{ main

sub main {
    my (@monitors) = @ARGV;

    usage() if (grep {/help/} @monitors);

    my ($target) = pop (@monitors);

    # Autoload TCP, else other protos won't get much to analyse
    push (@monitors, "TCP") if (! grep {/^TCP/} @monitors);

    my ($d)     = Net::Analysis::Dispatcher->new();
    my ($el)    = Net::Analysis::EventLoop->new (dispatcher => $d);

    foreach my $mon_str (@monitors) {

        my ($proto, @keyvals) = split (',', $mon_str);
        my %args;

        foreach (@keyvals) {
            my ($k,$v) = split('=',$_,2);
            $v = 1     if (!defined $v);
            $v = undef if ($v eq 'undef');

            $args{$k} = $v;
        }

        my $mod = "Net::Analysis::Listener::$proto";
        eval "use $mod";
        die "Could not load $mod\n$@\n" if ($@);

        my $mon_obj = "$mod"->new(dispatcher => $d, config => \%args)
            || die "$mod->new() failed\n";
    }

    if ($target =~ / /) {
        # Assume a filter string, for live capture
        print "(starting live capture)\n";
        $el->loop_net (filter => $target);
    } else {
        # A file to be loaded
        die "could not read file '$target'\n" if (! -r $target);
        $el->loop_file (filename => $target);
    }
}

# }}}

1;
__END__

# {{{ POD

=head1 NAME

Net::Analysis - Modules for analysing network traffic

=head1 SYNOPSIS

Using an existing analyser on a tcpdump/wireshark capture file:

 $ perl -MNet::Analysis -e main help
 $ perl -MNet::Analysis -e main TCP,v=1            dump.tcp # basic TCP info
 $ perl -MNet::Analysis -e main HTTP,v=1           dump.tcp # HTTP stuff
 $ perl -MNet::Analysis -e main Example2,regex=img dump.tcp # run an example

Or trying live capture:

 # perl -MNet::Analysis -e main TCP,v=1            "port 80"

Writing your own analyser:

  package MyExample;

  use base qw(Net::Analysis::Listener::Base);

  # Listen to events from other modules
  sub tcp_monologue {
      my ($self, $args) = @_;
      my ($mono) = $args->{monologue};

      my $t = $mono->t_elapsed()->as_number();
      my $l = $mono->length();

      # Emit your own event
      $self->emit(name => 'example_event',
                  args => { kb_sec => ($t) ? $l/($t*1024) : 'N/A' }
                 );
  }

  # Process your own event
  sub example_event {
      my ($self, $args) = @_;

      printf "Bandwidth: %10.2f KB/sec\n", $args->{kb_sec};
  }

  1;

=head1 ABSTRACT

Net::Analysis is a suite of modules that parse tcpdump files, reconstruct TCP
sessions from the packets, and provide a very lightweight framework for writing
protocol anaylsers.

=head1 DESCRIPTION

I wanted a batch version of Ethereal in Perl, so I could:

=over 4

=item *

sift through parsed protocols with structured filters

=item *

write custom reports that mixed events from multiple protocols

=back

So here it is. Net::Analysis is a stack of protocol handlers that emit, and
listen for, events.

At the bottom level, a combination of L<Net::Pcap> and L<NetPacket>
emit C<_internal_tcp_packet> events as they are read from the input
file (or live capture from a network device.)

The TCP listener (L<Net::Analysis::Listener::TCP>) picks up these
packets, and reconstructs TCP streams; in turn, it emits
C<tcp_monologue> events. A monologue is a series of bytes sent in one
direction in a TCP stream; a TCP session will usually involve a number
of monologues, back and forth.

For example, a typical TCP session for HTTP will consist of two monologues; the
request (client to server), and then the reponse (server to client). Although
if you have HTTP KeepAlive/pipelining on, then you may see multiple requests in
the same TCP session. A typical SMTP session will involve a rapid sequence of
small monologues as the sender talks SMTP, before sending the bulk of the
(hopefully not bulk) email.

The protocol analysers tend to listen for the C<tcp_monologue> event
and build from there. For example, the HTTP listener
(L<Net::Analysis::Listener::HTTP>) listens for C<tcp_monologue>s,
pairs them up, creates C<HTTP::Request> and C<HTTP::Response> objects
for them, and emits C<http_transaction> events.

If you wanted to sift for transactions to a certain website, this is the event
you'd listen for:

  package NoseyParker;

  use base qw(Net::Analysis::Listener::Base);

  # Listen for HTTP things
  sub http_transaction {
      my ($self, $args) = @_;
      my ($http_req) = $args->{req}; # $args documented in Listener::HTTP.pm

      # Check our HTTP::Request object ...
      if ($http_req->uri() =~ /cpan.org/) {
          print "Perl fan !\n";
      }
  }

Each event can set up whichever arguments it wants to. These are documented in
the module that emits the event. By convention, the event name is prefixed by
the protocol name (e.g. C<tcp_session_start>, C<http_transaction>).

The events emitted by this base distribution are:

=over 4

=item *

C<tcp_session_start> - session established, provides socketpair

=item *

C<tcp_session_end>

=item *

C<_internal_tcp_packet> - might be out of order, or a duplicate

=item *

C<tcp_monologue> - the packets glued together

=item *

C<http_transaction> - a request and its response

=back

=head1 WHERE NEXT

To look at how to invoke the whole thing, to plug into your own script, see the
C<main()> method in L<Net::Analysis>.

To see how to emit (and catch) your own events, look at
L<Net::Analysis::Listener::Example1>.

For a simple example that greps TCP monologue data, see
L<Net::Analysis::Listener::Example2>.

For a simple example that looks at the HTTP objects emitted for each HTTP
transaction, see L<Net::Analysis::Listener::Example3>.

To look at how to write a listener that maintains session state, see
L<Net::Analysis::Listener::HTTP>.

=head1 TODO

Performance - this may not be fast enough to handle busy servers in real time.

More work on live capture, this is still experimental.

UDP support

Other handy protocols - DNS, SMTP, ...

Move event loop and dispatching to POE ?

Move TCP reassembly to Net::LibNIDS ?

=head1 SEE ALSO

L<Net::Analysis::Listener::Example1>,
L<Net::Analysis::Listener::Example2>,
L<Net::Analysis::Listener::Example3>,
L<Net::Analysis::Listener::HTTPClientPerf>,
L<Net::Pcap>, L<NetPacket>.

=head1 AUTHOR

A. B. Worrall, E<lt>worrall@cpan.orgE<gt>

Please report any bugs via http://rt.cpan.org.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by A. B. Worrall

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

# }}}
