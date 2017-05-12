package NVDefined;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	     NVExists
	     NVDefined
	    );

use Hash::NoVivify;

$VERSION = '0.02';

sub NVExists {
    my($hashref) = shift;
    Hash::NoVivify::Exists($hashref, @_);
}

sub NVDefined {
    my($hashref) = shift;
    Hash::NoVivify::Defined($hashref, @_);
}

__END__

=head1 NAME

NVDefined - Perl extension for non-vivifying exists and defined functions

=head1 SYNOPSIS

  use NVDefined;

  ...

  if (NVExists(\%hash, qw(key1 key2 ... keyn ))) {
      ...
  }

  if (NVDefined(\%hash, qw(key1 key2 ... keyn))) {
      ...
  }

=head1 DESCRIPTION

This module has been superseded by Hash::NoVivify, qv.

=head1 AUTHOR

Brent B. Powers (B2Pi), Powers@B2Pi.com

Copyright(c) 1999 Brent B. Powers. All rights reserved. This program
is free software, you may redistribute it and/or modify it under the
same terms as Perl itself.

=head1 SEE ALSO

perl(1), perlfunc(1).

=cut
