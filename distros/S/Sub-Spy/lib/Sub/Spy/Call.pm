package Sub::Spy::Call;
use strict;
use warnings;

use parent qw/Class::Accessor::Fast/;

__PACKAGE__->mk_ro_accessors(qw/args exception return_value/);

sub new {
    my ($class, $param) = @_;
    return $class->SUPER::new($param);
}

# exception

sub threw {
    return (defined shift->exception) ? 1 : 0;
}


1;
