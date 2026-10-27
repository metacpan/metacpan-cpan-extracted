use strict;
use warnings;

use Test::More;
use Mojolicious::Lite;

my $HAVE_PACKER = eval { require HTML::Packer; 1 } ? 1 : 0;

my $log = '';
open(my $log_fh, '>', \$log) or die $!;
app->log->handle($log_fh);
app->log->level('debug');

plugin 'Buffer' => {optimise_content => 1};

get '/' => sub {
	my $c = shift;
	$c->render(text => "<html>\n  <body>\n    <!-- a comment -->\n    <p>Hello   World</p>\n  </body>\n</html>");
};

use Test::Mojo;

my $t = Test::Mojo->new;
$t->ua->transactor->compressed(0);
$t->get_ok('/')->status_is(200);

my $body = $t->tx->res->body;
if ($HAVE_PACKER) {
	unlike($body, qr/a comment/, 'the plugin was loaded by name and optimised the response');
} else {
	like($body, qr/a comment/, 'comments are kept without HTML::Packer');
	like($log, qr/HTML::Packer is not installed/, 'the missing module was noted');
	unlike($log, qr/HTML::Packer failed/, 'no HTML::Packer failure was logged');
}
like($body, qr/<p>Hello World<\/p>/, 'white space was squashed');

done_testing();
