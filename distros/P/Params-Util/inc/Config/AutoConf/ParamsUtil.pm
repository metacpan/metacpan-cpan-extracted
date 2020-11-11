package Config::AutoConf::ParamsUtil;

use strict;
use warnings;

use parent qw(Config::AutoConf);

sub new
{
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(%args);
    # XXX might add c++ if required for some operating systems
    return $self;
}

sub check_paramsutil_prerequisites
{
    my $self = shift->_get_instance();

    $self->{config}->{cc} or $self->check_prog_cc();
    return $self->check_produce_loadable_xs_build();
}

1;

