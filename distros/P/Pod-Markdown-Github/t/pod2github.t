# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use lib 't/lib';
use MarkdownTests;

use File::Temp qw{ tempfile }; # core
use File::Spec::Functions qw( catfile ); # core

my ($lib, $bin) = scalar(grep { /\bblib\Wlib$/ } @INC)
  ? ('blib/lib', 'blib/script')
  : ('lib',      'bin');

my $script = catfile($bin, qw(pod2github));

my ($tmp_in,   $infile) = tempfile( 'pod2github-in.XXXXXX',  TMPDIR => 1, UNLINK => 1 );
print $tmp_in "=head1 Temp\n\nI<File>\n";
close $tmp_in;

my ($tmp_out, $outfile) = tempfile( 'pod2github-out.XXXXXX', TMPDIR => 1, UNLINK => 1 );
print $tmp_out "overwrite me\n";
close $tmp_out;

sub corpus {
  catfile( corpus => $_[0] );
}

# I tried this with IPC::Open2, but windows hangs waiting for more <STDIN>...

sub pod2github {
  my ($args, $exp, $desc) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  unshift @$args, $^X, "-I$lib", $script;
  {
    open(my $fh, '>', $outfile) or die "Failed to open $outfile: $!";
    print $fh "oops\n";
    close $fh;
  }
  is slurp_file($outfile), "oops\n", 'output file prepared';
  system(join ' ', map { length($_) > 1 ? qq["$_"] : $_ } @$args);
  is slurp_file($outfile), $exp, $desc;
}

{
  sub testp2m {
    splice @_, 1, 0, "# Temp\n\n_File_\n";
    goto &pod2github;
  }

  testp2m(
    ['<', $infile, '>', $outfile],
    'no args: < in > out',
  );

  testp2m(
    [$infile, '>', $outfile],
    '1 arg: input file, stdout',
  );

  testp2m(
    [$infile, $outfile],
    '2 args: input file, output file',
  );

  testp2m(
    ['-', $outfile, '<', $infile],
    '2 args: - (stdin), output file',
  );

  testp2m(
    ['-', '-', '<', $infile, '>', $outfile],
    'both dashes: - (stdin) - (stdout)',
  );

}

{
  my $in = corpus('copy.pod');
  my @args = ($in, $outfile);
  my $exp = sub { sprintf "# cr\n\n{ \\`%s\\` }\n", $_[0] };

  pod2github(
    [@args],
    $exp->("\xc2\xa9"),
    'no encoding specified returns UTF-8',
  );

  pod2github(
    ['--html-encode-chars=1', @args],
    $exp->("&copy;"),
    'html_encode_chars=1 encodes entities',
  );

  pod2github(
    ['-e', 'ascii', @args],
    $exp->("&copy;"),
    'ascii encoding returns ascii with html entities encoded',
  );

  pod2github(
    ['--output-encoding=utf-8', @args],
    $exp->("\xc2\xa9"),
    'specify utf-8 output encoding',
  );

  pod2github(
    ['--match-encoding', corpus('lit-cp1252-enc.pod'), $outfile],
    $exp->("\xa9"),
    'match input cp1252',
  );

  pod2github(
    ['-m', corpus('lit-utf8-enc.pod'), $outfile],
    $exp->("\xc2\xa9"),
    'match input utf-8',
  );
}

done_testing;
