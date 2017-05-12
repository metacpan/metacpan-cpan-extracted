use warnings;
use strict;
use FindBin '$Bin';
use Test::More;
use Module::Cloud;
my $clouder = Module::Cloud->new(dir => "$Bin/..");
my $cloud   = $clouder->get_cloud->html_and_css;
my @modules = qw(
  File::Find::Rule::MMagic HTML::TagCloud
  Module::ExtractUse strict warnings
);
plan tests => scalar @modules;

for my $module (@modules) {
    like(
        $cloud,
qr!<span class="tagcloud\d+"><a href="http://search.cpan.org/search\?query=$module">$module</a></span>!,
        "contains tagcloud span for $module"
    );
}
