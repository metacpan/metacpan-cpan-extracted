#!perl

use Test::More;
use Test::Mojo;
use Mojolicious;

my $t = Test::Mojo->new( Mojolicious->new );
$t->app->plugin('AntiSpamMailTo');
$t->app->routes->get("/" => 'index');

# HTML/XML
$t->get_ok('/')->status_is(200)->content_is(
    '<p><a
    href="&#109;&#97;&#105;&#108;&#116;&#111;&#58;&#122;&#111;&#102;&#102;&#105;&#120;&#64;&#99;&#112;&#97;&#110;&#46;&#99;&#111;&#109;">
        Send me an email at &#122;&#111;&#102;&#102;&#105;&#120;&#64;&#99;&#112;&#97;&#110;&#46;&#99;&#111;&#109;
</a></p>
'
);

done_testing();

__DATA__

@@ index.html.ep

<p><a
    href="<%== mailto_href 'zoffix@cpan.com' %>">
        Send me an email at <%== mailto 'zoffix@cpan.com' %>
</a></p>