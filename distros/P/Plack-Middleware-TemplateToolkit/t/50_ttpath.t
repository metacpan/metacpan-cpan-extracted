use Test::More;
use Plack::Builder;
use Plack::Middleware::TemplateToolkit;
use File::Spec;

my $root = File::Spec->catdir( "t"  );

my $app = Plack::Middleware::TemplateToolkit->new(
    INCLUDE_PATH => $root,
    path => 'root'
);

my $env = { PATH_INFO => '/root/' }; 
$res = $app->( $env );
is( $env->{'tt.path'}, '/root/', 'tt.path' );
is( $env->{'tt.template'}, 'root/index.html', 'tt.template' );

$env = { PATH_INFO => '/notmypath' };
$res = $app->( $env );
is( $env->{'tt.path'}, undef, 'path did not match' );

$env = { 
    PATH_INFO => '/notmypath', 'tt.path' => '/root/vars.html', 
};
$res = $app->( $env );
is( $env->{'tt.path'}, '/root/vars.html', 'tt.path set before' );
is( $res->[0], 200, 'found the template' );
is( $env->{'tt.template'}, 'root/vars.html', 'tt.template set' );

$env = { 
    PATH_INFO => '/notmypath', 'tt.path' => '/root/vars.html', 
    'tt.template' => 'root/index.html', # rules above all
};
$res = $app->( $env );
is( $res->[0], 200, 'found the template' );
is( $env->{'tt.template'}, 'root/index.html', 'tt.template still set' );
is( $env->{'tt.path'}, undef, 'tt.path removed' );

done_testing;
