use warnings;
use strict;    
use Test::More tests => 5;
use Data::Dumper; 
use English qw( -no_match_vars);

use_ok  'POD::Credentials';
can_ok(POD::Credentials->new() , POD::Credentials->show_fields('Public'));
my  $cred;
eval {
      $cred = POD::Credentials->new({ author => 'Joe Doe'  });
};
ok(!$EVAL_ERROR && $cred->author eq 'Joe Doe', " create object with author ") or
    diag(" create object   author failed $EVAL_ERROR ");
undef $EVAL_ERROR; 
my $str;   
eval {
      $str =  $cred->asString;
};
ok(!$EVAL_ERROR && $str =~ /Joe Doe/sm, " asString method  ") or
    diag("   asString method  failed $EVAL_ERROR ");
undef $EVAL_ERROR; 
 
eval {
      $cred->end_module('1');
      $str =  $cred->asString;
};
 
ok(!$EVAL_ERROR && $str =~ /__END__/sm, " asString method with __END__  ") or
    diag("   asString method eit __END__ failed $EVAL_ERROR ");
undef $EVAL_ERROR; 
