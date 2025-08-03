# This is an example package file for a OODoc::Parser::Markov documentation
# set-up.  Other syntax parsers can be added to OODoc.  You may also add
# all documentation to the end of the file, if you want to... as long as
# it stays in the same package name scope.

use warnings;
use strict;

package My::Name::Space;
use parent 'My::Other::Module';   # will result in INHERITANCE block autom

# I put these next declarations above NAME, but may also be included after
# the SYNOPSIS or DESCRIPTION.  These are the most important things for
# code maintainers, that's why I put them this visible.
use Getopt::Long;
my $verbose = 1;
### end of declarations.

=chapter NAME

My::Name::Space - just an example

=chapter SYNOPSIS

 my $obj = My::Name::Space->new;
 $obj->print;

=chapter DESCRIPTION

General description of the module.  Some people make this very long,
before the start of the explanation of the functions or methods.  My
preference is to explain only the really really important stuff which
should be read by everyone.  All less import things are kept in a
chapter named DETAILS after the explanation of functions and stuff such
that important things come first.

=chapter OVERLOADED
=chapter FUNCTIONS
=chapter METHODS
take whatever you need in the order you wish to define it (order of the
chapters is only determined by the output templates of the formatter)

=section Constructors
It is useful to use sections to group methods or functions when the number
of them grows large.  The methods and functions will get sorted
alphabetically, and you do not want the "new" to disappear far down in
the list.

=method new %options
Create a new object.  Read all about the =option, =default, =example, and
so on in the manual-page of the OODoc::Parser::Markov.
=cut

sub new(@)
{   my ($class, %args) = @_;
    ...
}

=method clone
Make a copy of the object.
=cut

sub clone() { bless { %{$_[0]} }, ref $_[0] }

=section Accessors
And so on.  Do not forget the C<=cut>'s!

=chapter DETAILS

Here I put the detailed explanation, especially about how different methods
and functions work together.

Again: do not forget the next line!!!
=cut

1;  # all package should end with this.
# Usually, the REFERENCES, COPYRIGHTS and LICENSE sections are added
# by the formatter: see PODTAIL in oodist.  That makes life simple:
# you do not have to copy things over all manual pages yourself.
# Also the DIAGNOSTICS block has to be added by the formatter.
