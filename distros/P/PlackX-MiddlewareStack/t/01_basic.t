use strict;
use warnings;
use PlackX::MiddlewareStack;
use Test::More;

ADD: {
    my $builder = PlackX::MiddlewareStack->new;
    $builder->add( 'Plack::Middleware::XFramework', { framework => 'Dog' } );
    $builder->add('Plack::Middleware::Static');
    my @keys = $builder->middleware_classes;
    is @keys, 2;
}

INSERT_AFTER: {
    my $builder = PlackX::MiddlewareStack->new;
    $builder->add( 'Plack::Middleware::XFramework', { framework => 'Dog' } );
    $builder->add('Plack::Middleware::Static');
    $builder->insert_after(
        'Plack::Middleware::Lint' => {},
        'Plack::Middleware::XFramework'
    );
    my @keys = $builder->middleware_classes;
    is $keys[1], 'Plack::Middleware::Lint';
}

INSERT_BEFORE: {
    my $builder = PlackX::MiddlewareStack->new;
    $builder->add( 'Plack::Middleware::XFramework', { framework => 'Dog' } );
    $builder->add('Plack::Middleware::Static');
    $builder->insert_before(
        'Plack::Middleware::Lint' => {},
        'Plack::Middleware::XFramework'
    );
    my @keys = $builder->middleware_classes;
    is $keys[0], 'Plack::Middleware::Lint';
}

TO_APP: {
    my $builder = PlackX::MiddlewareStack->new;
    $builder->add( 'Plack::Middleware::XFramework', { framework => 'Dog' } );
    my $handler = $builder->to_app(
        sub {
            [ 200, [], ['ok'] ];
        }
    );
    my $res = $handler->();
    is_deeply $res, [ 200, [ 'X-Framework' => 'Dog' ], ['ok'] ];
}

done_testing;
