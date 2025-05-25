use 5.14.1;
use warnings;
use File::Spec;
use Sereal::Encoder qw(SRL_ZSTD);
use Sereal::Decoder;

my $encoder = Sereal::Encoder->new({
  compress => SRL_ZSTD,
  compress_level => 22,
  compress_threshold => 1,
  sort_keys => 1,
  dedupe_strings => 1,
});
my $decoder = Sereal::Decoder->new();

my $dir = File::Spec->catdir(qw(lib Perl APIReference));
opendir my $dh, $dir or die $!;

while (my $f= readdir($dh)) { 
  my $file = File::Spec->catfile($dir, $f);
  if (-f $file and $f =~ /^V5_[0-9]{3}_[0-9]{3}\.pm$/) {
    say "Repacking $file";
    repack_file($file);
  }
}


sub repack_file {
  my $file = shift;
  open my $fh, "+<", $file or die $!;

  binmode($fh);

  local $/ = undef;
  my $content = <$fh>;
  my $data_mentions = () = $content =~ /DATA/g;
  if ($data_mentions <= 1) {
    #say "$file doesn't have a DATA section - skipping.";
    return;
  }

  #say "$file has binary DATA section - repacking.";

  $content =~ /^\s*__DATA__\s*\n(.+)$/ms;
  my $srl = $1;
  my $struct = $decoder->decode($srl);
  my $repack = $encoder->encode($struct);

  say "Size of original blob: " . length($srl)
      . " Size of repacked blob: " . length($repack);

  $content =~ s/^(\s*__DATA__\s*\n).+$/$1$repack/ms or die;
  
  seek $fh, 0, 0;
  truncate $fh, 0;
  print $fh $content;
  close $fh;
}
