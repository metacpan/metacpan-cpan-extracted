use Mojo::Base -strict;
 
# Disable IPv6 and libev
BEGIN {
  $ENV{MOJO_NO_IPV6} = 1;
}
 
use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

plugin 'JavaScript::Console';

get '/' => sub {
    my $self = shift;

    $self->console->group( 'group1' );
    $self->console->log( 'test log' );
    $self->console->group_end;
    $self->render( 'test' );
};

my $t = Test::Mojo->new;
 
# GET /

my $check = qq~<script charset="utf-8" defer>(function(console) {if (! console) { return; }console.group("group1");console.log("test log");console.groupEnd();})(window.console);</script>\n~;
$t->get_ok('/')->status_is(200)->content_is($check);

done_testing();

__DATA__
@@test.html.ep
<%= Mojo::ByteStream->new( console()->output ) %>
