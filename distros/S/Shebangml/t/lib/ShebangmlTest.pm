package ShebangmlTest;

use warnings;
use strict;
use Carp;

use Shebangml;

my $CLASS = __PACKAGE__;

use base 'Test::Builder::Module';
our @EXPORT = qw(
  hbml_is
  hbml_from
);

sub undent {
  if($_[0] =~ s/^(\s+)//) {
    my $ws = $1;
    for(@_) {s/^$ws//mg;}
  }
}

sub hbml_is ($$;$) {
  my @name = (shift(@_)) if(@_ > 2);
  my ($input, $expect) = @_;
  undent($input, $expect);

  local $Test::Builder::Level = $Test::Builder::Level + 1;
  check_hbml(\$input, $expect, @name);
}

sub hbml_from ($$) {
  my ($file, $expect) = @_;

  undent($expect);
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  check_hbml($file, $expect, $file);
}

sub check_hbml {
  my ($input, $expect, @name) = @_;

  my $output = '';
  open(my $out_fh, '>', \$output);
  my $hbml = Shebangml->new(out_fh => $out_fh);
  $hbml->process($input);
  $CLASS->builder->is_eq($output, $expect, @name);
}

1;
# vim:ts=2:sw=2:et:sta
