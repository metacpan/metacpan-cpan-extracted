package Rope::Autoload;
use strict;
use warnings;
use Want;

my (%PRO);

BEGIN {
	%PRO = (
		keyword => sub {
			my ($caller, $method, $cb) = @_;
			no strict 'refs';
			*{"${caller}::${method}"} = $cb;
		}
	);
}

sub import {
	my ($pkg, $caller) = (shift, scalar(caller));
	$PRO{keyword}($caller, 'DESTROY', sub {}) unless ($caller->CORE::can('DESTROY'));
	$PRO{keyword}($caller, 'AUTOLOAD', sub :lvalue {
		my $self = shift;
		my $classname =  ref $self;
		my $validname = '[_a-zA-Z][\:a-zA-Z0-9_]*';
		our $AUTOLOAD =~ /^${classname}::($validname)$/;		
		my $key = $1;
		die "illegal key name, must be of $validname form\n$AUTOLOAD" unless $key;
		return $self->{$key}(@_) if !want(qw'LVALUE ASSIGN') && ref $self->{$key} eq 'CODE'; 
		$self->{$key} = $_[0] if defined $_[0];
		return $self->{$key};
	});
}

1;

=head1 NAME

Rope::Autoload - Rope Autoload!

=head1 VERSION

Version 0.36

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

	package Knot;

	use Rope;
	use Rope::Autoload;

	prototyped (
		loops => 1,
		hitches => 10,
		...

	);

	properties {
		bends => {
			type => sub { $_[0] =~ m/^\d+$/ ? $_[0] : die "$_[0] != integer" },
			value => 10,
			writeable => 0,
			configurable => 1,
			enumerable => 1,
		},
		...
	};

	function add_loops => sub {
		my ($self, $loop) = @_;
		$self->loops += $loop;
	};

	1;

...

	my $k = Knot->new();

	say $k->loops; # 1;

	$k->add_loops(5);

	say $k->loops; # 6;

	$k->hitches = 15;
	
	$k->add_loops = 5; # errors


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

1; # End of Rope::Autoload
