package PeekPoke;

require 5.005_62;
use strict;
use warnings;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);
our @EXPORT_OK = qw(peek poke);
our $VERSION = '0.01';

bootstrap PeekPoke $VERSION;

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

PeekPoke - Perl extension for reading and writing memory

=head1 SYNOPSIS

  use PeekPoke qw(peek poke);
  my $val = peek($address);
  poke($address, $val|1);

=head1 DESCRIPTION

C<peek>'s argument is a machine address.  (Strings will be converted
to numbers as usual.)  C<peek> returns the value stored at that
address.

C<poke>'s arguments are a machine address and a value; the value is stored at the specified address.

Addresses and values are either 32- or 64-bit integers, depending on
whether your version of Perl was compiled with 64-bit support.

=head2 EXPORT

None by default.

=head1 AUTHOR

Mark Dominus mjd-perl-peek+@plover.com
Jason Dominus mjd-perl-poke+@plover.com

=head1 SEE ALSO

perl(1), Microsoft BASIC.

=cut
