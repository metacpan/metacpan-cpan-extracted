use v5.26;
use warnings;
use lib (__FILE__ =~ s,[^\\/]+$,lib,r);
use POSIX 'ceil';
use Test2AndUtils;
use experimental qw( signatures );
use Sys::Export qw( filedata );
use Sys::Export::GPT;

subtest fit_to_partitions => sub {
   my $tmp= File::Temp->new;
   my $guid_012= '00112233-4455-6677-8899-AABBCCDDEEFF';
   my $guid_fed= 'FFEEDDCC-BBAA-9988-7766-554433221100';
   my $gpt= Sys::Export::GPT->new(
      block_size => 512,
      partitions => [
         { name => "TEST", type => $guid_012, guid => $guid_fed,
           start_lba => 0x40, end_lba => 0x50 },
         (undef)x127
      ]
   );
   ok( $gpt->write_to_file($tmp), 'write_to_file' );
   note hexdump ${ filedata($tmp) };
};

done_testing;

   