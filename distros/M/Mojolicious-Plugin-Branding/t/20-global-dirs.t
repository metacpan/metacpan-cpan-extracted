use strict;
use warnings;
use Test::More;
use FindBin qw< $Bin >;
use lib "$Bin/lib";
use BrandingTest;

subtest 'rainy: missing global dir does not stop the following ones' => sub {
   my $t = t_for({%generic, 'global/templates/index.html.ep' => 'global page'},
      {global => ['missing', 'global']});
   $t->get_ok('/' => \%BAR)->content_is("global page\n");
};

subtest 'rainy: undef global items are skipped' => sub {
   for my $global (undef, [undef], [undef, 'global']) {
      my $t = t_for({%generic, 'global/templates/index.html.ep' => 'global page'},
         {global => $global});
      my $expected = ref($global) && $global->@* > 1 ? 'global' : 'generic';
      $t->get_ok('/' => \%BAR)->content_is("$expected page\n");
   }
};

subtest 'rainy: dir without templates/ or public/ is skipped' => sub {
   my $t = t_for({%generic, 'empty/other/file.txt' => 'nothing to see'},
      {global => ['empty']});
   $t->get_ok('/' => \%BAR)->content_is("generic page\n");
   $t->get_ok('/site.css' => \%BAR)->content_is('generic css');
};

subtest 'rainy: global as a hash ref' => sub {
   eval { t_for({%generic}, {global => {global => 1}}) };
   like $@, qr{invalid path, either Mojo::File or plain string accepted},
      'croaks';
};

subtest 'rainy: invalid items in global array' => sub {
   for my $case (
         ['array ref', [1], qr{invalid path, either Mojo::File or plain string}],
         ['hash ref', {}, qr{invalid path, either Mojo::File or plain string}],
         ['empty string', '', qr{invalid empty path}]) {
      my ($name, $item, $error) = $case->@*;
      eval { t_for({%generic}, {global => [$item]}) };
      like $@, $error, "croaks on $name";
   }
};

done_testing();
