use Test::More;
use Spica::URIMaker;

subtest 'basic' => sub {
    my $builder = Spica::URIMaker->new(host => 'example.ry-m.com')->create(
        path_base => '/',
        param     => +{}
    );
    isa_ok $builder => 'Spica::URIMaker';
    isa_ok $builder->uri => 'URI';
    is $builder->as_string => 'http://example.ry-m.com/';
};

subtest 'is_invalid_param' => sub {
    my $builder = Spica::URIMaker->new(host => 'example.ry-m.com');
    ok   $builder->is_invalid_param(+{}, [qw(huga hoge)]);
    ok ! $builder->is_invalid_param(+{huga => 1, hoge => 1}, [qw(huga hoge)]);
};

subtest 'create_path' => sub {
    my $builder = Spica::URIMaker->new(host => 'example.ry-m.com');
    $builder->create_path('/{main}', +{main => 'perl', sub => 'js'});
    is $builder->path => '/perl';
    is_deeply $builder->param => +{sub => 'js'};
    is $builder->as_string => 'http://example.ry-m.com/perl';
};

subtest 'create_query' => sub {
    my $builder = Spica::URIMaker->new(host => 'example.ry-m.com');
    $builder->param(+{main => 'perl'});
    $builder->create_query;
    is $builder->as_string => 'http://example.ry-m.com?main=perl';
};

subtest 'new_uri' => sub {
    my $builder = Spica::URIMaker->new(host => 'example.ry-m.com')->create(path_base => '/', param => +{});
    my $cloned = $builder->new_uri;
    $cloned->create(path_base => '/perl', param => +{sub => 'js'})->create_query;
    is $cloned->as_string => 'http://example.ry-m.com/perl?sub=js';
    is $builder->as_string => 'http://example.ry-m.com/';
};

done_testing;
