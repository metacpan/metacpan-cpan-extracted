package Sub::Conveyor;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.03';

sub new {
	my ($self) = shift;
	$self = bless {
		conveyor => [ ]
	}, ref $self || $self; 
	while (@_) {
		my ($type, $cb) = (shift, shift);
		$self->add(@{$type}, $cb);
	}
	return $self;
}

sub add {
	my ($self, @args) = @_;
	my $cb = pop @args;
	push @{$self->{conveyor}}, \@args, $cb;
}

sub call {
	my ($self, @params) = @_;
	my $len = scalar @{ $self->{conveyor} };
	for (my $i = 0; $i < $len; $i += 2) {
		my $conveyor_count = scalar @{ $self->{conveyor}->[$i] };
		if ( scalar @params == $conveyor_count ) {
			my $match = 1;
			for ( my $x = 0; $x < $conveyor_count; $x++ ) {
				eval {
					$self->{conveyor}->[$i]->[$x]->($params[$x])
				};
				if ($@) {
					$match = 0;
				}
			}
			if ($match) {
				@params = ($self->{conveyor}->[$i + 1]->(@params));
			}
		}
	}
	return wantarray ? @params : scalar @params == 1 ? $params[0] : \@params;
}

sub install {
	my ($self, $class, $method) = @_;
	no strict 'refs';
	no warnings 'redefine';
	*{"${class}::${method}"} = sub { shift; $self->call(@_) };
}

1;

__END__

=head1 NAME

Sub::Conveyor - Subroutine chaining with types

=head1 VERSION

Version 0.03

=cut

=head1 SYNOPSIS

	use Sub::Conveyor;
	use Types::Standard qw/Int StrMatch Any/;

	my $conveyor = Sub::Conveyor->new(
		[ Int ] => sub { return $_[0] },
		[ StrMatch[qr{^[a-zA-Z]+$}] ] => sub { return length $_[0] },
		[ Int ] => sub { return $_[0] / 2 },
	);

	$conveyor->add(Any, sub {
		return sprintf "The result is %s", $_[0];
	});
	
	$conveyor->call(100); # The result is 50
	$conveyor->call('Hello'); # The result is 2.5

	...

	$conveyor->install('Test', 'testing');

	Test->testing(100); # The result is 50


=head1 SUBROUTINES/METHODS

=head2 new

Instantiate a new L<Sub::Conveyor> chain.

	my $conveyor = Sub::Conveyor->new();

=cut

=head2 add

Add to the conveyor chain.

	$conveyor->add(Any, Str, Int, \&cb);

=cut

=head2 call

Call the conveyor chain.

	$conveyor->call(@params);

=cut

=head2 install

Install the conveyor chain into a package.

	$conveyor->install($package, $method);

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sub-conveyor at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sub-Conveyor>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Sub::Conveyor

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sub-Conveyor>

=item * Search CPAN

L<https://metacpan.org/release/Sub-Conveyor>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Sub::Conveyor
