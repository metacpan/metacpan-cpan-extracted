package MooX::StrictHas;

our $VERSION = '0.04';

# this bit would be MooX::Utils but without initial _ on func name
use strict;
use warnings;
use Moo ();
use Moo::Role ();
use Carp qw(croak);
#use base qw(Exporter);
#our @EXPORT = qw(override_function);
sub _override_function {
  my ($target, $name, $func) = @_;
  my $orig = $target->can($name) or croak "Override '$target\::$name': not found";
  my $install_tracked = Moo::Role->is_role($target) ? \&Moo::Role::_install_tracked : \&Moo::_install_tracked;
  $install_tracked->($target, $name, sub { $func->($orig, @_) });
}
# end MooX::Utils;

my %ATTR2MESSAGE = (
  auto_deref => q{just dereference in your using code},
  lazy_build => q{Use "is => 'lazy'" instead},
  does => q{Unsupported; use "isa" instead},
);
sub import {
  my $target = scalar caller;
  _override_function($target, 'has', sub {
    my ($orig, $namespec, %opts) = @_;
    $namespec = "[@$namespec]" if ref $namespec;
    my @messages;
    push @messages, exists($opts{$_})
      ? "$_ detected on $namespec: $ATTR2MESSAGE{$_}"
      : ()
      for sort keys %ATTR2MESSAGE;
    croak join "\n", @messages if @messages;
    $orig->($namespec, %opts);
  });
}

=head1 NAME

MooX::StrictHas - Forbid "has" attributes lazy_build and auto_deref

=begin markdown

# PROJECT STATUS

| OS      |  Build status |
|:-------:|--------------:|
| Linux   | [![Build Status](https://travis-ci.com/mohawk2/moox-stricthas.svg?branch=master)](https://travis-ci.org/mohawk2/moox-stricthas) |

[![CPAN version](https://badge.fury.io/pl/moox-stricthas.svg)](https://metacpan.org/pod/MooX::StrictHas) [![Coverage Status](https://coveralls.io/repos/github/mohawk2/moox-stricthas/badge.svg?branch=master)](https://coveralls.io/github/mohawk2/moox-stricthas?branch=master)

=end markdown

=head1 SYNOPSIS

  package MyMod;
  use Moo;
  use MooX::StrictHas;
  has attr => (
    is => 'ro',
    auto_deref => 1, # blows up, not implemented in Moo
  );
  has attr2 => (
    is => 'ro',
    lazy_build => 1, # blows up, not implemented in Moo
  );
  has attr2 => (
    is => 'ro',
    does => "Thing", # blows up, not implemented in Moo
  );

=head1 DESCRIPTION

This is a L<Moo> extension, intended to aid those porting modules from
L<Moose> to Moo. It forbids two attributes for L<Moo/has>, which Moo
does not implement, but silently accepts:

=over

=item auto_deref

This is not considered best practice - just dereference in your using code.

=item does

Unsupported; use C<isa> instead.

=item lazy_build

Use C<is =E<gt> 'lazy'> instead.

=back

=head1 AUTHOR

Ed J

=head1 LICENCE

The same terms as Perl itself.

=cut

1;
