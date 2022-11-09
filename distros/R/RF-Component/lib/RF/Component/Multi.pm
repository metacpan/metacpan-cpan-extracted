package RF::Component::Multi;

use RF::Component; $VERSION = $RF::Component::VERSION;

use strict;
use warnings;
use PDL::IO::Touchstone qw/rsnp_list_to_hash/;
use PDL::IO::MDIF;
use Carp;
use 5.010;

sub new
{
	my ($class, @components) = @_;

	return bless(\@components, $class);
}

sub load
{
	my ($class, $filename, %newopts) = @_;

	my $rmdif_opts = delete $newopts{load_options};
	my $mdif_data = rmdif($filename, $rmdif_opts);

	my @ret;
	foreach my $snp (@$mdif_data)
	{
		my %data = rsnp_list_to_hash(@{ $snp->{_data} });

		my $c = RF::Component->new(%data);
		
		push @ret, $c;
	}

	return $class->new(@ret);
}

# Thanks @ikegami:
# https://stackoverflow.com/a/74229589/14055985
sub AUTOLOAD
{
	my $method_name = our $AUTOLOAD =~ s/^.*:://sr;

	my $method = sub {
		my $self = shift;
		return [ map { $_->$method_name(@_) } @$self ];
	};

	{
		no strict 'refs';
		*$method_name = $method;
	}

	goto &$method;
}

sub DESTROY {}

1;


__END__

=head1 NAME

RF::Component::Multi - Multi-element vectorized handling of L<RF::Component> objects.

=head1 DESCRIPTION

This module enables loading L<Measurement Data Interchange Format (MDIF)|PDL::IO::MDIF> files
and operating on each component them as a vector.  Each C<RF::Component::Multi>
object is a blessed arrayref containing a list of L<RF::Component> objects, so
you can use it as a normal array to get a particular component.  You can also
run L<RF::Component> methods on an C<RF::Component::Multi> object to return a
vector of results, one result for each L<RF::Component> object in the arrayref.

=head1 SYNOPSIS

	use RF::Component::Multi;

	# Load an MDIF file:
	my $mdf = RF::Component::Multi->load('t/test-data/muRata/muRata-GQM-0402.mdf',
			load_options => { freq_min_hz => 100e6, freq_count => 1 }
		);

	# Query a single component in the MDIF:
	my $component1 = $mdf->[1];
	print $component1->cap_pF;

	# Query all components in the MDF with a vectorized result:
	my $cap_pF = $mdf->cap_pF;

	# Print the result value (same as $component1->cap_pF, above):
	print $cap_pF->[1];

=head1 IO Functions

=head2 C<RF::Component::Multi-E<gt>load> - Load a multiple-data file

Currently only MDIF files are supported, other formats are possible.  Usage:

	my $mdf = RF::Component::Multi->load($filename, %options);

=over 4

=item * The C<%options> hash is passed to L<RF::Component>'s C<load> function.

=item * If C<load_options> is provided in C<%options> then C<load_options> is
passed to L<PDL::IO::MDIF>'s C<rmdif> function.

=back

=head1 SEE ALSO

=over 4

=item L<RF::Component> - An object-oriented encapsulation of C<PDL::IO::Touchstone>.

=item L<PDL::IO::MDIF> - A L<PDL> IO module to load Measurement Data Interchange Format (*.mdf) files.

=item Building MDIF/MDF files from multiple S2P files: L<https://youtu.be/q1ixcb_mgeM>, L<https://github.com/KJ7NLL/mdf/>

=item Optimizing amplifer impedance match circuits with MDF files: L<https://youtu.be/nx2jy7EHzxw>

=item MDIF file format: L<https://awrcorp.com/download/faq/english/docs/users_guide/data_file_formats.html#i489154>

=back

=head1 AUTHOR

Originally written at eWheeler, Inc. dba Linux Global Eric Wheeler to
transform .s2p files and build MDF files to optimize with Microwave Office
for amplifer impedance matches.


=head1 COPYRIGHT

Copyright (C) 2022 eWheeler, Inc. L<https://www.linuxglobal.com/>

This module is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation, either version 3 of the License, or (at your
option) any later version.

This module is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License along
with this module. If not, see <http://www.gnu.org/licenses/>.
