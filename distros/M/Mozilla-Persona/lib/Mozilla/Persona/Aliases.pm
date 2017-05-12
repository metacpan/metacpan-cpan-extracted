# Copyrights 2012 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.00.
use warnings;
use strict;

package Mozilla::Persona::Aliases;
use vars '$VERSION';
$VERSION = '0.12';

use Log::Report  qw/persona/;


sub new(%) { my $class = shift; (bless {}, $class)->init({@_}) }
sub init($)
{   my ($self, $args) = @_;
    $self;
}

#-----------------------------

sub for($)
{   my ($self, $user) = @_;
    ($user);
}

1;
