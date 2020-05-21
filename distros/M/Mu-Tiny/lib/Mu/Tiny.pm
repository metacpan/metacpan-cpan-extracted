package Mu::Tiny;

our $VERSION = '0.000001'; # 0.0.1

$VERSION = eval $VERSION;

use strict;
use warnings;
use Carp ();

sub import {
  my $targ = caller;
  strict->import;
  warnings->import;
  no strict 'refs';
  @$_ or @$_ = ('Mu::Tiny::Object') for my $isa = \@{"${targ}::ISA"};
  my $attrs;
  *{"${targ}::extends"} = sub {
    Carp::croak "Can't call extends after attributes" if $attrs;
    Carp::croak "No superclass list passed to extends" unless @_;
    foreach my $el (@_) {
      require join('/', split '::', $el).'.pm';
    }
    @$isa = @_;
  };
  *{"${targ}::ro"} = sub {
    Carp::croak "No name passed to ro" unless my $name = shift;
    Carp::croak "Extra args passed to ro" if @_;
    ($attrs||=_setup_attrs($targ))->{$name} = 1;
    *{"${targ}::${name}"} = sub { $_[0]->{$name} };
  };
  *{"${targ}::lazy"} = sub {
    Carp::croak "No name passed to lazy" unless my $name = shift;
    Carp::croak "No builder passed to lazy" unless my $builder = shift;
    Carp::croak "Extra args passed to lazy" if @_;
    ($attrs||=_setup_attrs($targ))->{$name} = 0;
    if (ref($builder) eq 'CODE') {
      my $method = "_build_${name}";
      *{"${targ}::${method}"} = $builder;
      $builder = $method;
    } elsif (ref($builder)) {
      Carp::croak "Builder passed to lazy must be name or code, not ${builder}";
    }
    *{"${targ}::${name}"} = sub {
      exists($_[0]->{$name})
        ? $_[0]->{name}
        : ($_[0]->{name} = $_[0]->$builder)
    };
  };
}

my $ATTRS = '__Mu__Tiny__attrs';

sub _setup_attrs {
  my ($targ) = @_;
  my $attrs = {};
  my $orig = $targ->can($ATTRS);
  Carp::croak "Can't find Mu::Tiny attrs method ${ATTRS} in ${targ}"
    unless $orig;
  no strict 'refs';
  *{"${targ}::${ATTRS}"} = sub { $_[0]->$orig, %$attrs };
  $attrs;
}

package Mu::Tiny::Object;

sub __Mu__Tiny__attrs { () }

my %spec;

sub new {
  my $class = shift;
  my ($attr, $req) = @{$spec{$class} ||= do {
    my %attrs = $class->__Mu__Tiny__attrs;
    [[ sort keys %attrs ], [ sort grep $attrs{$_}, keys %attrs ]];
  }};
  my %args = @_ ? @_ > 1 ? @_ : %{$_[0]} : ();
  my @missing = grep !exists($args{$_}), @$req;
  Carp::croak "Missing required attributes: ".join(', ', @missing) if @missing;
  my %new = map { exists($args{$_}) ? ($_ => $args{$_}) : () } @$attr;
  bless(\%new, ref($class) || $class);
}

$INC{"Mu/Tiny/Object.pm"} = __FILE__;

1;

=head1 NAME

Mu::Tiny - NAE KING! NAE QUIN! NAE CAPTAIN! WE WILLNAE BE FOOLED AGAIN!

=head1 SYNOPSIS

  BEGIN {
    package Feegle;
  
    use Mu::Tiny;
  
    ro 'name';
    lazy plan => sub { 'PLN' };
  }
  
  my $rob = Feegle->new(name => 'Rob Anybody'); # name is required
  
  say $rob->plan; # outputs 'PLN'

=head1 DESCRIPTION

This is the aaaabsoluuuute baaaaare minimumimumimum subset o' L<Mu>, for
those o' ye who value yer independence over yer sanity. It doesnae trouble
wi' anythin' but the read-onlies, for tis a terrible thing to make a feegle
try t' write.

=head1 METHODS

=head2 new

  my $new = Feegle->new(%attrs|\%attrs);

The new method be inherited from C<Mu::Tiny::Object> like a shiny thing or
the duties o' a Kelda.

Ye may hand it a hash, or if ye already made yer own hash o' things, a
reference to the one so pre-prepared.

An ye forget any o' the attrs declared as L</ro>, then C<new> will go
waily waily waily and C<croak> with a list of all that ye missed.

=head1 EXPORTS

=head2 ro

  ro 'attr';

An C<ro> attr be required and read only, and knows nothin' but its own name.

=head2 lazy

  lazy 'attr' => sub { <build default value> };

A <lazy> attr be read only but not required, an' if ye make us, we'll take a
guess at what ye wanted, but only when we must.

If'n ye be slightly less lazy than us, then subclass and override yan
C<_build_attr> method t' change tha guess.

=head1 WHUT

Dinnae fash yersel', Hamish, you prob'ly wanted L<Mu> anyway.

=head1 APOLOGIES

... to Terry Pratchett, Mithaldu, and probably everybody else as well.

=head1 AUTHOR

 mst - Matt S. Trout (cpan:MSTROUT) <mst@shadowcat.co.uk>

=head1 CONTRIBUTORS

None yet - maybe this software is perfect! (ahahahahahahahahaha)

=head1 COPYRIGHT

Copyright (c) 2020 the Mu::Tiny L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.
