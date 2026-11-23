package Google::Protobuf::FieldMask;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    my $descriptor_b64 = <<'EOF';
CiBnb29nbGUvcHJvdG9idWYvZmllbGRfbWFzay5wcm90bxIPZ29vZ2xlLnByb3RvYnVmIiEK
CUZpZWxkTWFzaxIUCgVwYXRocxgBIAMoCVIFcGF0aHNChQEKE2NvbS5nb29nbGUucHJvdG9i
dWZCDkZpZWxkTWFza1Byb3RvUAFaMmdvb2dsZS5nb2xhbmcub3JnL3Byb3RvYnVmL3R5cGVz
L2tub3duL2ZpZWxkbWFza3Bi+AEBogIDR1BCqgIeR29vZ2xlLlByb3RvYnVmLldlbGxLbm93
blR5cGVzSqE7CgcSBR4A9AEBCswMCgEMEgMeABIywQwgUHJvdG9jb2wgQnVmZmVycyAtIEdv
b2dsZSdzIGRhdGEgaW50ZXJjaGFuZ2UgZm9ybWF0CiBDb3B5cmlnaHQgMjAwOCBHb29nbGUg
SW5jLiAgQWxsIHJpZ2h0cyByZXNlcnZlZC4KIGh0dHBzOi8vZGV2ZWxvcGVycy5nb29nbGUu
Y29tL3Byb3RvY29sLWJ1ZmZlcnMvCgogUmVkaXN0cmlidXRpb24gYW5kIHVzZSBpbiBzb3Vy
Y2UgYW5kIGJpbmFyeSBmb3Jtcywgd2l0aCBvciB3aXRob3V0CiBtb2RpZmljYXRpb24sIGFy
ZSBwZXJtaXR0ZWQgcHJvdmlkZWQgdGhhdCB0aGUgZm9sbG93aW5nIGNvbmRpdGlvbnMgYXJl
CiBtZXQ6CgogICAgICogUmVkaXN0cmlidXRpb25zIG9mIHNvdXJjZSBjb2RlIG11c3QgcmV0
YWluIHRoZSBhYm92ZSBjb3B5cmlnaHQKIG5vdGljZSwgdGhpcyBsaXN0IG9mIGNvbmRpdGlv
bnMgYW5kIHRoZSBmb2xsb3dpbmcgZGlzY2xhaW1lci4KICAgICAqIFJlZGlzdHJpYnV0aW9u
cyBpbiBiaW5hcnkgZm9ybSBtdXN0IHJlcHJvZHVjZSB0aGUgYWJvdmUKIGNvcHlyaWdodCBu
b3RpY2UsIHRoaXMgbGlzdCBvZiBjb25kaXRpb25zIGFuZCB0aGUgZm9sbG93aW5nIGRpc2Ns
YWltZXIKIGluIHRoZSBkb2N1bWVudGF0aW9uIGFuZC9vciBvdGhlciBtYXRlcmlhbHMgcHJv
dmlkZWQgd2l0aCB0aGUKIGRpc3RyaWJ1dGlvbi4KICAgICAqIE5laXRoZXIgdGhlIG5hbWUg
b2YgR29vZ2xlIEluYy4gbm9yIHRoZSBuYW1lcyBvZiBpdHMKIGNvbnRyaWJ1dG9ycyBtYXkg
YmUgdXNlZCB0byBlbmRvcnNlIG9yIHByb21vdGUgcHJvZHVjdHMgZGVyaXZlZCBmcm9tCiB0
aGlzIHNvZnR3YXJlIHdpdGhvdXQgc3BlY2lmaWMgcHJpb3Igd3JpdHRlbiBwZXJtaXNzaW9u
LgoKIFRISVMgU09GVFdBUkUgSVMgUFJPVklERUQgQlkgVEhFIENPUFlSSUdIVCBIT0xERVJT
IEFORCBDT05UUklCVVRPUlMKICJBUyBJUyIgQU5EIEFOWSBFWFBSRVNTIE9SIElNUExJRUQg
V0FSUkFOVElFUywgSU5DTFVESU5HLCBCVVQgTk9UCiBMSU1JVEVEIFRPLCBUSEUgSU1QTElF
RCBXQVJSQU5USUVTIE9GIE1FUkNIQU5UQUJJTElUWSBBTkQgRklUTkVTUyBGT1IKIEEgUEFS
VElDVUxBUiBQVVJQT1NFIEFSRSBESVNDTEFJTUVELiBJTiBOTyBFVkVOVCBTSEFMTCBUSEUg
Q09QWVJJR0hUCiBPV05FUiBPUiBDT05UUklCVVRPUlMgQkUgTElBQkxFIEZPUiBBTlkgRElS
RUNULCBJTkRJUkVDVCwgSU5DSURFTlRBTCwKIFNQRUNJQUwsIEVYRU1QTEFSWSwgT1IgQ09O
U0VRVUVOVElBTCBEQU1BR0VTIChJTkNMVURJTkcsIEJVVCBOT1QKIExJTUlURUQgVE8sIFBS
T0NVUkVNRU5UIE9GIFNVQlNUSVRVVEUgR09PRFMgT1IgU0VSVklDRVM7IExPU1MgT0YgVVNF
LAogREFUQSwgT1IgUFJPRklUUzsgT1IgQlVTSU5FU1MgSU5URVJSVVBUSU9OKSBIT1dFVkVS
IENBVVNFRCBBTkQgT04gQU5ZCiBUSEVPUlkgT0YgTElBQklMSVRZLCBXSEVUSEVSIElOIENP
TlRSQUNULCBTVFJJQ1QgTElBQklMSVRZLCBPUiBUT1JUCiAoSU5DTFVESU5HIE5FR0xJR0VO
Q0UgT1IgT1RIRVJXSVNFKSBBUklTSU5HIElOIEFOWSBXQVkgT1VUIE9GIFRIRSBVU0UKIE9G
IFRISVMgU09GVFdBUkUsIEVWRU4gSUYgQURWSVNFRCBPRiBUSEUgUE9TU0lCSUxJVFkgT0Yg
U1VDSCBEQU1BR0UuCgoICgECEgMgABgKCAoBCBIDIgA7CgkKAgglEgMiADsKCAoBCBIDIwAs
CgkKAggBEgMjACwKCAoBCBIDJAAvCgkKAggIEgMkAC8KCAoBCBIDJQAiCgkKAggKEgMlACIK
CAoBCBIDJgAhCgkKAggkEgMmACEKCAoBCBIDJwBJCgkKAggLEgMnAEkKCAoBCBIDKAAfCgkK
AggfEgMoAB8KsiwKAgQAEgbxAQD0AQEaoywgYEZpZWxkTWFza2AgcmVwcmVzZW50cyBhIHNl
dCBvZiBzeW1ib2xpYyBmaWVsZCBwYXRocywgZm9yIGV4YW1wbGU6CgogICAgIHBhdGhzOiAi
Zi5hIgogICAgIHBhdGhzOiAiZi5iLmQiCgogSGVyZSBgZmAgcmVwcmVzZW50cyBhIGZpZWxk
IGluIHNvbWUgcm9vdCBtZXNzYWdlLCBgYWAgYW5kIGBiYAogZmllbGRzIGluIHRoZSBtZXNz
YWdlIGZvdW5kIGluIGBmYCwgYW5kIGBkYCBhIGZpZWxkIGZvdW5kIGluIHRoZQogbWVzc2Fn
ZSBpbiBgZi5iYC4KCiBGaWVsZCBtYXNrcyBhcmUgdXNlZCB0byBzcGVjaWZ5IGEgc3Vic2V0
IG9mIGZpZWxkcyB0aGF0IHNob3VsZCBiZQogcmV0dXJuZWQgYnkgYSBnZXQgb3BlcmF0aW9u
IG9yIG1vZGlmaWVkIGJ5IGFuIHVwZGF0ZSBvcGVyYXRpb24uCiBGaWVsZCBtYXNrcyBhbHNv
IGhhdmUgYSBjdXN0b20gSlNPTiBlbmNvZGluZyAoc2VlIGJlbG93KS4KCiAjIEZpZWxkIE1h
c2tzIGluIFByb2plY3Rpb25zCgogV2hlbiB1c2VkIGluIHRoZSBjb250ZXh0IG9mIGEgcHJv
amVjdGlvbiwgYSByZXNwb25zZSBtZXNzYWdlIG9yCiBzdWItbWVzc2FnZSBpcyBmaWx0ZXJl
ZCBieSB0aGUgQVBJIHRvIG9ubHkgY29udGFpbiB0aG9zZSBmaWVsZHMgYXMKIHNwZWNpZmll
ZCBpbiB0aGUgbWFzay4gRm9yIGV4YW1wbGUsIGlmIHRoZSBtYXNrIGluIHRoZSBwcmV2aW91
cwogZXhhbXBsZSBpcyBhcHBsaWVkIHRvIGEgcmVzcG9uc2UgbWVzc2FnZSBhcyBmb2xsb3dz
OgoKICAgICBmIHsKICAgICAgIGEgOiAyMgogICAgICAgYiB7CiAgICAgICAgIGQgOiAxCiAg
ICAgICAgIHggOiAyCiAgICAgICB9CiAgICAgICB5IDogMTMKICAgICB9CiAgICAgejogOAoK
IFRoZSByZXN1bHQgd2lsbCBub3QgY29udGFpbiBzcGVjaWZpYyB2YWx1ZXMgZm9yIGZpZWxk
cyB4LHkgYW5kIHoKICh0aGVpciB2YWx1ZSB3aWxsIGJlIHNldCB0byB0aGUgZGVmYXVsdCwg
YW5kIG9taXR0ZWQgaW4gcHJvdG8gdGV4dAogb3V0cHV0KToKCgogICAgIGYgewogICAgICAg
YSA6IDIyCiAgICAgICBiIHsKICAgICAgICAgZCA6IDEKICAgICAgIH0KICAgICB9CgogQSBy
ZXBlYXRlZCBmaWVsZCBpcyBub3QgYWxsb3dlZCBleGNlcHQgYXQgdGhlIGxhc3QgcG9zaXRp
b24gb2YgYQogcGF0aHMgc3RyaW5nLgoKIElmIGEgRmllbGRNYXNrIG9iamVjdCBpcyBub3Qg
cHJlc2VudCBpbiBhIGdldCBvcGVyYXRpb24sIHRoZQogb3BlcmF0aW9uIGFwcGxpZXMgdG8g
YWxsIGZpZWxkcyAoYXMgaWYgYSBGaWVsZE1hc2sgb2YgYWxsIGZpZWxkcwogaGFkIGJlZW4g
c3BlY2lmaWVkKS4KCiBOb3RlIHRoYXQgYSBmaWVsZCBtYXNrIGRvZXMgbm90IG5lY2Vzc2Fy
aWx5IGFwcGx5IHRvIHRoZQogdG9wLWxldmVsIHJlc3BvbnNlIG1lc3NhZ2UuIEluIGNhc2Ug
b2YgYSBSRVNUIGdldCBvcGVyYXRpb24sIHRoZQogZmllbGQgbWFzayBhcHBsaWVzIGRpcmVj
dGx5IHRvIHRoZSByZXNwb25zZSwgYnV0IGluIGNhc2Ugb2YgYSBSRVNUCiBsaXN0IG9wZXJh
dGlvbiwgdGhlIG1hc2sgaW5zdGVhZCBhcHBsaWVzIHRvIGVhY2ggaW5kaXZpZHVhbCBtZXNz
YWdlCiBpbiB0aGUgcmV0dXJuZWQgcmVzb3VyY2UgbGlzdC4gSW4gY2FzZSBvZiBhIFJFU1Qg
Y3VzdG9tIG1ldGhvZCwKIG90aGVyIGRlZmluaXRpb25zIG1heSBiZSB1c2VkLiBXaGVyZSB0
aGUgbWFzayBhcHBsaWVzIHdpbGwgYmUKIGNsZWFybHkgZG9jdW1lbnRlZCB0b2dldGhlciB3
aXRoIGl0cyBkZWNsYXJhdGlvbiBpbiB0aGUgQVBJLiAgSW4KIGFueSBjYXNlLCB0aGUgZWZm
ZWN0IG9uIHRoZSByZXR1cm5lZCByZXNvdXJjZS9yZXNvdXJjZXMgaXMgcmVxdWlyZWQKIGJl
aGF2aW9yIGZvciBBUElzLgoKICMgRmllbGQgTWFza3MgaW4gVXBkYXRlIE9wZXJhdGlvbnMK
CiBBIGZpZWxkIG1hc2sgaW4gdXBkYXRlIG9wZXJhdGlvbnMgc3BlY2lmaWVzIHdoaWNoIGZp
ZWxkcyBvZiB0aGUKIHRhcmdldGVkIHJlc291cmNlIGFyZSBnb2luZyB0byBiZSB1cGRhdGVk
LiBUaGUgQVBJIGlzIHJlcXVpcmVkCiB0byBvbmx5IGNoYW5nZSB0aGUgdmFsdWVzIG9mIHRo
ZSBmaWVsZHMgYXMgc3BlY2lmaWVkIGluIHRoZSBtYXNrCiBhbmQgbGVhdmUgdGhlIG90aGVy
cyB1bnRvdWNoZWQuIElmIGEgcmVzb3VyY2UgaXMgcGFzc2VkIGluIHRvCiBkZXNjcmliZSB0
aGUgdXBkYXRlZCB2YWx1ZXMsIHRoZSBBUEkgaWdub3JlcyB0aGUgdmFsdWVzIG9mIGFsbAog
ZmllbGRzIG5vdCBjb3ZlcmVkIGJ5IHRoZSBtYXNrLgoKIElmIGEgcmVwZWF0ZWQgZmllbGQg
aXMgc3BlY2lmaWVkIGZvciBhbiB1cGRhdGUgb3BlcmF0aW9uLCBuZXcgdmFsdWVzIHdpbGwK
IGJlIGFwcGVuZGVkIHRvIHRoZSBleGlzdGluZyByZXBlYXRlZCBmaWVsZCBpbiB0aGUgdGFy
Z2V0IHJlc291cmNlLiBOb3RlIHRoYXQKIGEgcmVwZWF0ZWQgZmllbGQgaXMgb25seSBhbGxv
d2VkIGluIHRoZSBsYXN0IHBvc2l0aW9uIG9mIGEgYHBhdGhzYCBzdHJpbmcuCgogSWYgYSBz
dWItbWVzc2FnZSBpcyBzcGVjaWZpZWQgaW4gdGhlIGxhc3QgcG9zaXRpb24gb2YgdGhlIGZp
ZWxkIG1hc2sgZm9yIGFuCiB1cGRhdGUgb3BlcmF0aW9uLCB0aGVuIG5ldyB2YWx1ZSB3aWxs
IGJlIG1lcmdlZCBpbnRvIHRoZSBleGlzdGluZyBzdWItbWVzc2FnZQogaW4gdGhlIHRhcmdl
dCByZXNvdXJjZS4KCiBGb3IgZXhhbXBsZSwgZ2l2ZW4gdGhlIHRhcmdldCBtZXNzYWdlOgoK
ICAgICBmIHsKICAgICAgIGIgewogICAgICAgICBkOiAxCiAgICAgICAgIHg6IDIKICAgICAg
IH0KICAgICAgIGM6IFsxXQogICAgIH0KCiBBbmQgYW4gdXBkYXRlIG1lc3NhZ2U6CgogICAg
IGYgewogICAgICAgYiB7CiAgICAgICAgIGQ6IDEwCiAgICAgICB9CiAgICAgICBjOiBbMl0K
ICAgICB9CgogdGhlbiBpZiB0aGUgZmllbGQgbWFzayBpczoKCiAgcGF0aHM6IFsiZi5iIiwg
ImYuYyJdCgogdGhlbiB0aGUgcmVzdWx0IHdpbGwgYmU6CgogICAgIGYgewogICAgICAgYiB7
CiAgICAgICAgIGQ6IDEwCiAgICAgICAgIHg6IDIKICAgICAgIH0KICAgICAgIGM6IFsxLCAy
XQogICAgIH0KCiBBbiBpbXBsZW1lbnRhdGlvbiBtYXkgcHJvdmlkZSBvcHRpb25zIHRvIG92
ZXJyaWRlIHRoaXMgZGVmYXVsdCBiZWhhdmlvciBmb3IKIHJlcGVhdGVkIGFuZCBtZXNzYWdl
IGZpZWxkcy4KCiBJbiBvcmRlciB0byByZXNldCBhIGZpZWxkJ3MgdmFsdWUgdG8gdGhlIGRl
ZmF1bHQsIHRoZSBmaWVsZCBtdXN0CiBiZSBpbiB0aGUgbWFzayBhbmQgc2V0IHRvIHRoZSBk
ZWZhdWx0IHZhbHVlIGluIHRoZSBwcm92aWRlZCByZXNvdXJjZS4KIEhlbmNlLCBpbiBvcmRl
ciB0byByZXNldCBhbGwgZmllbGRzIG9mIGEgcmVzb3VyY2UsIHByb3ZpZGUgYSBkZWZhdWx0
CiBpbnN0YW5jZSBvZiB0aGUgcmVzb3VyY2UgYW5kIHNldCBhbGwgZmllbGRzIGluIHRoZSBt
YXNrLCBvciBkbwogbm90IHByb3ZpZGUgYSBtYXNrIGFzIGRlc2NyaWJlZCBiZWxvdy4KCiBJ
ZiBhIGZpZWxkIG1hc2sgaXMgbm90IHByZXNlbnQgb24gdXBkYXRlLCB0aGUgb3BlcmF0aW9u
IGFwcGxpZXMgdG8KIGFsbCBmaWVsZHMgKGFzIGlmIGEgZmllbGQgbWFzayBvZiBhbGwgZmll
bGRzIGhhcyBiZWVuIHNwZWNpZmllZCkuCiBOb3RlIHRoYXQgaW4gdGhlIHByZXNlbmNlIG9m
IHNjaGVtYSBldm9sdXRpb24sIHRoaXMgbWF5IG1lYW4gdGhhdAogZmllbGRzIHRoZSBjbGll
bnQgZG9lcyBub3Qga25vdyBhbmQgaGFzIHRoZXJlZm9yZSBub3QgZmlsbGVkIGludG8KIHRo
ZSByZXF1ZXN0IHdpbGwgYmUgcmVzZXQgdG8gdGhlaXIgZGVmYXVsdC4gSWYgdGhpcyBpcyB1
bndhbnRlZAogYmVoYXZpb3IsIGEgc3BlY2lmaWMgc2VydmljZSBtYXkgcmVxdWlyZSBhIGNs
aWVudCB0byBhbHdheXMgc3BlY2lmeQogYSBmaWVsZCBtYXNrLCBwcm9kdWNpbmcgYW4gZXJy
b3IgaWYgbm90LgoKIEFzIHdpdGggZ2V0IG9wZXJhdGlvbnMsIHRoZSBsb2NhdGlvbiBvZiB0
aGUgcmVzb3VyY2Ugd2hpY2gKIGRlc2NyaWJlcyB0aGUgdXBkYXRlZCB2YWx1ZXMgaW4gdGhl
IHJlcXVlc3QgbWVzc2FnZSBkZXBlbmRzIG9uIHRoZQogb3BlcmF0aW9uIGtpbmQuIEluIGFu
eSBjYXNlLCB0aGUgZWZmZWN0IG9mIHRoZSBmaWVsZCBtYXNrIGlzCiByZXF1aXJlZCB0byBi
ZSBob25vcmVkIGJ5IHRoZSBBUEkuCgogIyMgQ29uc2lkZXJhdGlvbnMgZm9yIEhUVFAgUkVT
VAoKIFRoZSBIVFRQIGtpbmQgb2YgYW4gdXBkYXRlIG9wZXJhdGlvbiB3aGljaCB1c2VzIGEg
ZmllbGQgbWFzayBtdXN0CiBiZSBzZXQgdG8gUEFUQ0ggaW5zdGVhZCBvZiBQVVQgaW4gb3Jk
ZXIgdG8gc2F0aXNmeSBIVFRQIHNlbWFudGljcwogKFBVVCBtdXN0IG9ubHkgYmUgdXNlZCBm
b3IgZnVsbCB1cGRhdGVzKS4KCiAjIEpTT04gRW5jb2Rpbmcgb2YgRmllbGQgTWFza3MKCiBJ
biBKU09OLCBhIGZpZWxkIG1hc2sgaXMgZW5jb2RlZCBhcyBhIHNpbmdsZSBzdHJpbmcgd2hl
cmUgcGF0aHMgYXJlCiBzZXBhcmF0ZWQgYnkgYSBjb21tYS4gRmllbGRzIG5hbWUgaW4gZWFj
aCBwYXRoIGFyZSBjb252ZXJ0ZWQKIHRvL2Zyb20gbG93ZXItY2FtZWwgbmFtaW5nIGNvbnZl
bnRpb25zLgoKIEFzIGFuIGV4YW1wbGUsIGNvbnNpZGVyIHRoZSBmb2xsb3dpbmcgbWVzc2Fn
ZSBkZWNsYXJhdGlvbnM6CgogICAgIG1lc3NhZ2UgUHJvZmlsZSB7CiAgICAgICBVc2VyIHVz
ZXIgPSAxOwogICAgICAgUGhvdG8gcGhvdG8gPSAyOwogICAgIH0KICAgICBtZXNzYWdlIFVz
ZXIgewogICAgICAgc3RyaW5nIGRpc3BsYXlfbmFtZSA9IDE7CiAgICAgICBzdHJpbmcgYWRk
cmVzcyA9IDI7CiAgICAgfQoKIEluIHByb3RvIGEgZmllbGQgbWFzayBmb3IgYFByb2ZpbGVg
IG1heSBsb29rIGFzIHN1Y2g6CgogICAgIG1hc2sgewogICAgICAgcGF0aHM6ICJ1c2VyLmRp
c3BsYXlfbmFtZSIKICAgICAgIHBhdGhzOiAicGhvdG8iCiAgICAgfQoKIEluIEpTT04sIHRo
ZSBzYW1lIG1hc2sgaXMgcmVwcmVzZW50ZWQgYXMgYmVsb3c6CgogICAgIHsKICAgICAgIG1h
c2s6ICJ1c2VyLmRpc3BsYXlOYW1lLHBob3RvIgogICAgIH0KCiAjIEZpZWxkIE1hc2tzIGFu
ZCBPbmVvZiBGaWVsZHMKCiBGaWVsZCBtYXNrcyB0cmVhdCBmaWVsZHMgaW4gb25lb2ZzIGp1
c3QgYXMgcmVndWxhciBmaWVsZHMuIENvbnNpZGVyIHRoZQogZm9sbG93aW5nIG1lc3NhZ2U6
CgogICAgIG1lc3NhZ2UgU2FtcGxlTWVzc2FnZSB7CiAgICAgICBvbmVvZiB0ZXN0X29uZW9m
IHsKICAgICAgICAgc3RyaW5nIG5hbWUgPSA0OwogICAgICAgICBTdWJNZXNzYWdlIHN1Yl9t
ZXNzYWdlID0gOTsKICAgICAgIH0KICAgICB9CgogVGhlIGZpZWxkIG1hc2sgY2FuIGJlOgoK
ICAgICBtYXNrIHsKICAgICAgIHBhdGhzOiAibmFtZSIKICAgICB9CgogT3I6CgogICAgIG1h
c2sgewogICAgICAgcGF0aHM6ICJzdWJfbWVzc2FnZSIKICAgICB9CgogTm90ZSB0aGF0IG9u
ZW9mIHR5cGUgbmFtZXMgKCJ0ZXN0X29uZW9mIiBpbiB0aGlzIGNhc2UpIGNhbm5vdCBiZSB1
c2VkIGluCiBwYXRocy4KCiAjIyBGaWVsZCBNYXNrIFZlcmlmaWNhdGlvbgoKIFRoZSBpbXBs
ZW1lbnRhdGlvbiBvZiBhbnkgQVBJIG1ldGhvZCB3aGljaCBoYXMgYSBGaWVsZE1hc2sgdHlw
ZSBmaWVsZCBpbiB0aGUKIHJlcXVlc3Qgc2hvdWxkIHZlcmlmeSB0aGUgaW5jbHVkZWQgZmll
bGQgcGF0aHMsIGFuZCByZXR1cm4gYW4KIGBJTlZBTElEX0FSR1VNRU5UYCBlcnJvciBpZiBh
bnkgcGF0aCBpcyB1bm1hcHBhYmxlLgoKCwoDBAABEgTxAQgRCiwKBAQAAgASBPMBAhwaHiBU
aGUgc2V0IG9mIGZpZWxkIG1hc2sgcGF0aHMuCgoNCgUEAAIABBIE8wECCgoNCgUEAAIABRIE
8wELEQoNCgUEAAIAARIE8wESFwoNCgUEAAIAAxIE8wEaG2IGcHJvdG8z
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Protobuf::FieldMask::FieldMask ===
    # Fields for FieldMask
    # Field: paths Type: 9 ()

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Protobuf::FieldMask - Compiled Protocol Buffers messages for google/protobuf/field_mask.proto

=head1 SYNOPSIS

    use Google::Protobuf::FieldMask;

    my $msg = Google::Protobuf::FieldMask::FieldMask->new({
        paths => $paths,
    });

    # Read or update a field
    my $val = $msg->paths();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Protobuf::FieldMask::FieldMask->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/protobuf/field_mask.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Protobuf::FieldMask::FieldMask

`FieldMask` represents a set of symbolic field paths, for example:

    paths: "f.a"
    paths: "f.b.d"

Here `f` represents a field in some root message, `a` and `b`
fields in the message found in `f`, and `d` a field found in the
message in `f.b`.

Field masks are used to specify a subset of fields that should be
returned by a get operation or modified by an update operation.
Field masks also have a custom JSON encoding (see below).

# Field Masks in Projections

When used in the context of a projection, a response message or
sub-message is filtered by the API to only contain those fields as
specified in the mask. For example, if the mask in the previous
example is applied to a response message as follows:

    f {
      a : 22
      b {
        d : 1
        x : 2
      }
      y : 13
    }
    z: 8

The result will not contain specific values for fields x,y and z
(their value will be set to the default, and omitted in proto text
output):


    f {
      a : 22
      b {
        d : 1
      }
    }

A repeated field is not allowed except at the last position of a
paths string.

If a FieldMask object is not present in a get operation, the
operation applies to all fields (as if a FieldMask of all fields
had been specified).

Note that a field mask does not necessarily apply to the
top-level response message. In case of a REST get operation, the
field mask applies directly to the response, but in case of a REST
list operation, the mask instead applies to each individual message
in the returned resource list. In case of a REST custom method,
other definitions may be used. Where the mask applies will be
clearly documented together with its declaration in the API.  In
any case, the effect on the returned resource/resources is required
behavior for APIs.

# Field Masks in Update Operations

A field mask in update operations specifies which fields of the
targeted resource are going to be updated. The API is required
to only change the values of the fields as specified in the mask
and leave the others untouched. If a resource is passed in to
describe the updated values, the API ignores the values of all
fields not covered by the mask.

If a repeated field is specified for an update operation, new values will
be appended to the existing repeated field in the target resource. Note that
a repeated field is only allowed in the last position of a `paths` string.

If a sub-message is specified in the last position of the field mask for an
update operation, then new value will be merged into the existing sub-message
in the target resource.

For example, given the target message:

    f {
      b {
        d: 1
        x: 2
      }
      c: [1]
    }

And an update message:

    f {
      b {
        d: 10
      }
      c: [2]
    }

then if the field mask is:

 paths: ["f.b", "f.c"]

then the result will be:

    f {
      b {
        d: 10
        x: 2
      }
      c: [1, 2]
    }

An implementation may provide options to override this default behavior for
repeated and message fields.

In order to reset a field's value to the default, the field must
be in the mask and set to the default value in the provided resource.
Hence, in order to reset all fields of a resource, provide a default
instance of the resource and set all fields in the mask, or do
not provide a mask as described below.

If a field mask is not present on update, the operation applies to
all fields (as if a field mask of all fields has been specified).
Note that in the presence of schema evolution, this may mean that
fields the client does not know and has therefore not filled into
the request will be reset to their default. If this is unwanted
behavior, a specific service may require a client to always specify
a field mask, producing an error if not.

As with get operations, the location of the resource which
describes the updated values in the request message depends on the
operation kind. In any case, the effect of the field mask is
required to be honored by the API.

## Considerations for HTTP REST

The HTTP kind of an update operation which uses a field mask must
be set to PATCH instead of PUT in order to satisfy HTTP semantics
(PUT must only be used for full updates).

# JSON Encoding of Field Masks

In JSON, a field mask is encoded as a single string where paths are
separated by a comma. Fields name in each path are converted
to/from lower-camel naming conventions.

As an example, consider the following message declarations:

    message Profile {
      User user = 1;
      Photo photo = 2;
    }
    message User {
      string display_name = 1;
      string address = 2;
    }

In proto a field mask for `Profile` may look as such:

    mask {
      paths: "user.display_name"
      paths: "photo"
    }

In JSON, the same mask is represented as below:

    {
      mask: "user.displayName,photo"
    }

# Field Masks and Oneof Fields

Field masks treat fields in oneofs just as regular fields. Consider the
following message:

    message SampleMessage {
      oneof test_oneof {
        string name = 4;
        SubMessage sub_message = 9;
      }
    }

The field mask can be:

    mask {
      paths: "name"
    }

Or:

    mask {
      paths: "sub_message"
    }

Note that oneof type names ("test_oneof" in this case) cannot be used in
paths.

## Field Mask Verification

The implementation of any API method which has a FieldMask type field in the
request should verify the included field paths, and return an
`INVALID_ARGUMENT` error if any path is unmappable.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->paths() >> / C<< $msg->paths($value) >>

Type: C<String>

The set of field mask paths.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Protobuf::FieldMask::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
