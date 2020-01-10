#!inc/bin/testml-cpan

*swim.parse('Pod') == *pod
  :"Swim to Pod - +"


=== Wiki style link
--- swim
See [Swim::HTML] for more info.
--- pod
See L<Swim::HTML> for more info.
