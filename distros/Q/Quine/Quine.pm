package Quine;

$VERSION = '1.01';

sub import {
  my $file = (caller)[1];
  local ($/, *FILE);
  open FILE, $file;
  print STDOUT <FILE>;
  close FILE;
  exit;
}


1;

__END__

=head1 NAME

Quine - extension for creating quines

=head1 SYNOPSIS

  #!/usr/bin/perl -w

  use Quine;

  # rest of code here

=head1 DESCRIPTION

This module simply prints the content of the program using the module.  This
type of program is called a "quine".

=head1 AUTHOR

  Jeff "japhy" Pinyan
  CPAN ID: PINYAN
  japhy@pobox.com
  http://www.pobox.com/~japhy/

=cut
