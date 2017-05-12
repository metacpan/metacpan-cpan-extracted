package Net::Analysis::Packet;

use 5.008000;
our $VERSION = '0.03';
use strict;
use warnings;
use Carp qw(carp cluck);
use POSIX qw(strftime);

# {{{ Exported boilerplate

require Exporter;

our @ISA = qw(Exporter);

our @PKT_SLOT_CONSTS = qw(PKT_SLOT_TO
                          PKT_SLOT_FROM
                          PKT_SLOT_FLAGS
                          PKT_SLOT_DATA
                          PKT_SLOT_SEQNUM
                          PKT_SLOT_ACKNUM
                          PKT_SLOT_PKT_NUMBER
                          PKT_SLOT_TV_SEC
                          PKT_SLOT_TV_USEC
                          PKT_SLOT_SOCKETPAIR_KEY
                          PKT_SLOT_CLASS
                          );

our @PKT_FUNCTIONS = qw(pkt_time pkt_init pkt_as_string pkt_class);

our @EXPORT    = ();
our @EXPORT_OK = (@PKT_SLOT_CONSTS, @PKT_FUNCTIONS);
our %EXPORT_TAGS = (all      => [ @EXPORT, @EXPORT_OK ],
                    pktslots => [ @PKT_SLOT_CONSTS ],
                    func     => [ @PKT_FUNCTIONS],
                   );

# }}}

use Net::Analysis::Constants qw(:tcpflags :packetclasses);
use Net::Analysis::Time;

use Data::Dumper;

use constant {
    PKT_SLOT_TO              => 0,
    PKT_SLOT_FROM            => 1,
    PKT_SLOT_FLAGS           => 2,
    PKT_SLOT_DATA            => 3,
    PKT_SLOT_SEQNUM          => 4,
    PKT_SLOT_ACKNUM          => 5,
    PKT_SLOT_PKT_NUMBER      => 6,
    PKT_SLOT_TV_SEC          => 7,
    PKT_SLOT_TV_USEC         => 8,
    PKT_SLOT_TIME            => 9,
    PKT_SLOT_SOCKETPAIR_KEY  => 10,
    PKT_SLOT_CLASS           => 11,
};

#### Public methods
#
# {{{ pkt_time

sub pkt_time {
    my $pkt = shift;
    return $pkt->[PKT_SLOT_TIME];
}

# }}}
# {{{ pkt_init

sub pkt_init {
    my $pkt = shift;
    $pkt->[PKT_SLOT_CLASS] = PKT_NOCLASS;
    $pkt->[PKT_SLOT_SOCKETPAIR_KEY] = join('-', sort
                                           ($pkt->[PKT_SLOT_FROM],
                                            $pkt->[PKT_SLOT_TO]));

    $pkt->[PKT_SLOT_TIME] = Net::Analysis::Time->new
        ($pkt->[PKT_SLOT_TV_SEC], $pkt->[PKT_SLOT_TV_USEC]);

    return $pkt;
}

# }}}
# {{{ pkt_class

sub pkt_class {
    my ($self, $new) = @_;

    $self->[PKT_SLOT_CLASS] = $new if (defined $new);

    return $self->[PKT_SLOT_CLASS];
}

# }}}
# {{{ pkt_as_string

sub pkt_as_string {
    my ($self, $v) = @_;

    #cluck ("I was invoked :(");
    #exit;

    carp "bad pkt !\n" if (!exists $self->[PKT_SLOT_PKT_NUMBER]);

    my $flags = '';
    $flags .= 'F' if ($self->[PKT_SLOT_FLAGS] & FIN);
    $flags .= 'S' if ($self->[PKT_SLOT_FLAGS] & SYN);
    $flags .= 'A' if ($self->[PKT_SLOT_FLAGS] & ACK);
    $flags .= 'R' if ($self->[PKT_SLOT_FLAGS] & RST);
    $flags .= 'P' if ($self->[PKT_SLOT_FLAGS] & PSH);
    $flags .= 'U' if ($self->[PKT_SLOT_FLAGS] & URG);
    $flags .= '.' if ($flags eq '');

    my $p_time = pkt_time($self);

    my $time = ($p_time) ? $p_time->as_string('time') : "--";

    my $str = sprintf ("(% 3d $time %s-%s) ",
                       $self->[PKT_SLOT_PKT_NUMBER],
                       $self->[PKT_SLOT_FROM],
                       $self->[PKT_SLOT_TO]);

    # Show which class we have assigned to the packet
    $str .= {PKT_NOCLASS,     '-',
             PKT_NONDATA,     '_',
             PKT_DATA,        '*',
             PKT_DUP_DATA,    'p',
             PKT_FUTURE_DATA, 'f'}->{$self->[PKT_SLOT_CLASS]} || '?';

    $str .= sprintf ("%-6s ", "$flags");

    $str .= "SEQ:".$self->[PKT_SLOT_SEQNUM]." ACK:".$self->[PKT_SLOT_ACKNUM].
        " ".length($self->[PKT_SLOT_DATA])."b";

    if ($v) { # Get all verbose
        $str .= "\n"._hex_dump ($self->[PKT_SLOT_DATA]);
    }

    return $str;
}

# }}}

#### Private helpers
#
# {{{ _hex_dump

sub _hex_dump {
    my ($binary, $prefix) = @_;

    $prefix ||= '';
    my $hex = $prefix.unpack("H*", $binary);

    $hex =~ s {([0-9a-f]{2}(?! ))}     { $1}mg;

    $hex =~ s {(( [0-9a-f]{2}){16})}
              {"$1   ".safe_raw_line($1)."\n"}emg;

    # Unfinished last line
    $hex =~ s {(( [0-9a-f]{2})*)$}
              {sprintf("%-47.47s    ",$1) .safe_raw_line($1)."\n"}es;

    chomp($hex);
    return $hex."\n";
}

sub safe_raw_line {
    my ($s) = @_;
    $s =~ s {\s+} {}mg;

    my $raw = pack("H*", $s);
    $raw =~ s {([^\x20-\x7e])} {.}g;
    return "{$raw}";
}

# }}}

1;
__END__
# {{{ POD

=head1 NAME

Net::Analysis::Packet - wrapper for our own view of a packet.

=head1 SYNOPSIS

  use Net::Analysis::Packet qw(:pktslots :func);

  my $p = [...]; # See code in Net::Analysis::EventLoop
  pkt_init($p);

  my $packet_data = $p->[PKT_SLOT_DATA];

  print "My packet:-\n".pkt_as_string($p);
  print "Pretty hex dump of payload:-\n".pkt_as_string($p,'verbose');

  my $net_analysis_time = pkt_time($pkt);

=head1 DESCRIPTION

Internal module for abstracting the underlying packet representation.

It is just an array, not an object; there is no OO magic at all. You can use
the following constants to exctract these fields from the array:

 PKT_SLOT_TO         - ip:port (e.g. "192.0.0.200:8080")
 PKT_SLOT_FROM       - ip:port (e.g. "10.0.0.1:13211")
 PKT_SLOT_FLAGS      - byte of TCP flags (see Net::Analysis::Constants)
 PKT_SLOT_DATA       - packet payload (may be empty)
 PKT_SLOT_SEQNUM     - the SEQ number of the packet
 PKT_SLOT_ACKNUM     - the ACK number of the packet
 PKT_SLOT_PKT_NUMBER - packets are numbered from zero as we read them in
 PKT_SLOT_SOCKETPAIR_KEY -  the unique key for the TCP session

=head1 FUNCTIONS

=head2 pkt_init ($p)

Does some setup on the bare data passed in; mostly creating a time object.

=head2 pkt_time ($p)

Returns the Net::Analysis::Time object associated with the packet.

=head1 SEE ALSO

L<Net::Analysis>,
L<Net::Analysis::EventLoop>,
L<Net::Analysis::Time>,
L<Net::Analysis::Constants>.

=head1 AUTHOR

Adam B. Worrall, E<lt>worrall@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Adam B. Worrall

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut

# }}}

# {{{ -------------------------={ E N D }=----------------------------------

# Local variables:
# folded-file: t
# end:

# }}}
