use strict;
use warnings;
use Test::More;
use Parse::PMFile;
use File::Temp;

plan skip_all => "requires PAUSE::Permissions to test" unless eval "use PAUSE::Permissions 0.08; 1";

my $tmpdir = File::Temp->newdir(CLEANUP => 1);
plan skip_all => "tmpdir is not ready" unless -e $tmpdir && -w $tmpdir;

my $pmfile = "$tmpdir/Test.pm";
{
  open my $fh, '>', $pmfile or plan skip_all => "Failed to create a pmfile";
  print $fh "package " . "Parse::PMFile::Test;\n";
  print $fh 'our $VERSION = "0.01";',"\n";
  close $fh;
}

my $permsfile = "$tmpdir/06perms.txt";
{
  open my $fh, '>', $permsfile or plan skip_all => "Failed to create a 06perms.txt";
  print $fh "File:        06perms.txt\n";
  print $fh "\n";
  print $fh "Parse::PMFile::Test,FIRSTCOME,f\n";
  print $fh "Parse::PMFile::Test,MAINT,m\n";
  print $fh "Parse::PMFile::Test,COMAINT,c\n";
  close $fh;
}

my $permissions = PAUSE::Permissions->new(path => "$tmpdir/06perms.txt");

for (0..1) {
  no warnings 'once';
  local $Parse::PMFile::FORK = $_;
  for my $user (qw/FIRSTCOME MAINT COMAINT UNKNOWN/) {
    my $parser = Parse::PMFile->new(undef, {USERID => $user, PERMISSIONS => $permissions});
    my $info = $parser->parse($pmfile);

    if ($user ne 'UNKNOWN') {
      ok $info->{'Parse::PMFile::Test'}{version} eq '0.01';
    } else {
      ok !defined $info->{'Parse::PMFile::Test'}{version};
    }
    note explain $info;
  }
}

done_testing;
