use strict;
use warnings;
use File::Spec;
use File::Basename 'dirname';
use Config::Micro;
use lib (
    File::Spec->catdir(dirname(__FILE__), 'lib'), 
);
use Nephia::TestApp;
my $config = require( Config::Micro->file( dir => File::Spec->catdir('etc','conf') ) );
Nephia::TestApp->run( %$config );
