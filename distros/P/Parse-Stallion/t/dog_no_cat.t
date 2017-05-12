#!/usr/bin/perl
#Copyright 2008-10 Arthur S Goldstein
#tests a simple assertion
use Test::More tests => 9;
BEGIN { use_ok('Parse::Stallion') };

my %dog_rules = (
 start_rule => A('bunch_of_chars','dog','no_cat'),
 bunch_of_chars => M(qr/./),
 dog => qr/dog/,
 no_cat => L(PF(
   sub{my $parameters = shift;
     my $string = ${$parameters->{parse_this_ref}};
     my $cv = $parameters->{current_position};
     if ($string =~ /cat/) {
        return (0, undef);
     }
     return (1, '', 0);
    }
   )),
);

my $dog_parser = new Parse::Stallion(\%dog_rules);
my $result;

$result = $dog_parser->parse_and_evaluate('dog');
is (defined $result, 1, "simple dog");

$result = $dog_parser->parse_and_evaluate('dogcat');
is (defined $result, '', "simple dogcat");

$result = $dog_parser->parse_and_evaluate('asdfdog');
is (defined $result, 1, "asdfdog");

$result = $dog_parser->parse_and_evaluate('asdfdogxklcjcat');
is (defined $result, '', "asdfdogxklcjcat");

my %dog_no_commit_rules = (
 start => O('bocdd','bocd'),
 bocdd => A('bunch_of_chars','dog', 'cow'),
 bocd => A('bunch_of_chars','dog'),
 bunch_of_chars => M(qr/./),
 dog => qr/dog/,
 cow => qr/cow/,
);

my %dog_commit_rules = (
 start => O('bocdd','bocd'),
 bocdd => A('bunch_of_chars','dog','commit', 'cow'),
 bocd => A('bunch_of_chars','dog'), #should never reach here because of commit
 bunch_of_chars => M(qr/./),
 dog => qr/dog/,
 cow => qr/cow/,
 commit => L(qr//,PB( sub{return 1})),
);

my $dog_commit_parser = new Parse::Stallion(\%dog_commit_rules);
my $dog_no_commit_parser = new Parse::Stallion(\%dog_no_commit_rules);

$result = $dog_commit_parser->parse_and_evaluate('xdogcow');
is (defined $result, 1, "commit xdogdog");

$result = $dog_commit_parser->parse_and_evaluate('xdog');
is (defined $result, '', "commit xdog");

$result = $dog_no_commit_parser->parse_and_evaluate('xdogcow');
is (defined $result, 1, "no commit xdogdog");

$result = $dog_no_commit_parser->parse_and_evaluate('xdog');
is (defined $result, 1, "no commit xdog");

print "\nAll done\n";
