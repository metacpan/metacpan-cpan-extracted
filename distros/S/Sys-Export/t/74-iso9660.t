use v5.26;
use warnings;
use lib (__FILE__ =~ s,[^\\/]+$,lib,r);
use POSIX 'ceil';
use Test2AndUtils;
use experimental qw( signatures );
use Sys::Export::ISO9660 qw( is_valid_shortname is_valid_joliet_name BOOT_EFI BOOT_X86
   EMU_NONE EMU_FLOPPY144 );

# The isoinfo utility can dump details of an ISO filesystem.
my $isoinfo= do { chomp(my $x= `which isoinfo`); $? == 0? $x : undef };

subtest is_valid_shortname => sub {
   ok( is_valid_shortname($_), "valid short '$_'" )
      for '12345678',
          '12345678.9AB',
          '123456~1.TXT';
   ok( !is_valid_shortname($_), "invalid short '$_'" )
      for '12345678.', '123456789.', '12345678.1234';
};

subtest is_valid_joliet_name => sub {
   ok( is_valid_joliet_name($_), "valid joliet '$_'" )
      for '12345678',
          '12345678.',
          '12345678.9AB',
          "&%'-_@~`.!()",
          '${}^#',
          '+,=[]';
   ok( !is_valid_joliet_name($_), "invalid joliet '$_'" )
      for '/', '\\', ';';
};

subtest empty_fs => sub {
   my $tmp= File::Temp->new;
   my $dst= Sys::Export::ISO9660->new($tmp);
   $dst->finish;
   my $sectors= 16 # system
      + 3 # Volume Descriptors (primary, secondary, terminator)
      + 4 # 4x path table (LE, BE, Joliet LE, Joliet BE)
      + 2;# root dir, Joliet root dir
   is( -s $tmp, $sectors * 2048, 'minimal fs size' );
   note `$isoinfo -dJRf -i $tmp` if $isoinfo;
};

subtest empty_with_boot_loader => sub {
   my $tmp= File::Temp->new;
   my $dst= Sys::Export::ISO9660->new($tmp);
   my $boot_code_size= 1000000;
   my $sectors= 16 # system
      + 4 # Volume Descriptors (boot, primary, secondary, terminator)
      + 1 # boot catalog
      + 4 # 4x path table (LE, BE, Joliet LE, Joliet BE)
      + ceil($boot_code_size/2048)
      + 2;# root dir, Joliet root dir
   # One entry describing extent of ESP which this moule will assume is already written,
   # because we don't supply 'data' here
   my $esp_size= 0x10000;
   my $esp_ent= $dst->add_boot_catalog_entry(platform => BOOT_EFI);
   # One entry supplying a floppy image, providing data which needs allocated and written.
   $dst->add_boot_catalog_entry(platform => BOOT_X86, data => 'X'x$boot_code_size);
   is( $dst->allocate_extents, $sectors*2048, 'max_assigned_lba' );
   # Now define the location of the ESP
   my $esp_ofs= $dst->volume_size;
   $esp_ent->{extent}->size($esp_size);
   $esp_ent->{extent}->device_offset($esp_ofs);
   $dst->finish;
   is( $dst->boot_catalog, {
         sections => [
            {  id_string => 'UEFI',
               platform => BOOT_EFI,
               entries => [
                  {  bootable => 0x88,
                     load_segment => 0,
                     media_type => EMU_NONE,
                     system_type => 0xEF,
                     extent => object {
                        call device_offset => $esp_ofs;
                        call size => $esp_size;
                     },
                  }
               ]
            },
            {  id_string => 'x86',
               platform => BOOT_X86,
               entries => [
                  {  bootable => 0x88,
                     load_segment => 0x7C0,
                     media_type => EMU_FLOPPY144,
                     system_type => 0,
                     extent => object {
                        call lba => T;
                        call size => $boot_code_size;
                     },
                  },
               ]
            },
         ],
         extent => object {
            call lba => T;
            call size => 32*5; # header, section, entry, section, entry
         }
      },
      'boot_catalog'
   ) or note explain $dst->boot_catalog;
   # The actual size will leave room for the 0x100000 partition we described
   is( $dst->volume_size, $esp_ofs + $esp_size, 'volume_size after finish' );
   is( -s $tmp, $esp_ofs + $esp_size, 'file size' );
   note `$isoinfo -dJRf -i $tmp` if $isoinfo;
};

subtest readme_fs => sub {
   my $tmp= File::Temp->new;
   my $dst= Sys::Export::ISO9660->new(
      filename => $tmp,
      volume_label => 'TESTVOL',
      default_time => 946684800,
   );
   my $readme= <<END;
Hello World
-----------

Stuff and things.
END
   my $readme_file= $dst->add([ file => 'README.TXT', \$readme ]);
   $dst->abstract_file($readme_file);
   $dst->finish;
   my $sectors= 16 # system
      + 3 # Volume Descriptors (primary, secondary, terminator)
      + 4 # 4x path table (LE, BE, Joliet LE, Joliet BE)
      + 2 # root dir, Joliet root dir
      + 1;# README.txt content
   is( -s $tmp, $sectors*2048, 'fs size with only README.TXT' );
   note `$isoinfo -d -i $tmp` if $isoinfo;
   `cp $tmp /tmp/README.iso && chmod go+r /tmp/README.iso`;
   subtest mount_fs => sub {
      skip_all 'Set TEST_MOUNT=1 to enable tests that mount the generated filesystem'
         unless $ENV{TEST_MOUNT};
      my $mnt= File::Temp->newdir;
      if (is( system('mount', '-r', -t => 'iso9660', -o => 'loop', "$tmp", "$mnt"), 0, "mount $tmp on $mnt" )) {
         ok( -f "$mnt/README.TXT", 'README.TXT exists' );
         is( slurp("$mnt/README.TXT"), $readme, 'README.TXT content' );
         is( system('umount', "$mnt"), 0, "umount $mnt" );
      }
   };
};

done_testing;

   