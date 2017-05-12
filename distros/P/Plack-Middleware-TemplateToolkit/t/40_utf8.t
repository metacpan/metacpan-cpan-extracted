use Test::More;
use File::Spec;
use Plack::Middleware::TemplateToolkit;
use Plack::Builder;
use Plack::Test;
use HTTP::Request::Common;
use Encode;

#use encoding::warnings; # used for development

my $root = File::Spec->catdir( "t", "root" );

my $snowman = "\x{2603}";
my $smiley  = "\x{263A}";

# encode utf8
my $app = Plack::Middleware::TemplateToolkit->new( INCLUDE_PATH => $root );
test_psgi $app, sub {
    my $res = shift->(GET '/vars.html');
    is $res->content, '', 'empty template';
};
test_psgi $app, sub {
    my $res = shift->(GET '/unicode.html');
    is $res->content, encode('utf-8',"$snowman\x0A"), 'unicode template';
};

# template variables must be unicode if template is unicode
my $env = { PATH_INFO => '/vars.html', 'tt.vars' => { foo => $smiley, } };

my $res = $app->call( $env );
my ($str) = @{$res->[2]};

is $str, pack('H*','E298BA'), "unicode variables in template are encoded";
ok( $str =~ /[^\x00-\x7f]/ && !utf8::is_utf8($str), 'so it\'s not UTF-8' );


$app = Plack::Middleware::TemplateToolkit->new(
    INCLUDE_PATH  => $root,
    request_vars => ['parameters'],
);
test_psgi $app, sub {
    my $res = shift->(GET '/unicode.html?foo=bar');
    is $res->content, encode('utf-8',"${snowman}bar\x0A"), 'with parameter';
};
test_psgi $app, sub {
    my $res = shift->(GET '/unicode.html?foo=%E2%98%BA');
    is $res->content, encode('utf-8',"${snowman}${smiley}\x0A"), 'unicode parameter';
};


# allow utf8
$app = Plack::Middleware::TemplateToolkit->new( 
    INCLUDE_PATH => $root, encode_response => 0 );
$app->prepare_app;

$res = $app->call( $env );
($str) = @{$res->[2]};

ok( utf8::is_utf8($str), 'allowed utf8 is UTF8' );
ok( $str =~ /[^\x00-\x7f]/, 'allowed utf8 look\'s like UTF8' );
is( $str, $smiley, 'utf8 passed through' );


done_testing;
