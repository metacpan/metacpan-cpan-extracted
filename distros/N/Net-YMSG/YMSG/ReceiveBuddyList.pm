package Net::YMSG::ReceiveBuddyList;
use base 'Net::YMSG::Event';
use strict;


sub source
{
	my $self = shift;
	if (@_) {
		$self->SUPER::source(@_);
		my $yahoo = $self->get_connection;
		my $buddy_list = $self->body();
		while ($buddy_list =~ /([^:]+):([^\x0a]+)\x0a/g) {
			my $group = $1;
			my @buddy = split ',', $2;
			$yahoo->add_buddy_by_name($group, @buddy);
		}
	}
	$self->SUPER::source();
}


sub body
{
	my $self = shift;
	$self->_get_by_name('BUDDY_LIST');
}


sub code
{
	return 0x55;
}


sub to_string
{
	my $self = shift;
#	sprintf "%s: transit to '%s'", $self->{sender}, $self->{body};
}

1;
__END__
