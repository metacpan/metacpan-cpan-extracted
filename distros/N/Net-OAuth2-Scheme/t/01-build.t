#!/usr/bin/perl

use strict;
use Test::More tests => 46;
use Test::Exception;
{
   package F;
   use parent 'Net::OAuth2::Scheme::Option::Builder';
   use Net::OAuth2::Scheme::Option::Defines;

   Define_Group bagel => undef, qw(bagel_taste bagel_seed_count);

   Default_Value bagel_color => 'blue';

   sub pkg_bagel_plain {
       my $self = shift;
       $self->parameter_prefix(bagel_ => @_);
       $self->install(bagel_seed_count => 17);
       $self->install(bagel_taste => 'buh');
   }  

}

$Net::OAuth2::Scheme::Option::Builder::Show_Uses_Stack = 0;
$Net::OAuth2::Scheme::Option::Builder::Visible_Destroy = 0;

my $f;
$f = F->new(a => 1, b => 2);

is( $f->installed('a'), 1, 'installed a');
is( $f->uses('a'),      1, 'uses a');
is( $f->ensure(a => 1), 1, 'ensure a');
throws_ok { $f->ensure(a => 2); } qr('a' must be '2'), 'ensure wrong';
ok( !defined($f->installed('c')), 'c not there yet');
throws_ok { $f->uses('c'); } qr(a setting for 'c' is needed), 'uses unset';
is( $f->ensure('c',3), 3, 'ensure unset');
is( $f->uses('c',3),   3, 'uses after ensure');
is_deeply( [$f->uses_all(qw(a b c))], [1,2,3], 'uses_all' );
throws_ok { $f->install(d => undef); } qr/install undef/, 'install undef';
lives_ok { $f->install(d => 4); } 'install';
throws_ok { $f->install(d => 5); } qr/multiple def/, 'install again';
throws_ok { $f->install(d => 4); } qr/multiple def/, 'install same';

is ( $f->actual('a'),'a', 'actual');
throws_ok { $f->make_alias('a','b'); } qr/settings of options 'a' and 'b' conflict/, 'alias fail';
lives_ok { $f->make_alias('newa','a'); } 'alias to existing';
is ( $f->uses('newa'), 1, 'newa after alias' );
is ( $f->uses('a'),    1, 'a after alias' );
is ( $f->actual('newa'),'a');
is ( $f->actual('a'),'a');
lives_ok { $f->make_alias('a','a2'); } 'alias from existing';
is ( $f->actual('newa'),'a2');
is ( $f->actual('a'),'a2');
is ( $f->uses('a2'),  1, 'a2 after alias' );

lives_ok { $f->make_alias('u','u2'); $f->make_alias('v','v2'); } 'alias of unset';
dies_ok { $f->uses('u'); };
dies_ok { $f->uses('u2'); };
lives_ok { $f->install(u => 37); $f->install(v2 => 38); };
is ( $f->uses('u'), 37 );
is ( $f->uses('u2'), 37 );
is ( $f->uses('v'), 38 );
is ( $f->uses('v2'), 38 );

is ( $f->uses('bagel_color'), 'blue' );

throws_ok { $f->export('e'); } qr(a setting for 'e' is needed), 'export unset';
is_deeply ( [$f->all_exports], [], 'no exports' );
is_deeply ( [$f->export(qw(a b c d u v))], [1,2,3,4,37,38], 'export');
is_deeply ( [sort {$a cmp $b} $f->all_exports], [qw(a b c d u v)], 'have exports' );

# start over
lives_ok { $f = F->new(bagel => ['plain', color => 'red']); };
is( $f->uses('bagel_seed_count'), 17);
is( $f->uses('bagel_color'),'red');

# start over
lives_ok { $f = F->new(bagel => 'plain'); };
is( $f->uses('bagel_seed_count'), 17);
throws_ok { $f->make_alias('bagel_seed_count','bagel_taste'); }
  qr(cannot alias group members), 'aliaspkg';
lives_ok { $f->make_alias('scount','bagel_seed_count'); };
lives_ok { $f->make_alias('taste','bagel_taste'); };
throws_ok { $f->make_alias('scount','taste'); }
  qr(cannot alias group members), 'aliaspkg2';

# parameter_prefix {

#    Carp::croak("cannot alias group members to each other: '$okey'"
#        $self->croak("settings of options '$key' and '$key2' conflict")
#            Carp::croak("package failed to define value:  $pkg -> $key")

1;
