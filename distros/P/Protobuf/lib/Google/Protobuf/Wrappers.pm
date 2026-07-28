package Google::Protobuf::Wrappers;

use strict;
use warnings;

our $VERSION = '0.11';

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
bHVlGAEgASgJUgV2YWx1ZSIiCgpCeXRlc1ZhbHVlEhQKBXZhbHVlGAEgASgMUgV2YWx1ZUKD
AQoTY29tLmdvb2dsZS5wcm90b2J1ZkINV3JhcHBlcnNQcm90b1ABWjFnb29nbGUuZ29sYW5n
Lm9yZy9wcm90b2J1Zi90eXBlcy9rbm93bi93cmFwcGVyc3Bi+AEBogIDR1BCqgIeR29vZ2xl
LlByb3RvYnVmLldlbGxLbm93blR5cGVzSsYfCgYSBCgAegEK2xAKAQwSAygAEjLBDCBQcm90
b2NvbCBCdWZmZXJzIC0gR29vZ2xlJ3MgZGF0YSBpbnRlcmNoYW5nZSBmb3JtYXQKIENvcHly
aWdodCAyMDA4IEdvb2dsZSBJbmMuICBBbGwgcmlnaHRzIHJlc2VydmVkLgogaHR0cHM6Ly9k
ZXZlbG9wZXJzLmdvb2dsZS5jb20vcHJvdG9jb2wtYnVmZmVycy8KCiBSZWRpc3RyaWJ1dGlv
biBhbmQgdXNlIGluIHNvdXJjZSBhbmQgYmluYXJ5IGZvcm1zLCB3aXRoIG9yIHdpdGhvdXQK
IG1vZGlmaWNhdGlvbiwgYXJlIHBlcm1pdHRlZCBwcm92aWRlZCB0aGF0IHRoZSBmb2xsb3dp
bmcgY29uZGl0aW9ucyBhcmUKIG1ldDoKCiAgICAgKiBSZWRpc3RyaWJ1dGlvbnMgb2Ygc291
cmNlIGNvZGUgbXVzdCByZXRhaW4gdGhlIGFib3ZlIGNvcHlyaWdodAogbm90aWNlLCB0aGlz
IGxpc3Qgb2YgY29uZGl0aW9ucyBhbmQgdGhlIGZvbGxvd2luZyBkaXNjbGFpbWVyLgogICAg
ICogUmVkaXN0cmlidXRpb25zIGluIGJpbmFyeSBmb3JtIG11c3QgcmVwcm9kdWNlIHRoZSBh
Ym92ZQogY29weXJpZ2h0IG5vdGljZSwgdGhpcyBsaXN0IG9mIGNvbmRpdGlvbnMgYW5kIHRo
ZSBmb2xsb3dpbmcgZGlzY2xhaW1lcgogaW4gdGhlIGRvY3VtZW50YXRpb24gYW5kL29yIG90
aGVyIG1hdGVyaWFscyBwcm92aWRlZCB3aXRoIHRoZQogZGlzdHJpYnV0aW9uLgogICAgICog
TmVpdGhlciB0aGUgbmFtZSBvZiBHb29nbGUgSW5jLiBub3IgdGhlIG5hbWVzIG9mIGl0cwog
Y29udHJpYnV0b3JzIG1heSBiZSB1c2VkIHRvIGVuZG9yc2Ugb3IgcHJvbW90ZSBwcm9kdWN0
cyBkZXJpdmVkIGZyb20KIHRoaXMgc29mdHdhcmUgd2l0aG91dCBzcGVjaWZpYyBwcmlvciB3
cml0dGVuIHBlcm1pc3Npb24uCgogVEhJUyBTT0ZUV0FSRSBJUyBQUk9WSURFRCBCWSBUSEUg
Q09QWVJJR0hUIEhPTERFUlMgQU5EIENPTlRSSUJVVE9SUwogIkFTIElTIiBBTkQgQU5ZIEVY
UFJFU1MgT1IgSU1QTElFRCBXQVJSQU5USUVTLCBJTkNMVURJTkcsIEJVVCBOT1QKIExJTUlU
RUQgVE8sIFRIRSBJTVBMSUVEIFdBUlJBTlRJRVMgT0YgTUVSQ0hBTlRBQklMSVRZIEFORCBG
SVRORVNTIEZPUgogQSBQQVJUSUNVTEFSIFBVUlBPU0UgQVJFIERJU0NMQUlNRUQuIElOIE5P
IEVWRU5UIFNIQUxMIFRIRSBDT1BZUklHSFQKIE9XTkVSIE9SIENPTlRSSUJVVE9SUyBCRSBM
SUFCTEUgRk9SIEFOWSBESVJFQ1QsIElORElSRUNULCBJTkNJREVOVEFMLAogU1BFQ0lBTCwg
RVhFTVBMQVJZLCBPUiBDT05TRVFVRU5USUFMIERBTUFHRVMgKElOQ0xVRElORywgQlVUIE5P
VAogTElNSVRFRCBUTywgUFJPQ1VSRU1FTlQgT0YgU1VCU1RJVFVURSBHT09EUyBPUiBTRVJW
SUNFUzsgTE9TUyBPRiBVU0UsCiBEQVRBLCBPUiBQUk9GSVRTOyBPUiBCVVNJTkVTUyBJTlRF
UlJVUFRJT04pIEhPV0VWRVIgQ0FVU0VEIEFORCBPTiBBTlkKIFRIRU9SWSBPRiBMSUFCSUxJ
VFksIFdIRVRIRVIgSU4gQ09OVFJBQ1QsIFNUUklDVCBMSUFCSUxJVFksIE9SIFRPUlQKIChJ
TkNMVURJTkcgTkVHTElHRU5DRSBPUiBPVEhFUldJU0UpIEFSSVNJTkcgSU4gQU5ZIFdBWSBP
VVQgT0YgVEhFIFVTRQogT0YgVEhJUyBTT0ZUV0FSRSwgRVZFTiBJRiBBRFZJU0VEIE9GIFRI
RSBQT1NTSUJJTElUWSBPRiBTVUNIIERBTUFHRS4KMowEIFdyYXBwZXJzIGZvciBwcmltaXRp
dmUgKG5vbi1tZXNzYWdlKSB0eXBlcy4gVGhlc2UgdHlwZXMgYXJlIHVzZWZ1bAogZm9yIGVt
YmVkZGluZyBwcmltaXRpdmVzIGluIHRoZSBgZ29vZ2xlLnByb3RvYnVmLkFueWAgdHlwZSBh
bmQgZm9yIHBsYWNlcwogd2hlcmUgd2UgbmVlZCB0byBkaXN0aW5ndWlzaCBiZXR3ZWVuIHRo
ZSBhYnNlbmNlIG9mIGEgcHJpbWl0aXZlCiB0eXBlZCBmaWVsZCBhbmQgaXRzIGRlZmF1bHQg
dmFsdWUuCgogVGhlc2Ugd3JhcHBlcnMgaGF2ZSBubyBtZWFuaW5nZnVsIHVzZSB3aXRoaW4g
cmVwZWF0ZWQgZmllbGRzIGFzIHRoZXkgbGFjawogdGhlIGFiaWxpdHkgdG8gZGV0ZWN0IHBy
ZXNlbmNlIG9uIGluZGl2aWR1YWwgZWxlbWVudHMuCiBUaGVzZSB3cmFwcGVycyBoYXZlIG5v
IG1lYW5pbmdmdWwgdXNlIHdpdGhpbiBhIG1hcCBvciBhIG9uZW9mIHNpbmNlCiBpbmRpdmlk
dWFsIGVudHJpZXMgb2YgYSBtYXAgb3IgZmllbGRzIG9mIGEgb25lb2YgY2FuIGFscmVhZHkg
ZGV0ZWN0IHByZXNlbmNlLgoKCAoBAhIDKgAYCggKAQgSAywAOwoJCgIIJRIDLAA7CggKAQgS
Ay0AHwoJCgIIHxIDLQAfCggKAQgSAy4ASAoJCgIICxIDLgBICggKAQgSAy8ALAoJCgIIARID
LwAsCggKAQgSAzAALgoJCgIICBIDMAAuCggKAQgSAzEAIgoJCgIIChIDMQAiCggKAQgSAzIA
IQoJCgIIJBIDMgAhCmcKAgQAEgQ3ADoBGlsgV3JhcHBlciBtZXNzYWdlIGZvciBgZG91Ymxl
YC4KCiBUaGUgSlNPTiByZXByZXNlbnRhdGlvbiBmb3IgYERvdWJsZVZhbHVlYCBpcyBKU09O
IG51bWJlci4KCgoKAwQAARIDNwgTCiAKBAQAAgASAzkCExoTIFRoZSBkb3VibGUgdmFsdWUu
CgoMCgUEAAIABRIDOQIICgwKBQQAAgABEgM5CQ4KDAoFBAACAAMSAzkREgplCgIEARIEPwBC
ARpZIFdyYXBwZXIgbWVzc2FnZSBmb3IgYGZsb2F0YC4KCiBUaGUgSlNPTiByZXByZXNlbnRh
dGlvbiBmb3IgYEZsb2F0VmFsdWVgIGlzIEpTT04gbnVtYmVyLgoKCgoDBAEBEgM/CBIKHwoE
BAECABIDQQISGhIgVGhlIGZsb2F0IHZhbHVlLgoKDAoFBAECAAUSA0ECBwoMCgUEAQIAARID
QQgNCgwKBQQBAgADEgNBEBEKZQoCBAISBEcASgEaWSBXcmFwcGVyIG1lc3NhZ2UgZm9yIGBp
bnQ2NGAuCgogVGhlIEpTT04gcmVwcmVzZW50YXRpb24gZm9yIGBJbnQ2NFZhbHVlYCBpcyBK
U09OIHN0cmluZy4KCgoKAwQCARIDRwgSCh8KBAQCAgASA0kCEhoSIFRoZSBpbnQ2NCB2YWx1
ZS4KCgwKBQQCAgAFEgNJAgcKDAoFBAICAAESA0kIDQoMCgUEAgIAAxIDSRARCmcKAgQDEgRP
AFIBGlsgV3JhcHBlciBtZXNzYWdlIGZvciBgdWludDY0YC4KCiBUaGUgSlNPTiByZXByZXNl
bnRhdGlvbiBmb3IgYFVJbnQ2NFZhbHVlYCBpcyBKU09OIHN0cmluZy4KCgoKAwQDARIDTwgT
CiAKBAQDAgASA1ECExoTIFRoZSB1aW50NjQgdmFsdWUuCgoMCgUEAwIABRIDUQIICgwKBQQD
AgABEgNRCQ4KDAoFBAMCAAMSA1EREgplCgIEBBIEVwBaARpZIFdyYXBwZXIgbWVzc2FnZSBm
b3IgYGludDMyYC4KCiBUaGUgSlNPTiByZXByZXNlbnRhdGlvbiBmb3IgYEludDMyVmFsdWVg
IGlzIEpTT04gbnVtYmVyLgoKCgoDBAQBEgNXCBIKHwoEBAQCABIDWQISGhIgVGhlIGludDMy
IHZhbHVlLgoKDAoFBAQCAAUSA1kCBwoMCgUEBAIAARIDWQgNCgwKBQQEAgADEgNZEBEKZwoC
BAUSBF8AYgEaWyBXcmFwcGVyIG1lc3NhZ2UgZm9yIGB1aW50MzJgLgoKIFRoZSBKU09OIHJl
cHJlc2VudGF0aW9uIGZvciBgVUludDMyVmFsdWVgIGlzIEpTT04gbnVtYmVyLgoKCgoDBAUB
EgNfCBMKIAoEBAUCABIDYQITGhMgVGhlIHVpbnQzMiB2YWx1ZS4KCgwKBQQFAgAFEgNhAggK
DAoFBAUCAAESA2EJDgoMCgUEBQIAAxIDYRESCm8KAgQGEgRnAGoBGmMgV3JhcHBlciBtZXNz
YWdlIGZvciBgYm9vbGAuCgogVGhlIEpTT04gcmVwcmVzZW50YXRpb24gZm9yIGBCb29sVmFs
dWVgIGlzIEpTT04gYHRydWVgIGFuZCBgZmFsc2VgLgoKCgoDBAYBEgNnCBEKHgoEBAYCABID
aQIRGhEgVGhlIGJvb2wgdmFsdWUuCgoMCgUEBgIABRIDaQIGCgwKBQQGAgABEgNpBwwKDAoF
BAYCAAMSA2kPEApnCgIEBxIEbwByARpbIFdyYXBwZXIgbWVzc2FnZSBmb3IgYHN0cmluZ2Au
CgogVGhlIEpTT04gcmVwcmVzZW50YXRpb24gZm9yIGBTdHJpbmdWYWx1ZWAgaXMgSlNPTiBz
dHJpbmcuCgoKCgMEBwESA28IEwogCgQEBwIAEgNxAhMaEyBUaGUgc3RyaW5nIHZhbHVlLgoK
DAoFBAcCAAUSA3ECCAoMCgUEBwIAARIDcQkOCgwKBQQHAgADEgNxERIKZQoCBAgSBHcAegEa
WSBXcmFwcGVyIG1lc3NhZ2UgZm9yIGBieXRlc2AuCgogVGhlIEpTT04gcmVwcmVzZW50YXRp
b24gZm9yIGBCeXRlc1ZhbHVlYCBpcyBKU09OIHN0cmluZy4KCgoKAwQIARIDdwgSCh8KBAQI
AgASA3kCEhoSIFRoZSBieXRlcyB2YWx1ZS4KCgwKBQQIAgAFEgN5AgcKDAoFBAgCAAESA3kI
DQoMCgUECAIAAxIDeRARYgZwcm90bzM=
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

__END__

=head1 NAME

Google::Protobuf::Wrappers - Protocol Buffers schema definition

=head1 DESCRIPTION

Auto-generated Protocol Buffers schema definition class.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
