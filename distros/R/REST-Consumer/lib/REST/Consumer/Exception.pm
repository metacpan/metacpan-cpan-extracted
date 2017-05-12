package REST::Consumer::Exception;
use strict;
use warnings;

# an exception is always true
use overload bool => sub {1}, '""' => 'as_string', fallback => 1;

sub new {
	my ($class, %args) = @_;
	my $self = {
		request  => $args{request},
		response => $args{response},
		attempts => $args{attempts},
	};

	# get the immediate non-REST::Consumer caller
	# like Carp::croak for exception objects
	my ($package, $filename, $line) = caller;
	my $counter = 1;
	while ($package =~ /^REST::Consumer/) {
		($package, $filename, $line) = caller($counter++);
		last if $counter > 10;
	}

	$self->{_immediate_caller} = "$filename line $line";

	return bless $self, $class;
}

sub request { return shift->{request} }

sub response { return shift->{response} }

sub throw {
	my $class = shift;
	die $class->new(@_);
}

# as_string is an abstract method
# implemented by this class's descendants

1;
