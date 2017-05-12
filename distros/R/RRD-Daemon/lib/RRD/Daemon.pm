package RRD::Daemon;

# pragmata ----------------------------

use feature qw( :5.10 );
use strict;
use warnings;

# utility -----------------------------

use Module::Pluggable
  sub_name => 'plugins',  # default, explicit for searchability
  require  => 1,          # do a require on subclasses
#  file_regex => qr!(?(?=/CVS/).xxx$|\.pm$)!;
#  except   => qr/::CVS::Base::/;
  ;

BEGIN {
  # override Module::Pluggable::Object::find_files to ignore files in CVS
  # directories
  # I tried using file_regex, but cannot find a regex that excludes /CVS/ but otherwise allows .pm
  # I tried using except, but the module is still loaded even though it is not used
  # Since Module::Pluggable::Object is not directly used by us, to inherit & override
  # I would have to inherit & override import from Module::Pluggable itself, too; 
  # which would bind very tightly to the current implementation of Module::Pluggable.
  # The below is simpler, and there's something to be said for simpler
  
  my $find_files_orig = \&Module::Pluggable::Object::find_files;
  no warnings 'redefine';
  *Module::Pluggable::Object::find_files = 
    sub { grep !m!/CVS/!, $find_files_orig->(@_) };
}

# constants ------------------------------------------------------------------

our $VERSION = '1.01';

# methods --------------------------------------------------------------------

sub listp {
  print "P> $_\n"
    for $_[0]->plugins;
}

# ----------------------------------------------------------------------------

1; # keep require happy
