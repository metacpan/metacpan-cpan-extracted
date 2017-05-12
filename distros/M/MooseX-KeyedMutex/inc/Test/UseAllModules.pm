#line 1
package Test::UseAllModules;

use strict;
use warnings;
use ExtUtils::Manifest qw( maniread );

our $VERSION = '0.09';

use Exporter;

our @ISA = qw/Exporter/;
our @EXPORT = qw/all_uses_ok/;

use Test::More;

sub all_uses_ok {
  shift if @_ && $_[0] eq 'except';

  my @exceptions = @_;
  my @modules;

  unless (-f 'MANIFEST') {
    plan skip_all => 'no MANIFEST';
    exit;
  }

  my $manifest = maniread();

READ:
  foreach my $file (keys %{ $manifest }) {
    if (my ($module) = $file =~ m|^lib/(.*)\.pm\s*$|) {
      $module =~ s|/|::|g;

      foreach my $rule (@exceptions) {
        next READ if $module eq $rule || $module =~ /$rule/;
      }

      push @modules, $module;
    }
  }

  unless (@modules) {
    plan skip_all => 'no .pm files are found under the lib directory';
    exit;
  }
  plan tests => scalar @modules;

  my @failed;
  foreach my $module (@modules) {
    use_ok($module) or push @failed, $module;
  }

  BAIL_OUT( 'failed: ' . (join ',', @failed) ) if @failed;
}

1;
__END__

#line 124
