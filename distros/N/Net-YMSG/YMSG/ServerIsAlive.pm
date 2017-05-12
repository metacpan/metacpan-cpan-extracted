package Net::YMSG::ServerIsAlive;
use base 'Net::YMSG::Event';
use strict;

sub to_string
{
	my $self = shift;
	sprintf "Yahoo!Messenger server is alive";
}

1;
__END__
