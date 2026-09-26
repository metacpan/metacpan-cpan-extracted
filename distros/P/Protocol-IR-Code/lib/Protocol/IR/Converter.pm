package Protocol::IR::Converter;
use strict;
use warnings;

our $VERSION = '1.2';

use Protocol::IR::Code;
use Protocol::IR::Proto::NEC;
use Protocol::IR::Proto::NEC2;
use Protocol::IR::Proto::NEC48;
use Protocol::IR::Proto::NEC482;
use Protocol::IR::Proto::JVC;
use Protocol::IR::Proto::JVC48;
use Protocol::IR::Proto::SAMSUNG;
use Protocol::IR::Proto::SAMSUNG20;
use Protocol::IR::Proto::SAMSUNG36;
use Protocol::IR::Proto::NECX1;
use Protocol::IR::Proto::NECX2;
use Protocol::IR::Proto::MWM;
use Protocol::IR::Format::Pronto;
use Protocol::IR::Format::CSV;
use Protocol::IR::Format::Wig;
use Protocol::IR::Format::JSON;
use Protocol::IR::Format::Tasmota;
use Protocol::IR::Format::Mode2;
use Protocol::IR::Format::LIRC;

sub new {
    my ($class) = @_;
    my $self = bless {
        protocols      => {},
        protocol_order => [],
        formats        => {},
    }, $class;

    # Protocols, registered in the order Pronto/Tasmota/wig decoding tries
    # them. Handlers whose timing signatures overlap must be ordered so the
    # most likely interpretation wins, because the timing decoders cannot
    # tell them apart:
    #
    #   NEC before NEC2 - a single NEC2 frame is timing-identical to a NEC1
    #   frame (the "2" variants only differ in repeat structure), so NEC,
    #   the far more common framing, absorbs NEC2 frames on a timing decode.
    #   NEC2 stays registered so codes imported by name (IRDB CSV) keep the
    #   NEC2 identity.
    #
    #   48-NEC1/48-NEC2 after NEC - the 48-bit frames share NEC's 9000/4500
    #   us header, but fail the 32-bit stop check (pair 33 is a data bit, so
    #   its space never reaches the 3000 µs threshold), so they only reach
    #   the 48-bit decoders. 48-NEC1 before 48-NEC2: single frames are
    #   timing-identical, so the base variant absorbs the timing decode.
    #
    #   JVC before JVC-48 - JVC-48's 3456/1728 µs header is rejected by the
    #   32-bit JVC header check (7000-9800 µs), so it only reaches the
    #   48-bit decoder.
    #
    #   SAMSUNG before NECX1/NECX2 - NECx frames use Samsung's 4500/4500 µs
    #   half header, so the two families share a header and bit timing. A
    #   single-frame NECx1/NECx2 capture is therefore only distinguished from
    #   SAMSUNG by the Samsung byte structure (address repeated, command
    #   followed by its complement) that SAMSUNG's strict decoder enforces
    #   and NECx frames lack (they carry a subaddress byte). The NECx decoder
    #   that follows is then the one that matches, so NECx frames keep their
    #   NECx1/NECX2 identity on a timing decode. (IRremoteESP8266 has no NECx
    #   decoder and reports the same capture as UNKNOWN; ours names the
    #   protocol it recognizes.)
    #
    #   SAMSUNG before SAMSUNG36 - SAMSUNG's stop check (a >= 3000 µs space)
    #   rejects a 36-bit frame's mid-frame pairs, so SAMSUNG36 is only
    #   reached when its 39-pair framing matches.
    #
    #   SAMSUNG20 last - its 22-pair frames cannot match the 34-pair
    #   minimums of SAMSUNG/NEC or the 39-pair minimum of SAMSUNG36.
    #
    #   MWM last - MWM frames have no header at all (a 417 µs start mark),
    #   so every other decoder's header check rejects them first, and MWM's
    #   strict tick matching rejects any header-bearing frame in turn.
    $self->register_protocol('NEC',       'Protocol::IR::Proto::NEC');
    $self->register_protocol('NEC2',      'Protocol::IR::Proto::NEC2');
    $self->register_protocol('48-NEC1',   'Protocol::IR::Proto::NEC48');
    $self->register_protocol('48-NEC2',   'Protocol::IR::Proto::NEC482');
    $self->register_protocol('JVC',       'Protocol::IR::Proto::JVC');
    $self->register_protocol('JVC-48',    'Protocol::IR::Proto::JVC48');
    $self->register_protocol('PANASONIC', 'Protocol::IR::Proto::Panasonic');
    $self->register_protocol('SAMSUNG',   'Protocol::IR::Proto::SAMSUNG');
    $self->register_protocol('SAMSUNG36', 'Protocol::IR::Proto::SAMSUNG36');
    $self->register_protocol('SAMSUNG20', 'Protocol::IR::Proto::SAMSUNG20');
    $self->register_protocol('NECX1',     'Protocol::IR::Proto::NECX1');
    $self->register_protocol('NECX2',     'Protocol::IR::Proto::NECX2');
    $self->register_protocol('MWM',       'Protocol::IR::Proto::MWM');

    # Formats
    $self->register_format('Pronto', 'Protocol::IR::Format::Pronto');
    $self->register_format('CSV',    'Protocol::IR::Format::CSV');
    $self->register_format('wig',    'Protocol::IR::Format::Wig');
    $self->register_format('JSON',   'Protocol::IR::Format::JSON');
    $self->register_format('Tasmota','Protocol::IR::Format::Tasmota');
    $self->register_format('Mode2',  'Protocol::IR::Format::Mode2');
    $self->register_format('LIRC',   'Protocol::IR::Format::LIRC');

    return $self;
}

sub register_protocol {
    my ($self, $name, $class) = @_;
    my $key = uc $name;
    $self->{protocols}{$key} = $class;
    push @{$self->{protocol_order}}, $key
        unless grep { $_ eq $key } @{$self->{protocol_order}};
}

sub register_format {
    my ($self, $name, $class) = @_;
    $self->{formats}{uc $name} = $class;
}

sub get_protocol {
    my ($self, $name) = @_;
    return $self->{protocols}{uc $name};
}

# Registered protocols in deterministic registration order.
# Pronto decoding tries protocols in this order, so handlers whose timing
# signatures overlap must be registered most-specific-first.
sub get_protocols {
    my ($self) = @_;
    return map { $self->{protocols}{$_} } @{$self->{protocol_order}};
}

# Cross-protocol mappings: protocols with identical timing and compatible
# frame layouts but different field naming conventions.
#
# NECX2 <-> SAMSUNG: same 4500/4500 µs header, 560/1680 µs bit timing,
# 32 bits, per-byte LSB-first.  Samsung enforces addr,addr,cmd,~cmd
# while NECX2 allows addr,subaddr,cmd,~cmd.  The Samsung address is the
# bit-reversal of the NECX2 device byte, and likewise for the command.
my %CROSS_PROTOCOL = (
    SAMSUNG => 'NECX2',
    NECX2   => 'SAMSUNG',
);

sub cross_protocol {
    my ($self, $code) = @_;
    my $proto = uc($code->protocol);
    my $target = $CROSS_PROTOCOL{$proto};
    return [] unless $target;

    my $target_class = $self->get_protocol($target);
    return [] unless $target_class;

    # Build the equivalent code in the target protocol.
    # The source protocol handler provides an as_<target>_params method.
    my $source_class = $self->get_protocol($proto);
    my $method = "as_\L${target}_params";
    my $params = $source_class->can($method)
        ? $source_class->$method($code)
        : undef;
    return [] unless $params;

    my $equiv = $target_class->decode_params(%$params);
    return [$equiv];
}

sub import_code {
    my ($self, $protocol_name, $input) = @_;
    my $proto_class = $self->get_protocol($protocol_name);
    die "Unsupported protocol: $protocol_name\n" unless $proto_class;

    if (ref $input eq 'HASH') {
        return $proto_class->decode_params(%$input);
    } else {
        return $proto_class->decode_raw($input);
    }
}

# Import a transmitted frame value in a named byte order, mirroring the JS
# importLsb/importMsb and the LIRC/Tasmota routing.  When $lsb is true the
# value is the accumulated form (Tasmota DataLSB); when false it is the
# display form (Tasmota Data).  Protocols with a byte-order distinction
# translate so the decoded address/subaddress/command always matches the
# transmitted bytes; protocols without one decode the value as-is.
sub _import_byte_order {
    my ($self, $protocol_name, $input, $lsb) = @_;
    my $proto_class = $self->get_protocol($protocol_name);
    die "Unsupported protocol: $protocol_name\n" unless $proto_class;

    if ($proto_class->can('decode_byte_order')) {
        return $proto_class->decode_byte_order($input, $lsb);
    }
    return $proto_class->decode_raw($input);
}

# Import from the accumulated value (Tasmota DataLSB).
sub import_lsb {
    my ($self, $protocol_name, $input) = @_;
    return $self->_import_byte_order($protocol_name, $input, 1);
}

# Import from the display value (Tasmota Data).
sub import_msb {
    my ($self, $protocol_name, $input) = @_;
    return $self->_import_byte_order($protocol_name, $input, 0);
}

sub export_code {
    my ($self, $ir_code, $format_name, %opts) = @_;
    my $format_class = $self->{formats}{uc $format_name};
    die "Unsupported format: $format_name\n" unless $format_class;

    return $format_class->export($ir_code, $self, %opts);
}

# Export a set of Protocol::IR::Code objects to a container format (e.g. wig).
sub export_codes {
    my ($self, $format_name, $codes, %opts) = @_;
    my $format_class = $self->{formats}{uc $format_name};
    die "Unsupported format: $format_name\n" unless $format_class;

    return $format_class->export($codes, $self, %opts);
}

sub import_format {
    my ($self, $format_name, $input) = @_;
    my $format_class = $self->{formats}{uc $format_name};
    die "Unsupported format: $format_name\n" unless $format_class;

    return $format_class->decode($input, $self);
}

1;

=encoding utf8

=head1 NAME

Protocol::IR::Converter - Registry and manager for IR code protocols and formats

=head1 VERSION

version 1.2

=head1 SYNOPSIS

    use Protocol::IR::Converter;
    use Data::Dumper;

    my $converter = Protocol::IR::Converter->new();

    # Import a raw 32-bit NEC hex value
    my $code = $converter->import_code('NEC', '0x10EF00FF');

    # Tasmota IRSend JSON payload
    print Dumper($code->to_irsend);
    # { Protocol => 'NEC', Bits => 32, Data => '0x10EF00FF' }

    # Export to Pronto Hex
    my $pronto = $converter->export_code($code, 'Pronto');

    # Decode Pronto Hex back into an Protocol::IR::Code
    my $decoded = $converter->import_format('Pronto',
        '0000 006D 0022 0000 0157 00AC ...');

    # Import an IRDB-style CSV file
    my $codes = $converter->import_format('CSV',
        "functionname,protocol,device,subdevice,function\nKEY_POWER,NEC1,4,0,8");

    # Export a set of Protocol::IR::Code objects to a HAIR wig file
    my $wig = $converter->export_codes('wig', $codes,
        name  => 'Tigersecu DVR',
        brand => 'Tigersecu',
        kind  => 'dvr',
    );

    # Import and re-export Tasmota RawData captures
    my $capture = $converter->import_format('Tasmota',
        "+9185-4490+650-500+655dE-1630C-505+630-525Ed...")->[0];
    my $irsend = $converter->export_code($capture, 'Tasmota',
        style => 'comma', frequency => 38000);

=head1 DESCRIPTION

C<Protocol::IR::Converter> is the heart of the Protocol::IR::Code distribution: a registry that
knows which protocol and format modules are available and routes every
import and export through them. All codes are normalized into
L<Protocol::IR::Code> objects, so a signal decoded from one format can be encoded into
any other.

The following protocols and formats are registered by default:

=over 4

=item * Protocols: C<NEC> (32-bit), C<NEC2> (32-bit, whole-frame repeat),
C<48-NEC1>/C<48-NEC2> (48-bit), C<JVC> (16-bit), C<JVC-48> (48-bit Kaseikyo),
C<SAMSUNG> (32-bit), C<SAMSUNG20> (20-bit), C<SAMSUNG36> (36-bit),
C<NECX1>/C<NECX2> (extended NEC, half header), C<MWM> (Disney "Made With
Magic", 24-144 bit serial)

=item * Formats: C<Pronto>, C<Tasmota>, C<wig>, C<CSV>, C<Mode2>,
C<LIRC>, C<JSON> (import only)

=back

C<Pronto>, C<Tasmota>, C<Mode2>, and C<LIRC> are timing-based formats;
L<Protocol::IR::Format::Pronto>, L<Protocol::IR::Format::Tasmota>,
L<Protocol::IR::Format::Mode2>, and L<Protocol::IR::Format::LIRC> document
their exact behavior.
L<Protocol::IR::Format::Wig> implements the HAIR "wig"
JSON format. L<Protocol::IR::Format::CSV> imports IRDB-style button listings.
L<Protocol::IR::Format::JSON> imports a proprietary JSON IR database dump.

=head1 Decoding versus generating timings

For the timing-based formats (Tasmota C<RawData>, Pronto Hex, and wig), the
goal of this library is to I<generate> correct timings from fully decoded
C<Protocol::IR::Code> objects. That direction is authoritative: given a correctly
decoded code, the emitted timings are exact.

The reverse direction -- decoding raw timings back into commands -- is
best-effort. The protocol decoders match against simple header and
mark/space thresholds and are not designed to handle the signal variance,
jitter, and corruption that a real decoding library (such as
C<IRremoteESP8266>) accounts for. A capture may therefore fail to be
recognized, or in rare ambiguous cases be misidentified. Conversions
between fully decoded representations (raw hex, parameter hashes, IRDB CSV,
wig) are exact and reliable.

Conversions between the timing formats themselves (Tasmota C<RawData>,
Pronto Hex, and wig) are exact and lossless: a signal decoded from any timed
input keeps its quantized C<timings> and, for Pronto Hex, the original hex
verbatim (see L<Protocol::IR::Code>), so a re-export reproduces the same
capture byte-for-byte rather than re-quantizing through a protocol encoder.
For recognized protocols, wig files produced by HAIR are assumed to carry
timings that have already been quantized and cleaned up, so they should
decode correctly -- but, as with any raw timing input, this is not
guaranteed.

=head1 INSTALLATION

    perl Makefile.PL
    make
    make test
    make install

Or with a cpan client:

    cpanm Protocol::IR::Code

The modules have no runtime dependencies beyond core Perl. C<JSON::PP>
(core since Perl 5.14) is declared as a prerequisite for older versions.

Two command-line tools are installed with the distribution:

=over 4

=item * C<ir-irdb2wig> -- convert an IRDB CSV file (local, fetched from a
URL, or downloaded from the IRDB repository by device path) to a HAIR wig
JSON file.

=item * C<ir-convert> -- general converter between the supported formats
(CSV, wig, Pronto, Tasmota, LIRC, JSON).

=back

Both read the Protocol::IR::Code modules from your normal Perl installation, so they
work from any directory once the distribution is installed.

=head1 METHODS

=head2 new

    my $converter = Protocol::IR::Converter->new;

Creates a converter, registering the bundled protocols (NEC, NEC2, 48-NEC1,
48-NEC2, JVC, JVC-48, SAMSUNG, SAMSUNG20, SAMSUNG36, NECX1, NECX2, MWM) and
formats (Pronto, CSV, wig, Tasmota, Mode2, LIRC, JSON).

=head2 import_code

    my $code = $converter->import_code('NEC', '0x10EF00FF');
    my $code = $converter->import_code('JVC', { address => 3, command => 12 });

Builds an L<Protocol::IR::Code> for the named protocol from either a raw value
(string or number) or a hash of parameters. Dies on an unregistered
protocol.

=head2 export_code

    my $pronto = $converter->export_code($code, 'Pronto');
    my $irsend = $converter->export_code($code, 'Tasmota',
        style => 'comma', frequency => 38000);

Serializes a single L<Protocol::IR::Code> object into the named format, passing any
extra options through to the format's C<export> method.

=head2 export_codes

    my $wig = $converter->export_codes('wig', \@codes, name => 'Remote');

Serializes one or more L<Protocol::IR::Code> objects into a container format such as
wig. A single object is wrapped in an arrayref automatically.

=head2 import_format

    my $codes = $converter->import_format('wig', 'remote.wig.json');
    my $code  = $converter->import_format('Pronto', $pronto_str);

Parses external input in the named format (file path, raw string, JSON,
etc.) into a list of L<Protocol::IR::Code> objects. Returns an arrayref. Dies on an
unregistered format.

=head2 register_protocol

    $converter->register_protocol('RC5', 'Protocol::IR::RC5');

Registers a protocol handler class under a name. See L</"EXTENDING THE
FRAMEWORK">.

=head2 register_format

    $converter->register_format('JSON', 'Protocol::IR::Format::JSON');

Registers a format handler class under a name. See L</"EXTENDING THE
FRAMEWORK">.

=head2 get_protocol

    my $class = $converter->get_protocol('NEC');

Returns the handler class registered for a protocol name, or C<undef>.

=head2 get_protocols

    my @classes = $converter->get_protocols;

Returns the registered protocol handler classes in deterministic
registration order. Pronto and Tasmota decoding try protocols in this
order, so handlers whose timing signatures overlap must be registered
most-specific-first.

=head2 cross_protocol

    my $equivs = $converter->cross_protocol($code);

Converts a code to its equivalent in a cross-protocol partner.  Currently
supports:

=over 4

=item SAMSUNG <-> NECX2

Both protocols share identical 4500/4500 µs half-header timing and 32-bit
LSB-first encoding, but name the fields differently.  The Samsung address
is the bit-reversal of the NECX2 device byte, and likewise for the
command/function byte.  See L<Protocol::IR::Proto::SAMSUNG/CROSS-PROTOCOL MAPPING>
for details.

=back

Returns an arrayref of L<Protocol::IR::Code> objects (zero or one entries)
in the equivalent protocol.  Returns C<[]> when the protocol has no
cross-protocol partner.

Example:

    # A Samsung TV POWER capture (address=0xE0, command=0x40)
    # converts to NECX2 (device=7, subdevice=7, function=2)
    my $necx2_equivs = $converter->cross_protocol($samsung_code);
    my $necx2_code   = $necx2_equivs->[0];

    # A NECX2 code from an IRDB CSV converts to SAMSUNG for capture matching
    my $sam_equivs = $converter->cross_protocol($necx2_code);

=head1 EXTENDING THE FRAMEWORK

=head2 Adding a new protocol (Protocol::IR::NAME)

Create a package under C<lib/Protocol/IR/> implementing these methods:

=over 4

=item * C<decode_raw($class, $raw_int)> -- takes a raw packed integer/hex
value and returns an L<Protocol::IR::Code> object.

=item * C<decode_params($class, %args)> -- accepts discrete parameters
(C<device>, C<subdevice>, C<command>) and returns an L<Protocol::IR::Code> object.

=item * C<decode_timing($class, \@burst_pairs_us)> -- accepts an arrayref
of microsecond C<[mark_us, space_us]> pairs, matches the protocol's timing
signature (headers, mark/space thresholds), and returns an L<Protocol::IR::Code>
object if valid, or C<undef> if non-matching.

=item * C<to_pronto($class, $ir_code)> -- converts an L<Protocol::IR::Code> object
into a Pronto Hex string.

=back

Register it in C<Protocol::IR::Converter::new()>:

    $self->register_protocol('RC5', 'Protocol::IR::RC5');

=head2 Adding a new format (Protocol::IR::Format::NAME)

Create a package under C<lib/Protocol/IR/Format/> implementing these methods:

=over 4

=item * C<export($class, $ir_code, $registry)> -- serializes one or more
L<Protocol::IR::Code> objects into the target format.

=item * C<decode($class, $input_data, $registry)> -- parses external input
(file path, raw string, JSON, etc.) into one or more L<Protocol::IR::Code> objects,
using C<< $registry->import_code(...) >> to build them.

=back

Register it in C<Protocol::IR::Converter::new()>:

    $self->register_format('JSON', 'Protocol::IR::Format::JSON');

=head1 SUPPORT

Source code: L<https://github.com/bwarden/perl-protocol-ir>

Bug reports and feature requests: L<https://github.com/bwarden/perl-protocol-ir/issues>

=head1 AUTHOR

Brett T. Warden <bwarden@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Brett T. Warden

This library is free software; you can redistribute it and/or modify it
under the terms of the GNU Lesser General Public License version 2.1 as
published by the Free Software Foundation.
