# BEGIN { $ENV{PERL_PEGEX_AUTO_COMPILE} = 'Pegex::Drinkup::Grammar' }
use lib 'inc';
use TestML;

TestML->new(
    testml => join('', <DATA>),
    bridge => 'TestMLBridge',
)->run;

{
    package TestMLBridge;
    use base 'TestML::Bridge';
    use TestML::Util;
    use Pegex::Drinkup;

    use YAML::XS;

    sub parse { native + Pegex::Drinkup->new->parse($_[1]->value) }
    sub load { native + Load($_[1]->value) }
    sub yaml { str + Dump($_[1]->value) }
}

__DATA__
%TestML 0.1.0

*drinkup.parse.yaml == *recipe.load.yaml;

=== test 1
--- drinkup
Tom Collins

This is a delicious beverage for a hot day.
Refreshing.

Drink it at a wedding.

* 4 ounces of Club Soda
*2 ounce Gin
\# beefeater is best!
* 1 Ounce of Lemon Juice
*1 tbsp of Simple Syrup

Shake over ice. Serve.

Enjoy.

Source: 500 Cocktails, p27
--- recipe
name: Tom Collins
description: |
  This is a delicious beverage for a hot day.
  Refreshing.

  Drink it at a wedding.
ingredients:
- ingredient: Club Soda
  amount: 4
  unit: ounces
- ingredient: Gin
  amount: 2
  unit: ounce
  note: beefeater is best!
- ingredient: Lemon Juice
  amount: 1
  unit: Ounce
- ingredient: Simple Syrup
  amount: 1
  unit: tbsp
instructions: |
  Shake over ice. Serve.

  Enjoy.
source: 500 Cocktails, p27

