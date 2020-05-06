package Module::Generate::Hash;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.06';

use Module::Generate;
use base 'Import::Export';

our %EX = (
	generate => [qw/all/]
);

sub generate {
	my (%generate) = scalar @_ > 1 ? @_ : %{$_[0]};
	my $gen = Module::Generate->start;
	$generate{$_} && $gen->$_($generate{$_})
		for (qw/dist lib author email version/);
	_build_classes($gen, $generate{classes});
	$gen->generate;	
}

sub _build_classes {
	my ($gen, $classes, $mod) = @_;
	for my $class (keys %{$classes}) {
		my $kls = $mod ? do {
			$classes->{$class}{base} = $classes->{$class}{base} ? [
				(ref $classes->{$class}{base} ? @{$classes->{$class}{base}} : $classes->{$class}{base}),
				$mod
			] : $mod;
			sprintf( '%s::%s', $mod, $class );
		} : $class;
		my ($cls, $new, $subs, $accessors, $subclass) = (
			$gen->class($kls)->new,
			delete $classes->{$class}{new},
			delete $classes->{$class}{subs},
			delete $classes->{$class}{accessors},
			delete $classes->{$class}{subclass}
		);
		_itterate_keys($cls, $classes->{$class});
		_itterate_keys($cls, $new);
		$cls->accessor($_) for (@{$accessors});
		while (scalar @{$subs}) {
			my ($key, $value) = (shift @{$subs}, shift @{$subs});
			my $sub = $cls->sub($key);
			_itterate_keys($sub, $value);
		}
		_build_classes($gen, $subclass, $kls) if ($subclass);
	}
}

sub _itterate_keys {
	my ($m, $value) = @_;
	for my $key (keys %{$value}) {
		my $ref = ref $value->{$key} || "SCALAR";
		$m->$key(
			$ref eq 'ARRAY'
				? @{$value->{$key}}
				: $value->{$key}
		);
	}
}

=head1 NAME

Module::Generate::Hash - Assisting with module generation.

=head1 VERSION

Version 0.06

=cut

=head1 SYNOPSIS

	use Module::Generate::Hash qw/all/;

	generate(
		dist => 'Planes',
		author => 'LNATION',
		email => 'email@lnation.org',
		version => '0.01',
		classes => {
			Planes => {
				abstract => 'Over my head.',
				our => '$type',
				begin => sub {
					$type = 'boeing';
				},
				accessors => [qw/
					airline
				/],
				subs => [	
					type => {
						code => sub { $type },
						pod => 'Returns the type of plane.',
						example => '$plane->type'
					},
					altitude => {
						code => sub {
							$_[1] / $_[2];
							...
						},
						pod => 'Discover the altitude of the plane.',
						example => '$plane->altitude(100, 100)'
					}
				]
			}
		}
	);

=head1 Exports

=head2 generate

This module exports a single method generate which accepts a hash that is a distribution specification.

	generate(%spec);

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-module-generate-hash at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Generate-Hash>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Module::Generate::Hash


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Generate-Hash>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Module-Generate-Hash>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Module-Generate-Hash>

=item * Search CPAN

L<https://metacpan.org/release/Module-Generate-Hash>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Module::Generate::Hash
