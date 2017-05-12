#
# This file is part of Tee
#
# This software is Copyright (c) 2006 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
use strict;
use warnings;
package Tee::App;
BEGIN {
  $Tee::App::VERSION = '0.14';
}
# ABSTRACT: Implementation of ptee

use Exporter ();
use File::Basename qw/basename/;
use Getopt::Long;
use IO::File;
our @ISA = 'Exporter';
our @EXPORT = qw/run/;

#--------------------------------------------------------------------------#
# define help text
#--------------------------------------------------------------------------#

my $help_text = <<'END_HELP';

 ptee [OPTIONS]... [FILENAMES]...

 OPTIONS:
 
    --append or -a
        append to file(s) rather than overwrite

    --help or -h
        give usage information

    --version or -V
        print the version number of this program

END_HELP

$help_text =~ s/\A.+?( ptee.*)/$1/ms;

sub run {

  #--------------------------------------------------------------------------#
  # process command line
  #--------------------------------------------------------------------------#

  my %opts;
  GetOptions( \%opts,
      'version|V',
      'help|h|?',
      'append|a',
  );

  #--------------------------------------------------------------------------#
  # options
  #--------------------------------------------------------------------------#

  if ($opts{version}) {
      print basename($0), " $main::VERSION\n";
      exit 0;
  }

  if ($opts{help}) {
      print "Usage:\n$help_text";
      exit 1;
  }

  my $mode = $opts{append} ? ">>" : ">";

  #--------------------------------------------------------------------------#
  # Setup list of filehandles
  #--------------------------------------------------------------------------#

  my @files;

  for my $file ( @ARGV ) {
      my $f = IO::File->new("$mode $file") 
          or die "Could't open '$file' for writing: $!'";
      push @files, $f;
  }

  #--------------------------------------------------------------------------#
  # Tee input to the filehandle list
  #--------------------------------------------------------------------------#

  my $buffer_size = 1024;
  my $buffer;

  while ( sysread( STDIN, $buffer, $buffer_size ) > 0 ) {
      syswrite STDOUT, $buffer;
      for my $fh ( @files ) {
          syswrite $fh, $buffer;
      }
  }
  return;
}

1;



=pod

=head1 NAME

Tee::App - Implementation of ptee

=head1 VERSION

version 0.14

=head1 DESCRIPTION

Guts of the C<<< ptee >>> command.

=for Pod::Coverage run

=head1 SEE ALSO

=over

=item *

L<ptee>

=back

=head1 BUGS

Please report any bugs or feature using the CPAN Request Tracker.  
Bugs can be submitted through the web interface at 
L<http://rt.cpan.org/Dist/Display.html?Queue=Tee>

When submitting a bug or request, please include a test-file or a patch to an
existing test-file that illustrates the bug or desired feature.

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2006 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut


__END__

