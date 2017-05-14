# Dropdown tests for values.

package My::Object;

sub new {
    my ($class, %self) = @_;
    return bless \%self, $class;
}

package My::Object::Class;

use base 'My::Object';

package main;

use strict;
use warnings;
use Test::More tests => 6;

use Template::Flute;


my $spec =<<'SPEC';
<specification>
<value name="name" field="session.salute"/>
</specification>
SPEC

my $html = <<'HTML';
<!DOCTYPE html>
<html>
  <head>
  </head>
  <body>
    <span class="name">Welcome back!</span>
  </body>
</html>
HTML

my %values = (
              session => My::Object::Class->new(
                                                salute => "Hello world",
                                               ),
             );

my $flute = Template::Flute->new(
                                 specification => $spec,
                                 template => $html,
                                 values => \%values,
                                );
my $out;

eval {
    $out = $flute->process();
};

my @ignores = $flute->_autodetect_ignores;
is scalar(@ignores), 0, "No ignores set";

ok $@, "Bad object raise exception $@";
ok(!$out, "No output!") or diag $out;


$flute = Template::Flute->new(
                              specification => $spec,
                              template => $html,
                              values => \%values,
                              autodetect => {
                                             disable => ['My::Object'],
                                            }
                             );

eval { $out = $flute->process };

ok(!$@, "All ok $@");
ok $out, "HTML produced";
like $out, qr{Hello world}, "object seen as hashref, methods ignored";
