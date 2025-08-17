use v5.26;
use warnings;
use lib (__FILE__ =~ s,[^\\/]+$,lib,r);
use Test2AndUtils;
use experimental qw( signatures );
use Sys::Export qw( :isa :stat_modes :stat_tests expand_stat_shorthand );

subtest explicit_permissions => sub {
   umask 0;
   my @tests= (
      [ [ file644 => "test", "DATA" ], { mode => S_IFREG|0644, name => "test", data => "DATA" } ],
      [ [ file644 => "test", { data_path => "test2" } ],
                                    { mode => S_IFREG|0644, name => "test", data_path => "test2" } ],
      [ [ sym777  => "foo",  "bar"  ], { mode => S_IFLNK|0777, name => "foo",  data => "bar"  } ],
      [ [ dir755  => "bin"          ], { mode => S_IFDIR|0755, name => "bin",  } ],
      [ [ blk644  => "sda",  [8,0]  ], { mode => S_IFBLK|0644, name => "sda",  rdev_major => 8, rdev_minor => 0 } ],
      [ [ chr644  => "null", "1,3"  ], { mode => S_IFCHR|0644, name => "null", rdev_major => 1, rdev_minor => 3 } ],
      [ [ fifo644 => "queue"        ], { mode => S_IFIFO|0644, name => "queue" } ],
      [ [ sock644 => "service.sock" ], { mode => S_IFSOCK|0644,name => "service.sock" } ],
   );
   for (@tests) {
      is( { expand_stat_shorthand($_->[0]) }, $_->[1], join ' ', "shorthand @{$_->[0]}" );
   }
};

subtest umask_permissions => sub {
   umask 022;
   # On Win32, umask always equals zero
   skip_all "umask not supported on this platform"
      unless umask == 022;

   my @tests= (
      [ [ file => "test", "DATA" ], { mode => S_IFREG|0644, name => "test", data => "DATA" } ],
      [ [ file => "test", { data_path => "test2" } ],
                                    { mode => S_IFREG|0644, name => "test", data_path => "test2" } ],
      [ [ sym  => "foo",  "bar"  ], { mode => S_IFLNK|0777, name => "foo",  data => "bar"  } ],
      [ [ dir  => "bin"          ], { mode => S_IFDIR|0755, name => "bin",  } ],
      [ [ blk  => "sda",  [8,0]  ], { mode => S_IFBLK|0644, name => "sda",  rdev_major => 8, rdev_minor => 0 } ],
      [ [ chr  => "null", "1,3"  ], { mode => S_IFCHR|0644, name => "null", rdev_major => 1, rdev_minor => 3 } ],
      [ [ fifo => "queue"        ], { mode => S_IFIFO|0644, name => "queue" } ],
      [ [ sock => "service.sock" ], { mode => S_IFSOCK|0644,name => "service.sock" } ],
   );
   for (@tests) {
      is( { expand_stat_shorthand($_->[0]) }, $_->[1], join ' ', "shorthand @{$_->[0]}" );
   }
};

done_testing;
