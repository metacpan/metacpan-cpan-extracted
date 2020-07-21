use strict;
use warnings;
use Config;
use File::Spec;
use File::Copy qw( copy );

if($^O eq 'cygwin')
{
  print "this script is for native build version of Perl (Strawberry)\n";
  exit 2;
}

unless($^O eq 'MSWin32')
{
  print "this does not appear to be Windows Perl\n";
  exit 2;
}

my $uname = $Config{myuname};

print "myuname = $uname\n";

unless(defined $uname && $uname =~ /strawberry-perl/)
{
  print "this does not appear to be Strawberry Perl\n";
  exit 2;
}

if($uname =~ /strawberry-perl 5\.(\d+)\.(\d+)\.(\d+)/)
{
  my($major,$minor,$patch) = ($1,$2,$3);

  if( ($major == 20 && !($minor == 0 && $patch == 1))
  ||  ($major > 20))
  {
    print "this version of Perl doesn't need to be patched\n";
    exit 2;
  }

  my($vol, $dir, $file) = File::Spec->splitpath($^X);
  my @dirs = File::Spec->splitdir($dir);
  splice @dirs, -3;
  my $path = (File::Spec->catdir($vol, @dirs, qw( c lib pkgconfig )));

  my $dh;
  opendir $dh, $path;
  my @pcfiles = grep !/^\./, grep /\.pc$/, readdir $dh;
  closedir $dh;

  foreach my $pcfile (@pcfiles)
  {
    my $bak = File::Spec->catfile($path, "$pcfile.bak");
    my $pc  = File::Spec->catfile($path, $pcfile);

    if(-e $bak)
    {
      print "already exists: $bak\n";
      print "patch has probably already been applied\n";
      next;
    }

    print "copy $pc => $bak\n";
    copy($pc, $bak) || die "Copy failed: $!";

    print "read $bak\n";
    open my $fh, '<', $bak;
    my @content = map { s{/mingw}{"\${pcfiledir}/../.."}eg; $_ } <$fh>;
    close $fh;

    print "write $pc\n";
    open $fh, '>', $pc;
    binmode $fh;
    print $fh @content;
    close $fh;
  }
}
