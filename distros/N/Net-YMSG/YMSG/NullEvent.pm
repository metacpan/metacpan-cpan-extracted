package Net::YMSG::NullEvent;
use base 'Net::YMSG::Event';
use strict;

sub to_string
{
	my $self = shift;
	sprintf "Null event(%d)", $self->code;
}

1;
__END__
