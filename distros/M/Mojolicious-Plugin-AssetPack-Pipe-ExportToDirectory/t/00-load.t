#!perl -T
# vim:syntax=perl:tabstop=4:number:noexpandtab:

use Test::More tests => 1;

BEGIN {
	use_ok('Mojolicious::Plugin::AssetPack::Pipe::ExportToDirectory') || print "Bail out!";
}

diag( "Testing Mojolicious::Plugin::AssetPack::Pipe::ExportToDirectory  $Mojolicious::Plugin::AssetPack::Pipe::ExportToDirectory::VERSION, Perl $], $^X" );
