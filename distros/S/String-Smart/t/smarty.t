use strict;
use warnings;
use Test::More tests => 25;
use String::Smart qw( :all );

# Set up some simple encodings
add_rep reversed => sub { reverse shift }, sub { reverse shift };
my $r13 = sub { my $s = shift; $s =~ tr/A-Za-z/N-ZA-Mn-za-m/; $s };
add_rep rot13 => $r13, $r13;
add_rep
 double => sub { my $s = shift; $s . $s },
 sub { my $s = shift; substr $s, 0, length( $s ) / 2 };
add_rep toonly => sub { shift() . '!' }, undef;
add_rep fromonly => undef, sub { '!' . shift() };

{
  # Simple transformations
  my $abc = 'abc';
  my $cba = as reversed => $abc;
  isa_ok $cba, 'String::Smart';
  is "$cba", 'cba', 'reversed OK';
  is plain $cba, 'abc', 'reverse it back';
  ok !ref plain $cba, 'returns plain string';
  is str_val $cba, 'cba', 'str_val OK';
  is_deeply [ rep $abc], [], 'no rep on plain string';
  is_deeply [ rep $cba], ['reversed'], 'rep for cba is reversed';

  my $olleh = already reversed => 'olleh';
  isa_ok $olleh, 'String::Smart';
  is "$olleh", 'olleh', 'stays reversed';
  is literal( reversed => $olleh ), 'olleh', 'stays reversed (2)';
}

{
  # Stacked transformations
  my $abc = 'abc';
  my $abc2 = as double => $abc;
  is "$abc2", 'abcabc', 'double';
  my $cba2 = as double_reversed => $abc2;
  is "$cba2", 'cbacba', 'stacked';
  my $cba2b = as double_reversed => $abc;
  is "$cba2b", 'cbacba', 'stacked';
  is plain $cba2,  'abc', 'stacked undone';
  is plain $cba2b, 'abc', 'stacked undone (2)';
  my $r13a = as double_reversed_rot13 => $abc;
  is "$r13a", 'ponpon', 'd,r,r13 (1)';
  my $r13b = as double_reversed_rot13 => $cba2;
  is "$r13b", 'ponpon', 'd,r,r13 (2)';
  my $r13c = as double_reversed_rot13 => $cba2b;
  is "$r13c", 'ponpon', 'd,r,r13 (3)';

  # A different route
  my $dbang = as double_toonly => $cba2b;
  is "$dbang", 'abcabc!', 'complex path';
  is_deeply [ rep $dbang], [ 'double', 'toonly' ],
   'rep for cba is reversed';
  my $rep = rep $dbang;
  is $rep, 'double_toonly', 'rep for cba is reversed';

}

{
  # Errors
  eval { add_rep name_with_underscore => undef, undef };
  like $@, qr{underscore}, 'name w/ underscore';

  my $pork = already toonly => 'Foo!';
  eval { plain $pork };
  like $@, qr{convert from toonly}, 'no convert from';

  eval { as fromonly => 'Bar' };
  like $@, qr{convert to fromonly}, 'no convert to';

  eval { as unknown => 'Bang' };
  like $@, qr{know about}, 'dunno';
}
