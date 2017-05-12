use strict;
use warnings;
use Test::More 0.88;
use Plack::Builder;
use HTTP::Request::Common;
use Plack::Test;

my $built = 0;

{

    # big stupid fragile hack to record how many times builder is called
    no warnings 'redefine';
    require Plack::Middleware::Assets;
    my $builder = \&Plack::Middleware::Assets::_build_content;
    *Plack::Middleware::Assets::_build_content
        = sub { ++$built; goto $builder; };
    if ( $ENV{DEVEL_COVER_72819} && $INC{'Devel/Cover.pm'} ) {
        no warnings 'redefine';
        eval
            "*Plack::Middleware::Assets::$_ = sub { \$_[0]->{$_} = \$_[1] if \@_ > 1; \$_[0]->{$_} };"
            for qw(mtime minify type);
    }
}

my $mw = Plack::Middleware::Assets->new(
    files => [<t/static/*.js>],
    app   => sub { },
);

# avoid undefined warning
my $env = { PATH_INFO => '' };

{
    local $ENV{PLACK_ENV};

    $mw->call($env);
    is $built, 1, 'built once';

    $mw->call($env);
    is $built, 1, 'still built once';
}

{
    local $ENV{PLACK_ENV} = 'development';

    $mw->call($env);
    is $built, 1, 'still not rebuilt';

    $mw->mtime( $mw->mtime - 1 );

    $mw->call($env);
    is $built, 2, 'rebuilt when files look newer';

    $mw->call($env);
    is $built, 2, 'cached again';
}

{
    local $ENV{PLACK_ENV} = 'test';

    $mw->call($env);
    is $built, 2, 'not rebuilt if not development';

    $mw->mtime( $mw->mtime - 1 );

    $mw->call($env);
    is $built, 2, 'not rebuilt if not development even after mtime change';
}

done_testing;
