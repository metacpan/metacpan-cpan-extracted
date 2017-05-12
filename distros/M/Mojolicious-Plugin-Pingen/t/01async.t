#!/usr/bin/env perl
use FindBin;
use lib $FindBin::Bin.'/../thirdparty/lib/perl5';
use lib $FindBin::Bin.'/../lib';

use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
{
    use Mojolicious::Lite;
    plugin 'Pingen' => {mocked => 1};
    post '/send/:fail' => sub {
        my $c = shift;
        my $fail = $c->param('fail');
        my $docId;
        $c->delay(
            sub { 
                $c->pingen->document->upload($c->req->upload('file'),shift->begin)
            },
            sub {
                my ($delay,$res)  = @_;
                if (not $res->{error}){
                    $docId = $res->{id};
                    $docId++ if $fail == 1;
                    $c->pingen->document->send($docId,{speed=>1},$delay->begin);
                }
                else {
                    return $c->render(json=>$res);
                }
            },
            sub {
                my ($delay,$res)  = @_;
                if (not $res->{error}){
                    $res->{id}++ if $fail == 2;
                    $c->pingen->send->cancel($res->{id},$delay->begin);
                }
                else {
                    return $c->render(json=>$res);
                }
            },
            sub {
                my ($delay,$res)  = @_;
                if (not $res->{error}){
                    $docId++ if $fail == 3;
                    $c->pingen->document->delete($docId,$delay->begin);
                }
                else {
                    return $c->render(json=>$res);
                }
            },
            sub {
                my ($delay,$res)  = @_;
                return $c->render(json=>$res);
            },
        );
    };
}

my $t = Test::Mojo->new;
my %form;

$t->post_ok('/send/0', form => { file => { content => '%!pdf', filename=>'hellovelo'} })->status_is(200)->json_is('/error', Mojo::JSON::false);
$t->post_ok('/send/1', form => { file => { content => '%!pdf', filename=>'hellovelo'} })->status_is(200)->json_is('/errormessage', 'You do not have rights to access this object');
$t->post_ok('/send/2', form => { file => { content => '%!pdf', filename=>'hellovelo'} })->status_is(200)->json_is('/errormessage', 'You do not have rights to access this object');
$t->post_ok('/send/3', form => { file => { content => '%!pdf', filename=>'hellovelo'} })->status_is(200)->json_is('/errormessage', 'You do not have rights to access this object');

done_testing;
