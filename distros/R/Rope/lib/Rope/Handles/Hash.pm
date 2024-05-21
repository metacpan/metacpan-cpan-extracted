package Rope::Handles::Hash;

use strict;
use warnings;
use Hash::Util qw/unlock_hash lock_hash/;

sub new {
	my $class = shift;
	bless ref $_[0] ? $_[0] : {@_}, __PACKAGE__;
}

sub length {
	my ($self) = @_;
	return scalar keys %{$self};
}

sub get {
	my ($self, $key) = @_;
	return $self->{$key};
}

sub set {
	my ($self, $key, $val) = @_;
	$self->{$key} = $val;
	return $self;
}

sub delete {
	my ($self, $key) = @_;
	delete $self->{$key};
	return $self;
}

sub clear {
	my ($self) = @_;
	%{$self} = ();
	return $self;
}

sub assign {
	my ($self, @data) = @_;

	for my $d (@data) {
		for my $k (keys %{ $d }) {
			$self->{$k} = $d->{$k};
		}
	}

	return $self;
}

sub each {
	my ($self, $code) = @_;
	my @out;
	for my $key (sort keys %{$self}) {
		my $value = $self->{$key};
		push @out, $code->($key, $value);
	}
	return @out;
}

sub entries { goto &each; }

sub keys {
	my ($self) = @_;
	return sort keys %{$self};
}

sub values {
	my ($self) = @_;
	return sort values %{$self};
}

sub freeze {
	lock_hash(%{$_[0]});
	$_[0];
}

sub unfreeze {
	unlock_hash(%{$_[0]});
	$_[0];
}

1;

__END__

=head1 NAME

Rope::Handles::Hash - Rope handles hashes

=head1 VERSION

Version 0.36

=cut

=head1 SYNOPSIS

	package Church;

	use Rope;
	use Rope::Autoload;

	property singular => (
		initable => 1,
		handles_via => 'Rope::Handles::Hash'
	);

	property plural => (
		initable => 1,
		handles_via => 'Rope::Handles::Hash',
		handles => {
			get_thing => 'get',
			set_thing => 'set',
			assign_thing => 'assign',
			length_thing => 'length'
		}
	);

	...

=head1 METHODS

=head2 length

=head2 get

=head2 set

=head2 delete

=head2 clear

=head2 assign

=head2 each

=head2 entries

=head2 keys

=head2 values

=head2 freeze

=head2 unfreeze


=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rope at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Rope>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Rope

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Rope>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Rope>

=item * Search CPAN

L<https://metacpan.org/release/Rope>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

