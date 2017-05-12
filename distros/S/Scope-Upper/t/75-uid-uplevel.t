#!perl -T

use strict;
use warnings;

use Test::More tests => 2 * 32 + 2 * 21;

use Scope::Upper qw<uplevel uid validate_uid UP>;

for my $run (1, 2) {
 sub {
  my $above_uid = uid;
  my $there     = "in the sub above the target (run $run)";

  my $uplevel_uid = sub {
   my $target_uid = uid;
   my $there      = "in the target sub (run $run)";

   my $uplevel_uid = sub {
    my $between_uid = uid;
    my $there       = "in the sub between the target and the source (run $run)";

    my $uplevel_uid = sub {
     my $source_uid = uid;
     my $there      = "in the source sub (run $run)";

     my $uplevel_uid = uplevel {
      my $uplevel_uid = uid;
      my $there       = "in the uplevel callback (run $run)";
      my $invalid     = 'temporarily invalid';

      ok  validate_uid($uplevel_uid), "\$uplevel_uid is valid $there";
      ok !validate_uid($source_uid),  "\$source_uid is $invalid $there";
      ok !validate_uid($between_uid), "\$between_uid is $invalid $there";
      ok !validate_uid($target_uid),  "\$target_uid is $invalid $there";
      ok  validate_uid($above_uid),   "\$above_uid is valid $there";

      isnt $uplevel_uid, $source_uid,  "\$uplevel_uid != \$source_uid $there";
      isnt $uplevel_uid, $between_uid, "\$uplevel_uid != \$between_uid $there";
      isnt $uplevel_uid, $target_uid,  "\$uplevel_uid != \$target_uid $there";
      isnt $uplevel_uid, $above_uid,   "\$uplevel_uid != \$above_uid $there";

      {
       my $here = uid;

       isnt $here, $source_uid,  "\$here != \$source_uid in block $there";
       isnt $here, $between_uid, "\$here != \$between_uid in block $there";
       isnt $here, $target_uid,  "\$here != \$target_uid in block $there";
       isnt $here, $above_uid,   "\$here != \$above_uid in block $there";
      }

      is uid(UP), $above_uid, "uid(UP) == \$above_uid $there";

      return $uplevel_uid;
     } UP UP;

     ok !validate_uid($uplevel_uid), "\$uplevel_uid is no longer valid $there";
     ok  validate_uid($source_uid),  "\$source_uid is valid again $there";
     ok  validate_uid($between_uid), "\$between_uid is valid again $there";
     ok  validate_uid($target_uid),  "\$target_uid is valid again $there";
     ok  validate_uid($above_uid),   "\$above_uid is still valid $there";

     return $uplevel_uid;
    }->();

    ok !validate_uid($uplevel_uid), "\$uplevel_uid is no longer valid $there";
    ok  validate_uid($between_uid), "\$between_uid is valid again $there";
    ok  validate_uid($target_uid),  "\$target_uid is valid again $there";
    ok  validate_uid($above_uid),   "\$above_uid is still valid $there";

    return $uplevel_uid;
   }->();

   ok !validate_uid($uplevel_uid), "\$uplevel_uid is no longer valid $there";
   ok  validate_uid($target_uid),  "\$target_uid is valid again $there";
   ok  validate_uid($above_uid),   "\$above_uid is still valid $there";

   return $uplevel_uid;
  }->();

  ok !validate_uid($uplevel_uid), "\$uplevel_uid is no longer valid $there";
  ok  validate_uid($above_uid),   "\$above_uid is still valid $there";

  sub {
   my $here  = uid;
   my $there = "in a new sub at replacing the target";

   ok !validate_uid($uplevel_uid), "\$uplevel_uid is no longer valid $there";
   ok  validate_uid($above_uid),   "\$above_uid is still valid $there";

   isnt $here, $uplevel_uid, "\$here != \$uplevel_uid $there";

   is   uid(UP), $above_uid, "uid(UP) == \$above_uid $there";
  }->();
 }->();
}

for my $run (1, 2) {
 sub {
  my $first_sub = uid;
  my $there     = "in the first sub (run $run)";
  my $invalid   = 'temporarily invalid';

  uplevel {
   my $first_uplevel = uid;
   my $there         = "in the first uplevel (run $run)";

   ok !validate_uid($first_sub),     "\$first_sub is $invalid $there";
   ok  validate_uid($first_uplevel), "\$first_uplevel is valid $there";

   isnt $first_uplevel, $first_sub, "\$first_uplevel != \$first_sub $there";
   isnt uid(UP),        $first_sub, "uid(UP) != \$first_sub $there";

   my ($second_sub, $second_uplevel) = sub {
    my $second_sub = uid;
    my $there      = "in the second sub (run $run)";

    my $second_uplevel = uplevel {
     my $second_uplevel = uid;
     my $there          = "in the second uplevel (run $run)";

     ok !validate_uid($first_sub),      "\$first_sub is $invalid $there";
     ok  validate_uid($first_uplevel),  "\$first_uplevel is valid $there";
     ok !validate_uid($second_sub),     "\$second_sub is $invalid $there";
     ok  validate_uid($second_uplevel), "\$second_uplevel is valid $there";

     isnt $second_uplevel, $second_sub,
                                      "\$second_uplevel != \$second_sub $there";
     is   uid(UP),         $first_uplevel,  "uid(UP) == \$first_uplevel $there";

     return $second_uplevel;
    };

    return $second_sub, $second_uplevel;
   }->();

   ok  validate_uid($first_uplevel),    "\$first_uplevel is still valid $there";
   ok !validate_uid($second_sub),      "\$second_sub is no longer valid $there";
   ok !validate_uid($second_uplevel),
                                   "\$second_uplevel is no longer valid $there";

   uplevel {
    my $third_uplevel = uid;
    my $there         = "in the third uplevel (run $run)";

    ok !validate_uid($first_uplevel),      "\$first_uplevel is $invalid $there";
    ok !validate_uid($second_sub),     "\$second_sub is no longer valid $there";
    ok !validate_uid($second_uplevel),
                                   "\$second_uplevel is no longer valid $there";
    ok  validate_uid($third_uplevel),         "\$third_uplevel is valid $there";

    isnt $third_uplevel, $first_uplevel,
                                    "\$third_uplevel != \$first_uplevel $there";
    isnt $third_uplevel, $second_sub,  "\$third_uplevel != \$second_sub $there";
    isnt $third_uplevel, $second_uplevel,
                                   "\$third_uplevel != \$second_uplevel $there";
    isnt uid(UP), $first_sub, "uid(UP) != \$first_sub $there";
   }
  }
 }->();
}
