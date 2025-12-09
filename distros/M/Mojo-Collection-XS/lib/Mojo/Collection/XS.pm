package Mojo::Collection::XS;
use Mojo::Base 'Mojo::Collection';

our $VERSION = '0.2';

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

our @EXPORT_OK = ('c');

# Optional constructor helper
sub c { __PACKAGE__->new(@_) }

sub new {
  my $class = shift;
  return bless [@_], ref $class || $class;
}

sub while_fast  { my ($self, $cb) = @_; Mojo::Collection::XS::while_fast($self, $cb); }
sub while_ultra { my ($self, $cb) = @_; Mojo::Collection::XS::while_ultra($self, $cb); }
sub each_fast   { my ($self, $cb) = @_; Mojo::Collection::XS::each_fast($self, $cb); }
sub map_fast    { my ($self, $cb) = @_; Mojo::Collection::XS::map_fast($self, $cb); }
sub map_ultra   { my ($self, $cb) = @_; Mojo::Collection::XS::map_ultra($self, $cb); }
sub grep_fast   { my ($self, $cb) = @_; Mojo::Collection::XS::grep_fast($self, $cb); }

1;

__END__

=pod

=head1 NAME

Mojo::Collection::XS - Fast XS-based subclass of Mojo::Collection

=head1 SYNOPSIS

  use Mojo::Collection::XS;

  my $c = Mojo::Collection::XS->new(qw/foo bar baz/);

  # Fast walk (aliases $_)
  $c->while_fast(sub {
    say "$num: $_";
  });

  # Ultra-fast walk (never touches $_)
  $c->while_ultra(sub ($e, $num) {
    say "$num: $e";
  });

  # Fast variants
  $c->while_fast(sub ($e, $num) { ... });
  $c->while_ultra(sub ($e, $num) { ... });
  my $mapped = $c->map_fast(sub ($e) { uc $e });
  my $mapped_ultra = $c->map_ultra(sub ($e) { $e });
  my $filtered = $c->grep_fast(sub ($e) { $e =~ /foo/ });
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

Faster drop-in for L<Mojo::Collection/each> when you need to walk the list and
return the same collection. C<$_> is aliased to the current element, and
C<$num> is 1-based, matching the Perl implementation.

=head2 while_ultra

  $collection = $collection->while_ultra(sub ($e, $num) {...});

Like L</while_fast> but never touches C<$_> and minimizes stack work. Designed
to be faster than L<Mojo::Collection/each> (and far faster than a Perl
while-loop with callbacks) while keeping the same argument order and return
value.

=head2 map_fast

  my $new = $collection->map_fast(sub ($e) { ... });

Faster equivalent of L<Mojo::Collection/map>. The callback runs in list
context, C<$_> is aliased, and the list return is flattened into a new
collection of the same class.

=head2 map_ultra

  my $new = $collection->map_ultra(sub ($e) { ... });

Scalar variant tuned for speed: no C<$_>, minimal argument handling, and each
scalar return value is gathered into a new collection of the same class. Built
to beat L<Mojo::Collection/map> and be significantly faster than Perl's native
map for callback-heavy workloads.

=head2 grep_fast

  my $new = $collection->grep_fast(sub ($e) { ... });

Faster equivalent of L<Mojo::Collection/grep>. Call the callback for each
element and include the original element in the resulting collection when the
callback returns a true value. C<$_> is set to the current element (alias).

=head2 each_fast

  $collection = $collection->each_fast(sub ($e, $num) {...});

Iterate over all elements, passing the element and its 1-based index to the
callback. C<$_> is set to the current element (alias). Returns the same
collection. This is a faster drop-in for L<Mojo::Collection/each>.

=head1 CALLBACK COST

All helpers still invoke your Perl callbacks for every element. They reduce
stack/aliasing overhead (e.g. C<while_ultra> never touches C<$_>), but the
callback body dominates runtime. In real workloads (hash/object munging, I/O,
JSON), the XS loops can help; in micro-benchmarks with trivial callbacks, the
savings may be small or even reversed because C<call_sv> overhead is the
bottleneck.

=head1 COMBINING WITH Mojo::Collection

Mix the XS helpers with the rest of L<Mojo::Collection> for readable pipelines:

=head2 map_fast with Mojo::Collection::grep/reduce

Heavy transforms in XS, aggregate in Perl:

  my $sum = $collection->map_fast(sub { $_ * 2 })->grep(sub { $_[0] > 10 })->reduce(sub { $_[0] + $_[1] });

=head2 while_fast with Mojo::Collection::map/grep/to_array

Side effects in XS, render in Perl:

  my $ids = $collection->while_fast(sub { $_->{seen} = 1 })->map(sub { $_[0]{id} })->to_array;

=head2 while_ultra with Mojo::Collection::map/to_array

Iterate without touching C<$_>, then finish in Perl:

  my $names = $collection->while_ultra(sub { $_[0]{score}++ })->map(sub { $_[0]{name} })->to_array;

=head2 map_ultra with Mojo::Collection::head/each

Fast scalar map, then light iteration:

  my $top = $collection->map_ultra(sub { $_[0]{score} })->head(3); $top->each(sub { ... });

=head2 map_ultra with Mojo::Collection::uniq/size

Count unique values without touching C<$_>:

  my $count_unique = $collection->map_ultra(sub { $_[0]{id} })->uniq->size;

=head2 grep_fast with Mojo::Collection::map/join

Filter in XS, render in Perl:

  my $csv = $collection->grep_fast(sub { $_->{active} })->map(sub { $_[0]{name} })->join(',');

=head2 each_fast with Mojo::Collection::sort/head

Quick mutation then ordering:

  my $first = $collection->each_fast(sub { $_->{score} += 1 })->sort(sub { $_[0]{score} <=> $_[1]{score} })->head(1);

=head1 AUTHORS

  Achmad Yusri Afandi, [ yusrideb at cpan.org ]

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025 by Achmad Yusri Afandi

This program is free software, you can redistribute it and/or modify
it under the terms of the Artistic License version 2.0.

=cut
