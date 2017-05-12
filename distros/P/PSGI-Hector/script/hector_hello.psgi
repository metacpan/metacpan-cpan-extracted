#run using the following command:
#plackup script/hector_hello.psgi
use strict;
use warnings;
use FindBin;
use local::lib "$FindBin::Bin/local/lib/perl5";
print $FindBin::Bin;
use lib qw(lib);
use PSGI::Hector::Middleware;

my $app = App->init({
	'responsePlugin' => 'PSGI::Hector::Response::Raw',
	'checkReferer' => 0
});

PSGI::Hector::Middleware->wrap($app);

###########################################
###########################################
package App;
use strict;
use warnings;
use parent qw(PSGI::Hector);
###########################################
sub handleDefault{
	my $h = shift;
	my $response = $h->getResponse();
	$response->setContent("Hello World");
}