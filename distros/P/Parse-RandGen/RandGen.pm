# $Revision: #4 $$Date: 2005/08/31 $$Author: jd150722 $
######################################################################
#
# This program is Copyright 2003-2005 by Jeff Dutton.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of either the GNU General Public License or the
# Perl Artistic License.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# If you do not have a copy of the GNU General Public License write to
# the Free Software Foundation, Inc., 675 Mass Ave, Cambridge, 
# MA 02139, USA.
######################################################################

package Parse::RandGen;

require 5.006_001;
use Carp;
use Data::Dumper;

BEGIN {
    require Exporter;
    @ISA = ('Exporter');
    @EXPORT_OK = qw($Debug);
}

use strict;
use vars qw($VERSION $Debug);
$VERSION = '0.202';
#$Debug = 1;  # Set to turn on debugging

# Use all of the components of this package (so each module doesn't have to replicate the code)
use Parse::RandGen::Condition;
use Parse::RandGen::Production;
use Parse::RandGen::Rule;
use Parse::RandGen::Grammar;
use Parse::RandGen::Subrule;
use Parse::RandGen::Literal;
use Parse::RandGen::CharClass;
use Parse::RandGen::Regexp;

######################################################################
#### Package return
1;
__END__

=pod

=head1 NAME

Parse::RandGen - Package for the creation of randomly generated parse data

=head1 DESCRIPTION

This package contains modules that can be used to randomly generate parse data
(that will either match or not match the grammatical specification).  The primary
use for randomly generated parse data is to test parsers (or just regular expressions).

The most concise and useful function of this package is to create random data
that matches or doesn't match a given regular expression (see B<Parse::RandGen::Regexp>).

For example, 'Parse::RandGen::Regexp->new(qr/foo(bar|baz)*/)->pick()' will return
strings such as 'foo', 'foobaz', 'foobazbarbarbaz', etc....

Additionally, the package may be used to build a BNF style Grammar object, composed of Rules,
Productions, and various types of Conditions (Literals, Regexps, Subrules) and randomly create
data based on the grammatical specification.

=head1 SEE ALSO

B<Parse::RandGen::Regexp>,
B<Parse::RandGen::Grammar>,
B<Parse::RandGen::Rule>,
B<Parse::RandGen::Production>,
B<Parse::RandGen::Condition>,
B<Parse::RandGen::Subrule>,
B<Parse::RandGen::Literal>, and
B<Parse::RandGen::CharClass>

=head1 AUTHORS

Jeff Dutton

=cut
######################################################################
