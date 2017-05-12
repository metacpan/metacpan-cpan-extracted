# Copyright (c) Philippe Verdret, 1995-1997
require 5.000;
use strict;

package Parse::Trace;
$Parse::Trace::VERSION = '2.21';
use Carp;
#use vars qw($indent);
$Trace::indent = 0;

# doesn't work with my Perl current version
#use FileHandle;
my $TRACE = \*STDERR;		# Default

my %cache = ();
sub name { $cache{$_[0]} or ($cache{$_[0]} = $_[0]->findName) }
sub inpkg { 'main' }		# no better definition at the present time

sub findName {			# Try to find the "name" of self
				# assume $self is put in a scalar variable
  my $self = shift;
  my $pkg = $self->inpkg;
  my $symbol;
  my $value;
  no strict qw(refs);
  local $^W = 0;
  map {
    ($symbol = ${"${pkg}::"}{$_}) =~ s/[*]//;
    if (defined($value = ${$symbol})) {
      return $symbol if ($value eq $self);
    } 
  } grep {! /\W/} keys %{"${$pkg}::"};
  use strict qw(refs);
  return undef;
}
sub context {
  my $self = shift;
  my $ref = ref($self);
  my $name = '';
  $name = $self->name;	
  if (not $name) {
    $name = $self->Parse::Trace::name;
  }
  my $sign = defined $name ? "[$name|$ref]" : "[$ref]";
  print $TRACE "  " x $Trace::indent, "$sign @_\n";
}

sub trace {	
  my $self = shift;
  my $class = (ref $self or $self);
				# state switch
  no strict qw(refs);

  ${"${class}::trace"} = not ${"${class}::trace"};
  if (${"${class}::trace"}) {
    my $file = $class;
    $file =~ s!::!/!g;
    eval {			# Load specialized methods
      # die() is trapped by $Parse::Template::SIG{__DIE__}
      #local $SIG{__DIE__} = sub {};
      #require "${file}-t.pm";
      do "${file}-t.pm";	# do esn't raised an exception
    };
    print STDERR "Trace is ON in class $class\n";
  } else {
    print STDERR "Trace is OFF in class $class\n";
  }
  use strict qw(refs);
				# output
  if (@_) {
    if (ref $_[0]) {
      $TRACE = $_[0];
    } else {
#      $TRACE = new FileHandle("> $_[0]");
      unless ($TRACE) {
	croak qq^unable to open "$_[0]"^;
      } else {
	print STDERR "Trace put in $_[0]\n";
      }
    }
  }
}

1;
__END__

=head1 NAME

C<Parse::Trace> - Trace functions used by the lexical analyzers

=head1 AUTHOR

Philippe Verdret.

=head1 COPYRIGHT

Copyright (c) 1999 Philippe Verdret. All rights reserved.  This module
is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.
