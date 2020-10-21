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

#    AX_CHECK_LIB_FLAGS([log4cplus], [stdc++,stdc++ unwind], [log4cplus_initialize();], [
#    AC_INCLUDES_DEFAULT
##include <log4cplus/clogger.h>
#      ], [log4cplus >= 2.0.0], [

sub check_paramsutil_prerequisites
{
    my $self = shift->_get_instance();

    $self->{config}->{cc}                    or $self->check_prog_cc();
    $self->check_produce_loadable_xs_build() or die "Can't produce loadable XS module";
}

1;

