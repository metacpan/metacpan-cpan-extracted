package Net::YMSG::GoesOffline;
use base 'Net::YMSG::Event';
use strict;


sub source
{
	my $self = shift;
	if (@_) {
		$self->SUPER::source(@_);
		my $yahoo = $self->get_connection;
		my ($buddy) = grep {
			$_->name eq lc $self->from
		} $yahoo->buddy_list;
		return unless $buddy;

		$buddy->online(undef);
	}
	$self->SUPER::source();
}


sub from
{
	my $self = shift;
	$self->_get_by_name('BUDDY_ID');
}

sub to_string
{
	my $self = shift;
	sprintf "%s: goes offline", $self->{sender};
}

1;
__END__
