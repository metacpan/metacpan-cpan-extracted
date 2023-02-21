package Mockery;
use 5.006; use strict; use warnings;
our $VERSION = '0.01';

sub new {
	return bless $_[1] || {}, $_[0];
}

sub action {
	my ($self, %mockery) = @_;
	{
		no strict 'refs';
		no warnings 'redefine';
		for (keys %{ $mockery{methods} }) {
			*{"$mockery{class}::$_"} = $mockery{methods}{$_};
		}
	
	}
}

sub fake {
	my ($self, %mockery) = @_;
	my $module = qq{
		package $mockery{class};
		use strict;
		use warnings;
		sub new {
			bless \$_[1] || {}, \$_[0];
		}
		1;
	};
	eval $module;
	die $@ if $@;
	$self->action(%mockery);
	return $mockery{class};
}

sub true {
	my ($self, %mockery) = @_;
	my @methods = @{$mockery{methods}};
	$mockery{methods} = {};
	my $sub = sub { return 1; };
	for (@methods) {
		$mockery{methods}{$_} = $sub;
	}
	$_[0]->action(%mockery);
}

sub false {
	my ($self, %mockery) = @_;
	my @methods = @{$mockery{methods}};
	$mockery{methods} = {};
	my $sub = sub { return 0; };
	for (@methods) {
		$mockery{methods}{$_} = $sub;
	}
	$_[0]->action(%mockery);
}


1;

__END__

=head1 NAME

Mockery - Mock objects for testing purposes

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

	use Mockery;

    	my $mockery = Mockery->new();

	$mockery->action(
		class => 'Nefarious',
		methods => {
			nefarious => sub {
				...
				return $nefarious;
			}
		}
	);
	
	Nefarious->new(...)->nefarious(...); # nefarious

	$mockery->fake(
		class => 'Heinous',
		methods => {
			heinous => sub {
				...
				return $heinous;
			},
			...
		}
	);

	Heinous->new->heinous(...); # $heinous

	$mockery->true(
		class => 'Nefarious',
		methods => ['Nefarious', ...]
	);

	Nefarious->new(...)->nefarious(...); # 1

	$mockery->false(
		class => 'Heinous',
		methods => ['heinous', ...]
	);

	Heinous->new->heinous(...); # 0

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mockery at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mockery>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mockery


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Mockery>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Mockery>

=item * Search CPAN

L<https://metacpan.org/release/Mockery>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Mockery
