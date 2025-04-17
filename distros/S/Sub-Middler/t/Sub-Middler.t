# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Sub-Middler.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More;
BEGIN { use_ok('Sub::Middler') };


my $middler=Sub::Middler->new;
ok $middler, "New object";



# Fail non code ref for register
####################################################################
# $@=undef;                                                        #
# eval {                                                           #
#   $middler->register("asdf");                                    #
# };                                                               #
# my $e=$@;                                                        #
# ok $e =~ /Middleware must be a CODE reference/, "register fail"; #
####################################################################



for my $v (1..3){
  $middler->register(
    sub {
      my ($next, $index, @args)=@_;

      sub {
        $_[0].="Index $index,".join(",",@args)."\n";
        &$next;
      }
    }
  );
}


################################################################################
# # Fail non code ref for link                                                 #
# $@=undef;                                                                    #
# eval {                                                                       #
#   $middler->link("noncode", qw<extra args>);                                 #
# };                                                                           #
#                                                                              #
# $e=$@;                                                                       #
# ok $e =~ /A CODE reference is requred when linking middleware/, "link fail"; #
################################################################################


# Test the linking lexical linking of extra arguments at link time.
# Tests that arguments between link in chain are up to the links only.
my $output;
my $dispatcher=$middler->link(sub {$output=$_[0]},qw<extra args>);

ok $dispatcher, "Dispatcher created";

$dispatcher->(my $input="");

ok $output eq
"Index 0,extra,args
Index 1,extra,args
Index 2,extra,args
", "Data pass through middleware";

done_testing;
