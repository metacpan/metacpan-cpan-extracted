#!perl -w
use strict;

use Ruby qw(rb_const);
use Config;

sub print_version
{
	my($name, $version, $platform) = @_;
	printf "%s %s [%s]\n", $name, $version, $platform;
}

print_version 'ruby', rb_const(RUBY_VERSION), rb_const(RUBY_PLATFORM);

print_version 'perl', $Config{version},  $Config{archname};
