package MooX::Keyword::Factory;

use 5.006; use strict; use warnings; our $VERSION = '1.01';
use Factory::Sub; use Moo;

our %FACTORY;

use MooX::Keyword {
	factory => {
		builder => sub {
			my ($moo, $name, @args) = @_;
			if (! $FACTORY{$name}) {
				$moo->has($name, is => 'rw');
				$moo->around($name, sub {
					my ($orig, $self, @args) = @_;
					$self->$orig(scalar @args ? $FACTORY{$name}->(@args) : ());
				});
				$FACTORY{$name} = Factory::Sub->new();
			}
			$FACTORY{$name}->add(@args);
		}
	}
};

1;

__END__

=head1 NAME

MooX::Keyword::Factory - Moo attribute factories

=head1 VERSION

Version 1.01

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

	package Factory;

	use Moo;
	use MooX::Keyword extends => '+Factory';
	use My::Type::Library qw/Name Email Phone PostCode/

	factory worker => Name, Email, sub {
		...
		return 2;
	};

	factory worker => Name, Email, Phone, sub {
		...
		return 3;
	};

	factory worker => Name, Email, PostCode, sub {
		...
		return 3;
	};

	factory worker => Name, Email, Phone, PostCode, sub {
		...
		return 4;
	};

	1;

	...

	my $factory = Factory->new();

	$factory->worker($name, $email); # 2
	$factory->worker($name, $email, $phone); # 3
	$factory->worker($name, $email, $postcode); # 3 
	$factory->worker($name, $email, $phone, $postcode); # 4

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moox-keyword-factory at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooX-Keyword-Factory>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc MooX::Keyword::Factory

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-Keyword-Factory>

=item * Search CPAN

L<https://metacpan.org/release/MooX-Keyword-Factory>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022->2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of MooX::Keyword::Factory
