use v5.26;
use warnings;
use lib (__FILE__ =~ s,[^\\/]+$,lib,r);
use POSIX 'ceil';
use Test2AndUtils;
use experimental qw( signatures );
use Sys::Export::VFAT qw( FAT12 FAT16 FAT32 is_valid_shortname is_valid_longname );

# Additional tests if host contains fsck.vfat
chomp(my $fsck= `which fsck.vfat`);
my $have_fsck= length $fsck && -x $fsck;
sub fsck($fname) {
   SKIP: {
      skip "no fsck.vfat available" unless $have_fsck;
      my $cmd= "$fsck -v -n '$fname'";
      note `$cmd`;
      is( $?, 0, $cmd );
   }
}

subtest is_valid_shortname => sub {
   ok( is_valid_shortname($_), "valid short '$_'" )
      for '12345678',
          '12345678.',
          '12345678.9AB',
          'A B.C D',
          "&%'-_@~`.!()",
          '${}^#';
   ok( !is_valid_shortname($_), "invalid short '$_'" )
      for '+', ',', ';', '=', '[', ']',
          ' A';
};

subtest is_valid_longname => sub {
   ok( is_valid_longname($_), "valid long '$_'" )
      for '12345678',
          '12345678.',
          '12345678.9AB',
          "&%'-_@~`.!()",
          '${}^#',
          '+,;=[]';
   ok( !is_valid_shortname($_), "invalid long '$_'" )
      for '<', '>', '|';
};

subtest empty_fs => sub {
   my $tmp= File::Temp->new;
   my $dst= Sys::Export::VFAT->new($tmp);
   $dst->finish;
   # one boot sector, two FATs, one root dir, one empty cluster
   is( -s $tmp, 512*5, 'minimal fs size' );
   fsck($tmp);
};

subtest one_file => sub {
   my $tmp= File::Temp->new;
   my $dst= Sys::Export::VFAT->new($tmp);
   $dst->add([ file => "README.TXT", "Hello World!\r\n" ]);
   $dst->finish;
   # one boot sector, two FATs, one root dir, one used cluster
   is( -s $tmp, 512*5, 'fs size' );
   fsck($tmp);
};

subtest one_dir => sub {
   my $tmp= File::Temp->new;
   my $dst= Sys::Export::VFAT->new($tmp);
   $dst->add([ dir => "a" ]);
   $dst->finish;
   is( -s $tmp, 512*5, 'fs size' ); # one boot sector, two FATs, one root dir, one used cluster
   fsck($tmp);
};

subtest root_dir_math => sub {
   # Root directory has one volume label dirent, no '.' or '..' entries, and 16 dirents per sector
   # Test crossing of threshold to more sectors.
   for (510, 511, 512) {
      my $tmp= File::Temp->new;
      my $dst= Sys::Export::VFAT->new($tmp);
      $dst->add([ file => "$_.TXT", "Some Data" ]) for 1..$_;
      $dst->finish;
      # one boot sector, two FATs 2 sec each, root dir in 32 sec, 511 used clusters
      is( -s $tmp, 512*(1 + 2*2 + ceil((1+$_)/16) + $_), "fs size $_ root entries" );
      fsck($tmp);
   }
};

subtest large_deep_directory => sub {
   for my $bits (FAT12, FAT16, FAT32) {
      my $files= $bits == 12? 125 : $bits == 16? 625 : 8192;
      my $expect_clusters= $files * 8 # 8 cluster per file
                                 + 10 # 1 cluster per small directory
              + int(($files+2+15)/16) # 1 dir of ceil((N+2)/16) sectors @ 1 sector per cluster
            + ($bits == FAT32? 1 : 0);# in fat32, root dir gets a cluster

      my $tmp= File::Temp->new;
      my $dst= Sys::Export::VFAT->new(filehandle => $tmp, bytes_per_sector => 512, sectors_per_cluster => 1);
      my $fourk= "\1"x4096;
      for (1..$files) {
         $dst->add([ file => "a/b/c/d/e/f/g/h/i/j/k/$_", \$fourk ]);
      }
      $dst->finish;

      is( $dst->geometry,
         object {
            call bits          => $bits;
            call cluster_count => $expect_clusters;
         },
         "$bits geometry"
      );
      is( -s $tmp, $dst->geometry->total_size, "$bits size" );
      fsck($tmp);
   }
};

subtest shortname_conflict => sub {
   my $tmp= File::Temp->new;
   my $dst= Sys::Export::VFAT->new($tmp);
   $dst->add([ file => 'bitmap_scale.mod', 'test' ]);
   $dst->add([ file => 'bitmap.mod', 'test2' ]);
   $dst->finish;
   # The shorter name should get ~1 because they get assigned in alphabetical order
   like( $dst->root->entries, [
      {
         name => 'bitmap_scale.mod',
         shortname => 'BITMAP~2.MOD',
      },
      {
         name => 'bitmap.mod',
         shortname => 'BITMAP~1.MOD',
      }
   ]) or note explain $dst->root->entries;
};

subtest device_addr_placement => sub {
   my $tmp= File::Temp->new;
   my $dst= Sys::Export::VFAT->new($tmp);
   my $token= "UniqueString".("0123456789"x50);
   my $addr= 4096*256;
   $dst->add([ file => "/TEST.DAT", $token, { device_offset => $addr }]);
   $dst->finish;

   # TODO: aim for exact minimal size
   #is( -s $tmp, $addr + $dst->geometry->bytes_per_cluster, 'filesystem sized to exactly hold file' );
   ok( -s $tmp > $addr + $dst->geometry->bytes_per_cluster, 'filesystem large enough' );

   sysseek $tmp, $addr, 0 or die "seek: $!";
   sysread $tmp, my $buf, length $token or die "read: $!";
   is( $buf, $token, sprintf "Found token at 0x%X", $addr );
};

subtest device_align_placement => sub {
   for my $align (1<<9, 1<<10, 1<<11, 1<<12, 1<<13, 1<<14) {
      for my $vol_ofs (0, 512, 1536) {
         my $tmp= File::Temp->new;
         my $dst= Sys::Export::VFAT->new($tmp);
         my $token= "UniqueString".("0123456789"x50);
         my $token2= "UniqueString9876543210";

         $dst->add([ file => "TEST.DAT", $token, { device_align => $align }]);
         my $f= $dst->add([ file => "TEST2.DAT", $token2, { device_align => $align*2 }]);
         $dst->volume_offset($vol_ofs);
         $dst->finish;
         is( $dst->geometry->volume_offset, $vol_ofs, 'final volume_offset' );

         my $img= do { $tmp->seek(0,0); local $/; <$tmp> };
         my $offset= index($img, $token);
         my $offset2= index($img, $token2);
         note sprintf "image is 0x%X bytes, found token at 0x%X, token2 at 0x%X, align 0x%X",
            length($img), $offset, $offset2, $align;

         ok( $offset > 0, 'offset > 0' );
         is( $offset & ($align-1), 0, "TEST.DAT aligned to $align (vol_ofs = $vol_ofs)" );
         is( $offset2 & (($align*2)-1), 0, "TEST2.DAT aligned to ".($align*2)." (vol_ofs = $vol_ofs)" );
         is( $f->device_offset, $offset2, 'reported location of TEST2.DAT' );
      }
   }
};

subtest test_mounts => sub {
   skip_all 'Set TEST_MOUNTS=1 to enable tests that call "mount"'
      unless $ENV{TEST_MOUNTS};

   my $tmp= File::Temp->newdir;
   my $dst= Sys::Export::VFAT->new(filename => "$tmp/fs");
   $dst->add([ dir => "a" ]);
   $dst->add([ dir => "a/b" ]);
   $dst->add([ dir => "a/b/c" ]);
   my $data= "Example Data";
   $dst->add([ file => "a/b/c/.d/config", $data ]);
   $dst->finish;
   
   mkdir "$tmp/mnt" or die "mkdir: $!";
   if (is( system('mount', -t => 'vfat', -o => 'loop', "$tmp/fs", "$tmp/mnt"), 0, "mount $tmp/mnt" )) {
      ok( -d "$tmp/mnt/a/b/c/.d", 'a/b/c/d exist' );
      ok( -f "$tmp/mnt/a/b/c/.d/config", "a/b/c/.d/config exists" );
      is( slurp("$tmp/mnt/a/b/c/.d/config"), $data, 'a/b/c/.d/config content' );
      is( system('umount', "$tmp/mnt"), 0, "umount $tmp/mnt" );
   }
};

done_testing;

   