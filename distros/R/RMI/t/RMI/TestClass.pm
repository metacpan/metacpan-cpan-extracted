
package RMI::TestClass;
use Scalar::Util;

my %obj_this_process;

sub new {
    my $class = shift;
    my $self = bless { pid => $$, @_ }, $class;
    $obj_this_process{$self} = $self;
    Scalar::Util::weaken($obj_this_process{$self});
    return $self;
}

sub DESTROY {
    my $self = shift;
    delete $obj_this_process{$self};
}


1;