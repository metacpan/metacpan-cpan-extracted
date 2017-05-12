#!perl

use Mojolicious::Lite;
use Test::More tests => 5;
use Test::Mojo;

app->log->level('fatal');

plugin 'write_excel';

my $data =
  [[qw(Zak B. Elep)], [qw(Joel T Tanangonan)], [qw(Jerome S Gotangco)]];

get '/demo.xls' => sub {
  shift->render_xls(result => $data);
};

# Test
my $t = Test::Mojo->new;

$t->get_ok('/demo.xls')->status_is(200)
  ->content_like(qr/Zak/,    "Zak's in the spreadsheet")
  ->content_like(qr/Joel/,   "Joel's in the spreadsheet")
  ->content_like(qr/Jerome/, "Jerome's in the spreadsheet");
