use Perl6::Rules;
use Test::Simple 'no_plan';

$var = rx/a+b/;

# BUG: Not happy with rx's for some reason...
# @var = (rx/a/, rx/b/, rx/c/, rx/\w/);
  @var = (qr/a/, qr/b/, qr/c/, qr/\w/);

%var = (a=>rx:w/ 4/, b=>rx:w/ cos/, c=>rx:w/ \d+/);


# SCALARS

ok( "a+b" !~ m/<$::var>/, "Simple scalar match");
ok( "zzzzzza+bzzzzzz" !~ m/<$::var>/, "Nested scalar match");
ok( "aaaaab" =~ m/<$::var>/, "Rulish scalar match");


# ARRAYS

ok( "a" =~ m/<@::var>/, "Simple array match (a)");
ok( "b" =~ m/<@::var>/, "Simple array match (b)");
ok( "c" =~ m/<@::var>/, "Simple array match (c)");
ok( "d" =~ m/<@::var>/, "Simple array match (d)");
ok( "!" !~ m/<@::var>/, "Simple array match (!)");
ok( "!!!!a!!!!!" =~ m/<@::var>/, "Nested array match (a)");
ok( "!!!!e!!!!!" =~ m/<@::var>/, "Nested array match (e)");

{
  no warnings 'regexp';

  ok( "abca" =~ m/^<@::var>+$/, "Multiple array matching");
  ok( "abca!" !~ m/^<@::var>+$/, "Multiple array non-matching");
}


# HASHES

ok( "a 4" =~ m/<%::var>/, "Simple hash interpolation (a)");
ok( "b cos" =~ m/<%::var>/, "Simple hash interpolation (b)");
ok( "c 1234" =~ m/<%::var>/, "Simple hash interpolation (c)");
ok( "d" !~ m/<%::var>/, "Simple hash interpolation (d)");
ok( "====a 4=====" =~ m/<%::var>/, "Nested hash interpolation (a)");
ok( "abca" !~ m/^<%::var>$/, "Simple hash non-matching");

{
  no warnings 'regexp';

  ok( "a 4 b cos c 99  a 4" =~ m:w/^[ <%::var>]+$/, "Simple hash repeated matching");
}
