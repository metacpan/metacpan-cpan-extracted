package Net::Analysis::Constants;
# $Id: Constants.pm 131 2005-10-02 17:24:31Z abworrall $

# {{{ Boilerplate

use 5.008000;
our $VERSION = '0.01';
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our @TCPFLAG_CONSTS = (qw(FIN SYN RST PSH ACK URG));

our @SESHSTATE_CONSTS = (qw(SESH_UNDEFINED
                            SESH_CONNECTING
                            SESH_ESTABLISHED
                            SESH_HALF_CLOSED
                            SESH_CLOSED
                           ));

our @PKTCLASS_CONSTS  = qw(PKT_NOCLASS
                           PKT_NONDATA
                           PKT_DATA
                           PKT_DUP_DATA
                           PKT_FUTURE_DATA
                           );

our @EXPORT      = qw();
our @EXPORT_OK   = (@TCPFLAG_CONSTS, @SESHSTATE_CONSTS, @PKTCLASS_CONSTS);
our %EXPORT_TAGS = (all           => [ @EXPORT, @EXPORT_OK ],
                    tcpseshstates => [ @SESHSTATE_CONSTS ],
                    tcpflags      => [ @TCPFLAG_CONSTS ],
                    packetclasses => [ @PKTCLASS_CONSTS ],);

# }}}

# TCP Session states
use constant {
    SESH_UNDEFINED   => 'SESH_UNDEFINED',

    # The main states; sending SYNs, data or FINs. Or all done.
    SESH_CONNECTING  => 'SESH_CONNECTING',
    SESH_ESTABLISHED => 'SESH_ESTABLISHED',
    SESH_HALF_CLOSED => 'SESH_HALF_CLOSED',
    SESH_CLOSED      => 'SESH_CLOSED'
};

# TCP packet flags
use constant {
    FIN => 0x01,
    SYN => 0x02,
    RST => 0x04,
    PSH => 0x08,
    ACK => 0x10,
    URG => 0x20,
};


# How we classify the packet (for reporting
use constant {
    PKT_NOCLASS             => 0, # Should be an error
    PKT_NONDATA             => 1, # Was a bare ACK, or part of setup/teardown
    PKT_DATA                => 2, # Was a juicy data packet
    PKT_DUP_DATA            => 3, # Was a resend of data we already have
    PKT_FUTURE_DATA         => 4, # Was something we weren't expecting
};


1;
__END__
# {{{ POD

=head1 NAME

Net::Analysis::Constants - some families of constants

=head1 SYNOPSIS

  use Net::Analysis::Constants qw(tcpseshstates tcpflags packetclasses);

  if ($var == PKT_DUP_DATA) {...}

=head1 DESCRIPTION

Some useful constants.

=head2 EXPORT

None by default.

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
