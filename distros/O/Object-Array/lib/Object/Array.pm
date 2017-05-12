package Object::Array;

use strict;
use warnings;
use Scalar::Util ();

use Module::Pluggable (require => 1);

for my $plugin (__PACKAGE__->plugins) {
  $plugin->import('-all');
}

use Sub::Exporter -setup => {
  exports => [ Array => \&_array_generator ],
};

use 5.006001;

=head1 NAME

Object::Array - array references with accessors

=head1 VERSION

Version 0.060

=cut

our $VERSION = '0.060';

=head1 SYNOPSIS

  use Object::Array qw(Array);
  my $array = Object::Array->new;       # or
  $array = Object::Array->new(\@array); # or
  $array = Array(\@array);
  $array->push(1..5);
  print $array->shift;
  $_++ for grep { $_ < 4 } @{ $array };
  $array->[0] = "a pony";

=head1 IMPORTANT NOTE

Several of these methods do not behave exactly like their
builtin counterparts.

Specifically, any method that you would expect to return a
list does so, but B<only in list context>.  In scalar
context, these methods will return an Object::Array object
constructed from a copy of the list that would have been
returned.

This sounds more complicated than it is.  It means that you
can chain some methods together, e.g.

  $arr->grep(sub { defined })->[-1];

instead of the more bracing

  ${ $arr->grep(sub { defined }) }[-1];

Currently, these array objects only contain copies of the
original values.  In the future, they will retain references
to the original object, and this sort of thing will be possible:

  $arr->grep(sub { defined })->[-1]++;

=head1 METHODS

=head2 new

  my $array = Object::Array->new;
  # or use existing array
  my $array = Object::Array->new(\@a);

Creates a new array object, either from scratch or from an
existing array.

Using an existing array will mean that any changes to C<<
$array >> also affect the original array object.  If you
don't want that, copy the data first or use something like
Storable's C<< dclone >>.

=head2 isa

Overridden to respond to 'ARRAY'.

=head2 ref

Returns a reference to the underlying array.

=cut

my %real;

sub _addr { Scalar::Util::refaddr($_[0]) }

sub _real { $real{shift->_addr} }
*ref = \&_real;

sub _array {
  my ($self, @values) = @_;
  return wantarray ? @values : ref($self)->new(\@values);
}

# for exporting
sub _array_generator {
  my ($class) = @_;
  return sub { $class->new(@_) };
}

use overload (
  q(@{})   => 'ref',
  fallback => 1,
);
  
sub new {
  my $class = shift;
  my $real  = shift || [];

  my $self = bless \$real => $class;
  
  $real{$self->_addr} = $real;

  return $self;
}

sub isa {
  my ($class, $type) = @_;
  return 1 if $type eq 'ARRAY';
  return $class->SUPER::isa($type);
}

=head1 SEE ALSO

L<Object::Array::Plugin::Builtins>

L<Object::Array::Plugin::ListMoreUtils>

=head1 AUTHOR

Hans Dieter Pearcey, C<< <hdp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-object-array at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Object-Array>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Object::Array

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Object-Array>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Object-Array>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Object-Array>

=item * Search CPAN

L<http://search.cpan.org/dist/Object-Array>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Hans Dieter Pearcey, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Object::Array
