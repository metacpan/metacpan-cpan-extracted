package SVL::Command::Help;
use strict;
use warnings;
use FindBin qw($Bin);
use Path::Class;
use base qw(SVL::Command);

sub run {
  my ($self, $what) = @_;
  my $path;
  if ($what) {
    $path =
      file(file($Bin)->parent, 'lib', 'SVL', 'Command',
      ucfirst(lc($what)) . '.pm');
  } else {
    $path = file(file($Bin)->parent, 'lib', 'SVL.pm');
  }
  if (-f $path) {
    my $parser = Pod::Simple::Text->new;
    $parser->output_string(\my $buf);
    $parser->parse_file("$path");
    print $buf;
  } else {
    print "svl: no help found for $what, try 'svl help'\n";
  }
}

1;
