# Device destinations and media examples

This change addresses the three remaining validated findings from the
2026-10-23 review: discovery-derived request destinations, cyclic/deep media
traversal and XML injection in generated RSS. It builds on the network limits
in PR #5. The original sealed audit documents remain unchanged.

## Destination policy

Discovery retains the SSDP sender's IPv4 address. By default, description GETs
and subsequent SOAP actions/queries may connect only to that address. Private
and link-local peers are supported; differing service ports on the same device
are allowed. Unspecified, loopback and multicast/reserved sender addresses do
not gain implicit trust.

`search(allowed_addresses => ['192.168.1.20'])` explicitly adds a numeric IPv4
address for a trusted proxy or multihomed device. For a deliberately local
test device, use `allowed_addresses => ['127.0.0.1']`. This is a caller-owned
allowlist; device descriptions cannot expand it. It contains additional
permitted destinations, not an instruction to trust arbitrary advertised URLs.

HTTP checks the actual resolved packed address immediately before connecting,
then uses that same address. Every request rechecks the policy, including
hostname aliases and later DNS changes. `URLBase`, absolute `controlURL`,
`postaction`, the `postcontrol` alias and `postquery` all retain the discovered
device's policy. Per-request HTTP tuning cannot replace it.

Advertisement deduplication includes the sender address, so a rejected URL
advertised by another peer cannot suppress the legitimate peer's later reply.

`getallowedaddresses()` returns a copy. A caller constructing a Device directly
can explicitly set its policy with `setallowedaddresses(\@addresses)`. Manually
constructed devices and direct HTTP callers remain caller-trusted when no
policy was supplied; they must not be used as substitutes for discovery when
processing untrusted network advertisements. An empty explicit policy denies
all destinations. Blocked discovery requests set the control point's
`geterror()`; blocked SOAP requests have status code `0`.

Address binding is a destination constraint, not device authentication. SSDP
has no authenticated identity in this library. Callers still need an
appropriate network trust model; explicitly permitted proxy/local targets
remain their responsibility.

## Bounded media walking

`MediaServer->walkcontent(callback => sub { ... })` replaces recursive sample
walkers with an explicit depth-first stack. The callback receives the content
object and depth (root children have depth 1). Existing `getcontentlist()`
remains a repeatable one-level Browse operation.

Each walk has its own visited-container set, seeded with the starting ObjectID
(default `0`). Repeated containers are skipped. Defaults are `max_depth => 32`,
`max_nodes => 4096`, and `timeout => 30` seconds. These must be positive finite
values; depth/node limits must be integers. The node budget counts parsed
items and pending siblings as well as containers, and response parsing stops
before accumulating an oversized object list. All Browse calls, including the
metadata fallback and retry, receive the same remaining deadline.

The time budget covers walking and Browse operations. Time spent in the
caller callback (for example, intentional ffmpeg conversion) is excluded;
callbacks must manage their own execution resources. Callback exceptions
propagate. The method returns the number of visited objects; callers must
inspect `getwalkerror()` for partial traversal. The three executable examples
and the copied POD samples abort explicitly on a walk error. They preserve
depth-first output order and indentation without recursive Perl calls.
Transport/SOAP Browse failures are reported through the same error accessor,
rather than being mistaken for empty directories.

## RSS serialization

The converter uses `Net::UPnP::AV::RSS` at its output boundary. Channel text,
item titles, GUIDs and enclosure attributes are escaped as XML data. Titles
retaining DIDL entities are decoded exactly once before escaping, preserving
ordinary `&amp;` titles and numeric entities without allowing markup injection.

The serializer accepts UTF-8 bytes or Perl character strings; the converter
writes through an explicit UTF-8 output layer. Invalid UTF-8 fails explicitly;
characters XML 1.0 cannot represent are replaced with `?`. Attribute whitespace
uses character references, and remote quotes cannot add attributes.

This does not change or validate the external Shell/curl/ffmpeg execution
boundary, media URL schemes, or converter exit-status handling. The audit's
command-execution candidate remains unresolved.

## Verification

`t/destination-policy.t` covers numeric hostname aliases, actual-address
checking, DNS changes, policy copying, blocked discovery and SOAP variants,
and explicitly trusted local/direct requests. `t/media-safety.t` covers
cycles, unique deep/wide graphs, per-walk state, budgets, Browse fallbacks,
RSS element/attribute injection, entity/Unicode preservation and the actual
converter output with preexisting media and stubbed external commands.

The tests require no live devices or external services. The converter fixture
does not execute curl/ffmpeg. XML::Parser, when available, additionally checks
the produced feed's parsed structure; the core regression tests do not require
that optional module.
