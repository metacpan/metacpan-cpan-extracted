#! /usr/bin/env perl

use v5.26;
use Getopt::Long;
use Sys::Export qw/ filedata /;
use Sys::Export::GPT;
use Sys::Export::ISO9660Hybrid qw/ GPT_TYPE_GRUB /;
use Log::Any::Adapter 'TAP';

GetOptions(
   'mbr=s'      => \my $mbr_img,
   'grub=s'     => \my $grub_img,
   'output|o=s' => \my $out
) or die "wrong usage";
-f $mbr_img or die "Missing mbr";
-f $grub_img or die "Missing grub";
-e $out and die "Output file $out already exists";

my $gpt= Sys::Export::GPT->new(
#   device_size => 2048*1024,
   partitions => [
      (undef) x int(rand(100)),
      {  name => "bootloader",
         type => GPT_TYPE_GRUB,
         start_lba => int(rand(40))+50,
         data => filedata($grub_img)
      },
   ],
);

open my $fh, '>', $out or die "open($out): $!";
$gpt->write_to_file($fh);
sysseek($fh, 0, 0) == 0 or die "sysseek: $!";
syswrite($fh, ${filedata($mbr_img)}, 440) == 440 or die "syswrite: $!";
close $fh or die "close: $!";
