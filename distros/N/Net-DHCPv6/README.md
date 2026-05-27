# Net-DHCPv6

Perl library for encoding and decoding DHCPv6 packets — message types,
options, and DUIDs to/from wire format.

## Build

```bash
dzil build
```

## Test

```bash
dzil test
prove -lvr t/
```

## Test Data

Real-world captures used for testing are stored in `t/data/`. Sources:

| File | Origin | Packets |
|---|---|---|
| `wireshark-sample-DHCPv6.pcap` | [Wireshark Sample Captures](https://wiki.wireshark.org/samplecaptures) | 6 — Solicit/Advertise/Request/Reply/Release/Reply with IA_PD/IAPrefix |
| `ztp-pcap-dhcpv6.pcap` | [ios-xr/ztp-pcap](https://github.com/ios-xr/ztp-pcap/blob/master/6225/pcap/dhcpv6.pcap) | 4 — Solicit/Advertise/Request/Reply with IA_NA/IAAddr, VendorClass, Bootfile URL, DNS, Domain List |
| `dhcpv6-ia-pd.pcap` | [AOSP tcpdump tests](https://github.com/aosp-mirror/platform_external_tcpdump/blob/master/tests/dhcpv6-ia-pd.pcap) | 4 — Solicit/Advertise/Request/Reply with IA_PD/IAPrefix (prefix_len=56), DUID-LL, zero-sub-option IA_PD in Solicit |
| `dhcpv6-AFTR-Name-RFC6334.pcap` | [AOSP tcpdump tests](https://git.codelinaro.org/clo/la/platform/external/tcpdump/-/tree/aosp-new/aosp-new/master/tests) | 4 — Solicit/Advertise/Request/Reply with IA_PD/IAPrefix, PREFERENCE, DNS_SERVERS, OPTION_64 (AFTR-Name-like) |
| `dhcpv6-ia-ta.pcap` | [AOSP tcpdump tests](https://git.codelinaro.org/clo/la/platform/external/tcpdump/-/tree/aosp-new/aosp-new/master/tests) | 4 — Solicit/Advertise/Request/Reply with IA_TA/IAAddr |
| `dhcpv6-mud.pcap` | [AOSP tcpdump tests](https://git.codelinaro.org/clo/la/platform/external/tcpdump/-/tree/aosp-new/aosp-new/master/tests) | 5 — RELAY_FORW containing SOLICIT with MUD_URL, VENDOR_CLASS, IA_NA |
| `dhcpv6-ntp-server.pcap` | [AOSP tcpdump tests](https://git.codelinaro.org/clo/la/platform/external/tcpdump/-/tree/aosp-new/aosp-new/master/tests) | 1 — REPLY with NTP_SERVER(56) |
| `dhcpv6-sip-server-d.pcap` | [AOSP tcpdump tests](https://git.codelinaro.org/clo/la/platform/external/tcpdump/-/tree/aosp-new/aosp-new/master/tests) | 1 — REPLY with SIP_SERVER_D(21) |

**Licensing note:** The license status of these capture files is unknown.
They are attributed to their respective upstream sources above.
Packagers distributing Net-DHCPv6 should consider removing `t/data/*.pcap`
if licensing clarity is required.
