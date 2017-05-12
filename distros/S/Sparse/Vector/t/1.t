#!/usr/local/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

######################### Load Sparse::Vector

use Test::More tests => 20;

BEGIN { use_ok('Sparse::Vector'); }
require_ok('Sparse::Vector');

######################### Instantiate Vector

$vector = Sparse::Vector->new;
isa_ok($vector, 'Sparse::Vector');

######################### isnull

cmp_ok($vector->isnull, '==', 1, 'test isnull when null');

######################### get/set value 

$vector->set(12,5);

cmp_ok($vector->get(12), '==', 5, 'test get/set');

######################### isnull

cmp_ok($vector->isnull, '==', 0, 'test isnull when not null');

######################### get keys 

$vector->set(100,2);
$vector->set(20,4);
@vector_indices=$vector->keys();

@expected_keys = (12, 20, 100);

eq_array(\@vector_indices, \@expected_keys);

######################### print 

# tested what $vector->print(); prints

######################### stringify

cmp_ok($vector->stringify, 'eq', "12 5 20 4 100 2", 'test stringify');

######################### incr

$vector->incr(20);

cmp_ok($vector->get(20), '==', 5, 'test incr');

######################### add

# v1 	=     5 2 8 15     12 3 24 6       30 7 50 3 100 9
# v2 	= 2 5 5 7      9 4      24 7  27 2      50 5       105 3

# v1+v2 = 2 5 5 9 8 15 9 4 12 3 24 13 27 2 30 7 50 8 100 9 105 3

$v1=Sparse::Vector->new;
$v2=Sparse::Vector->new;

$v1->set(5,2);
$v1->set(8,15);
$v1->set(12,3);
$v1->set(24,6);
$v1->set(30,7);
$v1->set(50,3);
$v1->set(100,9);

$v2->set(2,5);
$v2->set(5,7);
$v2->set(9,4);
$v2->set(24,7);
$v2->set(27,2);
$v2->set(50,5);
$v2->set(105,3);

$v1->add($v2);

# v1 = v1+v2 = 2 5 5 9 8 15 9 4 12 3 24 13 27 2 30 7 50 8 100 9 105 3

cmp_ok($v1->stringify, 'eq', "2 5 5 9 8 15 9 4 12 3 24 13 27 2 30 7 50 8 100 9 105 3", 'test add');

######################### norm

$v3 = Sparse::Vector->new;
$v3->set(1,3);
$v3->set(5,5);
$v3->set(16,3);
$v3->set(20,4);
$v3->set(12,4);
$v3->set(8,5);

# norm = 10

cmp_ok($v3->norm, '==', 10, 'test norm');

######################### normalize

$v3->normalize;

cmp_ok($v3->stringify, 'eq', "1 0.3 5 0.5 8 0.5 12 0.4 16 0.3 20 0.4", 'test normalize');

######################### more add 

# v3 	 = 		1 0.3 5 0.5 8 0.5 12 0.4 16 0.3 20 0.4 
# vector = 				  12 5          20 5   100 2

$vector->add($v3);

# $vector += $v3
# $vector =		1 0.3 5 0.5 8 0.5 12 5.4 16 0.3 20 5.4 100 2

cmp_ok($vector->stringify, 'eq', "1 0.3 5 0.5 8 0.5 12 5.4 16 0.3 20 5.4 100 2", 'test add');

cmp_ok($v3->stringify, 'eq', "1 0.3 5 0.5 8 0.5 12 0.4 16 0.3 20 0.4", 'test add');

######################### free

$v1->free;
$v2->free;
$v3->free;

cmp_ok($v1->stringify, 'eq', "", 'test free');
cmp_ok($v2->stringify, 'eq', "", 'test free');
cmp_ok($v3->stringify, 'eq', "", 'test free');

######################### isnull after free

cmp_ok($v1->isnull, '==', 1, 'test isnull after free');

######################### dot

$v1=Sparse::Vector->new;
$v2=Sparse::Vector->new;

$v1->set(0,2);
$v1->set(3,1);
$v1->set(4,4);
$v1->set(5,2);
$v1->set(6,1);
$v1->set(7,3);

$v2->set(0,2);
$v2->set(1,1);
$v2->set(4,2);
$v2->set(7,1);
$v2->set(8,2);

# v1 = 		2 0 0 1 4 2 1 3 0
# v2 = 		2 1 0 0 2 0 0 1 2

# v1.v2 = 	4+8+3 = 15

cmp_ok($v1->dot($v2), '==', 15, 'test dot');

######################### div

# v1   = 		2  0  0    1  4  2    1    3  0

# v1/2 =		1  0  0  0.5  2  1  0.5  1.5  0

$v1->div(2);
cmp_ok($v1->stringify, 'eq', "0 1 3 0.5 4 2 5 1 6 0.5 7 1.5", 'test div');

######################### binadd

$v1->free;
$v2->free;

$v1=Sparse::Vector->new;
$v1->set(5,1);
$v1->set(10,1);
$v1->set(15,1);
$v1->set(22,1);
$v1->set(27,1);
$v1->set(34,1);

$v2=Sparse::Vector->new;
$v2->set(2,4);
$v2->set(10,5);
$v2->set(13,3);
$v2->set(22,6);
$v2->set(30,7);
$v2->set(36,1);

# v1 =		    5 1 10 1      15 1 22 1 27 1      34 1
# v2 =		2 4     10 5 13 3      22 6      30 7      36 1

$v1->binadd($v2);

# v1 =		2 1 5 1 10 1 13 1 15 1 22 1 27 1 30 1 34 1 36 1

cmp_ok($v1->stringify, 'eq', "2 1 5 1 10 1 13 1 15 1 22 1 27 1 30 1 34 1 36 1", 'test binadd');

