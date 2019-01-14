package PMLTQ::Base;
our $AUTHORITY = 'cpan:MATY';
$PMLTQ::Base::VERSION = '2.0.1';
# ABSTRACT: Base class for PMLTQ inspired by L<Mojo::Base> and L<Mojo::Base::XS>

use strict;
use warnings;
use utf8;
use feature ();

# Only Perl 5.14+ requires it on demand
use IO::Handle ();

# Supported on Perl 5.22+
my $NAME
  = eval { require Sub::Util; Sub::Util->can('set_subname') } || sub { $_[1] };

# Protect subclasses using AUTOLOAD
sub DESTROY { }

sub _monkey_patch {
  my ($class, %patch) = @_;
  no strict 'refs';
  no warnings 'redefine';
  *{"${class}::$_"} = $NAME->("${class}::$_", $patch{$_}) for keys %patch;
}

require Mojo::Base::XS;

Mojo::Base::XS::newxs_constructor(__PACKAGE__ . '::new');
Mojo::Base::XS::newxs_attr(__PACKAGE__ . '::attr');

sub import {
  my $class = shift;
  return unless my $flag = shift;

  # Base
  if ($flag eq '-base') { $flag = $class }

  # Strict
  elsif ($flag eq '-strict') { $flag = undef }

  # Module
  elsif ((my $file = $flag) && !$flag->can('new')) {
    $file =~ s!::|'!/!g;
    require "$file.pm";
  }

  # ISA
  if ($flag) {
    my $caller = caller;
    no strict 'refs';
    no warnings 'redefine';

    push @{"${caller}::ISA"}, $flag;
    _monkey_patch $caller, 'has', sub { attr($caller, @_) };
  }

  # PMLTQ modules are strict!
  $_->import for qw(strict warnings utf8);
  feature->import(':5.10');
}

1;

__END__

=head1 SYNOPSIS

  package Cat;
  use PMLTQ::Base -base;

  has name => 'Nyan';
  has [qw(age weight)] => 4;

  package Tiger;
  use PMLTQ::Base 'Cat';

  has friend  => sub { Cat->new };
  has stripes => 42;

  package main;
  use PMLTQ::Base -strict;

  my $mew = Cat->new(name => 'Longcat');
  say $mew->age;
  say $mew->age(3)->weight(5)->age;

=head1 DESCRIPTION

L<PMLTQ::Base> is a simple base class for L<PMLTQ> project. It works the same
way as L<Mojo::Base>. The following is taken from L<Mojo::Base> documentation:

  # Automatically enables "strict", "warnings", "utf8" and Perl 5.10 features
  use PMLTQ::Base -strict;
  use PMLTQ::Base -base;
  use PMLTQ::Base 'SomeBaseClass';

All three forms save a lot of typing.

  # use PMLTQ::Base -strict;
  use strict;
  use warnings;
  use utf8;
  use feature ':5.10';
  use IO::Handle ();

  # use PMLTQ::Base -base;
  use strict;
  use warnings;
  use utf8;
  use feature ':5.10';
  use IO::Handle ();
  use PMLTQ::Base;
  push @ISA, 'PMLTQ::Base';
  sub has { PMLTQ::Base::attr(__PACKAGE__, @_) }

  # use PMLTQ::Base 'SomeBaseClass';
  use strict;
  use warnings;
  use utf8;
  use feature ':5.10';
  use IO::Handle ();
  require SomeBaseClass;
  push @ISA, 'SomeBaseClass';
  use Mojo::Base;
  sub has { Mojo::Base::attr(__PACKAGE__, @_) }

=head1 SEE ALSO

L<Mojo::Base>, L<Mojo::Base::XS>.

=cut
