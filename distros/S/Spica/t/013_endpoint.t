use Test::More;
use Spica;

{
    package Mock::Spec;
    use Spica::Spec::Declare;

    client {
        name 'basic';
        endpoint 'default' => '/' , [];
    };

    client {
        name 'multi';
        endpoint 'single' => '/single', ['id'];
        endpoint 'search' => '/search', [];
    };

    client {
        name 'has_name';
        endpoint 'searach' => '/', [];
    };

    client {
        name 'full_args';
        endpoint default => +{
            method   => 'POST',
            path     => '/single',
            requires => ['id'],
        };

    };
}

my $spica = Spica->new(
    host => 'localhost',
    spec => 'Mock::Spec',
);

is_deeply $spica->spec->get_client('basic')->get_endpoint('default') => +{
    method   => 'GET',
    path     => '/',
    requires => [],
};

is_deeply $spica->spec->get_client('multi')->get_endpoint('single') => +{
    method   => 'GET',
    path     => '/single',
    requires => ['id'],
};

is_deeply $spica->spec->get_client('multi')->get_endpoint('search') => +{
    method   => 'GET',
    path     => '/search',
    requires => [],
};

is_deeply $spica->spec->get_client('full_args')->get_endpoint('default') => +{
    method   => 'POST',
    path     => '/single',
    requires => ['id'],
};


done_testing;
