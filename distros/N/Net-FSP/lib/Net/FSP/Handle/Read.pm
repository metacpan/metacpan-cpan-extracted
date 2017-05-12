package Net::FSP::Handle::Read;
use strict;
use warnings;

use Net::FSP::Handle qw/do_or_fail/;
use base 'Net::FSP::Handle';
our $VERSION = $Net::FSP::VERSION;

sub OPEN {
	my ($self, $mode, $filename) = @_;

	$self->CLOSE if keys %{$self} > 1;
	$self->{position} = 0;
	$self->{reader}   = $self->{fsp}->_get_reader('get_file', $filename, \$self->{position});
	$self->{buffer}   = '';
	return $self;
}

sub _replenish {
	my $self = shift;

	my $block = $self->{reader}->();
	if (length $block == 0) {
		$self->{eof} = 1;
	}
	$self->{buffer} .= $block;
	return;
}

sub READ {
	my $self   = shift;
	my $bufref = \$_[0];
	my (undef, $length, $offset) = @_;

	return do_or_fail {
		while (length $self->{buffer} < $length and not $self->{eof}) {
			$self->_replenish;
		}
		my $to_move = substr $self->{buffer}, 0, $length, '';
		substr ${$bufref}, $offset, length $to_move, $to_move;
		return length $to_move;
	};
}

sub READLINE {
	my $self = shift;

	if (wantarray) {
		my @ret;
		while (defined(my $line = $self->READLINE)) {
			push @ret, $line;
		}
		return @ret;
	}

	return do_or_fail {
		while ($self->{buffer} !~ /\n/ and not $self->{eof}) {
			$self->_replenish;
		}
		if ($self->{buffer} =~ s/ \A ( [^\n]* \n ) //xms) {#TODO: refactor
			return $1;
		}
		elsif ($self->{buffer} =~ s/ \A ( [^\n]+ ) //xms) {
			return $1;
		}
		return;
	}
}

sub GETC {
	my $self = shift;
	my $len = $self->READ(my $ret, 1, 0);
	return $len ? $ret : undef;
}

sub EOF {
	my $self = shift;
	return $self->{eof} and $self->{buffer} eq '';
}

sub TELL {
	my $self = shift;
	return $self->{position};
}

#note: seeking is currently not supported

1;

__END__

=begin ignore

=item _replenish

=cut
