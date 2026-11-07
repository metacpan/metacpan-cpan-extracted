use Test::More;

# Check our Pod
# The test was provided by Andy Lester,
# who stole it from Brian D. Foy
# Thanks to both !

use File::Spec;
use File::Find;
use strict;

eval {
  require Test::Pod;
  Test::Pod->import;
};

require './Makefile.PL';
# Loaded from Makefile.PL
our %module = get_module_info();

my @files;

sub slurp {
    my( $fn ) = @_;
    local $/;
    open my $fh, '<:raw', $fn
        or die "Couldn't read '$fn': $!";
    <$fh>
}

if ($@) {
  plan skip_all => "Test::Pod required for testing POD";
}
elsif ($Test::Pod::VERSION < 0.95) {
  plan skip_all => "Test::Pod 0.95 required for testing POD";
}
else {
  my $blib = File::Spec->catfile(qw(blib lib));
  find(\&wanted, grep { -d } ($blib));

  if( my $exe = $module{EXE_FILES}) {
    push @files, @$exe;
  };

  plan tests => scalar @files *2;
  foreach my $file (@files) {
    pod_file_ok($file);

    my $content = slurp($file);
    my $has_pod = ($content =~ /^=(head|over)/);
    ok( (!$has_pod or $content =~ /^=encoding /), "$file has =encoding");
  }
}

sub wanted {
  push @files, $File::Find::name if /\.p(l|m|od)$/;
}

done_testing;

