use Mojo::Base -strict;

use Test::More;

use Mojolicious::Lite;
use Test::Mojo;

use lib '../lib';

use File::Basename qw/dirname/;
use File::Spec::Functions qw/rel2abs/;

my $FILE = rel2abs( dirname(__FILE__) . '/' . 'sample.txt' );

plugin 'RenderFile';

get '/default' => sub {
    my $self = shift;
    $self->render_file( filepath => $FILE );
};

get '/data' => sub {
    my $self = shift;
    $self->render_file( data => 'data to download', filename => 'sample.txt' );
};

get '/data/custom_content_type' => sub {
    my $self = shift;
    $self->render_file(
        data         => 'data to download',
        filename     => 'sample.txt',
        content_type => 'application/pdf'
    );
};

get '/data/no_filename' => sub {
    my $self = shift;
    $self->render_file( data => 'data to download' );
};

get '/all_attrs' => sub {
    my $self = shift;
    $self->render_file(
        filepath => $FILE,
        filename => 'mysample.txt',
        status => 201,
        format => 'pdf',
        content_disposition => 'inline'
    );
};


my $t = Test::Mojo->new;

$t->get_ok('/default')
    ->status_is(200)
    ->content_is('file to download')
    ->content_type_is('application/x-download;name="sample.txt"')
    ->header_is( 'Content-Disposition' => 'attachment;filename="sample.txt"' );

$t->get_ok('/all_attrs')
    ->status_is(201)
    ->content_is('file to download')
    ->content_type_is('application/pdf;name="mysample.txt"')
    ->header_is( 'Content-Disposition' => 'inline;filename="mysample.txt"' );

$t->get_ok('/default' => { 'Range' => 'bytes=5-' })
    ->status_is(206)
    ->content_is('to download')
    ->content_type_is('application/x-download;name="sample.txt"')
    ->header_is( 'Content-Disposition' => 'attachment;filename="sample.txt"' );

$t->get_ok('/default' => { 'Range' => 'bytes=5-6' })
    ->status_is(206)
    ->content_is('to')
    ->content_type_is('application/x-download;name="sample.txt"')
    ->header_is( 'Content-Disposition' => 'attachment;filename="sample.txt"' );

$t->get_ok('/default' => { 'Range' => 'bytes=17-3' })
    ->status_is(416);

$t->get_ok('/data')
    ->status_is(200)
    ->content_is('data to download')
    ->content_type_is('application/x-download;name="sample.txt"')
    ->header_is( 'Content-Disposition' => 'attachment;filename="sample.txt"' );

$t->get_ok('/data' => { 'Range' => 'bytes=5-' })
    ->status_is(206)
    ->content_is('to download')
    ->content_type_is('application/x-download;name="sample.txt"')
    ->header_is( 'Content-Disposition' => 'attachment;filename="sample.txt"' );

$t->get_ok('/data' => { 'Range' => 'bytes=5-6' })
    ->status_is(206)
    ->content_is('to')
    ->content_type_is('application/x-download;name="sample.txt"')
    ->header_is( 'Content-Disposition' => 'attachment;filename="sample.txt"' );

$t->get_ok('/data/custom_content_type' => { 'Range' => 'bytes=5-6' })
    ->status_is(206)
    ->content_is('to')
    ->content_type_is('application/pdf;name="sample.txt"')
    ->header_is( 'Content-Disposition' => 'attachment;filename="sample.txt"' );

$t->get_ok('/data/no_filename')
    ->status_is(200)
    ->content_is('data to download')
    ->content_type_is('application/x-download;name="no_filename"')
    ->header_is( 'Content-Disposition' => 'attachment;filename="no_filename"' );


done_testing();
