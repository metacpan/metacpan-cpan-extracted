#-------------------------------------------------------------------
#
#   $Id: 04_test_pre_post_conditions.t,v 1.9 2009/06/01 20:43:06 erwan_lemonnier Exp $
#

package main;

use strict;
use warnings;
use lib "../lib/", "t/", "lib/";
use Test::More;
use Data::Dumper;
use Carp qw(croak);

BEGIN {

    use check_requirements;
    plan tests => 15;

    use_ok("Sub::Contract",'contract');
};


#
# test the condition code
#

my @result = (1,2,3);
my $c;

sub foo {
    return @result;
}

# test pre condition
eval { $c = contract('foo')
	   ->pre(
		  sub {
		      croak "dying now" if ($_[0] eq 'please die');
		      return $_[0] eq 'bob';
		  }
		 )
	   ->enable;
   };
ok(!defined $@ || $@ eq '', "defined contract");

eval { foo('bob'); };
ok(!defined $@ || $@ eq "", "pre condition passes");

eval { foo('bilou') };
ok( $@ =~ /pre-condition fails before calling main::foo/, "pre condition fails");

eval { foo('please die') };
ok( $@ =~ /dying now at .*04_test_pre_post_conditions.t line 53/, "pre condition croaks");

# test post condition
eval {
    $c->pre(undef)
	->post(
	       sub {
		   my @args = @_;
		   croak "foo called in wrong context" if (!defined $Sub::Contract::wantarray || $Sub::Contract::wantarray != 1);
		   my @res = @Sub::Contract::results;
		   is_deeply(\@args,\@res,"\@Sub::Contract::results is same as \@args");
		   return $res[0] == 1 && $res[1] == 2 && $res[2] == 3;
		   }
	       )
	->enable;
};
ok(!defined $@ || $@ eq '', "recompiled contract");

my @res;
eval { @res = foo('bilou'); };
ok(!defined $@ || $@ eq "", "pre condition now disabled and post condition ok");
is_deeply(\@res,[1,2,3], "foo returned [1,2,3]");
is_deeply(\@Sub::Contract::results,[], "\@Sub::Contract::results is empty");
is_deeply(\@Sub::Contract::args,[], "\@Sub::Contract::args is empty");
is($Sub::Contract::wantarray,undef, "\$Sub::Contract::wantarray is undef");

@result = (4,5,6);
eval { @res = foo('bilou'); };
ok($@ =~ /post-condition fails after calling main::foo/, "post condition failed");

my $res;
@result = (1,2);
eval { $res = foo('asldkfjbilou'); };
ok($@ =~ /foo called in wrong context/, "post condition croaks");

