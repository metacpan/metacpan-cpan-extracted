use Test::Spec;
use lib 't/';
use TestClass2;
use File::Remove 'remove';
use autodie;
describe 'MooseX::Role::LogHandler' => sub  {
	
	my $test;	
	it 'should instantiate TestClass with role' => sub {
	  $test = TestClass2->new;
	  ok($test);	
	};

        it 'should log to custom location t/testlog2' => sub {
          $test = TestClass2->new;
          $test->logger->debug('log');
          ok(stat('t/testlog2'));                  
        };
        
        it 'should execute methods that log' => sub {
          $test = TestClass2->new;
          $test->method_that_logs_1;
          $test->method_that_logs_2;
          open my $fh, '<' , 't/testlog2';
          my $contents = do { local $/; <$fh> };
          close($fh);            
          like($contents,qr/method1/);
          like($contents,qr/method2/);
        };
               
        after sub{
          remove 't/testlog2';
        };
};

runtests unless caller;