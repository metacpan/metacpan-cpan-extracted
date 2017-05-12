#!/usr/bin/perl -w
use strict;
use PAR::WebStart::Util qw(make_par);
use Getopt::Long;

my ($name, $help, $no_sign, $src_dir, $dst_dir);
my $rc = GetOptions('help' => \$help,
                    'name=s' => \$name,
                    'no-sign' => \$no_sign,
                    'src_dir=s' => \$src_dir,
                    'dst_dir=s' => \$dst_dir);

if ($help or not $rc) {
    print <<"USE";

Make a par archive for use with PAR::WebStart

Usage: my (\$par, \$md5) = make_par [ options ]

Available options:

  --help:               display this message
  --no-sign:            do not sign the par file
  --name=MyPar:         specify the name of the par file
  --src_dir=/Some/src:  specify the source directory
  --dst_dir=/Some/dst:  specify the destination directory

If successful, returns the name of the par and md5 checksum files.

USE
    exit(1);
}

my ($par, $md5) = make_par(name => $name, src_dir => $src_dir,
                           dst_dir => $dst_dir, no_sign => $no_sign);
  print <<"END";

The par file was successfully created as
   $par,
with an associated md5 checksum file
   $md5.

END

__END__

=head1 NAME

make_par - make a par archive for use with PAR::WebStart

=head1 SYNOPSIS

  # make a par archive from the current directory
  make_par

  # get a short help message
  make_par --help

=head1 DESCRIPTION

This utility will make a par archive suitable for use with C<PAR::WebStart>.
The created C<par> file and C<md5> checksum file should
be moved to the appropriate location on the web server.

=head1 SEE ALSO

L<Par::WebStart::Util>

=head1 COPYRIGHT

Copyright, 2005, by Randy Kobes <r.kobes@uwinnipeg.ca>.
This software is distributed under the same terms as Perl itself.
See L<http://www.perl.com/perl/misc/Artistic.html>.

=head1 SEE ALSO

L<PAR::WebStart>

=cut

