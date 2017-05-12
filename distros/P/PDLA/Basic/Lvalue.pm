=head1 NAME

PDLA::Lvalue - declare PDLA lvalue subs

=head1 DESCRIPTION

Declares a subset of PDLA functions so that they
can be used as lvalue subs. In particular, this allows
simpler constructs such as

  $a->slice(',(0)') .= 1;

instead of the clumsy

  (my $tmp = $a->slice(',(0)')) .= 1;

This will only work if your perl supports lvalue subroutines
(i.e. versions  >= v5.6.0). Note that lvalue subroutines
are currently regarded experimental.

=head1 SYNOPSIS

 use PDLA::Lvalue; # automatically done with all PDLA loaders

=head1 FUNCTIONS

=cut

package PDLA::Lvalue;

# list of functions that can be used as lvalue subs
# extend as necessary
my @funcs = qw/ clump diagonal dice dice_axis dummy flat
                index index2d indexND indexNDb mslice mv
                nslice nslice_if_pdl nnslice polyfillv px
                range rangeb reorder reshape sever slice
                where whereND xchg /;

my $prots = join "\n", map {"use attributes 'PDLA', \\&PDLA::$_, 'lvalue';"}
  @funcs;

=head2 subs

=for ref

test if routine is a known PDLA lvalue sub

=for example

  print "slice is an lvalue sub" if PDLA::Lvalue->subs('slice');

returns the list of PDLA lvalue subs if no routine name is given, e.g.

  @lvfuncs = PDLA::Lvalue->subs;

It can be used in scalar context to find out if your
PDLA has lvalue subs:

  print 'has lvalue subs' if PDLA::Lvalue->subs;

=cut

sub subs {
  my ($type,$func) = @_;
  if (defined $func) {
    $func =~ s/^.*:://;
    return ($^V and $^V >= 5.006007) && scalar grep {$_ eq $func} @funcs;
  } else {
    return ($^V and $^V >= 5.006007) ? @funcs : ();
  }
}

# print "defining lvalue subs:\n$prots\n";

eval << "EOV" if ($^V and $^V >= 5.006007);
{ package PDLA;
  no warnings qw(misc);
  $prots
}
EOV

=head1 AUTHOR

Copyright (C) 2001 Christian Soeller (c.soeller@auckland.ac.nz). All
rights reserved. There is no warranty. You are allowed to redistribute
this software / documentation under certain conditions. For details,
see the file COPYING in the PDLA distribution. If this file is
separated from the PDLA distribution, the copyright notice should be
included in the file.

=cut

1;
