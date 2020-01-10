#!inc/bin/testml-cpan

*swim.parse('Pod') == *pod
  :"Swim to Pod - +"


=== Preformatted with Blank Lines
--- swim
Code:

  a = b

  b = c

--- pod
Code:

    a = b

    b = c
