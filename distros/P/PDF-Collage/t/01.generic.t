#!/usr/bin/env perl
use v5.24;
use warnings;
use experimental 'signatures';
no warnings 'experimental::signatures';

use PDF::Collage 'collage';
use Data::Resolver ();

use Test::More;
use Test::Exception;

use File::Basename 'dirname';
use lib dirname(__FILE__);
use PCTestLib qw< sibling >;

subtest successful => sub {

   # the input.dir is repeated twice to ensure that no renaming kicks in
   my @test_inputs = qw<
     input.dir
     input.dir
     input-prefixed.tar
     input-sharp.tar
   >;

   for my $input (@test_inputs) {
      my $path = sibling(__FILE__, $input);
      my $pc;
      lives_ok { $pc = collage(auto => $path) }
      "instantiation from '$input'";
      isa_ok $pc, 'PDF::Collage::TemplatesCollection';

      my @selectors = sort { $a cmp $b } $pc->selectors;
      is_deeply \@selectors, [qw< sample1 >], 'selectors';

      my $template = $pc->get('sample1');
      isa_ok $template, 'PDF::Collage::Template';

      my $pdf;
      lives_ok { $pdf = $template->render({recipient => 'World'}) }
      'generate PDF from template';
      isa_ok $pdf, 'PDF::Builder';

      $pdf = undef;
      lives_ok { $pdf = $pc->render({recipient => 'All'}) }
      'generate PDF from TemplatesCollection, using default selector';
      isa_ok $pdf, 'PDF::Builder';

      $pdf = undef;
      lives_ok { $pdf = $pc->render(sample1 => {recipient => 'All'}) }
      'generate PDF from TemplatesCollection, using explicit selector';
      isa_ok $pdf, 'PDF::Builder';
   } ## end for my $input (@test_inputs)

};

subtest 'multiple selectors' => sub {
   my $path      = sibling(__FILE__, 'input2.dir');
   my $pc        = collage(auto => $path);
   my @selectors = sort { $a cmp $b } $pc->selectors;
   is_deeply \@selectors, [qw< sample2 sample3 >], 'multiple selectors';

   lives_ok { $pc->get($_) for @selectors }
   'getting templates with the right selector';
   dies_ok { $pc->get('whatevah!') } 'inexistent selector fails';

   my $failing_template = $pc->get('sample2');
   {
      local $SIG{__WARN__} = sub { }; # ignore the warning from the library
      dies_ok { $failing_template->render({recipient => 'Void'}) }
      'template is not useable';
   }
};

subtest 'composition from multiple sources' => sub {
   my $path1    = sibling(__FILE__, 'input-prefixed.tar');
   my $path2    = sibling(__FILE__, 'input2.dir');
   my $resolver = Data::Resolver::generate(
      {
         -factory => resolver_from_alternatives => alternatives => [
            {-factory => resolver_from_tar => archive => $path1},
            {-factory => resolver_from_dir => root    => $path2},
         ],
         throw => 1,
      }
   );
   my $pc = collage(resolver => $resolver);

   my @selectors = sort { $a cmp $b } $pc->selectors;
   is_deeply \@selectors, [qw< sample1 sample2 sample3 >],
     'multiple, aggregated selectors';

   my $template = $pc->get('sample2');
   my $pdf;
   lives_ok { $pdf = $template->render({recipient => 'Joy'}) }
   'getting stuff from multiple sources';
   isa_ok $pdf, 'PDF::Builder';

   lives_ok { $pc->render($_ => {recipient => $_}) }
   "collection render on '$_'" for @selectors;

   dies_ok { $pc->render({recipient => 'Nope'}) }
   'unsupported default selector';
};

done_testing();
