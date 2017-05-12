package Path::Abstract::Fast;

use warnings;
use strict;

sub _deprecation_warning {
    warn <<_END_
** Path::Abstract::Fast is deprecated (use Path::Abstract or Path::Abstract::Underload instead) **
_END_
}

use Sub::Exporter -setup => {
	exports => [ path => sub {
        _deprecation_warning;
        sub {
		return __PACKAGE__->new(@_)
	} } ],
};

use base qw/Path::Abstract::Underload/;

sub new {
    _deprecation_warning;
    my $class = shift;
    return $class->SUPER::new(@_);
}

1;
