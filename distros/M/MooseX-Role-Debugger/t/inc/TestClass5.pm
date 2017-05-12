package TestClass5;
use Moose;
use Log::Dispatch;

with 'MooseX::Role::Debugger';

has 'an_attr' => (
   is => 'rw',
   writer => 'write_an_attr'
);

sub test_method { 
   my( $self, $arg ) = @_;
   print "An arg: $arg\n";
   return ('a list', 'of things');
}

__PACKAGE__->meta->make_immutable;
