use strict;
use warnings;
package PidTracker;

our $instance = -1;
our $VERSION = '1.234';

sub new
{
    my ($class, %opts) = @_;
    return bless {
        pid => $$,
        instance => ++$instance,
        $opts{recreated_from} ? ( recreated_from => $opts{recreated_from} ) : (),
    }, $class;
}

sub pid { shift->{pid} }

sub instance { shift->{instance} }

sub recreated_from { shift->{recreated_from} }

sub foo { 'a sub that returns foo' }

1;
