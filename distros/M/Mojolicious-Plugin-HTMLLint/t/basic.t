use Mojo::Base -strict;

use Test::More;

use Mojolicious::Lite;
use Test::Mojo;

my $error_string = '';

plugin 'HTMLLint' => { on_error => sub { $error_string = $_[1]; } };

get '/wrongattr' => sub {
    my $self = shift;
    $self->render('wrongattr');
};

get '/never_closed_div' => sub {
    my $self = shift;
    $self->render('never_closed_div');
};

my $t = Test::Mojo->new;

subtest 'wrongattr' => sub {
  $error_string = '';
  $t->get_ok('/wrongattr')->status_is(200)->content_like(qr{<a WRONGATTTR></a>});
  ok( $error_string =~ /Unknown attribute "wrongatttr"/, 'should be error about unknown attr');
};

subtest 'never_closed_div' => sub {
  $error_string = '';
  $t->get_ok('/never_closed_div')->status_is(200)->content_like(qr{<div>test<div>});
  ok( $error_string =~ /div.+is never closed/, 'should be error about never closed div') ;
};

done_testing;

__DATA__;

@@wrongattr.html.ep
<html>
    <head><title></title></head>
    <body><a WRONGATTTR></a></body>
</html>

@@never_closed_div.html.ep
<html>
    <head><title></title></head>
    <body><div>test<div></body>
</html>
