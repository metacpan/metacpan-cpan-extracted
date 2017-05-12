package Net::RRP::Lite::Response;

use strict;

sub new {
    my($class, $raw_data) = @_;
    my $self = bless {
	_code => 0,
	_message => '',
	_param => {},
    }, $class;
    $self->_initialize($raw_data);
    return $self;
}

sub _initialize {
    my($self, $raw_data) = @_;
    my @lines = split(/\r\n/, $raw_data);
    my $status_line = shift @lines;
    my($code, $message) = $status_line =~ m/^(\d+)\s+(.*)$/;
    $self->code($code);
    $self->message($message);
    my %vars;
    for my $line(@lines) {
	my($key, $val) = split(/\s*:\s*/, $line, 2);
	unless ($vars{lc($key)}) {
	    $vars{lc($key)} = $val
	}
	elsif (ref($vars{lc($key)}) eq 'ARRAY') {
	    push @{$vars{lc($key)}}, $val;
	} 
	else{
	    $vars{lc($key)} = [ $vars{lc($key)} ];
	    push @{$vars{lc($key)}}, $val;
	}
    }
    $self->{_param} = \%vars;
    return $self;
}

sub param {
    my $self = shift;
    if (@_ == 0) {
        return keys %{$self->{_param}};
    }
    elsif (@_ == 1) {
	my $key = lc($_[0]);
	$key =~ s/_/ /g;
	if (ref($self->{_param}->{$key}) eq 'ARRAY') {
	    return wantarray ? @{$self->{_param}->{$key}} : $self->{_param}->{$key};
	}
        return $self->{_param}->{$key};
    }
    else {
        $self->{_param}->{$_[0]} = $_[1];
    }
}

sub code {
    my($self, $code) = @_;
    $self->{_code} = $code if $code;
    return $self->{_code};
}

sub message {
    my($self, $message) = @_;
    $self->{_message} = $message if $message;
    return $self->{_message};
}

1;

__END__
