package Google::Protobuf::Wrappers;

use strict;
use warnings;

our $VERSION = '0.14';

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

# === Message: Google::Protobuf::Wrappers::FloatValue ===
    # Fields for FloatValue
    # Field: value Type: 2 ()

# === Message: Google::Protobuf::Wrappers::Int64Value ===
    # Fields for Int64Value
    # Field: value Type: 3 ()

# === Message: Google::Protobuf::Wrappers::UInt64Value ===
    # Fields for UInt64Value
    # Field: value Type: 4 ()

# === Message: Google::Protobuf::Wrappers::Int32Value ===
    # Fields for Int32Value
    # Field: value Type: 5 ()

# === Message: Google::Protobuf::Wrappers::UInt32Value ===
    # Fields for UInt32Value
    # Field: value Type: 13 ()

# === Message: Google::Protobuf::Wrappers::BoolValue ===
    # Fields for BoolValue
    # Field: value Type: 8 ()

# === Message: Google::Protobuf::Wrappers::StringValue ===
    # Fields for StringValue
    # Field: value Type: 9 ()

# === Message: Google::Protobuf::Wrappers::BytesValue ===
    # Fields for BytesValue
    # Field: value Type: 12 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Protobuf::Wrappers - Compiled Protocol Buffers messages for google/protobuf/wrappers.proto

=head1 SYNOPSIS

    use Google::Protobuf::Wrappers;

    my $msg = Google::Protobuf::Wrappers::DoubleValue->new({
        value => $value,
    });

    # Read or update a field
    my $val = $msg->value();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Protobuf::Wrappers::DoubleValue->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/protobuf/wrappers.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Protobuf::Wrappers::DoubleValue

Wrapper message for `double`.

The JSON representation for `DoubleValue` is JSON number.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<Double>

The double value.

=back

=head2 Google::Protobuf::Wrappers::FloatValue

Wrapper message for `float`.

The JSON representation for `FloatValue` is JSON number.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<Float>

The float value.

=back

=head2 Google::Protobuf::Wrappers::Int64Value

Wrapper message for `int64`.

The JSON representation for `Int64Value` is JSON string.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<Int64>

The int64 value.

=back

=head2 Google::Protobuf::Wrappers::UInt64Value

Wrapper message for `uint64`.

The JSON representation for `UInt64Value` is JSON string.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<UInt64>

The uint64 value.

=back

=head2 Google::Protobuf::Wrappers::Int32Value

Wrapper message for `int32`.

The JSON representation for `Int32Value` is JSON number.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<Int32>

The int32 value.

=back

=head2 Google::Protobuf::Wrappers::UInt32Value

Wrapper message for `uint32`.

The JSON representation for `UInt32Value` is JSON number.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<UInt32>

The uint32 value.

=back

=head2 Google::Protobuf::Wrappers::BoolValue

Wrapper message for `bool`.

The JSON representation for `BoolValue` is JSON `true` and `false`.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<Bool>

The bool value.

=back

=head2 Google::Protobuf::Wrappers::StringValue

Wrapper message for `string`.

The JSON representation for `StringValue` is JSON string.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<String>

The string value.

=back

=head2 Google::Protobuf::Wrappers::BytesValue

Wrapper message for `bytes`.

The JSON representation for `BytesValue` is JSON string.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<Bytes>

The bytes value.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Protobuf::Wrappers::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
