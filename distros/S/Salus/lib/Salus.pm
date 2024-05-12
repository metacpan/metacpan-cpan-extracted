package Salus;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.07';

use Salus::Header;
use Salus::Table;

my (%PRO, %META);
BEGIN {
	%PRO = (
		keyword => sub {
			no strict 'refs';
			my ($caller, $keyword, $cb) = @_;
			*{"${caller}::${keyword}"} = $cb;
		},
		clone => sub {
                        my $obj = shift;
                        my $ref = ref $obj;
                        return $obj if !$ref;
                        return [ map { $PRO{clone}->($_) } @{$obj} ] if $ref eq 'ARRAY';
                        return { map { $_ => $PRO{clone}->($obj->{$_}) } keys %{$obj} } if $ref eq 'HASH';
                        return $obj;
                }
	);
}

sub import {
	my ($pkg, %import) = @_;

	my $caller = caller();

	if (exists $import{header} ? $import{header} : $import{all}) {
		my ($index, %indexes) = (0, ());
		$PRO{keyword}($caller, 'header', sub {
			my ($name, %options) = @_;
			$options{name} = $name;
			push @{$META{$caller}{headers}}, \%options;
		});
	}

	if (exists $import{new} ? $import{new} : $import{all}) {
		$PRO{keyword}($caller, 'new', sub {
			my ($pkg, %options) = @_;
			__PACKAGE__->new($META{$caller}, \%options, $pkg);
		});
	}
}

sub new {
	my ($self, $meta, $options, $caller) = @_;
	
	$meta = $PRO{clone}($meta);

	my ($i, @headers, %properties) = (0, (), ());

	my %indexes = map {
		$_->{index} ? ($_->{index} => 1) : ()
	} @{ $meta->{headers} };

	for my $header (@{$meta->{headers}}) {
		while (1) {
			unless ($indexes{$i}) {
				$indexes{$i}++;
				$header->{index} = $i;		
				last;
			}
			++$i;
		}
		push @headers, Salus::Header->new(%{$header});
	}

	return Salus::Table->new(
		%{$options},
		headers => \@headers,
		rows => $meta->{rows} || []
	);
}

1;

__END__;

=head1 NAME

Salus - The great new Salus!

=head1 VERSION

Version 0.07

=cut

=head1 SYNOPSIS

	package Hacked::By::Corruption;

	use Salus all => 1;

	header id => (
		label => 'ID',
	);

	header firstName => (
		label => 'First Name',
	);

	header lastName => (
		label => 'Last Name',
	);

	header header => (
		label => 'Age',
	);

	1;

...

	my $unethical = Hacked::By::Corruption->new(
		file => 't/test.csv',
		unprotected_read => 1
	);

	$unethical->read();

	$unethical->write('t/test2.csv');

=head1 METHODS

=cut

=head2 new

	my $salus = Salus->new({
		headers => [
			{
				name => 'id',
				label => 'ID'
			},
			...
		]
	});

	$salus->add_rows([
		[1, 'Robert', 'Invisible', 32],
		[2, 'Jack', 'Joy', 33],
		[3, 'Pluto', 'Hades', 34]
	]);

	$salus->combine('t/test.csv', 'id');

	$salus->get_row(2)->as_array;

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-salus at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Salus>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Salus

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Salus>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Salus>

=item * Search CPAN

L<https://metacpan.org/release/Salus>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Salus
