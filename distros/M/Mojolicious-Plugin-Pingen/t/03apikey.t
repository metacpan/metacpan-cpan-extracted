#!/usr/bin/env perl
use FindBin;
use lib $FindBin::Bin.'/../thirdparty/lib/perl5';
use lib $FindBin::Bin.'/../lib';

use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

{
    use Mojolicious::Lite;
    plugin 'Pingen' => {mocked => 1, exceptions => 1, apikey => 'bad'};
    post '/upld' => sub {
        my $c = shift;
        eval {
           my $docId = $c->pingen->document->upload($c->req->upload('file'));
           $c->render(text=>$c->app->dumper($docId));
        };
        if ($@){
           return $c->render(text=>$@);
        }
    };
};

my $t = Test::Mojo->new;
my %form;

$t->post_ok('/upld', form => { file => { content => '%!pdf', filename=>'hellovelo'} })->status_is(200)->content_is('Your token is invalid or expired');

done_testing;
