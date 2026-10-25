# inspired by:
# http://perltricks.com/article/208/2016/1/5/Save-time-with-compile-tests
use strict;
use Test::More;
use Mojo::File qw< curfile >;

my $dir = curfile->dirname->sibling('lib');
for my $path ($dir->list_tree->grep(qr{\.pm\z})->each) {
   my $module = join '::', @{$path->to_rel($dir)};    # path components...
   $module =~ s{\.pm\z}{};                             # ... minus extension
   require_ok($module)
     or BAIL_OUT("can't load $module");
}

diag("Testing Mojolicious::Plugin::Branding $Mojolicious::Plugin::Branding::VERSION");
done_testing();
