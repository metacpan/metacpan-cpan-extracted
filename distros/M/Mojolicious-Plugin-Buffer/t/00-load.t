use strict;
use warnings;

use Test::More;

# Every module in the distribution loads, and they all carry the same
# version, so a release cannot ship with one module left behind.  The
# version itself is not repeated here, so bumping it needs no test edit.
my @modules = qw(
	Mojolicious::Plugin::Buffer
	Mojolicious::Plugin::Buffer::I18N
	Mojolicious::Plugin::Buffer::Lock::File
	Mojolicious::Plugin::Buffer::Lock::Redis
);

use_ok($_) for @modules;

my $version = Mojolicious::Plugin::Buffer->VERSION;
like("$version", qr/\A\d+\.\d{3}\.\d+\z/, "the version $version is a three-part dotted decimal");

for my $module (@modules[1 .. $#modules]) {
	is($module->VERSION, $version, "$module has the distribution version");
}

done_testing();
