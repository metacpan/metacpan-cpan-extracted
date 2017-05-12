package Params::Named;

$VERSION = '1.0.2';

require Exporter;
@ISA     = 'Exporter';
@EXPORT  = 'MAPARGS';

use strict;

use Carp      qw/croak carp/;
use PadWalker 'var_name';

sub VAR { return {qw/SCALAR $ ARRAY @ HASH % REF $/}->{ref $_[0]}.$_[1]; }

sub _set_param {
  my($p, $v, $n) = @_; # param, value, name
  return $$p = $v
    if ref $p eq 'SCALAR'
    && (ref $v || ref \$v) eq 'SCALAR' || (ref $v eq 'REF');
  return @$p = @$v
    if ref $p eq 'ARRAY' && ref $v eq 'ARRAY';
  return %$p = %$v
    if ref $p eq 'HASH' && ref $v eq 'HASH';

  croak sprintf "The parameter '%s' doesn't match argument type '%s'",
                VAR($p,$n), ( ref $v || ref \$v );
}

## Map named arguments to variables of those names.
sub MAPARGS {
  my %args = do { package DB; () = caller 1; @DB::args };
  ## Map the lexicals of the caller to the caller's arguments.
  my %vmap = map {
    my $arg = ref $_ ? $_ : \$_;
    my $prm = substr(var_name(1, $arg), 1);
    exists $args{$prm}
      ? ($prm => $arg)
      : (() = carp "Parameter '${\VAR($arg,$prm)}' not mapped to an argument")
  } @_;

  ## Now assign the caller's arguments to the caller's lexicals.
  _set_param $vmap{$_} => $args{$_}, $_
    for keys %vmap;

  return \%vmap;
}

1;

=pod

=head1 NAME

Params::Named - Map incoming arguments to parameters of the same name.

=head1 SYNOPSIS

  use Params::Named;
  use IO::All;

  sub storeurl {
    my $self = shift;
    MAPARGS \my($src, $dest);
    return io($src) > io($dest);
  }
  $obj->storeurl(src => $url, dest => $fh);

=head1 DESCRIPTION

This module does just one thing - it maps named arguments to a subroutine's
lexical parameter variables or, more specifically, any lexical variables
passed into C<MAPARGS>. Named parameters are exactly the same as a flattened
hash in that they provide a list of C<< key => value >> pairs. So for each
key that matches a lexical variable passed to C<MAPARGS> the corresponding
value will be mapped to that variable. Here is a short example to demonstrate
C<MAPARGS> in action:

  use Params::Named;
  sub mapittome {
    MAPARGS \my($this, @that, %other);
    print "This is:   '$this'\n";
    print "That is:   ", join(', ', @that), "\n";
    print "The other: ", join(', ',
                              map "$_ => $other{$_}", keys %other), "\n";
  }

  mapittome this  => 'a simple string',
            that  => [qw/a list of items/],
            other => {qw/a hash containing pairs/};
  ## Or if you've got a hash.
  my %args = (
    this  => 'using a hash',
    that  => [qw/is very cool/],
    other => {qw/is it not cool?/},
  );
  mapittome %args;

The example above illustrates the mapping of C<mapittome>'s arguments to
its parameters. It will work on scalars, arrays and hashes, the 3 types
of lexical values.

=head1 FUNCTIONS

=over 4

=item MAPARGS

Given a list of variables map those variables to named arguments from the
caller's argument. Taking advantage of one of Perl's more under-utilized
features, passing in a list of references as created by applying the
reference operator to a list will allow the mapping of compound variables
(without the reference lexically declared arrays and hashes flatten to an
empty list). Argument types must match their corresponding parameter types
e.g C<< foo => \@things >> should map to a parameter declared as an array
e.g C<MAPARGS \my(@foo)>.

The arguments passed to C<MAPARGS> don't need to be referenced if they are
simple scalars, but do need to be referenced if either an array or hash is
used.

=back

=head1 EXPORTS

C<MAPARGS>

=head1 DIAGNOSTICS

=over 4

=item C<Parameter '%s' not mapped to an argument>

This warning is issued because a parameter couldn't be mapped to an argument
i.e if C<< foo1 => 'bar' >> is accidentally passed to subroutine who's
parameter is C<$fool>.

=item C<The parameter '%s' doesn't match argument type '%s'>

A given parameter doesn't match it's corresponding argument's type e.g

  sub it'llbreak { MAPARGS \my($foo, @bar); ... }
  ## This will croak() because @bar's argument isn't an array reference.
  it'llbreak foo => 'this', bar => 'that';

So either the parameter or the argument needs to be updated to reflect
the desired behaviour.

=back

=head1 SEE. ALSO

L<Sub::Parameters>, L<Sub::Signatures>, L<Params::Smart>

=head1 THANKS

Robin Houston for bug spotting, code refactoring, idea bouncing and releasing
a new version of L<PadWalker> (is there anything he can't do?).
  
=head1 AUTHOR

Dan Brook C<< <cpan@broquaint.com> >>

=head1 COPYRIGHT

Copyright (c) 2005, Dan Brook. All Rights Reserved. This module is free
software. It may be used, redistributed and/or modified under the same
terms as Perl itself.

=cut
