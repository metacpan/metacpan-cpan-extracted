package Scope::local_OnExit;

use 5.006000;
$VERSION = 0.01;
use strict;
use warnings;
sub TIESCALAR { bless [
     sub {
          require Carp;
          Carp::croak( __PACKAGE__." stack underflow")
     }
] }
sub DEBUG() { 0 }
sub STORE {
  # my $stack = shift;
  # my $newval = shift;
  DEBUG and warn "STORING: @_";
  # if(ref $newval){
  #     push @$stack, $newval
  # }else{
  if(ref $_[1]){
      push @{$_[0]}, $_[1]
  }else{
     # eval {    &{pop @$stack}; 1 }
     # or warn "running top of stack failed: $@--"
     $_[1] > 0 and (pop @{$_[0]})->()
  }
}
sub FETCH {
  DEBUG and warn "FETCHING: @_ (@{$_[0]})";
  0+@{$_[0]}
}

sub import{
     no strict 'refs';
     tie ${caller().'::OnExit'}, __PACKAGE__;
}

1;
__END__


=head1 NAME

Scope::local_OnExit - an execute-at-scope-exit mechanism using C<local>

=head1 SYNOPSIS

  our $onExit;
  use Scope::local_OnExit;
  ...
  sub SomethingCritical{
     local$OnExit=\&release_lock;
     obtain_lock;
     ...
  }


=head1 DESCRIPTION

This very short module provides a pure-perl mechanism for executing
perl code at scope exit, at the time that the "old value" is returned to
the tied variable.

=head2 PORTING FROM Scope::OnExit

Instead of

   on_scope_exit { do_something($var) };

one would code

   local$OnExit=sub{ do_something($var) };

=head2 EXPORT

the scalar package variable C<$OnExit> is tied into the package.

To tie a different variable than C<$OnExit>, use empty parentheses
on the C<use> line to suppress C<import> and tie the variable of your
selection.

=head1 HISTORY

=over 8

=item 0.00

initial draft written March 2010 and published on a blog and
submitted to the module-authors mailing list for comment.


=item 0.01

This version (April 2010) reflects comments received.

=back


=head1 SEE ALSO

L<Scope::OnExit> provides the same functionality but must be compiled.

=head1 AUTHOR

David Nicol davidnico@cpan.org

Please comment via rt.cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by David Nicol / TipJar LLC

Released under the
L<http://creativecommons.org/licenses/by/3.0/>
Creative Commons Attribution 3.0 Unported License

Leaving this section in the documentation in your installed
library is sufficient attribution.

=cut

