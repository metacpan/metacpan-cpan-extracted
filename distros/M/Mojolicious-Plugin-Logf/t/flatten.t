use Mojo::Base -base;
use Test::More;
use Mojolicious::Plugin::Logf;

my $logf = Mojolicious::Plugin::Logf->new;

eval <<"CODE" or die $@;
package Test;
use overload q("") => sub { "yikes" };
1;
CODE

{
  my @args = $logf->flatten(
                { foo => 42 },
                bless({ bar => 42 }),
                "foo",
                undef,
                bless({ whatever => 42 }, 'Test'),
              );

  is $args[0], "{'foo' => 42}", "flatten foo=>1";
  is $args[1], "bless( {'bar' => 42}, 'main' )", "flatten object";
  is $args[2], "foo", "flatten scalar";
  is $args[3], "__UNDEF__", "flatten undef";
  is $args[4], "yikes", "flatten overloaded object";
}

done_testing;
