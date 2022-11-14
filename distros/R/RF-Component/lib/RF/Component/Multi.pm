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

	if (grep { ref $_ ne 'RF::Component' } @components)
	{
		croak "All component objects must be RF::Component objects!"
	}

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
		my %data = rsnp_list_to_hash(@{ delete $snp->{_data} });
		my $comments = delete $snp->{_comments};

		my $c = RF::Component->new(%data,
			vars => $snp,
			($comments ? (comments => $comments) : () ) );
		
		push @ret, $c;
	}

	return $class->new(@ret);
}

sub save
{
	my ($self, $filename, %opts) = @_;

	my $vars = delete $opts{vars} // {};
	my $save_snp_opts = delete $opts{save_options} // {};

	my @mdif;

	# Foreach component in $self, build out an @mdif array:
	foreach my $c (@$self)
	{
		my %c_vars;

		# Populate component vars from any existing vars first,
		# these can be overriden below if specified in %opts{vars}.
		foreach my $var (keys %{ $c->{vars} // {} })
		{
			$c_vars{$var} = $c->{vars}{$var};
		}

		# Build the MDIF vars:
		foreach my $var (keys %$vars)
		{
			my $val_name = $vars->{$var};
			my $val;

			if (ref $val_name eq 'CODE')
			{
				$val = $val_name->($c);
			}
			elsif (!ref($val_name) && $RF::Component::valid_opts{$val_name})
			{
				$val = $c->{$val_name};
			}
			else
			{
				croak "save: invalid value name: $val_name";
			}

			$c_vars{$var} = $val;
		}

		$c_vars{_data} = [ $c->get_wsnp_list(%$save_snp_opts)  ];

		push @mdif, \%c_vars;
	}

	return wmdif($filename, \@mdif);
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

	# Build an object from existing components:
	$multi = RF::Component::Multi->new(@components);

	# Save to an MDF:
	$multi->save('mydata.mdf', vars => { pF => 'value' }, ...)

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

=head1 Constructor

The constructor is simple, it just takes an array of L<RF::Component> objects
and returns a blessed arrayref:

	$m = RF::Component::Multi->new($c1, $c2, ...);

=head1 IO Functions

=head2 C<RF::Component::Multi-E<gt>load> - Load a multiple-data file

Currently only MDIF files are supported, other formats are possible.  Usage:

	my $mdf = RF::Component::Multi->load($filename, %options);

=over 4

=item * The C<%options> hash is passed to L<RF::Component>'s C<load> function.

=item * If C<load_options> is provided in C<%options> then C<load_options> is
passed to L<PDL::IO::MDIF>'s C<rmdif> function.

=back

=head2 C<$self-E<gt>save> - Save a multiple-data file

	$mdif->save($filename, %opts)

=over 4

=item * C<$filename> - path to file to output file.

Currently only L<MDIF|PDL::IO::MDIF> files are supported.

=item * C<%opts> - Options:

=over 4

=item C<vars>: a hashref of arbitrary variable/value mappings:

Generically:
	{
		var1 => var_name1,
		var2 => sub { $_[0]->something }
	}

Since this is a multi-data format, the name C<var_name1> must be a valid field
in L<RF::Component>.  For example, you might specify C<{ pF =E<gt> 'value'}> to
use the C<"value"> field from the component if it was parsed at load time.

You may also use a coderef, in which case the L<RF::Component> object will
be passed to the function.  For example:

	vars => {
			component => sub {
				our $i //= 0;
				my $c = shift;
				my $t = "$i. $c->{value} $c->{value_unit} $c->{model}";
				$i++;
				return $t;
			}
		}

Would produce variables which may show in your EDA software like this:

	component="0. 0.1 pF GRM1555C1HR10WA01" [v]

which convieniently provdes the index number, value, and component model so it
is readable in your EDA software and you know what parts to order.

MDIF structure being written.  Each variable should uniquely identify a
component.  So far only single-variable MDIF files have been tested.  The
format supports multiple variables, but it isn't clear how EDA software
(like L<Microwave Office|https://www.cadence.com/en_US/home/tools/system-analysis/rf-microwave-design/awr-microwave-office.html>)
will handle the extra variables.  Please send me an email with commentary if
you know what (if anything) should be done here!  See the MDIF format
specification linked below.

=item C<save_options>: These options are passed to
L<RF::Component-E<gt>get_wsnp_list|RF::Component> when generating to array
structure expected by L<wmdif|PDL::IO::MDIF>.

=back

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
