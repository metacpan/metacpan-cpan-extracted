# SYNOPSIS

    use Net::IDN::PP;

    say Net::IDN::PP->decode('xn--caf-dma.com'); # prints café.com

    say Net::IDN::PP->decode('café.com'); # prints xn--caf-dma.com

# DESCRIPTION

Net::IDN::PP is a pure Perl IDN encoder/decoder. The `decode()` method takes an
"A-label" and decodes it, and `encode()` takes a "U-label" and encodes it.

Other modules exist which provide similar functionality, but they all rely on
external C libraries such as libidn/libidn2 or ICU.

## IMPORTANT NOTE

This module only implements the Punycode algorithm from
[RFC 3492](https://www.rfc-editor.org/rfc/rfc3492.html); it does not implement
any of the "Nameprep" logic described in IDNA2003 or IDNA2008. This makes it
unsuitable for use in provisioning (domain registrar or registry) systems, but
it should work fine if you don't mind working on a "garbage in, garbage out"
basis.
