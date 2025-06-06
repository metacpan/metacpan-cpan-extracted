package MooX::Keyword;
use 5.006; use strict; use warnings; our $VERSION = '1.01'; 
use MooX::ReturnModifiers; use Anonymous::Object;

sub import {
	my ( $package, %import ) = (shift, ref $_[0] ? %{ $_[0] } : @_);
    	my $target = caller;
	my $moo = Anonymous::Object->new(object_name => 'MooX::Keyword')->hash_to_object_context({
		return_modifiers( $target )
	}); # *\o/*
	
	if ($import{extends}) {
		for my $extend ( ref $import{extends} ? @{ $import{extends} } : $import{extends} ) {
			$extend =~ s/^\+/MooX::Keyword::/;
			$moo->extends($extend);
			%import = (%import, $import{extends}->keyword_meta);	
		}
		delete $import{extends};
	}

	keyword($target, $moo, 'keyword_meta', { builder => sub {
		my $m = shift;
		return %import;
	}});
	keyword($target, $moo, $_, $import{$_}) for keys %import;
	
	return 1;
}

sub keyword {
	no strict 'refs';
	my ($target, $moo, $keyword, $params) = @_;
	die 'no builder for ${keyword}' unless $params->{builder};
	for ($keyword, $params->{alias} ? ref $params->{alias} ? @{ $params->{alias} } : $params->{alias} : ()) {
		*{"${target}::${_}"} = sub {
			$params->{builder}->($moo, @_);
		};
	}
}

1;

__END__

=head1 NAME

MooX::Keyword - define custom keywords in Moo.

=head1 VERSION

Version 1.01

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

	package Moon;

	use Moo;
	use MooX::Keyword {
		moon => {
			alias => 'star',
			builder => sub {
				shift->has(@_);
			}
		}
	};

	moon shine => (
		is => 'rw',
		default => sub { ... }
	);

	star light => (
		is => 'ro'
	);

	...

	my $moon = Moon->new(
		shine => 211,
		light => [{ ... }]
	);
	
	$moon->shine(633);
	$moon->light;

	...


=head1 Declaring a keyword

You can declare one or more keywords on import of MooX::Keyword by providing a hash where the keys are the keyword and values are an hashref of options that must contain a builder subroutine and may contain aliases for that keyword.

	package Sunset;

	use MooX::Keyword {
		sunset => {
			builder => sub {
				my ($moo, $class) = @_;
				$moo->extends($class);
			}
		},
		...
	};

=head1 Extending a package with keywords

You cannot use the traditional inheritance if you want to use keywords declared in another package, instead you need to pass extends when importing MooX::Keyword.

	package Night 

	use Moo;
	use MooX::Keyword extends => ["Moon", "Sunset"];

	sunset 'Day';

	star polaris  => (
		is => 'ro'
	);

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-moox-keyword at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooX-Keyword>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc MooX::Keyword


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-Keyword>

=item * Search CPAN

L<https://metacpan.org/release/MooX-Keyword>

=back

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022->2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of MooX::Keyword
