#########
# An example of how to derive from Module::PortablePath
# and supply site-specific paths which aren't /etc/perlconfig.ini
#
# You'd probably want to rename this file and package
# from siteexample to something like MySitePaths
#
# then your scripts could:
# use MySitePaths qw(myapp1 mylibs2);
#
package siteexample;
use strict;
use warnings;
use Module::PortablePath;
our $VERSION = q[0.07];

sub import {
  $Module::PortablePath::CONFIGS = {
				    'default'      => q[/path/to/mysite/default/perlconfig.ini],
				    '^webcluster'  => q[/lustre/data/www/conf/perlconfig.ini],
				    '^workcluster' => q[/work/conf/perlconfig.ini],
				   };

  &Module::PortablePath::import(@_);
}

sub config         { return &Module::PortablePath::config(@_); }
sub _import_libs   { return &Module::PortablePath::_import_libs(@_); }
sub _import_ldlibs { return &Module::PortablePath::_import_ldlibs(@_); }
sub dump           { return &Module::PortablePath::dump(@_); }

1;
