#!inc/bin/testml-cpan


*command.run == *output
  :"+ '{*command}' output is correct"

*command.run ~~ *match
  :"+ '{*command}' output matches '{Want}'"


=== Test 1
--- command: pegex
--- output(+)
pegex <command> [<options>] [<input-file>]

Commands:

   compile: Compile a Pegex grammar to some format
   version: Show Pegex version
      help: Show help

Options:
   -t,--to=:     Output type: yaml, json, perl
   -b, --boot:   Use the Pegex Bootstrap compiler
   -r, --rules=: List of starting rules

#
=== Test 2
--- command: pegex help
--- ^output


=== Test 3
--- command: pegex version
--- match(@)
The 'pegex' compiler command v0.
Using the Perl Pegex module v0.


=== Test 4
--- command: echo 'hash: BANG' | pegex compile --to=yaml
--- output(<)
    ---
    +toprule: hash
    BANG:
      .rgx: '!'
    hash:
      .ref: BANG


=== Test 5
--- command: echo 'hash: BANG' | pegex compile --to=json
--- output
{
   "+toprule" : "hash",
   "BANG" : {
      ".rgx" : "!"
   },
   "hash" : {
      ".ref" : "BANG"
   }
}


=== Test 6
--- command: echo 'hash: BANG' | pegex compile --to=perl
--- output
{
  '+toprule' => 'hash',
  'BANG' => {
    '.rgx' => qr/\G!/
  },
  'hash' => {
    '.ref' => 'BANG'
  }
}



