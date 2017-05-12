
package Proc::Forkfunc;

require Exporter;
require POSIX;
use Carp;

@ISA = (Exporter);
@EXPORT = qw(forkfunc);

use vars qw($VERSION);
$VERSION = 96.041701;

use strict;

sub forkfunc
{
    my ($func, @args) = @_;

    my $pid;

    {
	if ($pid = fork()) {
	    # parent
	    return $pid;
	} elsif (defined $pid) {
	    # child
	    &$func(@args);
	    croak "call to child returned\n";
	} elsif ($! == &POSIX::EAGAIN) {
	    my $o0 = $0;
	    $0 = "$o0: waiting to fork";
	    sleep 5;
	    $0 = $o0;
	    redo;
	} else {
	    croak "Can't fork: $!";
	}
    }
}

1;

__END__

=head1 NAME

Proc::Forkfunk -- fork off a function

=head1 SYNOPSIS

    use Proc::Forkfunc;

    forkfunc(\&child_func,@child_args);

=head1 DESCRIPTION

Fork off a process.  Call a function on the child process
the function should be passed in as a reference.  
The child function should not return.

Logic copied from somewhere, probably Larry Wall.

=head1 AUTHOR

David Muir Sharnoff <muir@idiom.com>

