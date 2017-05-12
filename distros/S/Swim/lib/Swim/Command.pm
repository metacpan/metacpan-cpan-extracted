use strict; use warnings;
package Swim::Command;
use Pegex::Base;

use Swim;
use Swim::Util;
use FindBin;
use Getopt::Long;

has argv => ();
has to => 'html';
has meta => {};
has option => {};
has debug => 0;

sub usage {
  print <<'...';
Usage:

  swim --to=<format> [<option>...] <file.swim>
  swim -h|--help

Formats:

  html      # HTML
  md        # Markdown
  pod       # Pod
  txt       # Plain text

  man       # nroff / manpage
  pdf       # PDF
  dvi       # DVI
  ps        # Postscript

  byte      # Swim Bytecode

Options:

  --meta=<file>     # YAML or JSON file containing metadata
  --wrap            # Attempt to wrap output to 80 cols
  --complete        # Add header and footer output as appropriate
  --pod-upper-head  # Convert header1 titles to uppercase

...
  exit 0
}

my $meta = {};
sub run {
  my ($self) = @_;
  local @ARGV = @{$self->argv};

  my $pod_cpan = 0;
  my %opt_spec = (
    "h|help" => \&usage,
    "to=s" => \$self->{to},
    "debug" => \$self->{debug},
    "meta=s" => \&meta_opt,
    "complete!" => \$self->{option}{complete},
    "wrap!" => \$self->{option}{wrap},
    "pod-upper-head!" => \$self->{option}{'pod-upper-head'},
    "pod-cpan" => \$pod_cpan,
  );
  GetOptions(%opt_spec) or die "Error in command line arguments";
  if ($pod_cpan) {
    $self->{to} = 'pod';
    $self->option->{complete} = 1;
    $self->option->{wrap} = 1;
    $self->option->{'pod-upper-head'} = 1;
  }
  $self->{meta} = $meta;

  binmode(STDOUT, ':utf8')
    unless $self->{to} eq 'man';
  my $text = Swim::Util->slurp(@ARGV);

  my $method = "to_" . $self->to;
  print Swim->new(
    text => $text,
    meta => $meta,
    option => $self->option,
    debug => $self->debug,
  )->$method();
}

sub meta_opt {
  my ($option, $value) = @_;
  for my $file (split /,/, $value) {
    my $yaml = Swim::Util->slurp($file);
    $meta = Swim::Util->merge_meta($meta, $yaml);
  }
}

1;
