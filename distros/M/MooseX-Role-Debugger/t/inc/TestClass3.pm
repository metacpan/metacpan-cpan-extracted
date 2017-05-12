package TestClass3;
use Moose;
use Log::Dispatch;

my $log = Log::Dispatch->new(
   outputs => [[ 'File', min_level => 'debug', newline => 1, filename => 'debug_Testclass3.log' ]]
);

with 'MooseX::Role::Debugger' => { debug => 1, logger => $log };

has 'an_attr' => (
   is => 'rw',
   writer => 'write_an_attr'
);

sub test_method { 
   my( $self, $arg ) = @_;
   print "An arg: $arg\n";
}

__PACKAGE__->meta->make_immutable;
