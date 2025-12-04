package Mojo::Collection::XS;
use Mojo::Base 'Mojo::Collection';

our $VERSION = '0.01';

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

# Optional constructor helper
sub c { __PACKAGE__->new(@_) }

sub new {
  my $class = shift;
  return bless [@_], ref $class || $class;
}

# Override
sub each {
  my ($self, $cb) = @_;
  return @$self unless $cb;
  each_fast($self, $cb);
}

sub while {
  my ($self, $cb) = @_;
  return @$self unless $cb;
  while_fast($self, $cb);
}

sub while_fast      { my ($self, $cb) = @_; Mojo::Collection::XS::while_fast($self, $cb); }
sub while_pure_fast { my ($self, $cb) = @_; Mojo::Collection::XS::while_pure_fast($self, $cb); }
sub each_fast       { my ($self, $cb) = @_; Mojo::Collection::XS::each_fast($self, $cb); }
sub map_fast        { my ($self, $cb) = @_; Mojo::Collection::XS::map_fast($self, $cb); }
sub map_pure_fast   { my ($self, $cb) = @_; Mojo::Collection::XS::map_pure_fast($self, $cb); }
sub grep_fast       { my ($self, $cb) = @_; Mojo::Collection::XS::grep_fast($self, $cb); }

1;

__END__

=pod

=head1 NAME

Mojo::Collection::XS - Fast XS-based subclass of Mojo::Collection

=head1 SYNOPSIS

  use Mojo::Collection::XS;

  my $c = Mojo::Collection::XS->new(qw/foo bar baz/);

  # Without parameters (uses $_)
  $c->while(sub {
    say $_;
  });

  # With parameters
  $c->while(sub ($e, $num) {
    say "$num: $e";
  });

  # Fast variants
  $c->while_fast(sub ($e, $num) { ... });
  $c->while_pure_fast(sub ($e, $num) { ... });
  my $mapped = $c->map_fast(sub ($e, $num) { uc $e });
  my $mapped_pure = $c->map_pure_fast(sub ($e, $num) { $e });
  my $filtered = $c->grep_fast(sub ($e, $num) { $e =~ /foo/ });
  $c->each_fast(sub ($e, $num) { ... });

=head1 DESCRIPTION

Mojo::Collection::XS is a subclass of L<Mojo::Collection> with hot paths
implemented in XS for better performance on large lists.

Callbacks must be code references; method-name strings are not supported.

=head1 METHODS

This class inherits all methods from L<Mojo::Collection> and adds the
following XS-backed helpers:

=head2 while_fast

  $collection = $collection->while_fast(sub ($e, $num) {...});

Iterate over all elements, passing the element as C<$e> and its 1-based index
as C<$num>. C<$_> is set to the current element (alias). Returns the same
collection.

=head2 while_pure_fast

  $collection = $collection->while_pure_fast(sub ($e, $num) {...});

Iterate over all elements without touching C<$_>, passing only the element
and its 1-based index. Returns the same collection.

=head2 map_fast

  my $new = $collection->map_fast(sub ($e, $num) { ... });

Call the callback for each element and collect its list return into a new
collection of the same class. C<$num> is 1-based and C<$_> is set to the
current element (alias).

=head2 map_pure_fast

  my $new = $collection->map_pure_fast(sub ($e, $num) { ... });

Scalar-returning variant of C<map_fast>. The callback is invoked in scalar
context and each return value is collected into a new collection of the same
class. C<$_> is not set.

=head2 grep_fast

  my $new = $collection->grep_fast(sub ($e, $num) { ... });

Call the callback for each element and include the original element in the
resulting collection when the callback returns a true value. C<$num> is
1-based and C<$_> is set to the current element (alias).

=head2 each_fast

  $collection = $collection->each_fast(sub ($e, $num) {...});

Iterate over all elements, passing the element and its 1-based index to the
callback. C<$_> is set to the current element (alias). Returns the same
collection.

=cut
