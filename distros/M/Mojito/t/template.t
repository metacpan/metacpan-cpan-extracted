use Test::More;
use Mojito::Template;
use Mojito::Model::Config;

# Need config as a constructor arg for Template
my $config = Mojito::Model::Config->new->config;
my $temple = Mojito::Template->new(config => $config);
isa_ok($temple, 'Mojito::Template');


done_testing();