# Copyrights 2011-2013 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use warnings;
use strict;

package POSIX::1003::Events;
use vars '$VERSION';
$VERSION = '0.98';

use base 'POSIX::1003::Module';

my @constants;
my @functions = qw/
  FD_CLR FD_ISSET FD_SET FD_ZERO select
  poll poll_names
 /;

my @poll = qw(poll poll_names);

our %EXPORT_TAGS =
 ( constants => \@constants
 , functions => \@functions
 );

my  $poll;

BEGIN {
    $poll = poll_table;
    push @constants, keys %$poll;
}


sub select($$$;$)
{   push @_, undef if @_==3;
    goto &select;
}


sub FD_CLR($$)   {vec($_[1],$_[0],1) = 0}
sub FD_ISSET($$) {vec($_[1],$_[0],1) ==1}
sub FD_SET($$)   {vec($_[1],$_[0],1) = 1}
sub FD_ZERO($)   {$_[0] = 0}


sub poll($;$)
{   my ($data, $timeout) = @_;
    defined $timeout or $timeout = -1;
    _poll($data, $timeout);
}

#----------------------

sub poll_names() { keys %$poll }

sub _create_constant($)
{   my ($class, $name) = @_;
    $name =~ m/^POLL/
        or die "constants expected to start with POLL, not $name\n";
    my $val = $poll->{$name} // return sub() {undef};
    sub() {$val};

}
#----------------------

1;
