package MooX::LazyRequire;
use strict;
use warnings;

our $VERSION = '0.001002';
$VERSION = eval $VERSION;

use Carp;
use Sub::Quote;
use Class::Method::Modifiers qw(install_modifier);

sub import {
  my ($class) = @_;
  my $target = caller;

  install_modifier $target, 'around', 'has', sub {
    my $orig = shift;
    my ($attrs, %opts) = @_;
    my @attrs = ref $attrs ? @$attrs : $attrs;
    if ($opts{lazy_required}) {
      if (exists $opts{lazy} && !$opts{lazy}) {
        croak "LazyRequire can't be used with lazy => 0";
      }
      elsif (exists $opts{default} || exists $opts{builder}) {
        croak "You may not use both a builder or a default and lazy_required for one attribute ("
          . (join ', ', @attrs) . ")";
      }
      $opts{lazy} = 1;
      for my $attr (@attrs) {
        my $opts = {
          default => quote_sub(qq{
            Carp::croak("Attribute '\Q$attr\E' must be provided before calling reader");
          }),
          %opts,
        };
        $orig->($attr, %$opts);
      }
    }
    else {
      $orig->($attrs, %opts);
    }
  }
}

1;

__END__

=head1 NAME

MooX::LazyRequire - Required attributes which fail only when trying to use them

=head1 SYNOPSIS

  package MyClass;
  use Moo;
  use MooX::LazyRequire;

  has attr => ( is => 'rw', lazy_required => 1 );

=head1 DESCRIPTION

MooX::LazyRequire creates attributes that are required, but will fail on use
rather that on object creation.

=head1 SEE ALSO

=over 4

=item L<MooseX::LazyRequire>

=back

=head1 AUTHOR

haarg - Graham Knop (cpan:HAARG) <haarg@haarg.org>

=head2 CONTRIBUTORS

None so far.

=head1 COPYRIGHT

Copyright (c) 2014 the MooX::LazyRequire L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
