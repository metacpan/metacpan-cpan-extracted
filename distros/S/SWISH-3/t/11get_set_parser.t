use strict;
use Test::More tests => 12;

#use Carp;

# TODO this test reveals the [possibly very flawed] logic in our
# C-struct reference counting.
# we need a way to know when to free the struct that
# is blessed in an object. we don't want to free it with every
# DESTROY, since there might be multiple Perl objects pointing
# at the same C pointer, and freeing the underlying pointer
# will segfault any remaining Perl objects.

use_ok('SWISH::3');

ok( my $s3 = SWISH::3->new( handler => sub { } ), "new parser" );

ok( my $conf1  = $s3->get_config,       "get initial config" );
ok( my $config = SWISH::3::Config->new, "new config" );
ok( !$s3->set_config($config), "set config" );
ok( $s3->get_config->isa('SWISH::3::Config'),
    "get config isa SWISH::3::Config"
);
ok( my $conf2 = $s3->get_config, "get conf2" );

#diag("config = $config");
#diag("conf1 = $conf1");
#diag("conf2 = $conf2");

ok( my $ana1 = $s3->get_analyzer, "get initial analyzer" );
ok( my $analyzer = SWISH::3::Analyzer->new($config), "new analyzer" );
ok( !$s3->set_analyzer($analyzer), "set analyzer" );
ok( $s3->get_analyzer->isa('SWISH::3::Analyzer'),
    "get analyzer isa SWISH::3::Analyzer"
);
ok( my $ana2 = $s3->get_analyzer, "get ana2" );

