use Test::Spec;
use lib 't/';
use TestClass;
use File::Remove 'remove';
use autodie;
describe 'MooseX::Role::LogHandler' => sub  {
	
	my $test;	
	it 'should instantiate TestClass with role' => sub {
	  $test = TestClass->new;
	  ok($test);	
	};

        it 'should log to custom location t/testlog' => sub {
          $test = TestClass->new;
          $test->logger->debug('log');
          ok(stat('t/testlog'));                  
        };
        
        it 'should execute methods that log' => sub {
          $test = TestClass->new;
          $test->method_that_logs_1;
          $test->method_that_logs_2;
          open my $fh, '<' , 't/testlog';
          my $contents = do { local $/; <$fh> };
          close($fh);            
          like($contents,qr/method1/);
          like($contents,qr/method2/);
        };
               
        after sub{
          remove 't/testlog';
        };
};

runtests unless caller;