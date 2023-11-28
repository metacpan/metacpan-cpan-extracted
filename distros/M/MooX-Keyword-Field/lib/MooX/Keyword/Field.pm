package MooX::Keyword::Field;

use 5.006; use strict; use warnings; our $VERSION = '0.03';
use Moo;

our %FIELDS;

use MooX::Keyword {
	field => {
		builder => sub {
			my ($moo, $name, @args) = @_;
			$moo->around('BUILDARGS', sub {
				my ($orig, $self, @args) = @_;
				my %args = scalar @args > 1 ? @args : %{$args[0] || {}};
				for (keys %args) {
					delete $args{$_} if $FIELDS{$_};
				}			
				$self->$orig(\%args);
			}) if ! keys %FIELDS;
			if (! $FIELDS{$name} ) {
				$moo->has($name, is => 'ro', @args);
				$FIELDS{$name} = 1;
			}
		}
	}
};

1;

__END__

=head1 NAME

MooX::Keyword::Field - field attributes that cannot be set via the constructor

=head1 VERSION

Version 0.03

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

	package Persona;

	use Moo;
	use MooX::Keyword extends => '+Field', param => {
		builder => sub {
			shift->has(shift, is => 'rw', @_);
		}
	};

	param "name";
	param "title"

	field created => ( # by default ro
		builder => sub {
			time;
		}
	);

	...

	my $persona = Persona->new({
		name => $name,
		title => $title,
		created => $sometime # won't get set here
	});

	$persona->created;

=head1 DESCRIPTION

This module simply adds a field keyword which effectively only creates a read only attribute.

=head1 KEYWORDS

=head2 field

Creates a read only attribute.

	field created => (
		builder => sub {
			time;
		}
	);

The behaviour is identical to the following Moo code.

	has created => (
		is => 'ro',
		builder => sub {
			time;
		}
	);

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moox-keyword-field at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooX-Keyword-Field>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc MooX::Keyword::Field

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-Keyword-Field>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/MooX-Keyword-Field>

=item * Search CPAN

L<https://metacpan.org/release/MooX-Keyword-Field>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of MooX::Keyword::Field
