use Test::More;

use_ok('Parse::SAMGov::Entity::Address');
use_ok('Parse::SAMGov::Entity::PointOfContact');
use_ok('Parse::SAMGov::Entity');
use_ok('Parse::SAMGov::Exclusion::Name');
use_ok('Parse::SAMGov::Exclusion');
use_ok('Parse::SAMGov');

my $p = new_ok('Parse::SAMGov');
can_ok($p, 'parse_file');

done_testing();
__END__
### COPYRIGHT: Selective Intellect LLC.
### AUTHOR: Vikas N Kumar <vikas@cpan.org>
