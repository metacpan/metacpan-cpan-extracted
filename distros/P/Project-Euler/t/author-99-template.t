#!perl -T

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}


use strict;
use warnings;

use autodie;
use Test::More;
use File::Spec qw/  /;

use constant PROBLEM_PATH => File::Spec->catdir( qw/ lib  Project  Euler  Problem / );


my @files;
opendir (my $dir, PROBLEM_PATH);
while (( my $filename = readdir($dir) )) {
    push @files, $filename  if  $filename =~ / \A p \d+ \.pm \z /xmsi;
}

plan tests => (scalar @files * 1);

sub not_in_file_ok {
    my ($type, $filename, %regex) = @_;
    open( my $fh, '<', $filename )
        or die "couldn't open $filename for reading: $!";

    my %violated;

    while (my $line = <$fh>) {
        while (my ($desc, $regex) = each %regex) {
            if ($line =~ $regex) {
                push @{$violated{$desc}||=[]}, $.;
            }
        }
    }

    if (%violated) {
        fail("$filename contains $type text");
        diag "$_ appears on lines @{$violated{$_}}" for keys %violated;
    } else {
        pass("$filename contains no $type text");
    }
}


for  my $module_name  (@files) {
    not_in_file_ok('template', File::Spec->catfile( PROBLEM_PATH, $module_name ), (
        '### TEMPLATE ###'   =>  qr/### TEMPLATE ###/,
    ));
}
