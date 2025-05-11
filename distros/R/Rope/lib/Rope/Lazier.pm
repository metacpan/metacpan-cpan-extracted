package Rope::Lazier;

use strict; use warnings;
use Types::Standard;
use Rope::Pro;

my (%PRO);

BEGIN {
	%PRO = Rope::Pro->new(
		function_map => {
			pro => 'prototyped',
			prop => 'property',
			props => 'properties',
			fun => 'function',
			pri => 'private',
			ro => 'readonly',
			ar => 'around',
			af => 'after',
			be => 'before'
		},
		property_map => {
			v => 'value',
			i => 'initable',
			w => 'writeable',
			c => 'configurable',
			e => 'enumerable',
			p => 'private',
			o => 'readonly',
			r => 'required',
			t => 'type',
			b => 'builder',
			tr => 'trigger',
			dtr => 'delete_trigger',
			pr => 'predicate',
			cl => 'clearer',
			hv => 'handles_via',
			h => 'handles'
		}
	);
}

sub import {
	my ($caller, $pkg, @props) = (scalar caller, @_);

	@props = (keys(%{$PRO{property_map}}), keys(%{$PRO{function_map}})) if (! scalar @props);

	for my $p (@props) {
		if ($PRO{property_map}{$p}) { 
			$PRO{keyword}($caller, $p, sub {
				my ($param) = @_;
				return ($PRO{property_map}{$p} => ($param // 1));
			});
		} elsif ($PRO{function_map}{$p}) {
			$PRO{keyword}($caller, $p, sub {
				my (@params) = @_;
				my $meth = $PRO{function_map}{$p};
				$caller->$meth(@params);
			});
		}
	}
}

1;

__END__

=head1 NAME

Rope::Lazier - Rope done lazier

=head1 VERSION

Version 0.43

=cut

=head1 SYNOPSIS

	package Knot;

	use Rope;
	use Rope::Lazier qw/prop fun v c e t/
	use Types::Standard qw/Int/;
	
	prop loops => (v(1), c, t(Int));
	prop [qw/hitches bends/] => (v(10), c, e, t(Int));

	fun add_loops => sub {
		my ($self, $loop) = @_;
		$self->{loops} += int->($loop);
	};

	1;

...

	my $k = Knot->new();

	say $k->{loops}; # 1;

	$k->{loops} = 'kaput'; # errors as Str is not an Int


=head1 Exports

=cut

=head2 pro

prototyped

=cut

=head2 prop

property

=cut

=head2 props

properties

=cut

=head2 fun

function

=head2 pri

private

=head2 ro

readonly

=cut

=head2 be

before

=cut

=head2 ar

around

=cut

=head2 af

after

=cut

=head2 v

value

=head2 i

initable

=head2 w

writeable

=head2 c

configurable

=head2 e

enumerable

=head2 p

private

=head2 o

readonly

=head2 r

required

=head2 t

type

=head2 b

builder

=head2 tr

trigger

=head2 dtr

delete_trigger

=head2 pr

predicate

=head2 cl

clearer

=head2 hv

handles_via

=head2 h

handles

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
