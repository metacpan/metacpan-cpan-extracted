package MooX::Readonly::Attribute;

use 5.006; use strict; use warnings; our $VERSION = '1.00';
use Const::XS qw/make_readonly/;
use MooX::ReturnModifiers;

sub import {
        my $target    = caller;
        my %modifiers = return_modifiers( $target, [qw/before around/] );
        $modifiers{around}->(
                'has',
                sub {
                        my ( $orig, $attr, %opts ) = @_;
                        if (delete $opts{readonly}) {
				if ($opts{coerce}) {
					my $coerce = $opts{coerce};
					$opts{coerce} = sub { my $val = $coerce->(@_); make_readonly($val); $val };
				} else {
					$opts{coerce} = sub { make_readonly($_[0]); $_[0] };
				}
			}
                        $orig->( $attr, %opts );
                }
        );
}
1;


1;

__END__

=head1 NAME

MooX::Readonly::Attribute - Truly readonly attributes

=head1 VERSION

Version 1.00

=cut

=head1 SYNOPSIS

	package Test;

	use Moo;
	use MooX::Readonly::Attribute;

	has hash => (
		is => 'ro',
		readonly => 1,
	);

	has array => (
		is => 'rw',
		readonly => 1,
	);

	1;

...

	my $test = Test->new(
		hash => { a => 1, b => 2, c => 3 },
		array => [ 1, 2, 3 ]
	);

	$test->hash->{a}; # 1
	$test->array->[0]; # 1

	$test->hash->{d}; # errors readonly
	push @{ $test->array }, 4; # errors readonly

	$test->array([4, 5, 6]); 
	$test->array->[0]; # 4
	$test->array->[0] = 1; # errors readonly


=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moox-readonly-attribute at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooX-Readonly-Attribute>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooX::Readonly::Attribute


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-Readonly-Attribute>

=item * Search CPAN

L<https://metacpan.org/release/MooX-Readonly-Attribute>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of MooX::Readonly::Attribute
