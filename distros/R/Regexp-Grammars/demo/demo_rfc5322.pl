#! /usr/bin/perl

# Thanks to Tom Christiansen and Abigail for doing the hard work
# underlying this example

use strict;
use 5.010;

use warnings;
use Data::Dumper "Dumper";

my $rfc5322 = do {
   use Regexp::Grammars;    # ...the magic is lexically scoped
   qr{

   # Keep the big stick handy, just in case...
   # <debug:on>

   # Match this...
   <address>

   # As defined by these...
   <token: address>         <mailbox> | <group>
   <token: mailbox>         <name_only> | <addr_spec> | <name_addr>
   <token: name_only>       [^<>@]+ $
   <token: name_addr>       <display_name>? <angle_addr>
   <token: angle_addr>      <CFWS>? \< <addr_spec> \> <CFWS>?
   <token: group>           <display_name> : (?:<mailbox_list> | <CFWS>)? ; <CFWS>?
   <token: display_name>    <phrase>
   <token: mailbox_list>    <[mailbox]>+ % (,)

   <token: addr_spec>       <local_part> \@ <domain>
   <token: local_part>      <dot_atom> | <quoted_string>
   <token: domain>          <dot_atom> | <domain_literal>
   <token: domain_literal>  <CFWS>? \[ (?: <FWS>? <[dcontent]>)*+ <FWS>?

   <token: dcontent>        <dtext> | <quoted_pair>
   <token: dtext>           <.NO_WS_CTL> | [\x21-\x5a\x5e-\x7e]

   <token: atext>           <.ALPHA> | <.DIGIT> | [-!#\$%&'*+/=?^_`{|}~]
   <token: atom>            <.CFWS>? <.atext>+ <.CFWS>?
   <token: dot_atom>        <.CFWS>? <.dot_atom_text> <.CFWS>?
   <token: dot_atom_text>   <.atext>+ (?: \. <.atext>+)*+

   <token: text>            [\x01-\x09\x0b\x0c\x0e-\x7f]
   <token: quoted_pair>     \\ <.text>

   <token: qtext>           <.NO_WS_CTL> | [\x21\x23-\x5b\x5d-\x7e]
   <token: qcontent>        <.qtext> | <.quoted_pair>
   <token: quoted_string>   <.CFWS>? <.DQUOTE> (?:<.FWS>? <.qcontent>)*+
                            <.FWS>? <.DQUOTE> <.CFWS>?

   <token: word>            <.atom> | <.quoted_string>
   <token: phrase>          <.word>+

   # Folding white space
   <token: FWS>             (?: <.WSP>* <.CRLF>)? <.WSP>+
   <token: ctext>           <.NO_WS_CTL> | [\x21-\x27\x2a-\x5b\x5d-\x7e]
   <token: ccontent>        <.ctext> | <.quoted_pair> | <.comment>
   <token: comment>         \( (?: <.FWS>? <.ccontent>)*+ <.FWS>? \)
   <token: CFWS>            (?: <.FWS>? <.comment>)*+
                            (?: (?:<.FWS>? <.comment>) | <.FWS>)

   # No whitespace control
   <token: NO_WS_CTL>       [\x01-\x08\x0b\x0c\x0e-\x1f\x7f]

   <token: ALPHA>           [A-Za-z]
   <token: DIGIT>           [0-9]
   <token: CRLF>            \x0d \x0a
   <token: DQUOTE>          "
   <token: WSP>             [\x20\x09]

   }x;

};

$| = 1;

while (my $input = <>) {
   say "Testing: $input";
   if ($input =~ $rfc5322) {
       say Dumper \%/;       # ...the parse tree of any successful match
                             # appears in this punctuation variable

   }
}
