package Google::Protobuf::Wrappers;

use strict;
use warnings;

our $VERSION = '0.05';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
Ch5nb29nbGUvcHJvdG9idWYvd3JhcHBlcnMucHJvdG8SD2dvb2dsZS5wcm90b2J1ZiIjCgtE
b3VibGVWYWx1ZRIUCgV2YWx1ZRgBIAEoAVIFdmFsdWUiIgoKRmxvYXRWYWx1ZRIUCgV2YWx1
ZRgBIAEoAlIFdmFsdWUiIgoKSW50NjRWYWx1ZRIUCgV2YWx1ZRgBIAEoA1IFdmFsdWUiIwoL
VUludDY0VmFsdWUSFAoFdmFsdWUYASABKARSBXZhbHVlIiIKCkludDMyVmFsdWUSFAoFdmFs
dWUYASABKAVSBXZhbHVlIiMKC1VJbnQzMlZhbHVlEhQKBXZhbHVlGAEgASgNUgV2YWx1ZSIh
CglCb29sVmFsdWUSFAoFdmFsdWUYASABKAhSBXZhbHVlIiMKC1N0cmluZ1ZhbHVlEhQKBXZh
bHVlGAEgASgJUgV2YWx1ZSImCgpCeXRlc1ZhbHVlEhgKBXZhbHVlGAEgASgMQgIIAVIFdmFs
dWVCgwEKE2NvbS5nb29nbGUucHJvdG9idWZCDVdyYXBwZXJzUHJvdG9QAVoxZ29vZ2xlLmdv
bGFuZy5vcmcvcHJvdG9idWYvdHlwZXMva25vd24vd3JhcHBlcnNwYvgBAaICA0dQQqoCHkdv
b2dsZS5Qcm90b2J1Zi5XZWxsS25vd25UeXBlc0qoKgoHEgUxAJ8BAQrOEwoBDBIDMQASMsEM
IFByb3RvY29sIEJ1ZmZlcnMgLSBHb29nbGUncyBkYXRhIGludGVyY2hhbmdlIGZvcm1hdAog
Q29weXJpZ2h0IDIwMDggR29vZ2xlIEluYy4gIEFsbCByaWdodHMgcmVzZXJ2ZWQuCiBodHRw
czovL2RldmVsb3BlcnMuZ29vZ2xlLmNvbS9wcm90b2NvbC1idWZmZXJzLwoKIFJlZGlzdHJp
YnV0aW9uIGFuZCB1c2UgaW4gc291cmNlIGFuZCBiaW5hcnkgZm9ybXMsIHdpdGggb3Igd2l0
aG91dAogbW9kaWZpY2F0aW9uLCBhcmUgcGVybWl0dGVkIHByb3ZpZGVkIHRoYXQgdGhlIGZv
bGxvd2luZyBjb25kaXRpb25zIGFyZQogbWV0OgoKICAgICAqIFJlZGlzdHJpYnV0aW9ucyBv
ZiBzb3VyY2UgY29kZSBtdXN0IHJldGFpbiB0aGUgYWJvdmUgY29weXJpZ2h0CiBub3RpY2Us
IHRoaXMgbGlzdCBvZiBjb25kaXRpb25zIGFuZCB0aGUgZm9sbG93aW5nIGRpc2NsYWltZXIu
CiAgICAgKiBSZWRpc3RyaWJ1dGlvbnMgaW4gYmluYXJ5IGZvcm0gbXVzdCByZXByb2R1Y2Ug
dGhlIGFib3ZlCiBjb3B5cmlnaHQgbm90aWNlLCB0aGlzIGxpc3Qgb2YgY29uZGl0aW9ucyBh
bmQgdGhlIGZvbGxvd2luZyBkaXNjbGFpbWVyCiBpbiB0aGUgZG9jdW1lbnRhdGlvbiBhbmQv
b3Igb3RoZXIgbWF0ZXJpYWxzIHByb3ZpZGVkIHdpdGggdGhlCiBkaXN0cmlidXRpb24uCiAg
ICAgKiBOZWl0aGVyIHRoZSBuYW1lIG9mIEdvb2dsZSBJbmMuIG5vciB0aGUgbmFtZXMgb2Yg
aXRzCiBjb250cmlidXRvcnMgbWF5IGJlIHVzZWQgdG8gZW5kb3JzZSBvciBwcm9tb3RlIHBy
b2R1Y3RzIGRlcml2ZWQgZnJvbQogdGhpcyBzb2Z0d2FyZSB3aXRob3V0IHNwZWNpZmljIHBy
aW9yIHdyaXR0ZW4gcGVybWlzc2lvbi4KCiBUSElTIFNPRlRXQVJFIElTIFBST1ZJREVEIEJZ
IFRIRSBDT1BZUklHSFQgSE9MREVSUyBBTkQgQ09OVFJJQlVUT1JTCiAiQVMgSVMiIEFORCBB
TlkgRVhQUkVTUyBPUiBJTVBMSUVEIFdBUlJBTlRJRVMsIElOQ0xVRElORywgQlVUIE5PVAog
TElNSVRFRCBUTywgVEhFIElNUExJRUQgV0FSUkFOVElFUyBPRiBNRVJDSEFOVEFCSUxJVFkg
QU5EIEZJVE5FU1MgRk9SCiBBIFBBUlRJQ1VMQVIgUFVSUE9TRSBBUkUgRElTQ0xBSU1FRC4g
SU4gTk8gRVZFTlQgU0hBTEwgVEhFIENPUFlSSUdIVAogT1dORVIgT1IgQ09OVFJJQlVUT1JT
IEJFIExJQUJMRSBGT1IgQU5ZIERJUkVDVCwgSU5ESVJFQ1QsIElOQ0lERU5UQUwsCiBTUEVD
SUFMLCBFWEVNUExBUlksIE9SIENPTlNFUVVFTlRJQUwgREFNQUdFUyAoSU5DTFVESU5HLCBC
VVQgTk9UCiBMSU1JVEVEIFRPLCBQUk9DVVJFTUVOVCBPRiBTVUJTVElUVVRFIEdPT0RTIE9S
IFNFUlZJQ0VTOyBMT1NTIE9GIFVTRSwKIERBVEEsIE9SIFBST0ZJVFM7IE9SIEJVU0lORVNT
IElOVEVSUlVQVElPTikgSE9XRVZFUiBDQVVTRUQgQU5EIE9OIEFOWQogVEhFT1JZIE9GIExJ
QUJJTElUWSwgV0hFVEhFUiBJTiBDT05UUkFDVCwgU1RSSUNUIExJQUJJTElUWSwgT1IgVE9S
VAogKElOQ0xVRElORyBORUdMSUdFTkNFIE9SIE9USEVSV0lTRSkgQVJJU0lORyBJTiBBTlkg
V0FZIE9VVCBPRiBUSEUgVVNFCiBPRiBUSElTIFNPRlRXQVJFLCBFVkVOIElGIEFEVklTRUQg
T0YgVEhFIFBPU1NJQklMSVRZIE9GIFNVQ0ggREFNQUdFLgoy/wYgKD09IHBhZ2UgcHJvdG9f
dHlwZXMgPT0pCgogV3JhcHBlcnMgZm9yIHByaW1pdGl2ZSAobm9uLW1lc3NhZ2UpIHR5cGVz
LiBUaGVzZSB0eXBlcyB3ZXJlIG5lZWRlZAogZm9yIGxlZ2FjeSByZWFzb25zIGFuZCBhcmUg
bm90IHJlY29tbWVuZGVkIGZvciB1c2UgaW4gbmV3IEFQSXMuCgogSGlzdG9yaWNhbGx5IHRo
ZXNlIHdyYXBwZXJzIHdlcmUgdXNlZnVsIHRvIGhhdmUgcHJlc2VuY2Ugb24gcHJvdG8zIHBy
aW1pdGl2ZQogZmllbGRzLCBidXQgcHJvdG8zIHN5bnRheCBoYXMgYmVlbiB1cGRhdGVkIHRv
IHN1cHBvcnQgdGhlIGBvcHRpb25hbGAga2V5d29yZC4KIFVzaW5nIHRoYXQga2V5d29yZCBp
cyBub3cgdGhlIHN0cm9uZ2x5IHByZWZlcnJlZCB3YXkgdG8gYWRkIHByZXNlbmNlIHRvCiBw
cm90bzMgcHJpbWl0aXZlIGZpZWxkcy4KCiBBIHNlY29uZGFyeSB1c2VjYXNlIHdhcyB0byBl
bWJlZCBwcmltaXRpdmVzIGluIHRoZSBgZ29vZ2xlLnByb3RvYnVmLkFueWAKIHR5cGU6IGl0
IGlzIG5vdyByZWNvbW1lbmRlZCB0aGF0IHlvdSBlbWJlZCB5b3VyIHZhbHVlIGluIHlvdXIg
b3duIHdyYXBwZXIKIG1lc3NhZ2Ugd2hpY2ggY2FuIGJlIHNwZWNpZmljYWxseSBkb2N1bWVu
dGVkLgoKIFRoZXNlIHdyYXBwZXJzIGhhdmUgbm8gbWVhbmluZ2Z1bCB1c2Ugd2l0aGluIHJl
cGVhdGVkIGZpZWxkcyBhcyB0aGV5IGxhY2sKIHRoZSBhYmlsaXR5IHRvIGRldGVjdCBwcmVz
ZW5jZSBvbiBpbmRpdmlkdWFsIGVsZW1lbnRzLgogVGhlc2Ugd3JhcHBlcnMgaGF2ZSBubyBt
ZWFuaW5nZnVsIHVzZSB3aXRoaW4gYSBtYXAgb3IgYSBvbmVvZiBzaW5jZQogaW5kaXZpZHVh
bCBlbnRyaWVzIG9mIGEgbWFwIG9yIGZpZWxkcyBvZiBhIG9uZW9mIGNhbiBhbHJlYWR5IGRl
dGVjdCBwcmVzZW5jZS4KCggKAQISAzMAGAoICgEIEgM1AB8KCQoCCB8SAzUAHwoICgEIEgM2
AEgKCQoCCAsSAzYASAoICgEIEgM3ACwKCQoCCAESAzcALAoICgEIEgM4AC4KCQoCCAgSAzgA
LgoICgEIEgM5ACIKCQoCCAoSAzkAIgoICgEIEgM7ACEKCQoCCCQSAzsAIQoICgEIEgM8ADsK
CQoCCCUSAzwAOwrQAQoCBAASBEQARwEawwEgV3JhcHBlciBtZXNzYWdlIGZvciBgZG91Ymxl
YC4KCiBUaGUgSlNPTiByZXByZXNlbnRhdGlvbiBmb3IgYERvdWJsZVZhbHVlYCBpcyBKU09O
IG51bWJlci4KCiBOb3QgcmVjb21tZW5kZWQgZm9yIHVzZSBpbiBuZXcgQVBJcywgYnV0IHN0
aWxsIHVzZWZ1bCBmb3IgbGVnYWN5IEFQSXMgYW5kCiBoYXMgbm8gcGxhbiB0byBiZSByZW1v
dmVkLgoKCgoDBAABEgNECBMKIAoEBAACABIDRgITGhMgVGhlIGRvdWJsZSB2YWx1ZS4KCgwK
BQQAAgAFEgNGAggKDAoFBAACAAESA0YJDgoMCgUEAAIAAxIDRhESCs4BCgIEARIETwBSARrB
ASBXcmFwcGVyIG1lc3NhZ2UgZm9yIGBmbG9hdGAuCgogVGhlIEpTT04gcmVwcmVzZW50YXRp
b24gZm9yIGBGbG9hdFZhbHVlYCBpcyBKU09OIG51bWJlci4KCiBOb3QgcmVjb21tZW5kZWQg
Zm9yIHVzZSBpbiBuZXcgQVBJcywgYnV0IHN0aWxsIHVzZWZ1bCBmb3IgbGVnYWN5IEFQSXMg
YW5kCiBoYXMgbm8gcGxhbiB0byBiZSByZW1vdmVkLgoKCgoDBAEBEgNPCBIKHwoEBAECABID
UQISGhIgVGhlIGZsb2F0IHZhbHVlLgoKDAoFBAECAAUSA1ECBwoMCgUEAQIAARIDUQgNCgwK
BQQBAgADEgNREBEKzgEKAgQCEgRaAF0BGsEBIFdyYXBwZXIgbWVzc2FnZSBmb3IgYGludDY0
YC4KCiBUaGUgSlNPTiByZXByZXNlbnRhdGlvbiBmb3IgYEludDY0VmFsdWVgIGlzIEpTT04g
c3RyaW5nLgoKIE5vdCByZWNvbW1lbmRlZCBmb3IgdXNlIGluIG5ldyBBUElzLCBidXQgc3Rp
bGwgdXNlZnVsIGZvciBsZWdhY3kgQVBJcyBhbmQKIGhhcyBubyBwbGFuIHRvIGJlIHJlbW92
ZWQuCgoKCgMEAgESA1oIEgofCgQEAgIAEgNcAhIaEiBUaGUgaW50NjQgdmFsdWUuCgoMCgUE
AgIABRIDXAIHCgwKBQQCAgABEgNcCA0KDAoFBAICAAMSA1wQEQrQAQoCBAMSBGUAaAEawwEg
V3JhcHBlciBtZXNzYWdlIGZvciBgdWludDY0YC4KCiBUaGUgSlNPTiByZXByZXNlbnRhdGlv
biBmb3IgYFVJbnQ2NFZhbHVlYCBpcyBKU09OIHN0cmluZy4KCiBOb3QgcmVjb21tZW5kZWQg
Zm9yIHVzZSBpbiBuZXcgQVBJcywgYnV0IHN0aWxsIHVzZWZ1bCBmb3IgbGVnYWN5IEFQSXMg
YW5kCiBoYXMgbm8gcGxhbiB0byBiZSByZW1vdmVkLgoKCgoDBAMBEgNlCBMKIAoEBAMCABID
ZwITGhMgVGhlIHVpbnQ2NCB2YWx1ZS4KCgwKBQQDAgAFEgNnAggKDAoFBAMCAAESA2cJDgoM
CgUEAwIAAxIDZxESCs4BCgIEBBIEcABzARrBASBXcmFwcGVyIG1lc3NhZ2UgZm9yIGBpbnQz
MmAuCgogVGhlIEpTT04gcmVwcmVzZW50YXRpb24gZm9yIGBJbnQzMlZhbHVlYCBpcyBKU09O
IG51bWJlci4KCiBOb3QgcmVjb21tZW5kZWQgZm9yIHVzZSBpbiBuZXcgQVBJcywgYnV0IHN0
aWxsIHVzZWZ1bCBmb3IgbGVnYWN5IEFQSXMgYW5kCiBoYXMgbm8gcGxhbiB0byBiZSByZW1v
dmVkLgoKCgoDBAQBEgNwCBIKHwoEBAQCABIDcgISGhIgVGhlIGludDMyIHZhbHVlLgoKDAoF
BAQCAAUSA3ICBwoMCgUEBAIAARIDcggNCgwKBQQEAgADEgNyEBEK0AEKAgQFEgR7AH4BGsMB
IFdyYXBwZXIgbWVzc2FnZSBmb3IgYHVpbnQzMmAuCgogVGhlIEpTT04gcmVwcmVzZW50YXRp
b24gZm9yIGBVSW50MzJWYWx1ZWAgaXMgSlNPTiBudW1iZXIuCgogTm90IHJlY29tbWVuZGVk
IGZvciB1c2UgaW4gbmV3IEFQSXMsIGJ1dCBzdGlsbCB1c2VmdWwgZm9yIGxlZ2FjeSBBUElz
IGFuZAogaGFzIG5vIHBsYW4gdG8gYmUgcmVtb3ZlZC4KCgoKAwQFARIDewgTCiAKBAQFAgAS
A30CExoTIFRoZSB1aW50MzIgdmFsdWUuCgoMCgUEBQIABRIDfQIICgwKBQQFAgABEgN9CQ4K
DAoFBAUCAAMSA30REgraAQoCBAYSBoYBAIkBARrLASBXcmFwcGVyIG1lc3NhZ2UgZm9yIGBi
b29sYC4KCiBUaGUgSlNPTiByZXByZXNlbnRhdGlvbiBmb3IgYEJvb2xWYWx1ZWAgaXMgSlNP
TiBgdHJ1ZWAgYW5kIGBmYWxzZWAuCgogTm90IHJlY29tbWVuZGVkIGZvciB1c2UgaW4gbmV3
IEFQSXMsIGJ1dCBzdGlsbCB1c2VmdWwgZm9yIGxlZ2FjeSBBUElzIGFuZAogaGFzIG5vIHBs
YW4gdG8gYmUgcmVtb3ZlZC4KCgsKAwQGARIEhgEIEQofCgQEBgIAEgSIAQIRGhEgVGhlIGJv
b2wgdmFsdWUuCgoNCgUEBgIABRIEiAECBgoNCgUEBgIAARIEiAEHDAoNCgUEBgIAAxIEiAEP
EArSAQoCBAcSBpEBAJQBARrDASBXcmFwcGVyIG1lc3NhZ2UgZm9yIGBzdHJpbmdgLgoKIFRo
ZSBKU09OIHJlcHJlc2VudGF0aW9uIGZvciBgU3RyaW5nVmFsdWVgIGlzIEpTT04gc3RyaW5n
LgoKIE5vdCByZWNvbW1lbmRlZCBmb3IgdXNlIGluIG5ldyBBUElzLCBidXQgc3RpbGwgdXNl
ZnVsIGZvciBsZWdhY3kgQVBJcyBhbmQKIGhhcyBubyBwbGFuIHRvIGJlIHJlbW92ZWQuCgoL
CgMEBwESBJEBCBMKIQoEBAcCABIEkwECExoTIFRoZSBzdHJpbmcgdmFsdWUuCgoNCgUEBwIA
BRIEkwECCAoNCgUEBwIAARIEkwEJDgoNCgUEBwIAAxIEkwEREgrQAQoCBAgSBpwBAJ8BARrB
ASBXcmFwcGVyIG1lc3NhZ2UgZm9yIGBieXRlc2AuCgogVGhlIEpTT04gcmVwcmVzZW50YXRp
b24gZm9yIGBCeXRlc1ZhbHVlYCBpcyBKU09OIHN0cmluZy4KCiBOb3QgcmVjb21tZW5kZWQg
Zm9yIHVzZSBpbiBuZXcgQVBJcywgYnV0IHN0aWxsIHVzZWZ1bCBmb3IgbGVnYWN5IEFQSXMg
YW5kCiBoYXMgbm8gcGxhbiB0byBiZSByZW1vdmVkLgoKCwoDBAgBEgScAQgSCiAKBAQIAgAS
BJ4BAiEaEiBUaGUgYnl0ZXMgdmFsdWUuCgoNCgUECAIABRIEngECBwoNCgUECAIAARIEngEI
DQoNCgUECAIAAxIEngEQEQoNCgUECAIACBIEngESIAoOCgYECAIACAESBJ4BEx9iBnByb3Rv
Mw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Protobuf::Wrappers::DoubleValue ===
    # Fields for DoubleValue
    # Field: value Type: 1 ()

=pod

=head1 NAME

Google::Protobuf::Wrappers::DoubleValue - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Protobuf::Wrappers;

    my $msg = Google::Protobuf::Wrappers::DoubleValue->new(
        value => $value,
    );

=head1 FIELDS

=over 4

=item * B<value>

Type: Double

=back

=cut

# === Message: Google::Protobuf::Wrappers::FloatValue ===
    # Fields for FloatValue
    # Field: value Type: 2 ()

=pod

=head1 NAME

Google::Protobuf::Wrappers::FloatValue - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Protobuf::Wrappers;

    my $msg = Google::Protobuf::Wrappers::FloatValue->new(
        value => $value,
    );

=head1 FIELDS

=over 4

=item * B<value>

Type: Float

=back

=cut

# === Message: Google::Protobuf::Wrappers::Int64Value ===
    # Fields for Int64Value
    # Field: value Type: 3 ()

=pod

=head1 NAME

Google::Protobuf::Wrappers::Int64Value - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Protobuf::Wrappers;

    my $msg = Google::Protobuf::Wrappers::Int64Value->new(
        value => $value,
    );

=head1 FIELDS

=over 4

=item * B<value>

Type: Int64

=back

=cut

# === Message: Google::Protobuf::Wrappers::UInt64Value ===
    # Fields for UInt64Value
    # Field: value Type: 4 ()

=pod

=head1 NAME

Google::Protobuf::Wrappers::UInt64Value - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Protobuf::Wrappers;

    my $msg = Google::Protobuf::Wrappers::UInt64Value->new(
        value => $value,
    );

=head1 FIELDS

=over 4

=item * B<value>

Type: UInt64

=back

=cut

# === Message: Google::Protobuf::Wrappers::Int32Value ===
    # Fields for Int32Value
    # Field: value Type: 5 ()

=pod

=head1 NAME

Google::Protobuf::Wrappers::Int32Value - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Protobuf::Wrappers;

    my $msg = Google::Protobuf::Wrappers::Int32Value->new(
        value => $value,
    );

=head1 FIELDS

=over 4

=item * B<value>

Type: Int32

=back

=cut

# === Message: Google::Protobuf::Wrappers::UInt32Value ===
    # Fields for UInt32Value
    # Field: value Type: 13 ()

=pod

=head1 NAME

Google::Protobuf::Wrappers::UInt32Value - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Protobuf::Wrappers;

    my $msg = Google::Protobuf::Wrappers::UInt32Value->new(
        value => $value,
    );

=head1 FIELDS

=over 4

=item * B<value>

Type: UInt32

=back

=cut

# === Message: Google::Protobuf::Wrappers::BoolValue ===
    # Fields for BoolValue
    # Field: value Type: 8 ()

=pod

=head1 NAME

Google::Protobuf::Wrappers::BoolValue - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Protobuf::Wrappers;

    my $msg = Google::Protobuf::Wrappers::BoolValue->new(
        value => $value,
    );

=head1 FIELDS

=over 4

=item * B<value>

Type: Bool

=back

=cut

# === Message: Google::Protobuf::Wrappers::StringValue ===
    # Fields for StringValue
    # Field: value Type: 9 ()

=pod

=head1 NAME

Google::Protobuf::Wrappers::StringValue - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Protobuf::Wrappers;

    my $msg = Google::Protobuf::Wrappers::StringValue->new(
        value => $value,
    );

=head1 FIELDS

=over 4

=item * B<value>

Type: String

=back

=cut

# === Message: Google::Protobuf::Wrappers::BytesValue ===
    # Fields for BytesValue
    # Field: value Type: 12 ()

=pod

=head1 NAME

Google::Protobuf::Wrappers::BytesValue - Compiled Protocol Buffers message class

=head1 SYNOPSIS

    use Google::Protobuf::Wrappers;

    my $msg = Google::Protobuf::Wrappers::BytesValue->new(
        value => $value,
    );

=head1 FIELDS

=over 4

=item * B<value>

Type: Bytes

=back

=cut

1;
