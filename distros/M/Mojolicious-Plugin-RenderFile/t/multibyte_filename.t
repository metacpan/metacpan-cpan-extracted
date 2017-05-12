use utf8;
use Mojo::Base -strict;

use Test::More;
use Encode;
use File::Copy qw( copy );
use File::Temp qw( tempdir );

use Mojolicious::Lite;
use Test::Mojo;

use lib '../lib';
use utf8;

use File::Basename qw/dirname/;
use File::Spec::Functions qw/rel2abs/;

my $FILE = rel2abs( tempdir( CLEANUP => 1)  . '/' . '漢字.txt' );
copy( rel2abs( dirname(__FILE__) . '/' . 'unicode.txt' ), $FILE) 
  || plan skip_all => 'unable to create file with unicode filename';

plugin 'RenderFile';

get "/default" => sub {
    my $self = shift;
    $self->render_file(
        filepath => $FILE
    );
};

get "/filename" => sub {
    my $self = shift;
    $self->render_file(
        filepath => $FILE,
        filename => '別名.txt',
    );
};

get "/encoded" => sub {
    my $self = shift;
    $self->render_file(
        filepath => encode_utf8 $FILE,
    );
};

get "/encoded_filename" => sub {
    my $self = shift;
    $self->render_file(
        filepath => encode_utf8 $FILE,
        filename => encode_utf8 '別名.txt',
    );
};


my $t = Test::Mojo->new;

$t->get_ok("/default")
    ->status_is(200)
    ->content_is( '漢字（かんじ）は、古代中国に発祥を持つ文字。' )
    ->header_is( 'Content-Disposition' => encode_utf8 'attachment;filename="漢字.txt"' );

$t->get_ok("/filename")
    ->status_is(200)
    ->header_is( 'Content-Disposition' => encode_utf8 'attachment;filename="別名.txt"' );

$t->get_ok("/encoded")
    ->status_is(200)
    ->header_is( 'Content-Disposition' => encode_utf8 'attachment;filename="漢字.txt"' );

$t->get_ok("/encoded_filename")
    ->status_is(200)
    ->header_is( 'Content-Disposition' => encode_utf8 'attachment;filename="別名.txt"' );

done_testing();
