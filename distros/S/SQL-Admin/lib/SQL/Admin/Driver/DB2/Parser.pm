
package SQL::Admin::Driver::DB2::Parser;
use base qw( SQL::Admin::Driver::Base::Parser );

use strict;
use warnings;

our $VERSION = v0.5.0;

######################################################################

use SQL::Admin::Utils qw( refhash refarray );

######################################################################

my $grammar = require SQL::Admin::Driver::DB2::Grammar;
my $cached;

######################################################################
######################################################################
sub new {                                # ;
    my $class = shift;

    $cached ||= $class->SUPER::new (@_);
    bless { @_, parser => $cached->{parser} }, ref $class || $class;
}


######################################################################
######################################################################
sub grammar {                             # ;
    $grammar;
}


######################################################################
######################################################################

package SQL::Admin::Driver::DB2::Parser;

1;
