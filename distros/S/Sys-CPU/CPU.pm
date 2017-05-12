package Sys::CPU;

use strict;

use vars qw(@ISA %EXPORT_TAGS @EXPORT_OK $VERSION);
require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

# This allows declaration	use Sys::CPU ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
  cpu_count
  cpu_clock
  cpu_type
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = '0.61';

bootstrap Sys::CPU $VERSION;

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Sys::CPU - Perl extension for getting CPU information. Currently only number of CPU's supported.

=head1 SYNOPSIS

  use Sys::CPU;

  $number_of_cpus = Sys::CPU::cpu_count();
  printf("I have %d CPU's\n",$number_of_cpus);
  print "  Speed : ",Sys::CPU::cpu_clock(),"\n";
  print "  Type  : ",Sys::CPU::cpu_type(),"\n";

=head1 DESCRIPTION

In responce to a post on perlmonks.org, a module for counting the number of CPU's on a
system. Support has now also been added for type of CPU and clock speed. While much of the
code is from UNIX::Processors, win32 support has been added (but not tested).

v0.45 - Corrected solaris support (Thanks Cloyce)

v0.60 - Added FreeBSD support (Thanks Johan & SREZIC)
v0.61 - Fix test numbering issue

=head2 EXPORT

None by default.

=head1 AUTHOR

Matt Sanford

=head1 MAINTENANCE

Marc Koderer

=head1 LICENSE


=head1 SEE ALSO

perl(1), sysconf(3)

=cut
