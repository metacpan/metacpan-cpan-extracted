package Pod::CopyrightYears;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use Pod::Abstract;
use String::UpdateYears qw(update_years);

our $VERSION = 0.02;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Pod file to update.
	$self->{'pod_file'} = undef;

	# Section names to update.
	$self->{'section_names'} = [
		'LICENSE AND COPYRIGHT',
	];

	# Process parameters.
	set_params($self, @params);

	if (! defined $self->{'pod_file'}) {
		err "Parameter 'pod_file' is required.";
	}
	$self->{'pod_abstract'} = Pod::Abstract->load_file($self->{'pod_file'});

	return $self;
}

sub change_years {
	my ($self, $year) = @_;

	if (! defined $year) {
		$year = (localtime(time))[5] + 1900;
	}

	foreach my $pod_node ($self->license_sections) {
		$self->_iterate_node($pod_node, $year);
	}

	return;
}

sub license_sections {
	my $self = shift;

	my @pod_nodes;
	foreach my $section (@{$self->{'section_names'}}) {
		my ($pod_node) = $self->{'pod_abstract'}->select('/head1[@heading =~ {'.$section.'}]');
		if (defined $pod_node) {
			push @pod_nodes, $pod_node;
		}
	}

	return @pod_nodes;
}

sub pod {
	my $self = shift;

	my $pod = $self->{'pod_abstract'}->pod;
	chomp $pod;
	my $ret = $pod;
	if ($pod =~ m/=cut\s+$/ms) {
		$ret = substr $pod, 0, -2;
		$ret .= "\n";
	} else {
		$ret .= "\n";
	}

	return $ret;
}

sub _iterate_node {
	my ($self, $pod_node, $year) = @_;

	if (defined $pod_node->children) {
		foreach my $child ($pod_node->children) {
			if ($child->type eq ':text') {
				$self->_change_years($child, $year);
			} else {
				$self->_iterate_node($child, $year);
			}
		}
	}

	return;
}

sub _change_years {
	my ($self, $pod_node, $year) = @_;

	my $text = $pod_node->pod;
	my $updated = update_years($text, {}, $year);
	if ($updated) {
		$pod_node->body($updated);
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Pod::CopyrightYears - Object for copyright years changing in POD.

=head1 SYNOPSIS

 use Pod::CopyrightYears;

 my $obj = Pod::CopyrightYears->new(%params);
 $obj->change_years($last_year);
 my @pod_nodes = $obj->license_sections;
 my $pod = $obj->pod;

=head1 METHODS

=head2 C<new>

 my $obj = Pod::CopyrightYears->new(%params);

Constructor.

=over 8

=item * C<pod_file>

POD or Perl module file to process.

It's required parameter.

=item * C<section_names>

List of POD C<=head1> section names

=back

Returns instance of object.

=head2 C<change_years>

 $obj->change_years($last_year);

Change year in text sections. Matches C<\d{4}> or C<\d{4}-\d{4}> strings.

Returns undef.

=head2 C<license_sections>

 my @pod_nodes = $obj->license_sections;

Get Pod::Abstract::Node nodes which match C<section_names> parameter.

Returns list of nodes.

=head2 C<pod>

 my $pod = $obj->pod;

Serialize object to Perl module or POD output.

Returns string.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.
         Parameter 'pod_file' is required.

=head1 EXAMPLE

=for comment filename=update_copyright_years.pl

 use strict;
 use warnings;

 use File::Temp;
 use IO::Barf qw(barf);
 use Pod::CopyrightYears;

 my $content = <<'END';
 package Example;
 1;
 __END__
 =pod

 =head1 LICENSE AND COPYRIGHT

 © 1977 Michal Josef Špaček

 =cut
 END

 # Temporary file.
 my $temp_file = File::Temp->new->filename;

 # Barf out.
 barf($temp_file, $content);

 # Object.
 my $obj = Pod::CopyrightYears->new(
         'pod_file' => $temp_file,
 );

 # Change years.
 $obj->change_years(1987);

 # Print out.
 print $obj->pod;

 # Unlink temporary file.
 unlink $temp_file;

 # Output:
 # package Example;
 # 1;
 # __END__
 # =pod
 # 
 # =head1 LICENSE AND COPYRIGHT
 # 
 # © 1977-1987 Michal Josef Špaček
 # 
 # =cut

=head1 SEE ALSO

=over

=item L<perl-module-copyright-years>

Tool for update copyright years in Perl distribution.

=item L<App::Perl::Module::CopyrightYears>

Base class for perl-module-copyright-years tool.

=back

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<Pod::Abstract>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Pod-CopyrightYears>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
