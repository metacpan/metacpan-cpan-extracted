package Perlmazing::Engine::Exporter;
use strict;
use warnings;
use Carp;
our $VERSION = '1.2810';
my $package = __PACKAGE__;
my $imports;
my $exports;

sub import {
  my $self = shift;
  my @call = caller 0;
  my $pack = $call[0];
  no strict 'refs';
  if ($self eq $package) {
    my $in_isa = grep { /^\Q$package\E$/ } @{"${pack}::ISA"};
    unshift (@{"${pack}::ISA"}, __PACKAGE__) unless $in_isa;
  } else {
    if (my @call = caller 1) {
      $pack = $call[0] if $call[3] eq "${self}::import";
    }
    return if $imports->{$pack}->{$self};
    my @export = (@_, @{"${self}::EXPORT"});
    @export = $self->_expand_names(@export);
    my (@yes, $no);
    for my $i (@export) {
      if ($i =~ s/^!//) {
        $no->{$i} = 1;
      }
      push (@yes, $i) unless $no->{$i};
    }
    for my $i (@yes) {
      $package->export($self, $i, $pack);
    }
    $imports->{$pack}->{$self}++;
  }
}

sub _expand_names {
  my $self = shift;
  my @expanded;
  no strict 'refs';
  for my $i (@_) {
    my $no = $i =~ s/^!//;
    my $neg = $no ? '!' : '';
    if ($i =~ /^:(\w+)$/) {
      my $name = $1;
      croak "Package $self doesn't define tag '$name' in \%EXPORT_TAGS" unless exists ${"${self}::EXPORT_TAGS"}{$name};
      push @expanded, map {($_ =~ s/^!//) ? ($no ? $_ : "$neg$_") : "$neg$_"} $self->_expand_names(@{${"${self}::EXPORT_TAGS"}{$name}});
    } else {
      push @expanded, "$neg$i";
    }
  }
  my $seen;
  my @final;
  for my $i (@expanded) {
    push @final, $i;
    $seen->{$i}++;
  }
  my $found_symbols = {map {$_ => 1} @{"${self}::found_symbols"}};
  for my $i (@final) {
    (my $name = $i) =~ s/^!//;
    croak "Unknown symbol '$name' from package '$self'" unless defined(&{"${self}::$name"}) or exists $found_symbols->{$name};
  }
  @final;
}

sub export {
  my $self = shift;
  my ($from, $symbol, $to) = (shift, shift, shift);
  my $sigil = '&';
  $symbol =~ s/^(:|\&|\$|\%|\@|\*)/$sigil = $1; ''/e;
  croak "Unknown symbol type for expression '$symbol' in EXPORT" if $symbol =~ /^\W/;
  no strict 'refs';
  no warnings 'once';
  if ($sigil eq ':') {
    my $tags = \%{"${from}::EXPORT_TAGS"};
    if (not exists $tags->{$symbol}) {
      croak "Export tag '$symbol' is not defined in package $from";
    }
    unless (ref($tags->{$symbol}) eq 'ARRAY') {
      croak "Export tags should contain array refs";
    }
    for my $i (@{$tags->{$symbol}}) {
      $self->export($from, $i, $to);
    }
  } elsif ($sigil eq '&') {
    if (not defined *{"${from}::$symbol"}{CODE}) {
      eval "sub ${from}::$symbol"; ## no critic
      croak "Cannot create symbol for sub ${from}::$symbol: $@" if $@;
    }
    if (not $exports->{$to}->{$symbol}) {
      if (defined *{"${to}::$symbol"}{CODE}) {
        croak "Cannot define symbol &${to}::$symbol: symbol is already defined under the same namespace and name";
      } else {
        *{"${to}::$symbol"} = *{"${from}::$symbol"}{CODE};
        $exports->{$to}->{$symbol}++;
      }
    }
  } elsif ($sigil eq '$') {
    if (not defined *{"${from}::$symbol"}{SCALAR}) {
      ${"${from}::$symbol"} = undef;
    }
    *{"${to}::$symbol"} = *{"${from}::$symbol"}{SCALAR};
  } elsif ($sigil eq '@') {
    if (not defined *{"${from}::$symbol"}{ARRAY}) {
      @{"${from}::$symbol"} = ();
    }
    *{"${to}::$symbol"} = *{"${from}::$symbol"}{ARRAY};
  } elsif ($sigil eq '%') {
    if (not defined *{"${from}::$symbol"}{HASH}) {
      %{"${from}::$symbol"} = ();
    }
    *{"${to}::$symbol"} = *{"${from}::$symbol"}{HASH};
  } elsif ($sigil eq '*') {
    *{"${to}::$symbol"} = *{"${from}::$symbol"};
  } else {
    croak "I don't know how to handle '$symbol' in EXPORT";
  }
}

1;