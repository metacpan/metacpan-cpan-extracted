#!perl -T

use Test::Base;
use Template;
use Template::Plugin::Filter::HTMLScrubber;

plan tests => 5;

my $tt = Template->new({
		PLUGINS => {
				HTMLScrubber => 'Template::Plugin::Filter::HTMLScrubber'
		}
});

ok($tt);
ok(UNIVERSAL::isa($tt, 'Template'));

sub default_sanitize {
		my $input = $_[0];
		my $output;
		$tt->process(\$input, undef, \$output);
		return $output;
}

run_is 'input' => 'expected';

__END__
=== Simple sanitize test
--- input default_sanitize
[% USE HTMLScrubber %][% FILTER html_scrubber %]<script type="text/javascript" src="/js/prototype.js">window.alert();</script>test[% END %]
--- expected
test
=== Simple sanitize test2
--- input default_sanitize
[% USE HTMLScrubber %][% FILTER html_scrubber %]<img src="http://your.photo.jpg"><img src="javascript:alert();">[% END %]
--- expected
<img src="http://your.photo.jpg"><img>
=== Optional sanitize test
--- input default_sanitize
[% USE HTMLScrubber %][% FILTER html_scrubber(['-img']) %]<img src="http://your.photo.jpg"><br>[% END %]
--- expected
<br>
