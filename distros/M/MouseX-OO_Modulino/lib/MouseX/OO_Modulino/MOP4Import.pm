package MouseX::OO_Modulino::MOP4Import;
use strict;
use warnings;

use Mouse ();
use Data::Dumper ();
use Carp ();

our $VERSION = '0.02';

use constant DEBUG => $ENV{DEBUG_MOP4IMPORT};
BEGIN {
  print STDERR "\nUsing ".__PACKAGE__. " = (file '"
    . __FILE__ . "')\n"
    if DEBUG;
}

#
# init_meta is called if `-as_base` import pragma is specified.
#
sub init_meta {
  my ($myPack, %options) = @_;

  my $for_class = $options{for_class}
    or Carp::croak "for_class is required!";

  my $meta = Mouse->init_meta(for_class => $for_class);

  $meta->superclasses($myPack, qw(Mouse::Object));
}

#
# Implement minimum MOP4Import::Declare
#
sub import {
  my ($myPack, @decls) = @_;

  my $caller = [caller];

  @decls = $myPack->default_exports($caller) unless @decls;

  $myPack->dispatch_declare($caller, $myPack->always_exports($caller), @decls);
}

sub default_exports { () }

sub always_exports  { () }

sub dispatch_declare {
  my ($myPack, $opts, @decls) = @_;

  print STDERR "$myPack->dispatch_declare("
    .join(", ", $myPack->cli_encode_dump($opts, @decls)).");\n" if DEBUG;

  foreach my $declSpec (@decls) {
    Carp::croak "Undefined pragma!" unless defined $declSpec;

    if (not ref $declSpec) {

      $myPack->dispatch_import($opts, $declSpec);

    }
    elsif (ref $declSpec eq 'ARRAY') {

      $myPack->dispatch_declare_pragma($opts, @$declSpec);

    }
    else {
      Carp::croak "Invalid pragma: ".$myPack->cli_encode_dump($declSpec);
    }
  }
}

sub dispatch_import {
  my ($myPack, $opts, $declSpec) = @_;

  my ($name, $exported);

  if (not ref $declSpec and $declSpec =~ /^-([A-Za-z]\w*)$/) {

    $myPack->dispatch_declare_pragma($opts, $1);

  }
  else {

    $myPack->dispatch_import_symbols($opts, $declSpec);
  }
}

sub dispatch_declare_pragma {
  my ($myPack, $opts, $pragma, @rest) = @_;

  my $sub = $myPack->can("declare_$pragma") or do {
    Carp::croak "No such pragma: $pragma at $opts->[1] line $opts->[2]";
  };

  $sub->($myPack, $opts, @rest);
}

sub declare_as_base {
  my ($myPack, $opts, @rest) = @_;

  print STDERR "Class $opts->[0] inherits $myPack\n"
    if DEBUG;

  my $caller = $opts->[0];

  Mouse->import(+{
    into => $caller
  });

  $myPack->init_meta(for_class => $caller, @rest);
}

sub declare_has {
  my ($myPack, $opts, $nameSpec, @attrs) = @_;

  unless (@attrs % 2 == 0) {
    Carp::croak "Usage: [has 'name' => (key => value, ...)],";
  }

  my $meta = Mouse::Meta::Class->initialize($opts->[0]);

  foreach my $name (ref $nameSpec ? @$nameSpec : $nameSpec) {
    $meta->add_attribute($name, @attrs);
  }

  $meta;
}

sub declare_field {
  my ($myPack, $opts, $nameSpec, @attrs) = @_;

  my $meta = $myPack->has($opts, $nameSpec, @attrs);

  my $sym = globref(ref $_[0] || $_[0], 'FIELDS');
  unless (*{$sym}{HASH}) {
    *$sym = {};
  }
  my $fields = *{$sym}{HASH};

  foreach my $name (ref $nameSpec ? @$nameSpec : $nameSpec) {
    $fields->{$name} = $meta;
  }
}

our %SIGIL_MAP = qw(
  * GLOB
  $ SCALAR
  % HASH
  @ ARRAY
  & CODE
);

sub dispatch_import_symbols {
  my ($myPack, $opts, @declSpec) = @_;
  foreach my $declSpec (@declSpec) {
    if ($declSpec =~ /^([\*\$\%\@\&])?([A-Za-z]\w*)$/) {
      if ($1) {
        my $kind = $SIGIL_MAP{$1};
        $myPack->import_SIGIL($opts, $1, $kind, $2);
      } else {
        $myPack->import_NAME($opts => $2);
      }
    } else {
      Carp::croak "Invalid import spec: $declSpec";
    }
  }
}

sub import_SIGIL  {
  my ($myPack, $opts, $sigil, $kind, $name) = @_;

  my $exported = *{safe_globref($myPack, $name)}{$kind};

  print STDERR " Declaring $sigil$opts->[0]::$name"
    . ", import from $sigil${myPack}::$name"
    . " (=".terse_dump($exported).")\n" if DEBUG;

  *{globref($opts->[0], $name)} = $exported;
}

sub import_NAME {
  my ($myPack, $opts, $name) = @_;

  my $exported = safe_globref($myPack, $name);

  print STDERR " Declaring $name in $opts->[0] as "
    .terse_dump($exported)."\n" if DEBUG;

  *{globref($opts->[0], $name)} = $exported;
}

sub cli_encode_dump {
  my ($self, @obj) = @_;
  Data::Dumper->new(\@obj)->Terse(1)->Indent(0)->Dump
}

#
# Stolen from MOP4Import::Util
#
sub globref {
  my $pack = shift;
  unless (defined $pack) {
    Carp::croak "undef is given to globref()";
  }
  my $symname = join("::", $pack, @_);
  no strict 'refs';
  \*{$symname};
}

sub symtab {
  *{globref(shift, '')}{HASH}
}

sub safe_globref {
  my ($pack_or_obj, $name) = @_;
  unless (defined symtab($pack_or_obj)->{$name}) {
    my $pack = ref $pack_or_obj || $pack_or_obj;
    Carp::croak "No such symbol '$name' in package $pack";
  }
  globref($pack_or_obj, $name);
}

1;
