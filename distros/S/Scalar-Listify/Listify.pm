package Scalar::Listify;

require 5.005_62;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Scalar::Listify ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our @EXPORT;
@EXPORT = qw(&listify &listify_aref);

our $VERSION = '0.03';


# Preloaded methods go here.

my $sub = 'Scalar::Listify::listify';

sub listify {

  scalar @_ == 1 or die "$sub only takes one argument and this argument
must be a simple scalar or array reference";

  my $scalar = shift;

  if (not ref($scalar)) {
    my @ret = ($scalar);
    return (@ret);
  }

  ref($scalar) eq 'ARRAY' and return @$scalar;

  require Data::Dumper;
  my $err = "Scalar::Listify::listify error - this function only takes
simple scalars or references to arrays. I'm not sure what you gave me, but
here is what Data::Dumper has to say about it:";
  warn $err;
  warn Data::Dumper->Dump([$scalar],['bad_data']);

}

sub listify_aref {

  [ listify @_ ]

}

1;
__END__

=head1 NAME

Scalar::Listify - produces an array(ref)? from a scalar value or array ref.

=head1 SYNOPSIS

  use Scalar::Listify;

  $text_scalar = 'text';
  $aref_scalar = [ 1.. 5 ];

  print join ':', listify $text_scalar; # => text
  print join ':', listify $aref_scalar; # => 1:2:3:4:5

=head1 DESCRIPTION

A lot of Perl code ends up with scalars having either a single scalar
value or a reference to an array of scalar values. In order to handle
the two conditions, one must check for what is in the scalar value
before getting on with one's task. Ie:

  $text_scalar = 'text';
  $aref_scalar = [ 1.. 5 ];

  print ref($text_scalar) ? (join ':', @$text_scalar) : $text_scalar;

And this module is designed to address just that!

=head2 EXPORT

listify() - listify takes a scalar as an argument and returns the
value of the scalar in a format useable in list contexts.

listify_aref() - returns [ listify (@_) ]

=head1 AUTHOR

T. M. Brannon, <tbone@CPAN.org>

=head1 COPYRIGHT

Copyright 1999-present by Terrence Brannon.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1).

=cut
