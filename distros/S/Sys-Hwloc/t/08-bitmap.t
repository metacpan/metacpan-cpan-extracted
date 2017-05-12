################################################################################
#
#  Copyright 2011 Zuse Institute Berlin
#
#  This package and its accompanying libraries is free software; you can
#  redistribute it and/or modify it under the terms of the GPL version 2.0,
#  or the Artistic License 2.0. Refer to LICENSE for the full license text.
#
#  Please send comments to kallies@zib.de
#
################################################################################
#
# Test the Sys::Hwloc::Bitmap API (hwloc-1.1)
#
# $Id: 08-bitmap.t,v 1.9 2011/01/11 10:49:40 bzbkalli Exp $
#
################################################################################

use Test::More 0.94;
use strict;
use Sys::Hwloc 0.08 qw(:DEFAULT :bitmap);

plan tests => 122;

my $apiVersion = HWLOC_XSAPI_VERSION();
my ($set, $set0, $set1, $rc);

SKIP: {

  skip 'Sys::Hwloc::Bitmap', 122 if ($apiVersion < 0x00010100);

  # --
  # Init bitmap, stop testing if this fails
  # --

  $set  = hwloc_bitmap_alloc();
  isa_ok($set, 'Sys::Hwloc::Bitmap', 'hwloc_bitmap_alloc()') or
    BAIL_OUT("Failed to initialize a bitmap via hwloc_bitmap_alloc()");

  # --
  # Should be empty
  # --

  $rc = hwloc_bitmap_to_ulong($set);
  is($rc, 0, 'hwloc_bitmap_to_ulong(<new>)');
  $rc = hwloc_bitmap_to_ith_ulong($set,0);
  is($rc, 0, 'hwloc_bitmap_to_ith_ulong(<new>,0)');
  $rc = hwloc_bitmap_sprintf($set);
  like($rc, qr/^0x0+$/, 'hwloc_bitmap_sprintf(<new>)');
  $rc = hwloc_bitmap_iszero($set);
  is($rc, 1, 'hwloc_bitmap_iszero(<new>)');
  $rc = hwloc_bitmap_isfull($set);
  is($rc, 0, 'hwloc_bitmap_isfull(<new>)');
  $rc = hwloc_bitmap_first($set);
  is($rc, -1, 'hwloc_bitmap_first(<new>)');
  $rc = hwloc_bitmap_last($set);
  is($rc, -1, 'hwloc_bitmap_last(<new>)');
  $rc = hwloc_bitmap_weight($set);
  is($rc, 0, 'hwloc_bitmap_weight(<new>)');

  # --
  # Fill set, check if full
  # --

  hwloc_bitmap_fill($set);
  $rc = hwloc_bitmap_iszero($set);
  is($rc, 0, 'hwloc_bitmap_fill() iszero');
  $rc = hwloc_bitmap_isfull($set);
  is($rc, 1, 'hwloc_bitmap_fill() isfull');
  $rc = hwloc_bitmap_to_ulong($set);
  cmp_ok($rc, '>', 0, 'hwloc_bitmap_to_ulong(<full>)');
  $rc = hwloc_bitmap_sprintf($set);
  like($rc, qr/^0xf\.\.\.f$/i, 'hwloc_bitmap_sprintf(<full>)');
  $rc = hwloc_bitmap_to_ith_ulong($set,0);
  cmp_ok($rc, '>', 0, 'hwloc_bitmap_to_ith_ulong(<full>,0)');
  $rc = hwloc_bitmap_weight($set);
  is($rc, -1, 'hwloc_bitmap_weight(<full>)');

  # --
  # Zero out, check
  # --

  hwloc_bitmap_zero($set);
  $rc = hwloc_bitmap_iszero($set);
  is($rc, 1, 'hwloc_bitmap_zero(<full>) iszero');

  # --
  # Duplicate set, check if the same, set cpu0, check if set
  # --

  $set0 = hwloc_bitmap_dup($set);
  isa_ok($set0, 'Sys::Hwloc::Bitmap', 'hwloc_bitmap_dup()') or
    BAIL_OUT("Failed to dup a bitmap via hwloc_bitmap_dup()");
  $rc = hwloc_bitmap_compare($set,$set0);
  is($rc, 0, 'hwloc_bitmap_compare(<emptydup>,<empty>)');
  $rc = hwloc_bitmap_isequal($set,$set0);
  is($rc, 1, 'hwloc_bitmap_isequal(<emptydup>,<empty>)');

  hwloc_bitmap_only($set0,0);
  $rc = hwloc_bitmap_compare($set,$set0);
  is($rc, -1, 'hwloc_bitmap_compare(<empty>,<cpu0>)');
  $rc = hwloc_bitmap_isequal($set,$set0);
  is($rc, 0, 'hwloc_bitmap_isequal(<empty>,<cpu0>)');
  $rc = hwloc_bitmap_to_ulong($set0);
  is($rc, 1, 'hwloc_bitmap_to_ulong(<cpu0>)');
  $rc = hwloc_bitmap_sprintf($set0);
  like($rc, qr/^0x0+1$/, 'hwloc_bitmap_sprintf(<cpu0>)');
  $rc = hwloc_bitmap_iszero($set0);
  is($rc, 0, 'hwloc_bitmap_iszero(<cpu0>)');
  $rc = hwloc_bitmap_isfull($set0);
  is($rc, 0, 'hwloc_bitmap_isfull(<cpu0>)');
  $rc = hwloc_bitmap_isset($set0,0);
  is($rc, 1, 'hwloc_bitmap_isset(<cpu0>,0)');
  $rc = hwloc_bitmap_first($set0);
  is($rc, 0, 'hwloc_bitmap_first(<cpu0>)');
  $rc = hwloc_bitmap_last($set0);
  is($rc, 0, 'hwloc_bitmap_last(<cpu0>)');
  $rc = hwloc_bitmap_weight($set0);
  is($rc, 1, 'hwloc_bitmap_weight(<cpu0>)');

  # --
  # Duplicate set, reinit from int to set cpu1, check if set
  # --

  $set1 = hwloc_bitmap_dup($set0);
  isa_ok($set, 'Sys::Hwloc::Bitmap', 'hwloc_bitmap_dup()') or
    BAIL_OUT("Failed to initialize a bitmap via hwloc_bitmap_dup()");

  hwloc_bitmap_from_ulong($set1,1 << 1);
  $rc = hwloc_bitmap_compare($set1,$set0);
  is($rc, 1, 'hwloc_bitmap_compare(<cpu1>,<cpu0>)');
  $rc = hwloc_bitmap_to_ulong($set1);
  is($rc, 1 << 1, 'hwloc_bitmap_to_ulong(<cpu1>)');
  $rc = hwloc_bitmap_isset($set1,0);
  is($rc, 0, 'hwloc_bitmap_isset(<cpu1>,0)');
  $rc = hwloc_bitmap_isset($set1,1);
  is($rc, 1, 'hwloc_bitmap_isset(<cpu1>,1)');
  $rc = hwloc_bitmap_includes($set0,$set1);
  is($rc, 0, 'hwloc_bitmap_includes(<cpu0>,<cpu1>)');
  $rc = hwloc_bitmap_isincluded($set0,$set1);
  is($rc, 0, 'hwloc_bitmap_isincluded(<cpu0>,<cpu1>)');
  $rc = hwloc_bitmap_intersects($set0,$set1);
  is($rc, 0, 'hwloc_bitmap_intersects(<cpu0>,<cpu1>)');

  # --
  # Check logics
  #  cpu0 | cpu1         should be 3
  # (cpu0 | cpu1) & cpu0 should be 1
  #  cpu0 ^ cpu0         should be 0
  # !(cpu0 ^ cpu0)       should be full
  # cpu0 & ! full        should be 0
  # --

  hwloc_bitmap_or($set,$set0,$set1);
  $rc = hwloc_bitmap_to_ulong($set);
  is($rc, (1 << 0) | (1 << 1), 'hwloc_bitmap_to_ulong(<cpu0 | cpu1>)');
  hwloc_bitmap_and($set1,$set,$set0);
  $rc = hwloc_bitmap_to_ulong($set1);
  is($rc, ((1 << 0) | (1 << 1)) & (1 << 0), 'hwloc_bitmap_to_ulong(<cpu0 | cpu1> & <cpu0>)');
  hwloc_bitmap_xor($set,$set0,$set0);
  $rc = hwloc_bitmap_to_ulong($set);
  is($rc, (1 << 0) ^ (1 << 0), 'hwloc_bitmap_to_ulong(<cpu0 ^ cpu0>)');
  hwloc_bitmap_not($set1,$set);
  $rc = hwloc_bitmap_isfull($set1);
  is($rc, 1, 'hwloc_bitmap_isfull(! <cpu0 ^ cpu0>)');
  hwloc_bitmap_andnot($set,$set0,$set1);
  $rc = hwloc_bitmap_iszero($set);
  is($rc, 1, 'hwloc_bitmap_iszero(<cpu0> & ! full)');

  # --
  # Init set from stringified arithmetic expression
  # --

  $rc = hwloc_bitmap_sscanf($set, 1 | 2);
  is($rc, 0, 'hwloc_bitmap_sscanf(1 | 2)');
  $rc = hwloc_bitmap_isset($set,0);
  is($rc, 1, 'hwloc_bitmap_isset(1 | 2,0)');
  $rc = hwloc_bitmap_isset($set,1);
  is($rc, 1, 'hwloc_bitmap_isset(1 | 2,1)');
  $rc =  hwloc_bitmap_weight($set);
  is($rc, 2, 'hwloc_bitmap_weight(1 | 2)');

  # --
  # Add cpu2, check
  # --

  hwloc_bitmap_zero($set);
  hwloc_bitmap_set($set,2);
  $rc = hwloc_bitmap_to_ulong($set);
  is($rc, 1 << 2, 'hwloc_bitmap_to_ulong(<cpu2>)');

  # --
  # Add cpu3 and 4, check
  # --

  hwloc_bitmap_zero($set);
  hwloc_bitmap_set_range($set,3,4);
  $rc = hwloc_bitmap_to_ulong($set);
  is($rc, (1 << 3) | (1 << 4), 'hwloc_bitmap_to_ulong(<cpu3,cpu4>)');
  my @ids = hwloc_bitmap_ids($set);
  is(scalar @ids, 2, 'scalar hwloc_bitmap_ids(<cpu3,cpu4>)');
  is(join(',', @ids), join(',', 3, 4), 'hwloc_bitmap_ids(<cpu3,cpu4>)');

  # --
  # Remove cpu4, check
  # --

  hwloc_bitmap_clr($set,4);
  $rc = hwloc_bitmap_isset($set,4);
  is($rc, 0, 'hwloc_bitmap_isset(<cpu3>,4)');
  $rc = hwloc_bitmap_to_ulong($set);
  is($rc, 1 << 3, 'hwloc_bitmap_to_ulong(<cpu3>)');

  # --
  # Remove cpu2 and 3, check
  # --

  hwloc_bitmap_clr_range($set,2,3);
  $rc = hwloc_bitmap_to_ulong($set);
  is($rc, 0, 'hwloc_bitmap_to_ulong(<empty>)');

  # --
  # Init full without cpu0
  # --

  hwloc_bitmap_allbut($set,0);
  $rc = hwloc_bitmap_isset($set,0);
  is($rc, 0, 'hwloc_bitmap_isset(<full w/o cpu0>,0)');

  # --
  # Compare against full using lowest cpu idx
  # --

  hwloc_bitmap_fill($set1);
  $rc = hwloc_bitmap_compare_first($set,$set1);
  is($rc, 1, 'hwloc_bitmap_compare_first(<full w/o cpu0>,<full>)');
  $rc = hwloc_bitmap_compare_first($set1,$set);
  is($rc, -1, 'hwloc_bitmap_compare_first(<full>,<full w/o cpu0>)');
  $rc = hwloc_bitmap_compare_first($set,$set);
  is($rc, 0, 'hwloc_bitmap_compare_first(<full w/o cpu0>,<full w/o cpu0>)');

  # --
  # Init with cpu2 .. 4, check next iterator
  # --

  hwloc_bitmap_zero($set);
  hwloc_bitmap_set_range($set,2,4);
  if(ok(hwloc_bitmap_isset($set,2) && hwloc_bitmap_isset($set,3) && hwloc_bitmap_isset($set,4), 'set 2 .. 4')) {
    subtest "hwloc_bitmap_next()" => sub {
      plan tests => 5;
      is(hwloc_bitmap_next($set,0), 2, "hwloc_bitmap_next(0)");
      is(hwloc_bitmap_next($set,1), 2, "hwloc_bitmap_next(1)");
      is(hwloc_bitmap_next($set,2), 3, "hwloc_bitmap_next(2)");
      is(hwloc_bitmap_next($set,3), 4, "hwloc_bitmap_next(3)");
      is(hwloc_bitmap_next($set,4), -1, "hwloc_bitmap_next(4)");
    };
  } else {
    fail("hwloc_bitmap_next()");
  }

  # --
  # Check sprintf_list output and the reverse
  # --

  hwloc_bitmap_zero($set);
  hwloc_bitmap_set_range($set,0,7);
  hwloc_bitmap_set_range($set,16,17);
  hwloc_bitmap_set_range($set,24,27);
  my $str = hwloc_bitmap_list_sprintf($set);
  is($str, '0-7,16,17,24-27', 'hwloc_bitmap_list_sprintf(0-7,16,17,24-27)');

  hwloc_bitmap_list_sscanf($set0,$str);
  $rc = hwloc_bitmap_isequal($set,$set0);
  is($rc, 1, "hwloc_bitmap_list_sscanf($str) eq '0-7,16,17,24-27'");

  # --
  # Free bitmaps
  # --

  hwloc_bitmap_free($set);
  hwloc_bitmap_free($set0);
  hwloc_bitmap_free($set1);

  # ==
  # Now try OO
  # ==

  # --
  # Init bitmap, stop testing if this fails
  # --

  $set = Sys::Hwloc::Bitmap->new;
  isa_ok($set, 'Sys::Hwloc::Bitmap', 'Sys::Hwloc::Bitmap->new') or
    BAIL_OUT("Failed to initialize a bitmap via Sys::Hwloc::Bitmap->new");

  # --
  # Should be empty
  # --

  $rc = $set->to_ulong;
  is($rc, 0, 'newset->to_ulong');
  $rc = $set->to_ith_ulong(0);
  is($rc, 0, 'newset->to_ith_ulong(0)');
  $rc = $set->sprintf;
  like($rc, qr/^0x0+$/, 'newset->sprintf');
  $rc = $set->iszero;
  is($rc, 1, 'newset->iszero');
  $rc = $set->isfull;
  is($rc, 0, 'newset->isfull');
  $rc = $set->first;
  is($rc, -1, 'newset->first');
  $rc = $set->last;
  is($rc, -1, 'newset->last');
  $rc = $set->weight;
  is($rc, 0, 'newset->weight');

  # --
  # Fill set, check if full
  # --

  $set->fill;
  $rc = $set->iszero;
  is($rc, 0, 'set->fill iszero');
  $rc = $set->isfull;
  is($rc, 1, 'set->fill isfull');
  $rc = $set->to_ulong;
  cmp_ok($rc, '>', 0, 'fullset->to_ulong');
  $rc = $set->sprintf;
  like($rc, qr/^0xf\.\.\.f$/i, 'fullset->sprintf');
  $rc = $set->to_ith_ulong(0);
  cmp_ok($rc, '>', 0, 'fullset->to_ith_ulong(0)');
  $rc = $set->weight;
  is($rc, -1, 'fullset->weight');

  # --
  # Zero out, check
  # --

  $set->zero;
  $rc = $set->iszero;
  is($rc, 1, 'fullset->zero iszero');

  # --
  # Duplicate set, check if the same, set cpu0, check if set
  # --

  $set0 = $set->dup;
  isa_ok($set0, 'Sys::Hwloc::Bitmap', 'emptyset->dup') or
    BAIL_OUT("Failed to dup a bitmap via set->dup");
  $rc = $set->compare($set0);
  is($rc, 0, 'emptyset->compare(emptyset)');
  $rc = $set->isequal($set0);
  is($rc, 1, 'emptyset->isequal(emptyset)');

  $set0->only(0);
  $rc = $set->compare($set0);
  is($rc, -1, 'emptyset->compare(cpu0set)');
  $rc = $set->isequal($set0);
  is($rc, 0, 'emptyset->isequal(cpu0set)');
  $rc = $set0->to_ulong;
  is($rc, 1, 'cpu0set->to_ulong');
  $rc = $set0->sprintf;
  like($rc, qr/^0x0+1$/, 'cpu0set->sprintf');
  $rc = $set0->iszero;
  is($rc, 0, 'cpu0set->iszero');
  $rc = $set0->isfull;
  is($rc, 0, 'cpu0set->isfull');
  $rc = $set0->isset(0);
  is($rc, 1, 'cpu0set->isset(0)');
  $rc = $set0->first;
  is($rc, 0, 'cpu0set->first');
  $rc = $set0->last;
  is($rc, 0, 'cpu0set->last');
  $rc = $set0->weight;
  is($rc, 1, 'cpu0set->weight');

  # --
  # Duplicate set, reinit from int to set cpu1, check if set
  # --

  $set1 = $set0->dup;
  isa_ok($set, 'Sys::Hwloc::Bitmap', 'set->dup') or
    BAIL_OUT("Failed to initialize a bitmap via set->dup");

  $set1->from_ulong(1 << 1);
  $rc = $set1->compare($set0);
  is($rc, 1, 'cpu1set->compare(cpu0set)');
  $rc = $set1->to_ulong;
  is($rc, 1 << 1, 'cpu1set->to_ulong');
  $rc = $set1->isset(0);
  is($rc, 0, 'cpu1set->isset(0)');
  $rc = $set1->isset(1);
  is($rc, 1, 'cpu1set->isset(1)');
  $rc = $set0->includes($set1);
  is($rc, 0, 'cpu0set->includes(cpu1set)');
  $rc = $set0->isincluded($set1);
  is($rc, 0, 'cpu0set->isincluded(cpu1set)');
  $rc = $set0->intersects($set1);
  is($rc, 0, 'cpu0set->intersects(cpu1set)');

  # --
  # Check logics
  #  cpu0 | cpu1         should be 3
  # (cpu0 | cpu1) & cpu0 should be 1
  #  cpu0 ^ cpu0         should be 0
  # !(cpu0 ^ cpu0)       should be full
  # cpu0 & ! full        should be 0
  # --

  $set1->or($set0);
  $rc = $set1->to_ulong;
  is($rc, (1 << 0) | (1 << 1), 'cpu1set |= cpu0set');
  $set1->and($set0);
  $rc = $set1->to_ulong;
  is($rc, ((1 << 0) | (1 << 1)) & (1 << 0), 'cpu01set &= cpu0set');
  $set0->xor($set0);
  $rc = $set0->to_ulong;
  is($rc, (1 << 0) ^ (1 << 0), 'cpu0set ^= cpu0set');
  $set0->not;
  $rc = $set0->isfull;
  is($rc, 1, '! (cpu0set ^= cpu0set) isfull');
  $set1->andnot($set0);
  $rc = $set1->iszero;
  is($rc, 1, '(cpu0set & ! fullset) iszero');

  # --
  # Init set from stringified arithmetic expression
  # --

  $rc = $set->sscanf(1 | 2);
  is($rc, 0, 'set->from_string(1 | 2)');
  $rc = $set->isset(0);
  is($rc, 1, '(1 | 2) -> isset(0)');
  $rc = $set->isset(1);
  is($rc, 1, '(1 | 2) -> isset(1)');
  $rc = $set->weight;
  is($rc, 2, '(1 | 2) -> weight');

  # --
  # Add cpu2, check
  # --

  $set->zero;
  $set->set(2);
  $rc = $set->to_ulong;
  is($rc, 1 << 2, 'cpu2set->to_ulong');

  # --
  # Add cpu3 and 4, check
  # --

  $set->zero;
  $set->set_range(3,4);
  $rc = $set->to_ulong;
  is($rc, (1 << 3) | (1 << 4), 'cpu34set->to_ulong');
  @ids = $set->ids;
  is(scalar @ids, 2, 'scalar cpu34set->ids');
  is(join(',', @ids), join(',', 3, 4), 'cpu34set->ids');

  # --
  # Remove cpu4, check
  # --

  $set->clr(4);
  $rc = $set->isset(4);
  is($rc, 0, 'cpu3set->isset(4)');
  $rc = $set->to_ulong;
  is($rc, 1 << 3, 'cpu3set->to_ulong');

  # --
  # Remove cpu2 and 3, check
  # --

  $set->clr_range(2,3);
  $rc = $set->to_ulong;
  is($rc, 0, 'emptyset->to_ulong');

  # --
  # Init full without cpu0
  # --

  $set->allbut(0);
  $rc = $set->isset(0);
  is($rc, 0, 'full-wo-cpu0->isset(0)');

  # --
  # Compare against full using lowest cpu idx
  # --

  $set1->fill;
  $rc = $set->compare_first($set1);
  is($rc, 1, 'hwloc_bitmap_compare_first(<full w/o cpu0>,<full>)');
  $rc = $set1->compare_first($set);
  is($rc, -1, 'hwloc_bitmap_compare_first(<full>,<full w/o cpu0>)');
  $rc = $set->compare_first($set);
  is($rc, 0, 'hwloc_bitmap_compare_first(<full w/o cpu0>,<full w/o cpu0>)');

  # --
  # Init with cpu2 .. 4, check next iterator
  # --

  $set->zero;
  $set->set_range(2,4);
  if(ok($set->isset(2) && $set->isset(3) && $set->isset(4), 'set 2 .. 4')) {
    subtest "set->next()" => sub {
      plan tests => 5;
      is($set->next(0), 2, "cpu234set->next(0)");
      is($set->next(1), 2, "cpu234set->next(1)");
      is($set->next(2), 3, "cpu234set->next(2)");
      is($set->next(3), 4, "cpu234set->next(3)");
      is($set->next(4), -1, "cpu234set->next(4)");
    };
  } else {
    fail("set->next()");
  }

  # --
  # Check sprintf_list output and the reverse
  # --

  $set->zero;
  $set->set_range(0,7);
  $set->set_range(16,17);
  $set->set_range(24,27);
  $str = $set->sprintf_list;
  is($str, '0-7,16,17,24-27', 'set->sprintf_list');

  $set0->sscanf_list($str);
  $rc = $set->isequal($set0);
  is($rc, 1, "set->sscanf_list($str) eq '0-7,16,17,24-27'");

  $set->free;
  $set0->free;
  $set1->destroy;

};
