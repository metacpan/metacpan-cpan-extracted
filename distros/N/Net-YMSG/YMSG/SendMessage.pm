package Net::YMSG::SendMessage;
use base 'Net::YMSG::Event';

sub code
{
	return 6;
}


sub to_string
{
	my $self = shift;
	sprintf "%s: %s", $self->{sender}, $self->{body};
}

1;
__END__
