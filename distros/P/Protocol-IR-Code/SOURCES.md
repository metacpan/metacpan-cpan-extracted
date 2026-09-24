# Sources and References

Everything below is external material that informed, or was used to verify,
this distribution. Treat it as the breadcrumb trail: if a behavior here
seems wrong or a number looks arbitrary, check these first.

## Reference implementations and repositories

- **IRDB** — https://github.com/probonopd/irdb
  The crowd-sourced database of IR codes this distribution targets. Rows are
  stored as `protocol,device,subdevice,function` and converted to signals.
  The IRDB README points at MakeHex and IrScrutinizer for rendering.
  Test fixture: `t/data/irdb-nec-receiver.csv` is a subset of an IRDB NEC
  receiver CSV (NEC1, device 25).

- **MakeHex** — https://github.com/probonopd/MakeHex
  By John Fine. Reads an IRP protocol file and emits Pronto Hex. This is the
  generator IRDB relies on, so its output is the ground truth for IRDB rows.
  The `protocols/` directory in this repo holds the IRP files that define the
  NEC family, JVC, and Samsung timing used here:
  `nec1.irp`, `nec2.irp`, `NECx1.irp`, `NECx2.irp`, `jvc.irp`,
  `Samsung20.irp`, `Samsung36.irp`.
  Cross-validation: the NEC and JVC Pronto output is checked against a built
  MakeHex (see "How correctness is verified" below). MakeHex's exact pulse
  conversion (`v = floor(µs * 4.145146 / unit + 0.5)`, `unit =
  floor(4145146/freq + 0.5)`) is mirrored by the `to_pronto` methods; the one
  intentional difference is that MakeHex appends a dataless repeat frame for
  NEC1/NECx1 (`Form=...;*,_`), which the library leaves to the transmitter.

- **IRremoteESP8266** — https://github.com/crankyoldgit/IRremoteESP8266
  Source of the SAMSUNG protocol semantics (32-bit, customer byte sent twice,
  command then its complement). `ir_Samsung.cpp` defines the timing used by
  `Protocol::IR::Proto::SAMSUNG`: `kSamsungTick=560`, 8×560 header mark/space,
  `kSamsungOneSpace=3*560`, `kSamsungZeroSpace=560`. The Samsung decoder here
  originated from Ken Shirriff's work (https://github.com/shirriff/Arduino-IRremote/).

- **Tasmota** — https://github.com/tasmota/tasmota
  Defines the `IrReceived` JSON shape this distribution ingests: the compact
  letter-coded `RawData` timings plus the `Data`/`DataLSB` fields.
  Test fixture: `t/data/tasmota-captures.log` holds real `IrReceived` captures
  (NEC and SAMSUNG) exported from a Tasmota console; they are used to confirm
  the decoder accepts real-world jitter and that the encoder reproduces the
  exact wire bitstream of a genuine signal.

- **HAIR** — https://github.com/DAB-LABS/HAIR
  Home Assistant IR integration. Defines the `hair-wig` format family
  (the "wig" format) that `Protocol::IR::Format::Wig` emits.

- **IrScrutinizer / harctoolboxbundle** — https://github.com/bengtmartensson/harctoolboxbundle
  (project: https://github.com/bengtmartensson/IrScrutinizer)
  The ecosystem around IRDB, MakeHex IRP files, and the LIRC/wig/HAIR/Pronto
  formats. Useful for cross-checking interpretations of the formats handled
  here.

- **Machina Speculatrix (lookin-home author)** —
  https://mansfield-devine.com/speculatrix/ and https://github.com/mspeculatrix
  Blog and code behind the "lookin-home" Medium publication; practical
  write-ups on decoding/sending NEC with microcontroller hardware.

## Protocol and format documentation

- **SB-Projects: IR NEC protocol** — https://www.sbprojects.net/knowledge/ir/nec.php
  The canonical NEC explanation (carrier, bit timings, repeated/inverted
  fields, 9 ms/4.5 ms header, the repeat code, and the 16-bit "extended"
  address form).

- **JP1 Remotes Wiki: NEC** — https://hifi-remote.com/wiki/index.php/NEC
  IRP notation and the distinguishing rules for NEC1, NEC2, NECx1, NECx2
  (including the "2" variants' whole-frame repeat and NECx half headers).

- **JP1 Remotes Wiki: ProntoHex** — https://hifi-remote.com/wiki/index.php/ProntoHex
  The Pronto Hex wire format (frequency word, pair counts, cumulative
  mark/space encoding).

- **JVC IR codes PDF** — http://www.jvcdig.com/D-ILA%20IR%20Codes%20REVa.pdf
  Referenced by MakeHex's `jvc.irp`; source of the JVC 37.9 kHz timing.

- **Samsung protocol PDF** — http://elektrolab.wz.cz/katalog/samsung_protocol.pdf
  Referenced by IRremoteESP8266's `ir_Samsung.cpp`; the Samsung 32-bit
  protocol as documented in the wild.

- **Renesas application note AN-1184** — https://www.renesas.com/us/en/document/apn/1184-remote-control-ir-receiver-decoder
  The original NEC application note (protocol now owned by Renesas),
  referenced from SB-Projects.

- **LOOKin Remote** — https://look-in.club/en/devices/remote
  The LOOKin device line this project's sibling work targets; its HTTP API
  takes commands in ProntoHex or raw timings form.

- **How does the remote control work? Explained** —
  https://lookin-home.medium.com/how-does-the-remote-control-work-explained-564bc7cd0291
  Machina Speculatrix's lookin-home Medium article on how IR remote
  signalling works (carrier, NEC pulse-distance modulation, timings).

## How correctness is verified

The risk with IR encoders is that encode→decode roundtrips prove
self-consistency only, not protocol correctness. Two external cross-checks
are used instead:

1. **MakeHex cross-validation.** A built MakeHex (from the repo above) is run
   on each IRP with the same device/subdevice/function, and its Pronto output
   is compared to the library's: carrier word, pair count, header, the 32- or
   16-bit wire bitstream, and stop pulse must agree. See
   `t/16-nec-variants.t` (NEC family, incl. the MakeHex-verified Samsung NECx2
   POWER row), the JVC tests, and `t/18-wide-protocols.t` (the wide-protocol
   additions, with the EncodeIR-generated `Samsung20.irp` wire timings for
   D=1/S=8/F=39 baked in as ground truth). The offline cross-validation
   harness is `tools/verify_pronto.pl`; the reference values it produces are
   baked into the tests so CI does not need the MakeHex binary.

2. **Real-capture fidelity.** `t/data/tasmota-captures.log` is decoded and
   re-encoded, and the encoded wire bitstream is compared bit-for-bit with the
   original capture (e.g. Samsung POWER transmits
   `11100000 11100000 01000000 10111111`, matching the capture and Tasmota's
   `Data=0xE0E040BF` / `DataLSB=0x070702FD`). The wide protocols are likewise
   cross-checked against live captures taken over the MQTT IR test rig
   (transmitted by the library's own encoders as Tasmota IRsend raw and
   captured back); `t/12-tasmota.t` and the sibling project's
   `test/tasmota.test.ts` require the RawData timing decode to recover the
   transmitted address/subaddress/command and the compact codec to roundtrip
   the captures byte-identically.

A convenience one-liner for rebuilding MakeHex locally:

```
git clone https://github.com/probonopd/MakeHex.git /tmp/makehex
cd /tmp/makehex && make
```
