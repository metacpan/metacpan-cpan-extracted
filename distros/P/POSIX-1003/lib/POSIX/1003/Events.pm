# Copyrights 2011-2020 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.02.
# This code is part of distribution POSIX-1003.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package POSIX::1003::Events;
use vars '$VERSION';
$VERSION = '1.02';

use base 'POSIX::1003::Module';

use warnings;
use strict;

my (@constants, @poll);

my @functions = qw/
  FD_CLR FD_ISSET FD_SET FD_ZERO select
  poll events_names
 /;

our %EXPORT_TAGS =
 ( constants => \@constants
 , poll      => \@poll
 , functions => \@functions
 );

my $events;

BEGIN {
    $events = events_table;
    push @constants, keys %$events;

    @poll = qw(poll events_names);
    push @poll, grep /^POLL/, keys %$events;
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

sub events_names() { keys %$events }

sub _create_constant($)
{   my ($class, $name) = @_;
    my $val = $events->{$name} // return sub() {undef};
    sub() {$val};

}
#----------------------

1;
