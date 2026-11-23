package Google::Protobuf::Type;

use strict;
use warnings;

our $VERSION = '0.14';

use Protobuf::Message;
use Protobuf::DescriptorPool;
use Protobuf::Internal qw(:all);
use MIME::Base64;

BEGIN {
    eval { require Google::Protobuf::Any };
    eval { require Google::Protobuf::SourceContext };
    my $descriptor_b64 = <<'EOF';
Chpnb29nbGUvcHJvdG9idWYvdHlwZS5wcm90bxIPZ29vZ2xlLnByb3RvYnVmGhlnb29nbGUv
cHJvdG9idWYvYW55LnByb3RvGiRnb29nbGUvcHJvdG9idWYvc291cmNlX2NvbnRleHQucHJv
dG8ijQIKBFR5cGUSEgoEbmFtZRgBIAEoCVIEbmFtZRIuCgZmaWVsZHMYAiADKAsyFi5nb29n
bGUucHJvdG9idWYuRmllbGRSBmZpZWxkcxIWCgZvbmVvZnMYAyADKAlSBm9uZW9mcxIxCgdv
cHRpb25zGAQgAygLMhcuZ29vZ2xlLnByb3RvYnVmLk9wdGlvblIHb3B0aW9ucxJFCg5zb3Vy
Y2VfY29udGV4dBgFIAEoCzIeLmdvb2dsZS5wcm90b2J1Zi5Tb3VyY2VDb250ZXh0Ug1zb3Vy
Y2VDb250ZXh0Ei8KBnN5bnRheBgGIAEoDjIXLmdvb2dsZS5wcm90b2J1Zi5TeW50YXhSBnN5
bnRheCK0BgoFRmllbGQSLwoEa2luZBgBIAEoDjIbLmdvb2dsZS5wcm90b2J1Zi5GaWVsZC5L
aW5kUgRraW5kEkQKC2NhcmRpbmFsaXR5GAIgASgOMiIuZ29vZ2xlLnByb3RvYnVmLkZpZWxk
LkNhcmRpbmFsaXR5UgtjYXJkaW5hbGl0eRIWCgZudW1iZXIYAyABKAVSBm51bWJlchISCgRu
YW1lGAQgASgJUgRuYW1lEhkKCHR5cGVfdXJsGAYgASgJUgd0eXBlVXJsEh8KC29uZW9mX2lu
ZGV4GAcgASgFUgpvbmVvZkluZGV4EhYKBnBhY2tlZBgIIAEoCFIGcGFja2VkEjEKB29wdGlv
bnMYCSADKAsyFy5nb29nbGUucHJvdG9idWYuT3B0aW9uUgdvcHRpb25zEhsKCWpzb25fbmFt
ZRgKIAEoCVIIanNvbk5hbWUSIwoNZGVmYXVsdF92YWx1ZRgLIAEoCVIMZGVmYXVsdFZhbHVl
IsgCCgRLaW5kEhAKDFRZUEVfVU5LTk9XThAAEg8KC1RZUEVfRE9VQkxFEAESDgoKVFlQRV9G
TE9BVBACEg4KClRZUEVfSU5UNjQQAxIPCgtUWVBFX1VJTlQ2NBAEEg4KClRZUEVfSU5UMzIQ
BRIQCgxUWVBFX0ZJWEVENjQQBhIQCgxUWVBFX0ZJWEVEMzIQBxINCglUWVBFX0JPT0wQCBIP
CgtUWVBFX1NUUklORxAJEg4KClRZUEVfR1JPVVAQChIQCgxUWVBFX01FU1NBR0UQCxIOCgpU
WVBFX0JZVEVTEAwSDwoLVFlQRV9VSU5UMzIQDRINCglUWVBFX0VOVU0QDhIRCg1UWVBFX1NG
SVhFRDMyEA8SEQoNVFlQRV9TRklYRUQ2NBAQEg8KC1RZUEVfU0lOVDMyEBESDwoLVFlQRV9T
SU5UNjQQEiJ0CgtDYXJkaW5hbGl0eRIXChNDQVJESU5BTElUWV9VTktOT1dOEAASGAoUQ0FS
RElOQUxJVFlfT1BUSU9OQUwQARIYChRDQVJESU5BTElUWV9SRVFVSVJFRBACEhgKFENBUkRJ
TkFMSVRZX1JFUEVBVEVEEAMi/wEKBEVudW0SEgoEbmFtZRgBIAEoCVIEbmFtZRI4CgllbnVt
dmFsdWUYAiADKAsyGi5nb29nbGUucHJvdG9idWYuRW51bVZhbHVlUgllbnVtdmFsdWUSMQoH
b3B0aW9ucxgDIAMoCzIXLmdvb2dsZS5wcm90b2J1Zi5PcHRpb25SB29wdGlvbnMSRQoOc291
cmNlX2NvbnRleHQYBCABKAsyHi5nb29nbGUucHJvdG9idWYuU291cmNlQ29udGV4dFINc291
cmNlQ29udGV4dBIvCgZzeW50YXgYBSABKA4yFy5nb29nbGUucHJvdG9idWYuU3ludGF4UgZz
eW50YXgiagoJRW51bVZhbHVlEhIKBG5hbWUYASABKAlSBG5hbWUSFgoGbnVtYmVyGAIgASgF
UgZudW1iZXISMQoHb3B0aW9ucxgDIAMoCzIXLmdvb2dsZS5wcm90b2J1Zi5PcHRpb25SB29w
dGlvbnMiSAoGT3B0aW9uEhIKBG5hbWUYASABKAlSBG5hbWUSKgoFdmFsdWUYAiABKAsyFC5n
b29nbGUucHJvdG9idWYuQW55UgV2YWx1ZSouCgZTeW50YXgSEQoNU1lOVEFYX1BST1RPMhAA
EhEKDVNZTlRBWF9QUk9UTzMQAUJ7ChNjb20uZ29vZ2xlLnByb3RvYnVmQglUeXBlUHJvdG9Q
AVotZ29vZ2xlLmdvbGFuZy5vcmcvcHJvdG9idWYvdHlwZXMva25vd24vdHlwZXBi+AEBogID
R1BCqgIeR29vZ2xlLlByb3RvYnVmLldlbGxLbm93blR5cGVzSsM4CgcSBR4AugEBCswMCgEM
EgMeABIywQwgUHJvdG9jb2wgQnVmZmVycyAtIEdvb2dsZSdzIGRhdGEgaW50ZXJjaGFuZ2Ug
Zm9ybWF0CiBDb3B5cmlnaHQgMjAwOCBHb29nbGUgSW5jLiAgQWxsIHJpZ2h0cyByZXNlcnZl
ZC4KIGh0dHBzOi8vZGV2ZWxvcGVycy5nb29nbGUuY29tL3Byb3RvY29sLWJ1ZmZlcnMvCgog
UmVkaXN0cmlidXRpb24gYW5kIHVzZSBpbiBzb3VyY2UgYW5kIGJpbmFyeSBmb3Jtcywgd2l0
aCBvciB3aXRob3V0CiBtb2RpZmljYXRpb24sIGFyZSBwZXJtaXR0ZWQgcHJvdmlkZWQgdGhh
dCB0aGUgZm9sbG93aW5nIGNvbmRpdGlvbnMgYXJlCiBtZXQ6CgogICAgICogUmVkaXN0cmli
dXRpb25zIG9mIHNvdXJjZSBjb2RlIG11c3QgcmV0YWluIHRoZSBhYm92ZSBjb3B5cmlnaHQK
IG5vdGljZSwgdGhpcyBsaXN0IG9mIGNvbmRpdGlvbnMgYW5kIHRoZSBmb2xsb3dpbmcgZGlz
Y2xhaW1lci4KICAgICAqIFJlZGlzdHJpYnV0aW9ucyBpbiBiaW5hcnkgZm9ybSBtdXN0IHJl
cHJvZHVjZSB0aGUgYWJvdmUKIGNvcHlyaWdodCBub3RpY2UsIHRoaXMgbGlzdCBvZiBjb25k
aXRpb25zIGFuZCB0aGUgZm9sbG93aW5nIGRpc2NsYWltZXIKIGluIHRoZSBkb2N1bWVudGF0
aW9uIGFuZC9vciBvdGhlciBtYXRlcmlhbHMgcHJvdmlkZWQgd2l0aCB0aGUKIGRpc3RyaWJ1
dGlvbi4KICAgICAqIE5laXRoZXIgdGhlIG5hbWUgb2YgR29vZ2xlIEluYy4gbm9yIHRoZSBu
YW1lcyBvZiBpdHMKIGNvbnRyaWJ1dG9ycyBtYXkgYmUgdXNlZCB0byBlbmRvcnNlIG9yIHBy
b21vdGUgcHJvZHVjdHMgZGVyaXZlZCBmcm9tCiB0aGlzIHNvZnR3YXJlIHdpdGhvdXQgc3Bl
Y2lmaWMgcHJpb3Igd3JpdHRlbiBwZXJtaXNzaW9uLgoKIFRISVMgU09GVFdBUkUgSVMgUFJP
VklERUQgQlkgVEhFIENPUFlSSUdIVCBIT0xERVJTIEFORCBDT05UUklCVVRPUlMKICJBUyBJ
UyIgQU5EIEFOWSBFWFBSRVNTIE9SIElNUExJRUQgV0FSUkFOVElFUywgSU5DTFVESU5HLCBC
VVQgTk9UCiBMSU1JVEVEIFRPLCBUSEUgSU1QTElFRCBXQVJSQU5USUVTIE9GIE1FUkNIQU5U
QUJJTElUWSBBTkQgRklUTkVTUyBGT1IKIEEgUEFSVElDVUxBUiBQVVJQT1NFIEFSRSBESVND
TEFJTUVELiBJTiBOTyBFVkVOVCBTSEFMTCBUSEUgQ09QWVJJR0hUCiBPV05FUiBPUiBDT05U
UklCVVRPUlMgQkUgTElBQkxFIEZPUiBBTlkgRElSRUNULCBJTkRJUkVDVCwgSU5DSURFTlRB
TCwKIFNQRUNJQUwsIEVYRU1QTEFSWSwgT1IgQ09OU0VRVUVOVElBTCBEQU1BR0VTIChJTkNM
VURJTkcsIEJVVCBOT1QKIExJTUlURUQgVE8sIFBST0NVUkVNRU5UIE9GIFNVQlNUSVRVVEUg
R09PRFMgT1IgU0VSVklDRVM7IExPU1MgT0YgVVNFLAogREFUQSwgT1IgUFJPRklUUzsgT1Ig
QlVTSU5FU1MgSU5URVJSVVBUSU9OKSBIT1dFVkVSIENBVVNFRCBBTkQgT04gQU5ZCiBUSEVP
UlkgT0YgTElBQklMSVRZLCBXSEVUSEVSIElOIENPTlRSQUNULCBTVFJJQ1QgTElBQklMSVRZ
LCBPUiBUT1JUCiAoSU5DTFVESU5HIE5FR0xJR0VOQ0UgT1IgT1RIRVJXSVNFKSBBUklTSU5H
IElOIEFOWSBXQVkgT1VUIE9GIFRIRSBVU0UKIE9GIFRISVMgU09GVFdBUkUsIEVWRU4gSUYg
QURWSVNFRCBPRiBUSEUgUE9TU0lCSUxJVFkgT0YgU1VDSCBEQU1BR0UuCgoICgECEgMgABgK
CQoCAwASAyIAIwoJCgIDARIDIwAuCggKAQgSAyUAOwoJCgIIJRIDJQA7CggKAQgSAyYAHwoJ
CgIIHxIDJgAfCggKAQgSAycALAoJCgIIARIDJwAsCggKAQgSAygAKgoJCgIICBIDKAAqCggK
AQgSAykAIgoJCgIIChIDKQAiCggKAQgSAyoAIQoJCgIIJBIDKgAhCggKAQgSAysARAoJCgII
CxIDKwBECi0KAgQAEgQuADsBGiEgQSBwcm90b2NvbCBidWZmZXIgbWVzc2FnZSB0eXBlLgoK
CgoDBAABEgMuCAwKMAoEBAACABIDMAISGiMgVGhlIGZ1bGx5IHF1YWxpZmllZCBtZXNzYWdl
IG5hbWUuCgoMCgUEAAIABRIDMAIICgwKBQQAAgABEgMwCQ0KDAoFBAACAAMSAzAQEQoiCgQE
AAIBEgMyAhwaFSBUaGUgbGlzdCBvZiBmaWVsZHMuCgoMCgUEAAIBBBIDMgIKCgwKBQQAAgEG
EgMyCxAKDAoFBAACAQESAzIRFwoMCgUEAAIBAxIDMhobCk8KBAQAAgISAzQCHRpCIFRoZSBs
aXN0IG9mIHR5cGVzIGFwcGVhcmluZyBpbiBgb25lb2ZgIGRlZmluaXRpb25zIGluIHRoaXMg
dHlwZS4KCgwKBQQAAgIEEgM0AgoKDAoFBAACAgUSAzQLEQoMCgUEAAICARIDNBIYCgwKBQQA
AgIDEgM0GxwKKwoEBAACAxIDNgIeGh4gVGhlIHByb3RvY29sIGJ1ZmZlciBvcHRpb25zLgoK
DAoFBAACAwQSAzYCCgoMCgUEAAIDBhIDNgsRCgwKBQQAAgMBEgM2EhkKDAoFBAACAwMSAzYc
HQoiCgQEAAIEEgM4AiMaFSBUaGUgc291cmNlIGNvbnRleHQuCgoMCgUEAAIEBhIDOAIPCgwK
BQQAAgQBEgM4EB4KDAoFBAACBAMSAzghIgohCgQEAAIFEgM6AhQaFCBUaGUgc291cmNlIHN5
bnRheC4KCgwKBQQAAgUGEgM6AggKDAoFBAACBQESAzoJDwoMCgUEAAIFAxIDOhITCjAKAgQB
EgU+AIsBARojIEEgc2luZ2xlIGZpZWxkIG9mIGEgbWVzc2FnZSB0eXBlLgoKCgoDBAEBEgM+
CA0KIgoEBAEEABIEQAJnAxoUIEJhc2ljIGZpZWxkIHR5cGVzLgoKDAoFBAEEAAESA0AHCwok
CgYEAQQAAgASA0IEFRoVIEZpZWxkIHR5cGUgdW5rbm93bi4KCg4KBwQBBAACAAESA0IEEAoO
CgcEAQQAAgACEgNCExQKIwoGBAEEAAIBEgNEBBQaFCBGaWVsZCB0eXBlIGRvdWJsZS4KCg4K
BwQBBAACAQESA0QEDwoOCgcEAQQAAgECEgNEEhMKIgoGBAEEAAICEgNGBBMaEyBGaWVsZCB0
eXBlIGZsb2F0LgoKDgoHBAEEAAICARIDRgQOCg4KBwQBBAACAgISA0YREgoiCgYEAQQAAgMS
A0gEExoTIEZpZWxkIHR5cGUgaW50NjQuCgoOCgcEAQQAAgMBEgNIBA4KDgoHBAEEAAIDAhID
SBESCiMKBgQBBAACBBIDSgQUGhQgRmllbGQgdHlwZSB1aW50NjQuCgoOCgcEAQQAAgQBEgNK
BA8KDgoHBAEEAAIEAhIDShITCiIKBgQBBAACBRIDTAQTGhMgRmllbGQgdHlwZSBpbnQzMi4K
Cg4KBwQBBAACBQESA0wEDgoOCgcEAQQAAgUCEgNMERIKJAoGBAEEAAIGEgNOBBUaFSBGaWVs
ZCB0eXBlIGZpeGVkNjQuCgoOCgcEAQQAAgYBEgNOBBAKDgoHBAEEAAIGAhIDThMUCiQKBgQB
BAACBxIDUAQVGhUgRmllbGQgdHlwZSBmaXhlZDMyLgoKDgoHBAEEAAIHARIDUAQQCg4KBwQB
BAACBwISA1ATFAohCgYEAQQAAggSA1IEEhoSIEZpZWxkIHR5cGUgYm9vbC4KCg4KBwQBBAAC
CAESA1IEDQoOCgcEAQQAAggCEgNSEBEKIwoGBAEEAAIJEgNUBBQaFCBGaWVsZCB0eXBlIHN0
cmluZy4KCg4KBwQBBAACCQESA1QEDwoOCgcEAQQAAgkCEgNUEhMKRgoGBAEEAAIKEgNWBBQa
NyBGaWVsZCB0eXBlIGdyb3VwLiBQcm90bzIgc3ludGF4IG9ubHksIGFuZCBkZXByZWNhdGVk
LgoKDgoHBAEEAAIKARIDVgQOCg4KBwQBBAACCgISA1YREwokCgYEAQQAAgsSA1gEFhoVIEZp
ZWxkIHR5cGUgbWVzc2FnZS4KCg4KBwQBBAACCwESA1gEEAoOCgcEAQQAAgsCEgNYExUKIgoG
BAEEAAIMEgNaBBQaEyBGaWVsZCB0eXBlIGJ5dGVzLgoKDgoHBAEEAAIMARIDWgQOCg4KBwQB
BAACDAISA1oREwojCgYEAQQAAg0SA1wEFRoUIEZpZWxkIHR5cGUgdWludDMyLgoKDgoHBAEE
AAINARIDXAQPCg4KBwQBBAACDQISA1wSFAohCgYEAQQAAg4SA14EExoSIEZpZWxkIHR5cGUg
ZW51bS4KCg4KBwQBBAACDgESA14EDQoOCgcEAQQAAg4CEgNeEBIKJQoGBAEEAAIPEgNgBBca
FiBGaWVsZCB0eXBlIHNmaXhlZDMyLgoKDgoHBAEEAAIPARIDYAQRCg4KBwQBBAACDwISA2AU
FgolCgYEAQQAAhASA2IEFxoWIEZpZWxkIHR5cGUgc2ZpeGVkNjQuCgoOCgcEAQQAAhABEgNi
BBEKDgoHBAEEAAIQAhIDYhQWCiMKBgQBBAACERIDZAQVGhQgRmllbGQgdHlwZSBzaW50MzIu
CgoOCgcEAQQAAhEBEgNkBA8KDgoHBAEEAAIRAhIDZBIUCiMKBgQBBAACEhIDZgQVGhQgRmll
bGQgdHlwZSBzaW50NjQuCgoOCgcEAQQAAhIBEgNmBA8KDgoHBAEEAAISAhIDZhIUCkMKBAQB
BAESBGoCcwMaNSBXaGV0aGVyIGEgZmllbGQgaXMgb3B0aW9uYWwsIHJlcXVpcmVkLCBvciBy
ZXBlYXRlZC4KCgwKBQQBBAEBEgNqBxIKNQoGBAEEAQIAEgNsBBwaJiBGb3IgZmllbGRzIHdp
dGggdW5rbm93biBjYXJkaW5hbGl0eS4KCg4KBwQBBAECAAESA2wEFwoOCgcEAQQBAgACEgNs
GhsKJQoGBAEEAQIBEgNuBB0aFiBGb3Igb3B0aW9uYWwgZmllbGRzLgoKDgoHBAEEAQIBARID
bgQYCg4KBwQBBAECAQISA24bHAo5CgYEAQQBAgISA3AEHRoqIEZvciByZXF1aXJlZCBmaWVs
ZHMuIFByb3RvMiBzeW50YXggb25seS4KCg4KBwQBBAECAgESA3AEGAoOCgcEAQQBAgICEgNw
GxwKJQoGBAEEAQIDEgNyBB0aFiBGb3IgcmVwZWF0ZWQgZmllbGRzLgoKDgoHBAEEAQIDARID
cgQYCg4KBwQBBAECAwISA3IbHAoeCgQEAQIAEgN2AhAaESBUaGUgZmllbGQgdHlwZS4KCgwK
BQQBAgAGEgN2AgYKDAoFBAECAAESA3YHCwoMCgUEAQIAAxIDdg4PCiUKBAQBAgESA3gCHhoY
IFRoZSBmaWVsZCBjYXJkaW5hbGl0eS4KCgwKBQQBAgEGEgN4Ag0KDAoFBAECAQESA3gOGQoM
CgUEAQIBAxIDeBwdCiAKBAQBAgISA3oCExoTIFRoZSBmaWVsZCBudW1iZXIuCgoMCgUEAQIC
BRIDegIHCgwKBQQBAgIBEgN6CA4KDAoFBAECAgMSA3oREgoeCgQEAQIDEgN8AhIaESBUaGUg
ZmllbGQgbmFtZS4KCgwKBQQBAgMFEgN8AggKDAoFBAECAwESA3wJDQoMCgUEAQIDAxIDfBAR
CpYBCgQEAQIEEgN/AhYaiAEgVGhlIGZpZWxkIHR5cGUgVVJMLCB3aXRob3V0IHRoZSBzY2hl
bWUsIGZvciBtZXNzYWdlIG9yIGVudW1lcmF0aW9uCiB0eXBlcy4gRXhhbXBsZTogYCJ0eXBl
Lmdvb2dsZWFwaXMuY29tL2dvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXAiYC4KCgwKBQQBAgQF
EgN/AggKDAoFBAECBAESA38JEQoMCgUEAQIEAxIDfxQVCqUBCgQEAQIFEgSCAQIYGpYBIFRo
ZSBpbmRleCBvZiB0aGUgZmllbGQgdHlwZSBpbiBgVHlwZS5vbmVvZnNgLCBmb3IgbWVzc2Fn
ZSBvciBlbnVtZXJhdGlvbgogdHlwZXMuIFRoZSBmaXJzdCB0eXBlIGhhcyBpbmRleCAxOyB6
ZXJvIG1lYW5zIHRoZSB0eXBlIGlzIG5vdCBpbiB0aGUgbGlzdC4KCg0KBQQBAgUFEgSCAQIH
Cg0KBQQBAgUBEgSCAQgTCg0KBQQBAgUDEgSCARYXCkYKBAQBAgYSBIQBAhIaOCBXaGV0aGVy
IHRvIHVzZSBhbHRlcm5hdGl2ZSBwYWNrZWQgd2lyZSByZXByZXNlbnRhdGlvbi4KCg0KBQQB
AgYFEgSEAQIGCg0KBQQBAgYBEgSEAQcNCg0KBQQBAgYDEgSEARARCiwKBAQBAgcSBIYBAh4a
HiBUaGUgcHJvdG9jb2wgYnVmZmVyIG9wdGlvbnMuCgoNCgUEAQIHBBIEhgECCgoNCgUEAQIH
BhIEhgELEQoNCgUEAQIHARIEhgESGQoNCgUEAQIHAxIEhgEcHQokCgQEAQIIEgSIAQIYGhYg
VGhlIGZpZWxkIEpTT04gbmFtZS4KCg0KBQQBAggFEgSIAQIICg0KBQQBAggBEgSIAQkSCg0K
BQQBAggDEgSIARUXClgKBAQBAgkSBIoBAhwaSiBUaGUgc3RyaW5nIHZhbHVlIG9mIHRoZSBk
ZWZhdWx0IHZhbHVlIG9mIHRoaXMgZmllbGQuIFByb3RvMiBzeW50YXggb25seS4KCg0KBQQB
AgkFEgSKAQIICg0KBQQBAgkBEgSKAQkWCg0KBQQBAgkDEgSKARkbCiUKAgQCEgaOAQCZAQEa
FyBFbnVtIHR5cGUgZGVmaW5pdGlvbi4KCgsKAwQCARIEjgEIDAofCgQEAgIAEgSQAQISGhEg
RW51bSB0eXBlIG5hbWUuCgoNCgUEAgIABRIEkAECCAoNCgUEAgIAARIEkAEJDQoNCgUEAgIA
AxIEkAEQEQonCgQEAgIBEgSSAQIjGhkgRW51bSB2YWx1ZSBkZWZpbml0aW9ucy4KCg0KBQQC
AgEEEgSSAQIKCg0KBQQCAgEGEgSSAQsUCg0KBQQCAgEBEgSSARUeCg0KBQQCAgEDEgSSASEi
CigKBAQCAgISBJQBAh4aGiBQcm90b2NvbCBidWZmZXIgb3B0aW9ucy4KCg0KBQQCAgIEEgSU
AQIKCg0KBQQCAgIGEgSUAQsRCg0KBQQCAgIBEgSUARIZCg0KBQQCAgIDEgSUARwdCiMKBAQC
AgMSBJYBAiMaFSBUaGUgc291cmNlIGNvbnRleHQuCgoNCgUEAgIDBhIElgECDwoNCgUEAgID
ARIElgEQHgoNCgUEAgIDAxIElgEhIgoiCgQEAgIEEgSYAQIUGhQgVGhlIHNvdXJjZSBzeW50
YXguCgoNCgUEAgIEBhIEmAECCAoNCgUEAgIEARIEmAEJDwoNCgUEAgIEAxIEmAESEwomCgIE
AxIGnAEAowEBGhggRW51bSB2YWx1ZSBkZWZpbml0aW9uLgoKCwoDBAMBEgScAQgRCiAKBAQD
AgASBJ4BAhIaEiBFbnVtIHZhbHVlIG5hbWUuCgoNCgUEAwIABRIEngECCAoNCgUEAwIAARIE
ngEJDQoNCgUEAwIAAxIEngEQEQoiCgQEAwIBEgSgAQITGhQgRW51bSB2YWx1ZSBudW1iZXIu
CgoNCgUEAwIBBRIEoAECBwoNCgUEAwIBARIEoAEIDgoNCgUEAwIBAxIEoAEREgooCgQEAwIC
EgSiAQIeGhogUHJvdG9jb2wgYnVmZmVyIG9wdGlvbnMuCgoNCgUEAwICBBIEogECCgoNCgUE
AwICBhIEogELEQoNCgUEAwICARIEogESGQoNCgUEAwICAxIEogEcHQpnCgIEBBIGpwEAsgEB
GlkgQSBwcm90b2NvbCBidWZmZXIgb3B0aW9uLCB3aGljaCBjYW4gYmUgYXR0YWNoZWQgdG8g
YSBtZXNzYWdlLCBmaWVsZCwKIGVudW1lcmF0aW9uLCBldGMuCgoLCgMEBAESBKcBCA4K/AEK
BAQEAgASBKwBAhIa7QEgVGhlIG9wdGlvbidzIG5hbWUuIEZvciBwcm90b2J1ZiBidWlsdC1p
biBvcHRpb25zIChvcHRpb25zIGRlZmluZWQgaW4KIGRlc2NyaXB0b3IucHJvdG8pLCB0aGlz
IGlzIHRoZSBzaG9ydCBuYW1lLiBGb3IgZXhhbXBsZSwgYCJtYXBfZW50cnkiYC4KIEZvciBj
dXN0b20gb3B0aW9ucywgaXQgc2hvdWxkIGJlIHRoZSBmdWxseS1xdWFsaWZpZWQgbmFtZS4g
Rm9yIGV4YW1wbGUsCiBgImdvb2dsZS5hcGkuaHR0cCJgLgoKDQoFBAQCAAUSBKwBAggKDQoF
BAQCAAESBKwBCQ0KDQoFBAQCAAMSBKwBEBEKoAIKBAQEAgESBLEBAhAakQIgVGhlIG9wdGlv
bidzIHZhbHVlIHBhY2tlZCBpbiBhbiBBbnkgbWVzc2FnZS4gSWYgdGhlIHZhbHVlIGlzIGEg
cHJpbWl0aXZlLAogdGhlIGNvcnJlc3BvbmRpbmcgd3JhcHBlciB0eXBlIGRlZmluZWQgaW4g
Z29vZ2xlL3Byb3RvYnVmL3dyYXBwZXJzLnByb3RvCiBzaG91bGQgYmUgdXNlZC4gSWYgdGhl
IHZhbHVlIGlzIGFuIGVudW0sIGl0IHNob3VsZCBiZSBzdG9yZWQgYXMgYW4gaW50MzIKIHZh
bHVlIHVzaW5nIHRoZSBnb29nbGUucHJvdG9idWYuSW50MzJWYWx1ZSB0eXBlLgoKDQoFBAQC
AQYSBLEBAgUKDQoFBAQCAQESBLEBBgsKDQoFBAQCAQMSBLEBDg8KSQoCBQASBrUBALoBARo7
IFRoZSBzeW50YXggaW4gd2hpY2ggYSBwcm90b2NvbCBidWZmZXIgZWxlbWVudCBpcyBkZWZp
bmVkLgoKCwoDBQABEgS1AQULCiAKBAUAAgASBLcBAhQaEiBTeW50YXggYHByb3RvMmAuCgoN
CgUFAAIAARIEtwECDwoNCgUFAAIAAhIEtwESEwogCgQFAAIBEgS5AQIUGhIgU3ludGF4IGBw
cm90bzNgLgoKDQoFBQACAQESBLkBAg8KDQoFBQACAQISBLkBEhNiBnByb3RvMw==
EOF
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

# Message definitions

# === Message: Google::Protobuf::Type::Type ===
    # Fields for Type
    # Field: name Type: 9 ()
    # Field: fields Type: 11 (.google.protobuf.Field)
    # Field: oneofs Type: 9 ()
    # Field: options Type: 11 (.google.protobuf.Option)
    # Field: source_context Type: 11 (.google.protobuf.SourceContext)
    # Field: syntax Type: 14 (.google.protobuf.Syntax)

# === Message: Google::Protobuf::Type::Field ===
    # Fields for Field
    # Field: kind Type: 14 (.google.protobuf.Field.Kind)
    # Field: cardinality Type: 14 (.google.protobuf.Field.Cardinality)
    # Field: number Type: 5 ()
    # Field: name Type: 9 ()
    # Field: type_url Type: 9 ()
    # Field: oneof_index Type: 5 ()
    # Field: packed Type: 8 ()
    # Field: options Type: 11 (.google.protobuf.Option)
    # Field: json_name Type: 9 ()
    # Field: default_value Type: 9 ()

# Enum: Field::Kind
our $Field_TYPE_UNKNOWN = 0;
our $Field_TYPE_DOUBLE = 1;
our $Field_TYPE_FLOAT = 2;
our $Field_TYPE_INT64 = 3;
our $Field_TYPE_UINT64 = 4;
our $Field_TYPE_INT32 = 5;
our $Field_TYPE_FIXED64 = 6;
our $Field_TYPE_FIXED32 = 7;
our $Field_TYPE_BOOL = 8;
our $Field_TYPE_STRING = 9;
our $Field_TYPE_GROUP = 10;
our $Field_TYPE_MESSAGE = 11;
our $Field_TYPE_BYTES = 12;
our $Field_TYPE_UINT32 = 13;
our $Field_TYPE_ENUM = 14;
our $Field_TYPE_SFIXED32 = 15;
our $Field_TYPE_SFIXED64 = 16;
our $Field_TYPE_SINT32 = 17;
our $Field_TYPE_SINT64 = 18;

# Enum: Field::Cardinality
our $Field_CARDINALITY_UNKNOWN = 0;
our $Field_CARDINALITY_OPTIONAL = 1;
our $Field_CARDINALITY_REQUIRED = 2;
our $Field_CARDINALITY_REPEATED = 3;

# === Message: Google::Protobuf::Type::Enum ===
    # Fields for Enum
    # Field: name Type: 9 ()
    # Field: enumvalue Type: 11 (.google.protobuf.EnumValue)
    # Field: options Type: 11 (.google.protobuf.Option)
    # Field: source_context Type: 11 (.google.protobuf.SourceContext)
    # Field: syntax Type: 14 (.google.protobuf.Syntax)

# === Message: Google::Protobuf::Type::EnumValue ===
    # Fields for EnumValue
    # Field: name Type: 9 ()
    # Field: number Type: 5 ()
    # Field: options Type: 11 (.google.protobuf.Option)

# === Message: Google::Protobuf::Type::Option ===
    # Fields for Option
    # Field: name Type: 9 ()
    # Field: value Type: 11 (.google.protobuf.Any)

1;

__END__

=encoding UTF-8

=head1 NAME

Google::Protobuf::Type - Compiled Protocol Buffers messages for google/protobuf/type.proto

=head1 SYNOPSIS

    use Google::Protobuf::Type;

    my $msg = Google::Protobuf::Type::Type->new({
        name => $name,
        fields => $fields,
        oneofs => $oneofs,
        options => $options,
    });

    # Read or update a field
    my $val = $msg->name();

    # Binary wire-format roundtrip
    my $bytes   = $msg->serialize();
    my $decoded = Google::Protobuf::Type::Type->parse($bytes);

    # Canonical ProtoJSON
    my $json = $msg->to_json();

=head1 DESCRIPTION

Auto-generated L<Protobuf> message classes compiled from C<google/protobuf/type.proto>. All message classes inherit from
L<Protobuf::Message> and support C<new()>, C<serialize()>, C<parse()>,
C<to_json()>, C<from_json()>, C<to_text()>, and C<to_perl()>.

=head1 MESSAGES

=head2 Google::Protobuf::Type::Type

A protocol buffer message type.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The fully qualified message name.

=item * C<< $msg->fields() >> / C<< $msg->fields($value) >>

Type: C<Message> (L<Google::Protobuf::Type::Field>)

The list of fields.

=item * C<< $msg->oneofs() >> / C<< $msg->oneofs($value) >>

Type: C<String>

The list of types appearing in `oneof` definitions in this type.

=item * C<< $msg->options() >> / C<< $msg->options($value) >>

Type: C<Message> (L<Google::Protobuf::Type::Option>)

The protocol buffer options.

=item * C<< $msg->source_context() >> / C<< $msg->source_context($value) >>

Type: C<Message> (L<Google::Protobuf::SourceContext::SourceContext>)

The source context.

=item * C<< $msg->syntax() >> / C<< $msg->syntax($value) >>

Type: C<Enum> (L<Google::Protobuf::Syntax>)

The source syntax.

=back

=head2 Google::Protobuf::Type::Field

A single field of a message type.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->kind() >> / C<< $msg->kind($value) >>

Type: C<Enum> (L<Google::Protobuf::Field::Kind>)

The field type.

=item * C<< $msg->cardinality() >> / C<< $msg->cardinality($value) >>

Type: C<Enum> (L<Google::Protobuf::Field::Cardinality>)

The field cardinality.

=item * C<< $msg->number() >> / C<< $msg->number($value) >>

Type: C<Int32>

The field number.

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The field name.

=item * C<< $msg->type_url() >> / C<< $msg->type_url($value) >>

Type: C<String>

The field type URL, without the scheme, for message or enumeration
types. Example: `"type.googleapis.com/google.protobuf.Timestamp"`.

=item * C<< $msg->oneof_index() >> / C<< $msg->oneof_index($value) >>

Type: C<Int32>

The index of the field type in `Type.oneofs`, for message or enumeration
types. The first type has index 1; zero means the type is not in the list.

=item * C<< $msg->packed() >> / C<< $msg->packed($value) >>

Type: C<Bool>

Whether to use alternative packed wire representation.

=item * C<< $msg->options() >> / C<< $msg->options($value) >>

Type: C<Message> (L<Google::Protobuf::Type::Option>)

The protocol buffer options.

=item * C<< $msg->json_name() >> / C<< $msg->json_name($value) >>

Type: C<String>

The field JSON name.

=item * C<< $msg->default_value() >> / C<< $msg->default_value($value) >>

Type: C<String>

The string value of the default value of this field. Proto2 syntax only.

=back

=head3 Enum: Field::Kind

=over 4

=item * C<TYPE_UNKNOWN> => C<0>

=item * C<TYPE_DOUBLE> => C<1>

=item * C<TYPE_FLOAT> => C<2>

=item * C<TYPE_INT64> => C<3>

=item * C<TYPE_UINT64> => C<4>

=item * C<TYPE_INT32> => C<5>

=item * C<TYPE_FIXED64> => C<6>

=item * C<TYPE_FIXED32> => C<7>

=item * C<TYPE_BOOL> => C<8>

=item * C<TYPE_STRING> => C<9>

=item * C<TYPE_GROUP> => C<10>

=item * C<TYPE_MESSAGE> => C<11>

=item * C<TYPE_BYTES> => C<12>

=item * C<TYPE_UINT32> => C<13>

=item * C<TYPE_ENUM> => C<14>

=item * C<TYPE_SFIXED32> => C<15>

=item * C<TYPE_SFIXED64> => C<16>

=item * C<TYPE_SINT32> => C<17>

=item * C<TYPE_SINT64> => C<18>

=back

=head3 Enum: Field::Cardinality

=over 4

=item * C<CARDINALITY_UNKNOWN> => C<0>

=item * C<CARDINALITY_OPTIONAL> => C<1>

=item * C<CARDINALITY_REQUIRED> => C<2>

=item * C<CARDINALITY_REPEATED> => C<3>

=back

=head2 Google::Protobuf::Type::Enum

Enum type definition.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Enum type name.

=item * C<< $msg->enumvalue() >> / C<< $msg->enumvalue($value) >>

Type: C<Message> (L<Google::Protobuf::Type::EnumValue>)

Enum value definitions.

=item * C<< $msg->options() >> / C<< $msg->options($value) >>

Type: C<Message> (L<Google::Protobuf::Type::Option>)

Protocol buffer options.

=item * C<< $msg->source_context() >> / C<< $msg->source_context($value) >>

Type: C<Message> (L<Google::Protobuf::SourceContext::SourceContext>)

The source context.

=item * C<< $msg->syntax() >> / C<< $msg->syntax($value) >>

Type: C<Enum> (L<Google::Protobuf::Syntax>)

The source syntax.

=back

=head2 Google::Protobuf::Type::EnumValue

Enum value definition.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

Enum value name.

=item * C<< $msg->number() >> / C<< $msg->number($value) >>

Type: C<Int32>

Enum value number.

=item * C<< $msg->options() >> / C<< $msg->options($value) >>

Type: C<Message> (L<Google::Protobuf::Type::Option>)

Protocol buffer options.

=back

=head2 Google::Protobuf::Type::Option

A protocol buffer option, which can be attached to a message, field,
enumeration, etc.

Inherits from L<Protobuf::Message>.

=head3 Accessors

=over 4

=item * C<< $msg->name() >> / C<< $msg->name($value) >>

Type: C<String>

The option's name. For protobuf built-in options (options defined in
descriptor.proto), this is the short name. For example, `"map_entry"`.
For custom options, it should be the fully-qualified name. For example,
`"google.api.http"`.

=item * C<< $msg->value() >> / C<< $msg->value($value) >>

Type: C<Message> (L<Google::Protobuf::Any::Any>)

The option's value packed in an Any message. If the value is a primitive,
the corresponding wrapper type defined in google/protobuf/wrappers.proto
should be used. If the value is an enum, it should be stored as an int32
value using the google.protobuf.Int32Value type.

=back

=head1 SEE ALSO

L<Protobuf>, L<Protobuf::Message>, L<Google::Protobuf::Type::Types>, L<https://protobuf.dev/>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
