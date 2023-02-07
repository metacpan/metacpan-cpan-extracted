package Nefarious; 
use 5.006; use strict; use warnings;
use Factory::Sub; use Tie::IxHash; our %META;
our $VERSION = '0.03'; 

BEGIN {
	tie %META, 'Tie::IxHash';
}

sub import {
	my ($pkg, $nefarious) = @_;
	nefarious($nefarious);
}

sub nefarious {
	my ($nefarious) = @_;
	for my $package ( keys %{ $nefarious }) {
		parse_meta($package, $nefarious->{$package});	
	}
	create_packages();
}

sub parse_meta {
	my ($name, $package) = @_;
	$META{$name} = {} if (! $META{$name} );
	for my $key (keys %{ $package }) {
		my $ref = ref $package->{$key};
		if (!$ref) {
			if ($key eq 'EXTENDS') {
				$META{$name}{$key} = $package->{$key};
			} else {
				$META{$name}{$key} = sub { $package->{$key} };
			}
		} elsif ($ref eq 'CODE') {
			$META{$name}{$key} = $package->{$key};
		} elsif ($ref eq 'ARRAY') {
			my $factory = Factory::Sub->new();
			for my $fact (reverse @{ $package->{$key} }) {
				$factory->add(ref $fact eq 'ARRAY' ? @{ $fact } : $fact);
			}	
			$META{$name}{$key} = sub { shift; return $factory->(@_) };
		} elsif ($ref eq 'HASH') {
			$package->{$key}->{EXTENDS} = $name;
			parse_meta($key, $package->{$key});
		}
	}
}

sub create_packages {
	for my $pkg ( keys %META ) {
		create_package($pkg, $META{$pkg});
	}
}


sub create_package {
	my ($name, $package) = @_;
	my $extends = delete $package->{EXTENDS} || "";
	$extends = qq|use base '$extends';| if ($extends);
	$package->{new} = sub { bless {}, $name } if (! $package->{new});
	my $p = qq|
		package $name;
		use strict;
		use warnings;
		$extends
		1;
	|;
	eval $p;
	no strict 'refs';
	for my $method (keys %{$package}) {
		*{"${name}::$method"} = $package->{$method};
	}
}

1;

__END__

=head1 NAME

Nefarious - wicked or criminal objects.

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

	use Nefarious {
		Good => {
			fictional => 'Churchill',
			Evil => {
				character => 'Hitler',
				Myself => {
					contract => 'Not Found',
					runners => 'Innocent',
					eyes => 'Everywhere',
				}
			}
		}
	};

    	my $lnation = Myself->new();
	$lnation->contract(); # Not Found

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-nefarious at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Nefarious>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Nefarious

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Nefarious>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Nefarious>

=item * Search CPAN

L<https://metacpan.org/release/Nefarious>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
