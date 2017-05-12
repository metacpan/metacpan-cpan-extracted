#!/usr/bin/env perl
use Mojo::Base -strict;
use Mojolicious::Lite;
use Mojo::ByteStream 'b';
use Test::Mojo;
use Test::More;
use Mojo::DOM;
use Mojo::URL;

$|++;

use lib '../lib';

my $t = Test::Mojo->new;
my $app = $t->app;

$app->plugin('TagHelpers::MailToChiffre' => {
  pattern_rotate => 8
});

my $css = $app->mail_to_chiffre_css;
ok($css =~ m/^a\[onclick\$='return ([a-zA-Z]+?)\(this,false\)'/, 'css is as expected');
my $method_name = $1;

my $js = $app->mail_to_chiffre_js;
like($js, qr/^function $method_name\(/, 'js is as expected');
like($js, qr/\(2,3\)/, 'pattern shift is as expected');

$css = $app->mail_to_chiffre_css;
ok($css =~ m/^a\[onclick\$='return $method_name\(this,false\)'/, 'css is still as expected');

sub url_to_sort {
  my $url = shift;
  my $s = $url->scheme .':';
  $s .= $url->path;
  my $x = $url->query->to_hash;
  $s .= '?' . join('&' , sort map( $_ . '=' . (ref $x->{$_} ? join(',', @{$x->{$_}}) : $x->{$_}), keys %$x ) );
};

# New start
$t = Test::Mojo->new;
$app = $t->app;

$app->plugin('TagHelpers::MailToChiffre' => {
  pattern_rotate => 9,
  method_name => $method_name
});

my $a = $app->mail_to_chiffre('akron@batteriehuhn.de')->to_string;
$a = Mojo::DOM->new($a)->at('a');
like($a->attr('href'), qr/^javascript:/, 'No fallback route');
like($a->attr('onclick'), qr/^return true;/, 'No fallback route');

done_testing;

__END__
