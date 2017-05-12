use Test::More;

eval 'use Test::CPAN::Changes::ReallyStrict::Object';
plan skip_all => 'Test::CPAN::Changes::ReallyStrict::Object required for this test' if $@;

use lib 't/lib';
use Requires::CCAPI \$Test::CPAN::Changes::ReallyStrict::Object::TODO;

require Text::Wrap;
$Text::Wrap::columns = 120;
$Text::Wrap::break   = '(?![\x{00a0}\x{202f}])\s';
$Text::Wrap::huge    = 'overflow';
Test::CPAN::Changes::ReallyStrict::Object->new(
  {
    filename => 'Changes'
  }
)->changes_ok();
done_testing();

