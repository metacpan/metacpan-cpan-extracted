#!/usr/bin/perl
use Plack::Loader;
(my $file = __FILE__)
	=~ s/cgi$/psgi/;
my $app = Plack::Util::load_psgi($file);
Plack::Loader->auto->run($app);
