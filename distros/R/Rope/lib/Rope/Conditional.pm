package Rope::Conditional;

my (%PRO);

use Rope::Pro;
use Struct::Conditional;

BEGIN {
	%PRO = Rope::Pro->new;
}

sub import {
	my ($caller, $pkg) = (scalar caller);
	$PRO{keyword}($caller, 'conditional', sub {
		my ($name, %conditional) = @_;
		my ($meta, $class, $data) = (Rope->get_meta($caller), 'Struct::Conditional');

		if ($meta->{properties}->{$name}) {
			if ($meta->{properties}->{$name}->{conditional}) {
				Rope->clear_property($caller, $name);
			} else {
				die 'Cannot extend Object($caller) with a conditional property ($prop) as a property with that name is already defined';
			}
		}
		if (ref $_[1]) {
			$pkg = $class = $_[1]->[0] . '::Conditional';
			$pkg =~ s/\:\:/\//g;
			require $pkg . '.pm';
			$data = $_[1]->[1];
		}
		
		$caller->property($name,
			value => sub { shift; $class->new()->compile($data || \%conditional, @_, 1) },
			conditional => 1
		);
	});
}

1;

__END__

=head1 NAME

Rope::Conditional - Rope conditional properties

=head1 VERSION

Version 0.41

=cut

=head1 SYNOPSIS

	package Why::Not;

	use Rope;
	use Rope::Autoload;
	use Rope::Conditional;

	conditional data => (
		"not" => {
			"for" => {
				"key" => "why",
				"keys" => 1,
				"if" => {
					"m" => "test",
					"key" => "test",
					"then" => {
						"one" => 123
					}
				},
				"elsif" => {
					"m" => "other",
					"key" => "test",
					"then" => {
						"two" => 456
					}
				},
				"else" => {
					"then" => {
						"three" => 789
					}
				}
			},
			"four" => 123
		}
	);

	conditional json_data => ['JSON', 'path/to/file.json'];
	conditional yaml_data => ['YAML', 'path/to/file.yaml'];

	...

	1;

...

	my $k = Why::Not->new();

	say $k->data({
		why => { 
			a => { test => "other" },
			b => { test => "test" },
			c => { test => "other" },
			d => { test => "thing" },
		}
	}); 

	# not => {
        #	a => { two => 456 },
        #	b => { one => 123 },
        #	c => { two => 456 },
        #	d => { three => 789 },
       	#	def => 123
        # }


=head1 DESCRIPTION

Rope::Conditional extends rope with a conditional keyword which can be used to generate dynamic data based upon the passed in parameters, yes you could do all of this directly via a sub, but you only live once, right?

see L<Struct::Conditional> for more information on the supported struct

=cut

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
