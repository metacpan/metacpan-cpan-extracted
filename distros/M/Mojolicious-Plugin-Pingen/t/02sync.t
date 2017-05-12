#!/usr/bin/env perl
use FindBin;
use lib $FindBin::Bin.'/../thirdparty/lib/perl5';
use lib $FindBin::Bin.'/../lib';

use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
{
    use Mojolicious::Lite;
    plugin 'Pingen' => {mocked => 1, exceptions => 1};
    post '/send' => sub {
        my $c = shift;
        my $docId = $c->pingen->document->upload($c->req->upload('file'))->{id};
        my $sendId = $c->pingen->document->send($docId,{speed=>1})->{id};
        $c->pingen->send->cancel($sendId);
        $c->pingen->document->delete($docId);
        $c->render(text=>'done');
    };
}

my $t = Test::Mojo->new;
my %form;

$t->post_ok('/send', form => { file => { content => '%!pdf', filename=>'hellovelo'} })->status_is(200)->content_is('done');

done_testing;
