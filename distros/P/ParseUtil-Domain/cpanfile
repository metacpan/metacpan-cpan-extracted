requires 'Carp', '1.17';
requires 'Net::IDN::Encode', '2.003';
requires 'Net::IDN::Nameprep', '1.101';
requires 'Net::IDN::Punycode', '1.100';
requires 'Modern::Perl';
 
on 'build' => sub {
  requires 'namespace::autoclean';
  requires 'Net::IDN::Encode';
  requires 'Perl::Critic';
  requires 'Regexp::Assemble::Compressed';
  requires 'Smart::Comments';
  requires 'Test::Class';
  requires 'Test::Deep';
  requires 'Test::More';
  requires 'Test::Perl::Critic';
  requires 'Test::Routine';
  requires 'Mock::Quick';
  requires 'Unicode::CharName';
};

on 'configure' => sub { 
  requires 'Module::Build';
};
