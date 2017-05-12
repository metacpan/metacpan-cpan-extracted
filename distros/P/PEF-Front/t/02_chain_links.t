use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib "$Bin/../t";
use Test::More;

use PEF::Front::Model;

my $sub      = PEF::Front::Model::_chain_links_sub('some_handler');
my $expected = <<EOE;
sub {
	my (\$req, \$context) = \@_;
	my \$response;
	\$response = fakemodule::Local::some_handler(\$req, \$context, \$response);
	\$response;
}
EOE

is $sub => $expected, 'one simple handler';

$sub = PEF::Front::Model::_chain_links_sub(['some_handler', 'other_handler']);
$expected = <<EOE;
sub {
	my (\$req, \$context) = \@_;
	my \$response;
	\$response = fakemodule::Local::some_handler(\$req, \$context, \$response);
	\$response = fakemodule::Local::other_handler(\$req, \$context, \$response);
	\$response;
}
EOE
is $sub => $expected, 'two simple handlers';

$sub = PEF::Front::Model::_chain_links_sub(['^some_handler', '^other_handler']);
$expected = <<EOE;
sub {
	my (\$req, \$context) = \@_;
	my \$response;
	\$response = some_handler(\$req, \$context, \$response);
	\$response = other_handler(\$req, \$context, \$response);
	\$response;
}
EOE
is $sub => $expected, 'two simple exact handlers';

$sub = PEF::Front::Model::_chain_links_sub([{'^some_handler' => {qq => "aa"}}, '^other_handler']);
$expected = <<EOE;
sub {
	my (\$req, \$context) = \@_;
	my \$response;
	\$response = some_handler(\$req, \$context, \$response, \$handlers[0][1]);
	\$response = other_handler(\$req, \$context, \$response);
	\$response;
}
EOE
is $sub => $expected, 'one complex and one exact handlers';
$sub = PEF::Front::Model::_chain_links_sub([{'some_handler' => {qq => "aa"}}, {'^other_handler' => {yes => 1}}]);
$expected = <<EOE;
sub {
	my (\$req, \$context) = \@_;
	my \$response;
	\$response = fakemodule::Local::some_handler(\$req, \$context, \$response, \$handlers[0][1]);
	\$response = other_handler(\$req, \$context, \$response, \$handlers[1][1]);
	\$response;
}
EOE

is $sub => $expected, 'one complex and one exact comples handlers';

done_testing();
