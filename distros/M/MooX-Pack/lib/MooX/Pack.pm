package MooX::Pack;

use strict;
use warnings;
use Carp qw/croak/;
use MooX::ReturnModifiers;

our $VERSION = '0.04';

sub import {
	my ( $self, @import ) = @_;
	my $target = caller;
	my %modifiers = return_modifiers($target);
	$modifiers{has}->( 'target' => ( is => 'ro', lazy => 1, default => sub { return $target; } ) );
	my ($spec, $aspec, $index) = ({}, undef, 0);
	{ no strict 'refs'; *{"${target}::line"} = sub {
		my ( $name, %attributes ) = @_;
		if (!$spec->{$name}) { 
			$spec->{$name}->{spec} = [];
			$spec->{$name}->{index} = $index++;
		}
		push @{ $spec->{$name}->{spec} }, \%attributes;
	}; }
	{ no strict 'refs'; *{"${target}::seperator"} = sub {
		my ( %attributes ) = @_;
		$aspec = \%attributes;
	}; }
	$modifiers{with}->('MooX::Pack::Base');
	$modifiers{sub}->(
		"_build_line_spec" => sub {
			my ( $orig, $self ) = ( shift, shift );
			return $spec;
		}
	);
	$modifiers{sub}->(
		"_build_all_spec" => sub {
			my ( $orig, $self ) = ( shift, shift );
			return $aspec;
		}
	);
}

1;

__END__

=head1 NAME

MooX::Pack - The great new MooX::Pack!

=head1 VERSION

Version 0.04

=cut

=head1 SYNOPSIS

	package Memory::Test;

	use Moo;
	use MooX::Pack;

	seperator (
		character => 'x',
		pack => '|',
	);
		
	line heading => (
		key => 'data',
		character => 'A10',
		catch => 1,
	);

	line heading => (
		name => 'description',
		character => 'A27',
		catch => 1,
	);

	line heading => (
		name => 'income',
		character => 'A7',
		catch => 1,
	);

	line rest => (
		name => 'first name',
		character => 'A20',
		catch => 1,
		index => 4,
	);

	line rest => (
		key => 'last name',
		character => 'A20',
		catch => 1,
		index => 0,
	);

	line rest => (
		name => 'age',
		character => 'A3',
		catch => 1,
		index => 2,
	);

...

	my $memory = Memory::Test->new();

	$memory->raw_data(
q{
Public    |Property                   |NA     
Robert              |Acock               |32 
}
	);

	$memory->unpack;

	$memory->data;

=cut

=head1 AUTHOR

lnation, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-number-iterator at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=MooX-Pack>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooX::Pack

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-Pack>

=item * Search CPAN

L<https://metacpan.org/release/MooX-Pack>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024->2025 by lnation.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


