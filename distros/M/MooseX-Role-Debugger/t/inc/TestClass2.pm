package TestClass2;
use Moose;
use Log::Dispatch;

with 'MooseX::Role::Debugger' => { skip_attrs => 0 };

has 'an_attr' => (
   is => 'rw',
   writer => 'write_an_attr'
);

sub test_method { 
   my( $self, $arg ) = @_;
   print "An arg: $arg\n";
}

__PACKAGE__->meta->make_immutable;
