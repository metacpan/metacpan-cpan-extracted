#!/usr/bin/perl

## unit tests for Suck::Huggingface

use strict;
use warnings;
use Test::Most;
use File::Valet;

use lib "./lib";
use Suck::Huggingface;

my $DEBUGGING = 0;
my $LOG_LVL = $DEBUGGING ? 5 : -1;

my $shug = Suck::Huggingface->new(no_logfile => 1, show_log_to_stdout => 1, log_level => $LOG_LVL);
is ref($shug), "Suck::Huggingface", "instantiated class";

$shug->{testing} = 1;  # do not actually make system() calls

# testing _dissect_repo_url:
# https://huggingface.co/NickyNicky/Cerebras-GPT-111M-dataset-16k-v2/tree/main
my $repo_url = "https://huggingface.co/NickyNicky/Cerebras-GPT-111M-dataset-16k-v2";
my $git_url  = "https://huggingface.co/NickyNicky/Cerebras-GPT-111M-dataset-16k-v2.git";
my $repo_dir = "Cerebras-GPT-111M-dataset-16k-v2.git";
is_deeply [$shug->_dissect_repo_url("https://huggingface.co/NickyNicky/Cerebras-GPT-111M-dataset-16k-v2")], ["OK", $repo_url, $git_url, $repo_dir], "_dissect_repo_url: expected case";
is_deeply [$shug->_dissect_repo_url("https://huggingface.co/NickyNicky/Cerebras-GPT-111M-dataset-16k-v2/")], ["OK", $repo_url, $git_url, $repo_dir], "_dissect_repo_url: trailing slash";
is_deeply [$shug->_dissect_repo_url("https://huggingface.co/NickyNicky/Cerebras-GPT-111M-dataset-16k-v2.git")], ["OK", $repo_url, $git_url, $repo_dir], "_dissect_repo_url: trailing .git";
is_deeply [$shug->_dissect_repo_url("https://huggingface.co/NickyNicky/Cerebras-GPT-111M-dataset-16k-v2/tree/main")], ["OK", $repo_url, $git_url, $repo_dir], "_dissect_repo_url: deeper path";

is_deeply [$shug->ok(1, 2, 3)], ["OK", 1, 2, 3], "ok: is ok";

# my $ar = [$shug->_clone_repo($git_url, $repo_dir)];
# print "_clone_repo: ", $shug->{js_or}->encode($ar), "\n";

# testing _clone_repo:
my $tmp_repo_dir = "/tmp/$repo_dir";
system "mkdir $tmp_repo_dir" unless (-e $tmp_repo_dir);
is [$shug->_clone_repo($git_url, $tmp_repo_dir)]->[0], "OK", "_clone_repo: already got repo";
system "rmdir $tmp_repo_dir >\& /dev/null";
is [$shug->_clone_repo($git_url, $tmp_repo_dir)]->[0], "ERROR", "_clone_repo: unable to clone repo";

# testing _scan_for_external_downloads:
system "mkdir $tmp_repo_dir";
is_deeply [$shug->_scan_for_external_downloads($git_url, $tmp_repo_dir)], ["OK", 0, []], "_scan_for_external_downloads: degenerate case";
mock_repo_files($tmp_repo_dir, [["bar", 12340000], ["foo", 5678]]);
is_deeply [$shug->_scan_for_external_downloads($git_url, $tmp_repo_dir)], ["OK", 12345678, [{f => "bar", oid_alg => "rc4", oid_dig => "42", sz => 12340000}, {f => "foo", oid_alg => "rc4", oid_dig => "42", sz => 5678}]], "_scan_for_external_downloads: complex case";
system "rm -rf $tmp_repo_dir";

# testing _download_files:
# zzapp

# sub _download_files {
#     my ($self, $repo_url, $git_url, $repo_dir, $to_dl_ar) = @_;
#     my $dl_url = "$repo_url/resolve/main";
#     my $wget_opts = "";
#     my $rl = $self->opt('limit_rate');
#     $wget_opts .= "-q " unless ($self->opt('v', 0));
#     $wget_opts .= "--rate-limit=$rl " if ($rl && $rl =~ /^[\d\.]+\w?$/);  # eg: "2.5m" or "500k"
#     for my $f_hr (@$to_dl_ar) {
#       my $f = $f_hr->{f};
#       rename("$repo_dir/$f", "$repo_dir/$f.orig");  # chicken
#       $self->info("downloading file", $f_hr);
#       my $url = "$dl_url/$f";
#       my $wget_bin = $self->{wget_bin} // "wget";
#       my $cmd = "cd $repo_dir && $wget_bin --tries=1000 $wget_opts '$url'";
#       $self->dbg("wget cmd", $cmd, 6);
#       my $tm0 = Time::HiRes::time();
#       system($cmd) unless ($self->{testing});
#       my $dur = Time::HiRes::time() - $tm0;
#       my $kbps = int(($f_hr->{sz} // 0) / $dur + 0.5) / 1024;
#       $kbps = $1 if ($kbps + 0.0005 =~ /^(\d+\.\d{3})/);
#       $self->dbg("wget done", {duration => $dur, kbps => $kbps}, 6);;
#       # zzapp -- TO-DO: check against digest and re-download on mismatch
#     }
#     return $self->ok();
# }

done_testing();
exit(0);

sub mock_repo_files {
  my ($dir, $dl_ar) = @_; # [["foo", 12340000], ["bar", 5678]]); 
  # [{f => "foo", oid_alg => "rc4", oid_dig => "42", sz => 12340000}, ...]
  wr_f("$dir/bigg_file", "X" x 1024);
  wr_f("$dir/smol_file", "X" x   64);
  wr_f("$dir/.dot_file", "X" x   64);
  for my $tup (@$dl_ar) {
    my ($f, $sz) = @$tup;
    wr_f("$dir/$f", join("\n", ("version 69", "oid rc4:42", "size $sz", "")));
  }
  return;
}
