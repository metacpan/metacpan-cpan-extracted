package NetAddr::IP::Obfuscate;

require 5.006_000; # Needed for NetAddr::IP and the $fh in _slurp_file
use strict;
use warnings;
require Exporter;

our @ISA = qw(Exporter);

use vars qw($VERSION @EXPORT);

$VERSION = '0.02';
@EXPORT = qw(do_obfu);

use Carp;
use NetAddr::IP::Find;

sub do_obfu {

  my %obfuscated;
  my $infile;
  my $net;
  my $outfile;

  if (scalar(@_) == 0) {
    # No arguments, supply some sane defaults
      $infile = "-";
      $net = "10.0.0.0/8";
      $outfile = "STDOUT";

    } else {

      ($infile,$net,$outfile) = @_;

    }


  my $text_ref = _slurp_file ($infile);

  my $ip = NetAddr::IP->new("$net");

  find_ipaddrs($$text_ref, sub {
		 my($ipaddr, $orig) = @_;
		 return $obfuscated{$orig} if exists $obfuscated{$orig};
		 ++$ip;
		 $obfuscated{$orig} = $ip->addr;
	       });

  _burp_file ($outfile, $text_ref);

  return values %obfuscated if wantarray();

  return scalar(keys %obfuscated);

}


sub _slurp_file {

  my $infile = shift;

  open( my $fh, $infile ) or croak "Unable to open $infile in _slurp_file: $!\n";

  my $text = do { local( $/ ) ; <$fh> } ;

  return \$text;

}

sub _burp_file {

  my $outfile = shift;
  my $text_ref = shift;

  if ($outfile eq "STDOUT") {

    print $$text_ref;

  } else {

    open( my $fh, ">$outfile" ) or croak "Unable to open $outfile in _burp_file: $!\n" ;

    print $fh $$text_ref ;

  }

}

1;

__END__

=head1 NAME

NetAddr::IP::Obfuscate - Replace IP addresses in plain text with
obfuscated equivalents

=head1 SYNOPSIS

  use NetAddr::IP::Obfuscate;
  do_obfu();

  use NetAddr::IP::Obfuscate;
  $num_found = do_obfu($infile, "10.0.0.0/8", $outfile);

  use NetAddr::IP::Obfuscate;
  @obfuscated_ips = do_obfu($infile, "10.0.0.0/8", $outfile);

  use NetAddr::IP::Obfuscate;
  do_obfu("-", "10.0.0.0/8", "STDOUT");

  cat /tmp/somecompany.nsr | \
  perl -MNetAddr::IP::Obfuscate -e 'do_obfu()' > /tmp/sample.nsr

=head1 DESCRIPTION

This is a module for replacing IP addresses in plain text with
obfuscated equivalents from the network range supplied. IP addresses
are replaced one-for-one throughout the text, so once an IP address
has an obfuscated equivalent, it stays that way. This is useful for
things like Nessus scan reports that you want to share or make public,
but want to shield an organization's identity at the same time.

=head2 EXPORT

NetAddr::IP::Obfuscate exports one function, do_obfu().

  do_obfu();
  $num_found = do_obfu ($infile, $network, $outfile);
  @obfuscated_ips = do_obfu ($infile, $network, $outfile);

There is a no argument form of do_obfu, that assigns default values to
all its parameters. The first, the input file, is set to "-" (reads
from STDIN), the second, the network range used for replacement, is
set to "10.0.0.0/8", and the last, the output file, is set to
"STDOUT". This form is particularly useful for something like this
one-liner:

  cat /tmp/somecompany.nsr | \
  perl -MNetAddr::IP::Obfuscate -e 'do_obfu()' > /tmp/sample.nsr

Which will obfuscate all the IP addresses in /tmp/somecompany.nsr with
IP's from the range 10.0.0.0/8, and write the result out to
/tmp/sample.nsr.

In the three-argument version, the first argument is the input text
file, presumably containing IP addresses, that we will be
obfuscating. Use the string "-" to read from standard input.

The second argument is a network address, which should be given in
CIDR notation, and really represents a range of IP addresses from
which we can draw from while doing the IP address substitutions (Note
that the use of NetAddr::IP means that we will never overflow this
range - but it will wrap around if we increment it enough). Using an
RFC1918 private address range is a good idea if you are using this
module to obfuscate Nessus scan reports for public dissemination.

The last function argument is the output file, which will have all of
the original file's IP addresses, replaced one-for-one with IP
addresses from the supplied range. Use the string "STDOUT" for
standard output.

do_obfu returns the total number of IP addresses replaced if it is
called in a scalar context, or a list of the obfuscated IP addresses,
if called in a list context.

=head1 EXAMPLES

use NetAddr::IP::Obfuscate;

my $infile = "/tmp/somecompany.nsr";
my $outfile = "/tmp/sample.nsr";

@ips = do_obfu($infile,"10.1.1.0/24",$outfile);

Do something with @ips...

=head1 TODO

=over 4

=item *

More robust error checking, for instance supplying very small IP
ranges in the second parameter.

=item *

More test cases.

=back

=head1 AUTHOR

Doug Maxwell E<lt>doug@turinglabs.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Doug Maxwell

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<NetAddr::IP>, L<NetAddr::IP::Find>, L<File::Slurp>

=cut
