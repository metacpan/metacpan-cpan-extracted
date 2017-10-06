package MooseX::AccessorsOnly;

our $VERSION = '1';
$VERSION = eval $VERSION;

use warnings;
use strict;
use Carp ();
use Tie::Hash;
our @ISA = 'Tie::StdHash';

our %magic; # Global on the off chance somebody wants to fuck with it

sub TIEHASH {
  my $self = shift;
  my $store = $self->SUPER::TIEHASH();
  if (ref $_[0]) {
    $magic{"$store"}{cb} = $_[0];
  } else {
    my $complainer = $_[0] || 'carp';
    Carp::croak "Invalid complainer $complainer"
      unless grep { $complainer eq $_ }
        qw(carp croak confess cluck die warn);
    $complainer = 'Carp::' . $complainer if $complainer =~ /^c/; # convenient
    # Eugh:
    $magic{"$store"}{cb} = eval qq{
      sub {
        my (\$who, \$how, \$what) = \@_;
        $complainer ("DIRECT ACCESS from \$who: \$how " . \$what || 'NOKEY');
      }
    };
  }
  $store;
}

sub DESTROY {
  delete $magic{"$_[0]"};
  # Tie::StdHash doesn't have a DESTROY method
}

sub UNTIE { Carp::croak "Attempt to UNTIE" }

for my $sub (qw(
                 CLEAR
                 DELETE
                 EXISTS
                 FETCH
                 FIRSTKEY
                 NEXTKEY
                 SCALAR
                 STORE
              )) {
  my $super = 'SUPER::' . $sub;
  no strict 'refs';
  *$sub = sub {
    my $self = shift;
    my @caller = caller(0);
    $magic{"$self"}{cb}->("$caller[0]:$caller[2]", $sub, $_[0])
      unless (caller(2))[0] || '' eq 'Moose::Object'
      or $caller[0] =~ /^(?:Eval::Closure|Data::Dump)/;
    $self->$super(@_);
  };
}

1;

__END__

=encoding utf8

=head1 NAME

MooseX::AccessorsOnly - React when users root around inside your objects

=head1 SYNOPSIS

  package Foo;

  use Moose;
  use MooseX::AccessorsOnly;

  sub BUILD {
    my $self = shift;
    my %saved = %$self;
    tie %$self, "MooseX::AccessorsOnly";
    %$self = %saved;
  }

=head1 DESCRIPTION

Call a function every time the elements of the hash which underlies a
regular L<Moose> object are accessed directly.

=head1 BUGS

=over

=item There should be no need to write the BUILD sub's boilerplate.

=item It is almost certainly too slow.

=item Not compatible with L<Moo>.

=item Edge cases have undoubtedly been missed.

=item There are no tests.

=back

=head1 USAGE

The simplest way to use this module is to copy the BUILD sub from the
SYNOPSIS into your class.

If you can be sure that none of your attributes have a default value
(lazy attributes with a builder should be fine) then there is no need
to save and restore its contents; only the C<tie> line is necessary:

  sub BUILD { tie %{$_[0]}, "MooseX::AccessorsOnly" }

=head1 ADVANCED USAGE

You may optionally pass a callback as the third option to C<tie()>
will be called I<instead of> emitting the regular warning. It will be
called with three argument: The package and line number from which the
errant access took place, the access type being attempted and the key
that is being accessed, or C<undef>:

  $cb->($who, $how, $what);

The default callback is simply:

  sub {
    my ($who, $how, $what) = @_;
    carp "DIRECT ACCESS from $who: $how " . $what || 'NOKEY'
  };

Example:

  sub BUILD {
    my $self = shift;
    tie %$self, 'MooseX::AccessorsOnly',
      sub { $self->log("DEPRECATED API USED", @_) };
  }

As a shortcut, you can pass any of the strings C<carp>, C<croak>,
C<confess>, C<cluck>, C<die> or C<warn> as tie's 3rd argument and the
default callback will be modified to use that function to do the
reporting.

=head1 WHY

I'm shepherding a terrible codebase and attempting to drag it into at
least the 20th if not the 21st century. We've all been there. A
significant part of that work involved converting our ancient modules
to use L<Moo> but of course out of the 300,000 lines I'm bound to miss
some places where the code reaches into the hash directly.

This module exists so that I have partially-converted code deploy4ed
to production and have it report all the places I missed. I can then
trawl through the logs and make the necessary repairs. After enough
time passes without any messages being logged I can remove this module
and continue to refactor the code safely.

(And convert the module back to using Moo)

=head1 Moo

Unfortunately because of the magic L<Moo> uses to eke more speed out
of its accessors I could not get this technique to work with it. I'm
sure it's possible but I have work to do so this will have to suffice.

Conveniently, thanks to the hard work of Matt Trout and others, L<Moo>
is entirely compatible with L<Moose>. Provided you're disciplined not
to use L<Moose>-specific features in your class, you can simply take
the speed hit during the conversion period and then switch back to
L<Moo> when you've finished.

If anybody can come up with a way to write L<MooX::AccessorsOnly>, I
will gladly include it in this package.

=head1 HISTORY

=over

=item MooseX::AccessorsOnly 1

First L<Moose>-only implementation.

=back

=head1 SEE ALSO

L<Moo>

L<Moose>

L<perltie>

=head1 AUTHOR

Matthew King (cpan:CHOHAG) <chohag@jtan.com>

=head1 COPYRIGHT

Copyright © 2017 Matthew King

=head1 LICENSE

This library is free software and may be distributed under the terms
of the Do What the Fuck You Want To Public License version 2 or, at
your option, any version of any license you choose.

=cut
