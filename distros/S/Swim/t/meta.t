#!inc/bin/testml-cpan

*swim.parse('Markdown') == *markdown
  :"Swim to Markdown - +"

*swim.parse('Pod') == *pod
  :"Swim to Pod - +"


=== Inline meta section
--- swim(<)
    ---
    name: John
    number: 42
    ...
    Dear <$name>,

    Now that you are <$number> years old, I regret to inform you...

--- markdown
Dear John,

Now that you are 42 years old, I regret to inform you...

--- pod
Dear John,

Now that you are 42 years old, I regret to inform you...

