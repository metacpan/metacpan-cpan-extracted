use Test::More tests => 3;

{

    package MyConfig;
    our @ISA = ('SWISH::3::Config');

    sub DESTROY {
        $_[0]->SUPER::DESTROY;
    }
}

use_ok('SWISH::3');
ok( my $s3 = SWISH::3->new( config_class => 'MyConfig' ), "new s3" );
ok( my $conf = $s3->config, "get config" );
