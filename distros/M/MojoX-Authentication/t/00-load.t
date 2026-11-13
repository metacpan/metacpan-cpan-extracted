# inspired by:
# http://perltricks.com/article/208/2016/1/5/Save-time-with-compile-tests
use strict;
use Test::More;
use Path::Tiny;

my $dir  = path(__FILE__)->parent(2)->child('lib');
my $has_saml2 = eval { require Net::SAML2; Net::SAML2->VERSION(0.86); 1 };  # optional dependency
my $iter = $dir->iterator(
   {
      recurse         => 1,
      follow_symlinks => 0,
   }
);
while (my $path = $iter->()) {
   next if $path->is_dir();    # avoid directories...
   next unless $path =~ /\.pm$/mxs;    # ... and non-module files
   my $module = $path->relative($dir); # get relative path...
   $module =~ s{ \.pm \z}{}gmxs;       # ... and transform it...
   $module =~ s{/}{::}gmxs;            # ... into a module name
   if (! $has_saml2 && $module =~ m{::SAML2\z}mxs) {
      SKIP: { skip "$module needs Net::SAML2 0.86", 1 }
      next;
   }
   require_ok($module)
     or BAIL_OUT("can't load $module");
} ## end while (my $path = $iter->...)

diag("Testing MojoX::Authentication $MojoX::Authentication::VERSION");
done_testing();
