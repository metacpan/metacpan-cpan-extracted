
use strict;
use warnings FATAL => 'all';

package RayApp::Request::Params;

package RayApp::Request::Params::Hashref;
sub new {
	my $class = shift;
	my $hashref = shift;
	return bless { data => $hashref }, $class;
}
sub param {
	my $self = shift;
	if (not @_) {
		return sort keys %{ $self->{data} };
	} elsif (@_ == 1) {
		if (ref $self->{data}{$_[0]}) {
			if (wantarray) {
				return @{ $self->{data}{$_[0]} };
			} else {
				return $self->{data}{$_[0]}[0];
			}
		}
		return $self->{data}{$_[0]};
	} elsif (@_ == 2) {
		$self->{data}{$_[0]} = $_[1];
	} else {
		my $key = shift;
		$self->{data}{$key} = [ @_ ];
	}
}
sub delete {
	my $self = shift;
	delete $self->{data}{$_[0]};
}

package RayApp::Request::Params::Arrayref;
use base 'RayApp::Request::Params::Hashref';
sub new {
	my $class = shift;
	my $arrayref = shift;
	my $hashref = {};
	for (my $i = 0; $i < @$arrayref; $i += 2) {
		push @{ $hashref->{ $arrayref->[$i] } }, $arrayref->[$i + 1];
	}
	return bless { arrayref => $arrayref, data => $hashref }, $class;
}
sub param {
	my $self = shift;
	if (@_ >= 2) {
		my $key = shift;
		$self->delete($key);
		for (@_) {
			push @{ $self->{arrayref} }, $key, $_;
		}
	}
	$self->SUPER::param(@_);
}
sub delete {
	my $self = shift;
	my $arrayref = $self->{arrayref};
	for (my $i = 0; $i < @$arrayref; $i += 2) {
		if ($_[0] eq $arrayref->[$i]) {
			splice @$arrayref, $i, 2;
			$i -= 2;
		}
	}
	$self->SUPER::delete($_[0]);
}


package RayApp::Request::Params;
sub new {
	my $class = shift;
	my $self = {};
	if (not ref $_[0]) {
                die "second argument to RayApp::Request::Params::new has to be a reference\n";
        } elsif (ref $_[0] eq 'HASH') {
		$self->{obj} = new RayApp::Request::Params::Hashref($_[0]);
        } elsif (ref $_[0] eq 'ARRAY') {
		$self->{obj} = new RayApp::Request::Params::Arrayref($_[0]);
        } else {
                die "second argument to RayApp::Request::Params::new is unknown reference [@{[ ref $_[0] ]}]\n";
        }
	return bless $self, $class;
}
sub param {
	my $self = shift;
	$self->{obj}->param(@_);
}
sub delete {
	my $self = shift;
	$self->{obj}->delete(@_);
}

1;

