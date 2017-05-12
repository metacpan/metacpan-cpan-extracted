package Net::FSP::Handle::Write;
use strict;
use warnings;
our $VERSION = $Net::FSP::VERSION;
use Net::FSP::Handle qw/do_or_fail/;
use base 'Net::FSP::Handle';

sub OPEN {
	my ($self, $mode, $filename) = @_;
	$self->CLOSE if keys %{$self} > 1;
	$self->{writer} = $self->{fsp}->_get_writer($filename);
	return $self;
}

sub PRINT {
	my ($self, @args) = @_;
	my $separator = defined $, ? $, : '';
	my $buffer = join $separator, @args;
	return $self->WRITE($buffer, length $buffer, 0);
}

sub PRINTF {
	my ($self, @args) = @_;
	my $buffer = sprintf shift, @args;
	return $self->WRITE($buffer, length $buffer, 0);
}

sub WRITE {
	my ($self, $buffer, $length, $offset) = @_;
	return do_or_fail {
		$self->{writer}->(substr $buffer, $offset, $length);
	};
}

sub EOF {
	return 0;
}

sub CLOSE {
	my $self = shift;

	my $ret = do_or_fail {
		$self->{writer}->(undef) if defined $self->{writer};
	};
	$self->SUPER::CLOSE;
	return $ret;
}

1;

__END__

=begin ignore

=over 4

=item OPEN

=item PRINT

=item PRINTF

=item WRITE

=item EOF

=item CLOSE

=back

=cut
