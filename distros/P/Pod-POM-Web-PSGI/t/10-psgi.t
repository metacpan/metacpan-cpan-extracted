print "1..1\n";
use lib 'lib';
my $app = require Pod::POM::Web::PSGI;
print((ref($app) eq 'CODE' ? 'ok' : 'not ok'), " 1\n");
