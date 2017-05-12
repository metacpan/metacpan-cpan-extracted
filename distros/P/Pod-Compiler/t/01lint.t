#!perl
# Testing of Pod::Compiler
# Author: Marek Rouchal <marekr@cpan.org>

$| = 1;

use Test;

BEGIN { plan tests => 5 }

# load the module
my $source = 't/lint.pod';
my $dest = 'lint.out';

unlink glob('*.out');

my $perl = $^X . ' ' . join(' ', map { "-I$_" } @INC);

warn "*** the errors/warnings are ok ***\n";
system("$perl blib/script/podlint $source $dest");
my $out;
if(!-s $dest || $? || !defined($out = _readfile($dest))) {
  ok(0);
} else {
  ok(1);
}

my $xr = _readfile('t/lint.xr');
unless(defined $xr) {
  ok(0);
  die "Fatal: no crossreference found";
}
ok(1);

_canonify($out);
_canonify($xr);

unless($out eq $xr) {
  ok(0);
  warn "\n*** lint result does not match crossreference ***\n";
} else {
  ok(1);
}

my $dest2 = 'lint2.out';
system("$perl blib/script/podlint $dest $dest2");
if(!-s $dest2 || $? || !defined($out = _readfile($dest2))) {
  ok(0);
} else {
  ok(1);
}

_canonify($out);

unless($out eq $xr) {
  ok(0);
  warn "\n*** linted lint result does not match crossreference ***\n";
} else {
  ok(1);
}

exit 0;

sub _canonify
{
  $_[0] =~ s/\r*\n/\n/gs;
}

sub _readfile
{
  unless(open(IN, "<$_[0]")) {
    warn "Cannot read $_[0]: $!\n";
    return undef;
  }
  $/ = undef;
  my $in = <IN>;
  close(IN);
  $in;
}

__END__

