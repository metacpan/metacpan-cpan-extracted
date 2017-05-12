#
# Object::Generic::False.pm     
#
# A perl object that evaluates to a boolean false value
# but which still allows method calls.
#
#   use Object::Generic::False qw( false );
#   my $n = false;      # returns global $Object::Generic::False::_false_
#   print "n is false" if not $n;
#   print "n->foo->bar is also false" if not $n->foo->bar;
#
# See the bottom of this file for the documentation.
#
# $Id: False.pm 378 2005-06-07 19:00:32Z mahoney $
#
package Object::Generic::False;
use strict;
use warnings;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(false);
our $_false_ = new Object::Generic::False;     # The global returned by false().
use overload 
  q("")   => sub {return ''},         # Also autogenerates numeric false as 0.
  q(<=>)  => sub {return 0 <=> $_[1]},
  q(cmp)  => sub {return '' cmp $_[1]},
  # --- arithmetic ---
  q(+)    => \&false,
  q(-)    => \&false,
  q(neg)  => \&false,
  q(*)    => \&false,
  q(/)    => \&false,
  q(%)    => \&false,
  q(**)   => \&false,
  # --- strings -------
  #q(.)   => \&false,
  q(x)    => \&false,
  # --- bits ----------
  q(&)    => \&false,
  q(|)    => \&false,
  q(~)    => \&false,   # Should this perhaps return a (true) Object::Generic?
  ;
sub new {
  my $class = shift;
  my $false = shift || 0;
  return bless \$false => $class;
}
sub DESTROY {   # Defined here so that AUTOLOAD won't handle it.
}
sub AUTOLOAD {
  return shift;
}
sub false {
  return $_false_;
}
sub error {
  my $self = shift;
  return $$self;
}

1;

__END__

=head1 NAME

Object::Generic::False - 
a perl object that evaluates as false but allows method calls.

=head1 SYNOPSIS

  use Object::Generic::False qw(false);
  my $n = false;        # returns global $Object::Generic::False::_false_
  print "n is false" if not $n;
  print "n->foo->bar is also false" if not $n->foo->bar;

  my $result = Object::Generic::False->new('Some error message.');
  print The error is '" . $result->error . "'\n" if not $result;

=head1 DESCRIPTION

Lately I've been doing some object oriented perl in which I 
would like to have $object->foo return false without having
$object->foo->bar generate an error.  Hence this module.
 
To generate a false object, either use the exported false() method,
which returns the package global $Object::Generic::False::_false_, 
or create your own instance with Object::Generic::False->new;

Object::Generic::False objects continue to be false when combined with other
perl entities.  Thus for example unlike numeric 0, (2 + false) is still false.
In that respect they act somewhat "tainted" variables.

The exceptions to this rule are comparisons and string concatenation:
(false == 0) and (false eq '') are both true, while false()."foo" is "foo".

These objects can also be used as a returned error with an enclosed
message.  To do so, just pass in a string when creating one with
the new message, ie "$result = new Object::Generic::False 'your message'".
$result still evaluates as false, but the message may be retrieved
with $result->error.

=head2 EXPORT

The false() function is exported, which returns 
the global $Object::Generic::False::_false_ object.

=head1 AUTHOR

Jim Mahoney, E<lt>mahoney@marlboro.edu<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Jim Mahoney

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
