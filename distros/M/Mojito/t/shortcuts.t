use strictures 1;
use Test::More;
use Mojito::Model::Shortcuts;

my $content = '<section>With some <em>words</em> and a link shortcut: {{cpan MojoMojo}} for testing.</section>';
$content = Mojito::Model::Shortcuts->new->expand_shortcuts($content);
like($content, qr/<a href="http:\/\/search.cpan.org\/perldoc\?MojoMojo">MojoMojo<\/a>/, 'CPAN Link');

done_testing();