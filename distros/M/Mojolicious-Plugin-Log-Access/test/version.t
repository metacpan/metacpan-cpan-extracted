# ============
# version
# ============
use Mojo::Base -strict;

use Module::Metadata;
use Mojo::File;
use Mojo::Util 'decode';
use Test::More;

plan skip_all => 'set RELEASE_TESTING to enable this test (developer only!)'
  unless $ENV{RELEASE_TESTING};

sub version_from_module {
  my $makefile = 'Makefile.PL';
  unless (-f $makefile and -r $makefile) {
    diag "Failed to find/read makefile ($makefile)";
    fail 'version_from_module';
  }
  my $content = decode 'UTF-8', Mojo::File->new($makefile)->slurp;
  my $module = $1 if $content =~ /VERSION_FROM =>\s+\'([^\']+)\'/;
  unless ($module) {
    diag "Failed to parse makefile ($makefile)";
    return undef;
  }
  return Module::Metadata->new_from_file($module)->version;
}

sub version_from_changefile {
  my $changefile = shift // 'Changes';
  unless (-f $changefile and -r $changefile) {
    diag "Failed to find/read changefile ($changefile)";
    fail 'version_from_changefile';
  }
  my $content = decode 'UTF-8', Mojo::File->new($changefile)->slurp;
  return $1 if $content =~ /^([\d\.]+)\s+\d{4}-\d{2}-\d{2}$/m;
  return undef;
}

cmp_ok version_from_module, '==', version_from_changefile, 'versions match';

done_testing();
