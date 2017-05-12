use strict;
use warnings;
use Test::More;
BEGIN { delete $ENV{PKG_CONFIG_PATH} }
use PkgConfig;
use Config;
use FindBin ();
use File::Spec;

plan skip_all => "Test only for MSWin32" unless $^O eq 'MSWin32';
plan skip_all => "Test only for strawberry MSWin32" unless $Config{myuname} =~ /strawberry-perl/;
plan tests => 3;

# this assumes that zlib comes with Strawberry,
# which seems a fairly safe assumption.
my $pkg = PkgConfig->find('zlib');
is $pkg->errmsg, undef, 'found zlib';
diag $pkg->errmsg if $pkg->errmsg;

my $dir = File::Spec->catdir($FindBin::Bin, qw( data strawberry c lib pkgconfig ));
$dir =~ s{\\}{/}g;

my @pcfiles = do {
  @PkgConfig::DEFAULT_SEARCH_PATH = ($dir);
  my $lib = "$dir/../../lib";
  my $inc = "$dir/../../include";
  @PkgConfig::DEFAULT_EXCLUDE_LFLAGS = ("-L$lib");
  @PkgConfig::DEFAULT_EXCLUDE_CFLAGS = ("-I$inc");
  
  note "dir  = $dir";
  note "lib  = $lib";
  note "inc  = $inc";
  
  my $dh;
  opendir $dh, $dir;
  my @list = map { s/\.pc$//; $_ } grep !/^\./, grep /\.pc$/, readdir $dh;
  closedir $dh;
  @list;
};

my @good_includes;
my @good_libs;

subtest 'pcfiles excluded' => sub {
  plan tests => int @pcfiles;
  foreach my $pcfile (@pcfiles)
  {
    subtest $pcfile => sub {
      plan tests => 4;
      my $pkg = PkgConfig->find($pcfile);
      isa_ok $pkg, 'PkgConfig';
      is $pkg->errmsg, undef, 'no error';

      my $ok1 = 1;
      
      foreach my $cflag ($pkg->get_cflags)
      {
        if($cflag =~ /^-I(.*)$/)
        {
          my $dir = $1;
          if(-r File::Spec->catfile($dir, 'bad.h'))
          {
            $ok1 = 0;
            diag "header directory $dir should not been included";
          }
          else
          {
            push @good_includes, [ $pcfile, $dir ];
          }
        }
      }
      
      ok $ok1, "headers excluded correctly";
      
      my $ok2 = 1;
      
      foreach my $ldflag ($pkg->get_ldflags)
      {
        if($ldflag =~ /^-L(.*)$/)
        {
          my $dir = $1;
          if(-r File::Spec->catfile($dir, 'libbad.a'))
          {
            $ok2 = 0;
            diag "lib directory $dir should not have been included";
          }
          else
          {
            push @good_libs, [ $pcfile, $dir ];
          }
        }
      }
      
      ok $ok2, "lib excluded correctly";
    };
  }
};

note "inc";
note sprintf("  %20s %s", $_->[0], $_->[1]) for @good_includes;
note "lib";
note sprintf("  %20s %s", $_->[0], $_->[1]) for @good_libs;

subtest 'pcfiles included' => sub {
  my @pcfiles = qw( 
    freetype2 libexslt libpng libpng16 libxml-2.0 libxslt plplotd-c++ plplotd
  );
  plan tests => int @pcfiles;
  
  foreach my $pcfile (@pcfiles)
  {
    subtest $pcfile => sub {

      my $pkg = PkgConfig->find($pcfile);
      
      my $ok1 = 0;
      
      foreach my $flag ($pkg->get_cflags)
      {
        if($flag =~ m{^-I(.*)$})
        {
          my $dir = $1;
          $ok1 = -d $dir;
          note $dir;
        }
      }
      
      ok $ok1, "good directory included";

    };
  }

};
