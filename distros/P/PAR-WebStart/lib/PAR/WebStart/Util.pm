package PAR::WebStart::Util;
use strict;
use warnings;
use Archive::Zip;
use File::Find;
use Digest::MD5;
use File::Spec;
use File::Basename;
use Cwd;
use ExtUtils::Manifest qw(mkmanifest maniread);
use base qw(Exporter);
use Module::Signature qw(sign verify SIGNATURE_OK);

our $VERSION = '0.20';
our @EXPORT_OK = qw(make_par verifyMD5);

use constant WIN32 => ($^O eq 'MSWin32');

my $no_sign;

sub make_par {
  my %args = @_;
  my ($src_dir, $dst_dir, $name) = @args{qw(src_dir dst_dir name)};
  $no_sign = 1 if $args{no_sign};

  if ($src_dir and -d $src_dir) {
    chdir($src_dir) or die qq{Cannot chdir to "$src_dir": $!};
  }

  if (-d 'blib') {
    chdir('blib') or die qq{Cannot chdir to "blib": $!};
  }

  my $cwd = getcwd;
  $dst_dir ||= $cwd;
  $src_dir ||= $cwd;
  unless ($name) {
    my @d = File::Spec->splitdir($cwd);
    $name = ($d[$#d] eq 'blib') ? $d[$#d-1] : $d[$#d];
  }
  $name .= '.par' unless ($name =~ /\.par$/);
  my $dst_par = File::Spec->catfile($dst_dir, $name);
  my $dst_cs = $dst_par . '.md5';
  my $src_par = File::Spec->catfile($src_dir, $name);
  my $src_cs = $src_par . '.md5';

  my @dirs = qw(arch lib script bin);
  my $test = 0;
  my %has;
  foreach my $d (@dirs) {
    if (-d $d) {
      $test++;
      $has{$d}++;
    }
  }
  die qq{Cannot find any of "@dirs"} unless $test;

  for my $file ( $dst_par, $dst_cs, $src_par, $src_cs, qw(SIGNATURE MANIFEST) ) {
    next unless -f $file;
    warn "Removing $file ...\n";
    unlink($file);
  }

  mkmanifest();
  my $maniread = maniread();
  if ($no_sign) {
    $maniread->{SIGNATURE} = undef if $maniread->{SIGNATURE};
  }
  else {
    open(my $fh, '>>', 'MANIFEST') or die "Cannot open MANIFEST: $!";
    print $fh "SIGNATURE\n";
    close $fh;
    $maniread->{SIGNATURE}++;
    sign(overwrite => 1);
    (verify() == SIGNATURE_OK) or die qq{Signature verification failed};
  }

  my $arc = Archive::Zip->new();
  print qq{\nAdding files to zip archive...\n};
  foreach my $f(keys %$maniread) {
    die qq{zip of "$f" failed} unless $arc->addFile($f, $f);
    print "\t$f\n";
  }

  die qq{Writing to "$dst_par" failed}
        unless $arc->writeToFileNamed($dst_par) == Archive::Zip::AZ_OK();
  print qq{Done!\n};

  open(my $par_fh, $dst_par) or die qq{Cannot open "$dst_par": $!};
  binmode($par_fh);
  my $md5;
  unless ($md5 = Digest::MD5->new->addfile($par_fh)->hexdigest) {
    close $par_fh;
    die qq{Computing md5 checksum of "$dst_par" failed};
  }
  close $par_fh;

  open(my $md5_fh, '>', $dst_cs) or die qq{Cannot open "$dst_cs": $!};
  print $md5_fh $md5;
  close $md5_fh;

  my $check = verifyMD5(file => $dst_par, md5 => $dst_cs);
  if ($check == 1) {
    print "Checksum for $dst_par OK.\n";
  }
  else {
    die qq{Checksum for $dst_par failed: $check};
  }
  return ($dst_par, $dst_cs);
}

sub verifyMD5 {
  my %args = @_;

  my ($md5_file, $file) = @args{qw(md5 file)};

  my ($should, $is);
  open(my $cs, $md5_file)
    or return qq{Cannot open "$md5_file" to verify md5: $!};

  chomp($should = <$cs>);
  $should =~ s{\r}{};
  close $cs;

  open (my $par, $file)
    or return qq{Cannot open "$file": $!};
  binmode($par);
  unless ($is = Digest::MD5->new->addfile($par)->hexdigest) {
    close $par;
    return qq{Could not compute checksum for "$file": $!};
  }
  close $par;

  return ($should eq $is) ? 1 : qq{Checksum for "$file" failed};
}

1;

__END__

=head1 NAME

PAR::WebStart::Util - Utility functions for PAR::WebStart

=head1 SYNOPSIS

  use PAR::WebStart::Util qw(make_par verifyMD5);

=head1 Description

This module exports, on request, some utility functions
used by C<PAR::WebStart>. Available functions are described below.

=head2 make_par

This function, used as

   my ($par, $md5) = make_par(%opts);

makes a par file suitable for use with C<PAR::WebStart>. If
successful, it returns the name of the created par and md5
checksum file.

The files included in the archive will be those under a
C<arch>, C<lib>, C<script>, and/or C<bin> subdirectory;
these are normally created when making a CPAN-like distribution
beneath the C<blib> subdirectory. The steps carried out are

=over 4

=item *

Make a MANIFEST file.

=item *

Use C<Module::Signature> to sign the files, unless the C<--no-sign>
option is passed.

=item *

Use C<Archive::Zip> to create the zip file.

=item *

Use C<Digest::MD5> to create an md5 checksum file; this will
have the same name as the par file with an C<.md5> extension added.

=back

The available options are as follows:

=over 4

=item C<src_dir =E<gt> /some/src>

This specifies the source directory to be used. If such
a directory has beneath it a C<blib> subdirectory, the
C<blib> subdirectory will be used. If this is not specified,
the current directory, or a C<blib> subdirectory in the
current directory, will be used.

=item C<dst_dir =E<gt> /some/dst>

This specifies the destination directory for where to write
the par and md5 checksum files. If not specified, the
directory used for the C<src_dir> will be used.

=item C<name =E<gt> SomeName>

This specifies the name to be used in creating the par
archive (a C<.par> extension will automatically be added).
If this is not specified, the name will be derived
from the directory used for the C<src_dir>.

=item C<no_sign =E<gt> 1>

This specifies that the par file should not be signed
using C<Module::Signature>. If this is not specified,
such signing will occur.

=back

=head2 verifyMD5

This performs a check of a file against an md5 checksum.
It returns 1 if the check was successful, otherwise an
string describing the encountered error is returned.
It is used as

  my $status = verifyMD5(md5 => 'some_file.md5', file => 'some_file');
  unless ($status == 1) {
    die "An error was encountered: $status";
  }

The options used are

=over 4

=item C<file =E<gt> $file>

This specifies the source file.

=item C<md5 =E<gt> $md5>

This specifies the file containing the md5 checksum, to be used
to compare to the md5 checksum computed from the file
specified in the C<file> option.

=back

=head1 COPYRIGHT

Copyright, 2005, by Randy Kobes <r.kobes@uwinnipeg.ca>.
This software is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<PAR::WebStart>, L<PAR>, and L<Module::Signature>.

=cut



