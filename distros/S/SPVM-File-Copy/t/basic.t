use Test::More;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
BEGIN { $ENV{SPVM_BUILD_DIR} = "$FindBin::Bin/.spvm_build"; }

use File::Temp;
use SPVM 'TestCase::File::Copy';

use SPVM 'File::Copy';

ok(SPVM::TestCase::File::Copy->test);

# copy
{
  {
    my $from_file_base = "a.txt";
    my $tmp_dir = File::Temp->newdir;
    
    my $from_file = "$tmp_dir/$from_file_base";
    
    open my $from_fh, '>', $from_file
      or die "Can't open the file \"$from_file\":$!";
    print $from_fh "AAA";
    close $from_fh;

    ok(-f $from_file);
    
    my $to_file_base = "b.txt";
    my $to_file = "$tmp_dir/$to_file_base";
    
    SPVM::File::Copy->copy($from_file, $to_file);
    
    ok(-f $from_file);
    ok(-f $to_file);
    is(-s $from_file, -s $to_file);
  }

  {
    my $from_file_base = "a.txt";
    my $tmp_dir = File::Temp->newdir;
    
    my $from_file = "$tmp_dir/$from_file_base";
    
    open my $from_fh, '>', $from_file
      or die "Can't open the file \"$from_file\":$!";
    print $from_fh "AAA";
    close $from_fh;

    ok(-f $from_file);
    
    my $to_file_base = "b.txt";
    my $to_file = "$tmp_dir/$to_file_base";
    
    SPVM::File::Copy->copy($from_file, $to_file, 1024);
    
    ok(-f $from_file);
    ok(-f $to_file);
    is(-s $from_file, -s $to_file);
  }
}

# move
{
  {
    my $from_file_base = "a.txt";
    my $tmp_dir = File::Temp->newdir;
    
    my $from_file = "$tmp_dir/$from_file_base";
    
    open my $from_fh, '>', $from_file
      or die "Can't open the file \"$from_file\":$!";
    print $from_fh "AAA";
    close $from_fh;

    ok(-f $from_file);
    
    my $to_file_base = "b.txt";
    my $to_file = "$tmp_dir/$to_file_base";
    
    SPVM::File::Copy->move($from_file, $to_file);
    
    ok(!-e $from_file);
    ok(-f $to_file);
  }
}

done_testing;
