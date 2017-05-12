# Copyrights 2012 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.00.
use warnings;
use strict;

package Mozilla::Persona::Aliases::MailConfig;
use vars '$VERSION';
$VERSION = '0.12';

use base 'Mozilla::Persona::Aliases';

use Log::Report         qw/persona/;
use Mail::ExpandAliases ();


sub init($)
{   my ($self, $args) = @_;

    # Mail::ExpandAliases support only one file
    $self->{MPAM_file} = delete $args->{file};
    $self->SUPER::init($args);
    $self;
}

sub _table()
{   my $self = shift;
    $self->{MPAM_table} ||= Mail::ExpandAliases->new($self->{MPAM_file});
}

sub for($)
{   my ($self, $user) = @_;
    $user =~ s/\@.*//;
    $self->_table->expand($user);
}

1;
