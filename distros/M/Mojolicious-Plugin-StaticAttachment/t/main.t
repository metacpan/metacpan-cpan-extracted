use Mojo::Base -strict;

use Test::More;

use Mojolicious::Lite;
use Test::Mojo;
#~ use Mojo::Util qw'encode decode';

plugin 'StaticAttachment'=>paths=>['/sample00.txt', '/sample.txt'=>{filename=>"образец.txt"}, '/образец.txt'=>{content_type=>"app/foo"},];

my $content_type = 'text/plain;charset=UTF-8;name="образец.txt"';
utf8::encode($content_type);
my $content_disp = 'attachment;filename="образец.txt"';
utf8::encode($content_disp);

my $t = Test::Mojo->new;

$t->get_ok('/sample.txt')
    ->status_is(200)
    ->content_is('Доброго всем')
    ->content_type_is( $content_type )
    ->header_is( 'Content-Disposition' => $content_disp );

$content_type = 'app/foo;name="образец.txt"';
utf8::encode($content_type);
$t->get_ok('/образец.txt')
    ->status_is(200)
    ->content_is('Доброго всем')
    ->content_type_is( $content_type )
    ->header_is( 'Content-Disposition' => $content_disp );

done_testing();
