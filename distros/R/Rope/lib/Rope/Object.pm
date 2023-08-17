package Rope::Object;

use strict;
use warnings;

sub TIEHASH {
        my ($class, $obj) = @_;
        my $self = bless $obj || {}, $class;
	$self->compile();
	return $self;
}

sub compile {
	my ($self) = @_;
	$self->{keys} = scalar keys %{$self->{properties}};
	$self->{sort_keys} = [sort {
		$self->{properties}->{$a}->{index} <=> $self->{properties}->{$b}->{index}
	} grep { $self->{properties}->{$_}->{enumerable} } keys %{$self->{properties}}];
	return $self;
}
 
sub STORE {
        my ($self, $key, $value) = @_;
        my $k = $self->{properties}->{$key};
        if ($k) {
		if ($k->{writable}) {
                	$k->{value} = $value;
		} elsif ($k->{configurable}) {
			if ((ref($value) || "") eq (ref($k->{value}) || "")) {
				$k->{value} = $value;
			} else {
				die "Cannot change Object ($self->{name}) property ($key) type";
			}
		} else {
			die "Cannot set Object ($self->{name}) property ($key) it is only readable";
		}
        } elsif (! $self->{locked}) {
                $self->{properties}->{$key} = {
                        value => $value,
			writable => 1,
			configurable => 1,
			enumerable => 1,
			index => ++$self->{keys}
                };
		push @{$self->{sort_keys}}, $key;
        } else {
		die "Object ($self->{name}) is locked you cannot extend with new properties";
	}
        return $self;
}
 
sub FETCH {
        my ($self, $key) = @_;
        my $k = $self->{properties}->{$key};
        return $k ? $k->{value} : undef;
}
 
sub FIRSTKEY {
	goto &NEXTKEY;
}
 
sub NEXTKEY {
	return (each @{$_[0]->{sort_keys}})[1];
}
 
sub EXISTS {
       	exists $_[0]->{properties}->{$_[1]};
}
 
sub DELETE { 
        my $k = $_[0]->{properties}->{$_[1]};
        my $del = !$_[0]->{locked} && $k->{writeable} ? delete $_[0]->{properties}->{$_[1]} : undef;
	$_[0]->compile() if $del;
	return $del;
}
 
sub CLEAR {
	return;
        #%{$_[0]->{properties}} = () 
}
 
sub SCALAR { 
        scalar keys %{$_[0]->{properties}}
}

1;

__END__ 
