package Net::YMSG::ChatRoomReceive;
use base 'Net::YMSG::Event';

sub source
{
	my $self = shift;
	if (@_) {
		$self->{source} = shift;
		my $code = $self->_get_by_name('STATUS_CODE') || 0;
		if ($code == 99) {
			require Net::YMSG::NullEvent;
			bless $self, 'Net::YMSG::NullEvent';
		}
	}
	$self->{source};
}

sub from
{
	my $self = shift;
	$self->_set_by_name('CHATFROM', shift) if @_;
	if ($self->_get_by_name('ERROR_MESSAGE')) {
		return 'system';
	}
	$self->_get_by_name('CHATFROM');
}

sub body
{
	my $self = shift;
	$self->_set_by_name('CHATMESSAGE', shift) if @_;
	if ($self->_get_by_name('ERROR_MESSAGE')) {
		return $self->_get_by_name('ERROR_MESSAGE');
	}
	my $body=$self->_get_by_name('CHATMESSAGE');
	#$body=~s/<(.*)>//g;
	return $body;
}

1;
__END__

