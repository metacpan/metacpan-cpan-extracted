package ReleaseAction;
use Exporter;
@ISA = 'Exporter';
@EXPORT_OK = 'on_release';
$VERSION = 0.07;
use strict;

sub DESTROY {
  my ($self, @args) = @{shift(@_)};
  $self->(@args);
}

sub cancel {
  my $self = shift;
  @$self = sub {};
}

sub new {
  my $class = shift;
  bless [@_], $class;
}

sub on_release (&@) {
  __PACKAGE__->new(@_);
}

1;

__END__

=head1 NAME

ReleaseAction - call actions upon release.

=head1 SYNOPSIS

  use ReleaseAction 'on_release';
  {
    # OO style
    my $handle = ReleaseAction->new(
      sub {print "Exiting scope\n"}
    );
    print "In scope\n";
  }
  {
    # Functional style
    my $handle = on_release {print "Exiting scope\n"};
    print "In scope\n";
  }
  {
    my $rollback = on_release {rollback_trans()};
    if (do_stuff()) {
      $rollback->cancel();
    }
}

=head1 DESCRIPTION

This provides an easy way to create opaque handles which
will do something when they are destroyed.  There are
two ways of creating a new handle.  Both take one or more
arguments, with the first being the action to take when
the handle is released and the (optional) rest being the
arguments that the handle will get.

=over 4

=item *

C<new> is the method oriented constructor.

  my $handle = ReleaseAction->new(
    sub {print shift}, "Goodbye cruel world\n"
  );

=item *

And an optional function C<on_release> that you can
import.  For those who like that sort of thing, I have
provided the prototype &@ for syntactic sugar.

  my $handle = on_release {print "Goodbye cruel world\n"};

=item *

And should you decide that you don't want to do the action
on release after all, you can call the cancel() method.
As suggested in the SYNOPSIS, this is useful if you wish to
set up transactional mechanics.  Make the release action
do your cleanup.  And then when you commit your changes,
cancel the cleanup.

=back

=head1 EXAMPLE

  use ReleaseAction 'on_release';
  
  # This does the same thing as the module SelectSaver.
  sub tmp_select {
    on_release {select shift} select shift;
  }
  
  print "This print goes to STDOUT\n";
  {
    my $hold_select = tmp_select(\*STDERR);
    print "This print goes to STDERR\n";
  }
  print "Printing to STDOUT again\n";

=head1 A LONGER EXAMPLE

  use Carp;
  use Cwd;
  use ReleaseAction;
  
  sub cd_to {
    chdir($_[0]) or confess("Cannot chdir to $_[0]: $!");
  }
  
  sub tmp_cd {
    my $cwd = cwd();
    cd_to(shift);
    ReleaseAction->new(\&cd_to, $cwd);
  }
  
  sub something_interesting {
    my $in_dir = tmp_cd("some_dir");
    # Do something interesting in the new dir
    
    # I will automagically return to the old dir
    # when I exit the subroutine and $in_dir goes
    # out of scope.
  }

=head1 BUGS

The future of reliable destruction mechanics in Perl 6
is still unknown.  Many people want them, however they
also want incompatible things like real garbage
collection and implementations of Perl in .NET and
the Java Virtual Machine.

=head1 ACKNOWLEDGEMENTS

My thanks to Randal Schwartz for mentioning SelectSaver
to me, and to ncw on PerlMonks for pointing out that
prototypes would fit with on_release.  I still don't
like them, but they do make sense here.

=head1 AUTHOR AND COPYRIGHT

Written by Ben Tilly (btilly@gmail.com).

Copyright 2001.  This module may be modified and
distributed on the same terms as Perl itself.
