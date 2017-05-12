use Perl6::Builtins qw( system );
use Test::More qw( no_plan );

close *STDOUT;

ok system('ls')                         => 'successful system command';
ok !system('PAY_NO_ATTENTION_TO_THIS')  => 'unsuccessful system command';
    
my $good = system('ls');
ok $good                           => 'successful deferred system command';
ok !length $good                   => 'successful value system command';
    
my $bad = system('PAY_NO_ATTENTION_TO_THIS');
ok !$bad                           => 'unsuccessful deferred system command';
ok length $bad                     => 'unsuccessful value system command';
