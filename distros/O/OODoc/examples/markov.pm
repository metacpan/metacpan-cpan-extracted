# Copyrights 2003-2015 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
# This is an example package file for a OODoc::Parser::Markov documentation
# set-up.  Other syntax parsers can be added to OODoc.  You may also add
# all documentation to the end of the file, if you want to... as long as
# it stays in the same package name scope.

use warnings;
use strict;

package My::Name::Space;
use vars '$VERSION';
$VERSION = '2.01';

use base 'My::Other::Module';   # will result in INHERITANCE block autom

# I put these next declarations above NAME, but may also be included after
# the SYNOPSIS or DESCRIPTION.  These are the most important things for
# code maintainers, that's why I put them this visible.
use Getopt::Long;
my $verbose = 1;
### end of declarations.


sub new(@)
{   my ($class, %args) = @_;
    ...
}


sub clone() { bless { %{$_[0]} }, ref $_[0] }


1;  # all package should end with this.
# Usually, the REFERENCES, COPYRIGHTS and LICENSE sections are added
# by the formatter: see PODTAIL in oodist.  That makes life simple:
# you do not have to copy things over all manual pages yourself.
# Also the DIAGNOSTICS block has to be added by the formatter.
