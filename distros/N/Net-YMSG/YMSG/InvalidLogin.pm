package Net::YMSG::InvalidLogin;
use base 'Net::YMSG::Event';
use strict;

sub is_enable { undef }

sub to_string
{
	my $self = shift;
	"Invalid Login\n";
}

1;
__END__
