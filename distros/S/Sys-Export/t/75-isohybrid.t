use v5.26;
use warnings;
use lib (__FILE__ =~ s,[^\\/]+$,lib,r);
use POSIX 'ceil';
use Test2AndUtils;
use experimental qw( signatures );
use Sys::Export qw( filedata round_up_to_multiple );
use Sys::Export::ISO9660 qw( BOOT_X86 );
use Sys::Export::ISO9660Hybrid qw( GPT_TYPE_ESP GPT_TYPE_GRUB );

# The isoinfo utility can dump details of an ISO filesystem.
my $isoinfo= do { chomp(my $x= `which isoinfo`); $? == 0? $x : undef };

subtest empty_fs => sub {
   my $tmp= File::Temp->new;
   my $dst= Sys::Export::ISO9660Hybrid->new($tmp);
   $dst->finish;
   my $iso_sectors= 16 # system, partition table fits here
      + 4 # Volume Descriptors (primary, secondary, boot_catalog, terminator)
      + 1 # boot catalog
      + 4 # 4x path table (LE, BE, Joliet LE, Joliet BE)
      + 2;# root dir, Joliet root dir
   my $iso_4k_blocks= round_up_to_multiple($iso_sectors, 2) / 2;
   my $fat_sectors= 1 # reserved
      + 1 # 12-bit FAT for one cluster
      + 1 # root dir
      + 1;# empty cluster because there can't be zero clusters
   my $fat_4k_blocks= round_up_to_multiple($fat_sectors, 16) / 16;
   my $gpt_table_blocks= 1;
   is( $dst->gpt,
      object {
         call block_size => 4096;
         call entry_size => 128;
         call entry_table_lba => 2;
         call first_block => $iso_4k_blocks;
         call partitions => [
            object {
               call type => GPT_TYPE_ESP;
               call start_lba => $iso_4k_blocks;
               call end_lba => $iso_4k_blocks + $fat_4k_blocks - 1;
            },
            (undef)x31, # it automatically rounds up to number of entries that fit in a block
         ];
         call last_block => $iso_4k_blocks + $fat_4k_blocks - 1;
         call backup_table_lba => $iso_4k_blocks + $fat_4k_blocks + $gpt_table_blocks;
         call backup_header_lba => $iso_4k_blocks + $fat_4k_blocks + $gpt_table_blocks * 2;
      },
      'gpt alignment'
   );
   is( -s $tmp, ($dst->gpt->backup_header_lba + 1) * 4096, 'minimal hybrid size' );
   note `$isoinfo -i $tmp -d` if $isoinfo;
};

subtest readme_fs => sub {
   my $tmp= File::Temp->new;
   my $dst= Sys::Export::ISO9660Hybrid->new($tmp);
   my $readme= <<END;
Hello World
-----------

Stuff and things.
END
   $dst->add([ file => 'README.TXT', \$readme ]);
   $dst->finish;

   subtest mount_fs => sub {
      skip_all 'Set TEST_MOUNT=1 to enable tests that mount the generated filesystem'
         unless $ENV{TEST_MOUNT};
      my $loopdev= `losetup -Pf $tmp`;
      if (ok( $? == 0, 'losetup' )) {
         chomp $loopdev;
         my $mnt= File::Temp->newdir;
         if (is( system('mount', '-r', -t => 'iso9660', $loopdev, "$mnt"), 0, "mount $loopdev on $mnt" )) {
            ok( -f "$mnt/README.TXT", 'README.TXT exists' );
            is( slurp("$mnt/README.TXT"), $readme, 'README.TXT content' );
            is( system('umount', "$mnt"), 0, "umount $mnt" );
         }
         if (is( system('mount', '-r', -t => 'iso9660', $loopdev.'p1', "$mnt"), 0, "mount ${loopdev}p1 on $mnt" )) {
            ok( -f "$mnt/README.TXT", 'README.TXT exists' );
            is( slurp("$mnt/README.TXT"), $readme, 'README.TXT content' );
            is( system('umount', "$mnt"), 0, "umount $mnt" );
         }
         if (is( system('mount', '-r', -t => 'vfat', $loopdev.'p2', "$mnt"), 0, "mount ${loopdev}p2 on $mnt" )) {
            ok( -f "$mnt/README.TXT", 'README.TXT exists' );
            is( slurp("$mnt/README.TXT"), $readme, 'README.TXT content' );
            is( system('umount', "$mnt"), 0, "umount $mnt" );
         }
      } else {
         fail "losetup failed";
      }
   };
};

sub find_grub2_lib_dir {
   
}

0 && subtest with_boot_loader => sub {
   my $grub_mkimage= `which grub-mkimage`;
   skip_all 'require grub-mkimage'
      unless $? == 0;
   chomp($grub_mkimage);

   my $tmp= File::Temp->newdir;
   system("$grub_mkimage -O i386-pc -o $tmp/gpt-core.img -p '(hd0,gpt1)/boot/grub' "
      . "biosdisk part_gpt part_msdos fat normal") == 0
      or die "mkimage -o gpt-core.img failed";
   system("$grub_mkimage -O i386-pc -o $tmp/iso-core.img -p '/boot/grub' "
      . "iso9660 normal") == 0
      or die "mkimage -o iso-core.img failed";
   system("$grub_mkimage -O x86_64-efi -o grubx64.efi -p '/EFI/BOOT' "
      . "part_gpt fat normal") == 0
      or die "mkimage -o grubx64.efi failed";
   
   my $grub2_lib= -f '/usr/lib/grub/i386-pc/boot_hybrid.img'? '/usr/lib/grub'
      : '';
   note "grub2_lib = $grub2_lib";

   my $grub_mbr= $grub2_lib? filedata("$grub2_lib/i386-pc/boot_hybrid.img")
      : "x"x446;
   my $grub_stage1_5;
   my $grub_cdboot;
   my $grub_efi;
   my $secureboot_stub;

   my $dst= Sys::Export::ISO9660Hybrid->new(
      output => $tmp,
      mbr_boot_code => \$grub_mbr,
      partitions => [
         { type => GPT_TYPE_ESP },
         { type => GPT_TYPE_GRUB, data => \$grub_stage1_5 },
      ],
   );
   $dst->iso->add_boot_catalog_entry(platform => BOOT_X86, data => \$grub_cdboot);
   $dst->add([ file => 'EFI/BOOT/BOOTX64.EFI', \$secureboot_stub ]);
   $dst->add([ file => 'EFI/BOOT/grubx64.efi', \$grub_efi ]);
   # copy all the runtime grub files into this filesystem
   ...;
   # Write a grub config file
   $dst->add([ file => 'grub.cfg', \<<~END ]);
   END
   $dst->finish;
};

done_testing;

   