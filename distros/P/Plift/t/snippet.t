use strict;
use Test::More 0.98;
use FindBin;
use Plift;


my $engine = Plift->new(
    paths => ["$FindBin::Bin/templates"],
    snippet_namespaces => ['MyApp::Snippet']
);

my $ctx = $engine->template('snippet');

my $doc = $ctx->render({
    header => 'header snippet'
});

# note $doc->as_html;

is $doc->find('[data-plift], [data-snippet], [data-plift-snippet]')->size, 0;
is $doc->find('header')->text, 'header snippet', 'snippet context';
is $doc->find('#hello-user')->text, 'Hello, Cafe', 'snippet params';
is $doc->find('footer')->text, 'footer snippet', 'snippet set data and directives';



done_testing;


BEGIN {
    package MyApp::Snippet::Header;
    use Moo;

    sub process {
        my ($self, $element, $c) = @_;

        $element->text($c->get('header'));
    }

    package MyApp::Snippet::HelloUser;
    use Moo;

    sub process {
        my ($self, $element, $c, $params) = @_;

        $element->text('Hello, '.$params->{user});
    }

    package MyApp::Snippet::Footer;
    use Moo;

    sub process {
        my ($self, $el, $c) = @_;

        $c->set( footer => { msg => 'footer snippet' })
          ->at('footer' => 'footer.msg');
    }
}
