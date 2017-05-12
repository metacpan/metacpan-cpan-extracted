package PathTest;

use Parse::Path;
use Test::Most;
use base 'Exporter';

our @EXPORT = qw(test_pathing test_pathing_failures);

sub test_pathing {
   my ($pp_opts, $path_list, $expect_list, $name) = @_;

   die sprintf("%s --> Both lists are not the same size (%u vs. %u)", $name, scalar @$path_list, scalar @$expect_list)
      unless (@$path_list == @$expect_list);

   my $style = $pp_opts->{style} // 'DZIL';
   $style = "Parse::Path::$style" unless ($style =~ s/^\=//);

   for (my $i = 0; $i < @$path_list; $i++) { SKIP: {
      my ($path_str, $expect_str) = ($path_list->[$i], $expect_list->[$i]);
      my $test_name = $name.' --> '.$path_str;

      my $path;
      lives_ok {
         $path = Parse::Path->new(
            %$pp_opts,
            path => $path_str,
         );
      } "$test_name construction didn't die" or skip '$path died', 2;
      isa_ok $path, $style, "$test_name path";

      cmp_ok($path->as_string, 'eq', $expect_str, "$test_name compared correctly");
   } }
}

sub test_pathing_failures {
   my ($pp_opts, $path_list, $throws_list, $name) = @_;

   die sprintf("%s --> Both lists are not the same size (%u vs. %u)", $name, scalar @$path_list, scalar @$throws_list)
      unless (@$path_list == @$throws_list);

   my $style = $pp_opts->{style} // 'DZIL';
   $style = "Parse::Path::$style" unless ($style =~ s/^\=//);

   for (my $i = 0; $i < @$path_list; $i++) {
      my ($path_str, $throws) = ($path_list->[$i], $throws_list->[$i]);
      my $test_name = $name.' --> '.$path_str;

      my $path;
      throws_ok {
         $path = Parse::Path->new(
            %$pp_opts,
            path => $path_str,
         );
      } $throws, "$test_name construction dies" or diag "PATH: $path";
   }
}
