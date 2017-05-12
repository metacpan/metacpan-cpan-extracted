package Net::YMSG::UnImplementEvent;
use base 'Net::YMSG::Event';
use strict;

sub to_string
{
	my $self = shift;
	sprintf "Un Implement event(%d)", $self->code;
}

1;
__END__
