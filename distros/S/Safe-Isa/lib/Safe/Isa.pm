package Safe::Isa;

use strict;
use warnings FATAL => 'all';
use Scalar::Util qw(blessed);
use Exporter 5.57 qw(import);

our $VERSION = '1.000006';

our @EXPORT = qw($_call_if_object $_isa $_can $_does $_DOES);

our $_call_if_object = sub {
  my ($obj, $method) = (shift, shift);
  # This is intentionally a truth test, not a defined test, otherwise
  # we gratuitously break modules like Scalar::Defer, which would be
  # un-perlish.
  return unless blessed($obj);
  return $obj->isa(@_) if lc($method) eq 'does' and not $obj->can($method);
  return $obj->$method(@_);
};

our ($_isa, $_can, $_does, $_DOES) = map {
  my $method = $_;
  sub { my $obj = shift; $obj->$_call_if_object($method => @_) }
} qw(isa can does DOES);

1;
__END__

=pod

=head1 NAME

Safe::Isa - Call isa, can, does and DOES safely on things that may not be objects

=head1 SYNOPSIS

  use strict;
  use warnings;
  
  { package Foo; sub new { bless({}, $_[0]) } }
  { package Bar; our @ISA = qw(Foo); sub bar { 1 } }
  
  my $foo = Foo->new;
  my $bar = Bar->new;
  my $blam = [ 42 ];
  
  # basic isa usage -
  
  $foo->isa('Foo');  # true
  $bar->isa('Foo');  # true
  $blam->isa('Foo'); # BOOM
  
  $foo->can('bar');  # false
  $bar->can('bar');  # true
  $blam->can('bar'); # BOOM
  
  # Safe::Isa usage -
  
  use Safe::Isa;
  
  $foo->$_isa('Foo');  # true
  $bar->$_isa('Foo');  # true
  $blam->$_isa('Foo'); # false, no boom today
  
  $foo->$_can('bar');  # false
  $bar->$_can('bar');  # true
  $blam->$_can('bar'); # false, no boom today

Similarly:

  $maybe_an_object->$_does('RoleName'); # true or false, no boom today
  $maybe_an_object->$_DOES('RoleName'); # true or false, no boom today

And just in case we missed a method:

  $maybe_an_object->$_call_if_object(name => @args);

Or to re-use a previous example for purposes of explication:

  $foo->$_call_if_object(isa => 'Foo');  # true
  $bar->$_call_if_object(isa => 'Foo');  # true
  $blam->$_call_if_object(isa => 'Foo'); # false, no boom today

=head1 DESCRIPTION

How many times have you found yourself writing:

  if ($obj->isa('Something')) {

and then shortly afterwards cursing and changing it to:

  if (Scalar::Util::blessed($obj) and $obj->isa('Something')) {

Right. That's why this module exists.

Since perl allows us to provide a subroutine reference or a method name to
the -> operator when used as a method call, and a subroutine doesn't require
the invocant to actually be an object, we can create safe versions of isa,
can and friends by using a subroutine reference that only tries to call the
method if it's used on an object. So:

  my $isa_Foo = $maybe_an_object->$_call_if_object(isa => 'Foo');

is equivalent to

  my $isa_Foo = do {
    if (Scalar::Util::blessed($maybe_an_object)) {
      $maybe_an_object->isa('Foo');
    } else {
      undef;
    }
  };

Note that we don't handle trying class names, because many things are valid
class names that you might not want to treat as one (like say "Matt") - the
C<is_module_name> function from L<Module::Runtime> is a good way to check for
something you might be able to call methods on if you want to do that.

=head1 EXPORTS

=head2 $_isa

  $maybe_an_object->$_isa('Foo');

If called on an object, calls C<isa> on it and returns the result, otherwise
returns nothing.

=head2 $_can

  $maybe_an_object->$_can('Foo');

If called on an object, calls C<can> on it and returns the result, otherwise
returns nothing.

=head2 $_does

  $maybe_an_object->$_does('Foo');

If called on an object, calls C<does> on it and returns the result, otherwise
returns nothing.

=head2 $_DOES

  $maybe_an_object->$_DOES('Foo');

If called on an object, calls C<DOES> on it and returns the result, otherwise
returns nothing.

=head2 $_call_if_object

  $maybe_an_object->$_call_if_object(method_name => @args);

If called on an object, calls C<method_name> on it and returns the result,
otherwise returns nothing.

=head1 SEE ALSO

I gave a lightning talk on this module (and L<curry> and L<Import::Into>) at
L<YAPC::NA 2013|https://www.youtube.com/watch?v=wFXWV2yY7gE&t=46m05s>.

=head1 AUTHOR

mst - Matt S. Trout (cpan:MSTROUT) <mst@shadowcat.co.uk>

=head1 CONTRIBUTORS

None yet. Well volunteered? :)

=head1 COPYRIGHT

Copyright (c) 2012 the Safe::Isa L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
