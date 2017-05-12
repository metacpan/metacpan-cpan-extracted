package Perl::Dist::WiX::Mixin::ReleaseNotes;

=pod

=head1 NAME

Perl::Dist::WiX::Mixin::ReleaseNotes - Creates accessory files.

=head1 VERSION

This document describes Perl::Dist::WiX::Mixin::ReleaseNotes version 1.500.

=head1 DESCRIPTION

This module provides the routines that Perl::Dist::WiX uses in order to
make the distributions.txt and the release notes files.  

=head1 SYNOPSIS

	# This module is not to be used independently.
	# It provides methods to be called on a Perl::Dist::WiX object.

=head1 INTERFACE

=cut

use 5.010;
use Moose;
use English qw( -no_match_vars );
use File::Spec::Functions qw( catfile );
require IO::File;
require File::List::Object;

our $VERSION = '1.500';
$VERSION =~ s/_//ms;



=head2 release_notes_filename

The C<release_notes_filename> method returns the name of the release 
notes framework file.

=cut



sub release_notes_filename {
	my $self = shift;
	my $filename =
	    $self->perl_version_human() . q{.}
	  . $self->build_number()
	  . ( $self->beta_number() ? '.beta.' . $self->beta_number() : q{} )
	  . '.html';

	return $filename;
}



=head2 create_release_notes

The C<create_release_notes> method creates the framework file for the 
release notes to upload to a web site.

=cut



sub _get_cpan_link {
	my $self = shift;
	my $dist = shift;

	# If we're already a link, then return that.
	return $dist if ( $dist =~ m{\A http (?:s)? :}msx );

	# Otherwise, convert to a CPAN link.
	my $one = substr $dist, 0, 1;
	my $two = substr $dist, 1, 1;
	my $path =
	  File::Spec::Unix->catfile( 'authors', 'id', $one, "$one$two", $dist,
	  );
	return URI->new_abs( $path, 'http://search.cpan.org/CPAN/' )->as_string;

} ## end sub _get_cpan_link

sub create_release_notes {
	my $self = shift;
	my $dist_list;
	my ( $name, $ver, $link );

	foreach my $dist ( $self->_get_distributions() ) {
		$link = $self->_get_cpan_link($dist);
		$dist =~ s{[.] tar [.] gz}{}msx;   # Take off extensions.
		$dist =~ s{[.] zip}{}msx;
		$dist =~ s{.+\/}{}msx;         # Take off directories.
		( $name, $ver ) = $dist =~ m{(.*)-(?:v?)([\d._]*)}msx;

		if ( not defined $name ) {
			$self->trace_line( 0, "Could not parse $dist\n" );
		}
		$dist_list .= qq{<tr><td>$name</td><td>$ver</td><td>}
		  . qq{<a href="$link">Source</a></td></tr>\n};
	} ## end foreach my $dist ( $self->_get_distributions...)

	my @time   = localtime;
	my @months = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
	my $date   = sprintf '%02i %s %4i', $time[3], $months[ $time[4] ],
	  $time[5] + 1900;

	my $dist_txt;
	my $vars = {
		dist      => $self,
		dist_list => $dist_list,
		dist_date => $date,
	};

	my $tt = $self->patch_template();

	$tt->process( 'release_notes.html.tt', $vars, \$dist_txt )
	  || PDWiX::Caught->throw(
		message => 'Template error',
		info    => $tt->error(),
	  );

	my $dist_file =
	  catfile( $self->output_dir, $self->release_notes_filename );
	my $fh = IO::File->new( $dist_file, 'w' );

	$self->trace_line( 2, "Creating release notes at $dist_file\n" );

	if ( not defined $fh ) {
		PDWiX::File->throw(
			file    => $dist_file,
			message => 'Could not open file '
			  . "for writing [$OS_ERROR] [$EXTENDED_OS_ERROR]"
		);
	}
	$fh->print($dist_txt);
	$fh->close;

	$self->add_output_file($dist_file);

	return 1;
} ## end sub create_release_notes



# Private routine used to add to the distributions list.
sub _add_to_distributions_installed
{ ## no critic(ProhibitUnusedPrivateSubroutines)
	my $self = shift;
	my $dist = shift;
	$self->_add_distribution($dist);

	return;
}



=head2 create_distribution_list

The C<create_distribution_list> method creates the DISTRIBUTIONS.txt file 
for a L<Perl::Dist::WiX|Perl::Dist::WiX>-based distribution.

=cut



sub create_distribution_list {
	my $self = shift;

	return $self->create_distribution_list_file('DISTRIBUTIONS.txt');
}



=head2 create_distribution_list_file

    $self->create_distribution_list_file('DISTRIBUTIONS.txt');

The C<create_distribution_list_file> method creates a distribution list file
(like DISTRIBUTIONS.txt) that contains the list of distributions that are 
installed, and adds it to the .msi.

=cut



sub create_distribution_list_file {
	my $self           = shift;
	my $dist_file_name = shift;
	my $dist_list;
	my ( $name, $ver );

	foreach my $dist ( $self->_get_distributions() ) {
		$dist =~ s{[.] tar [.] gz}{}msx;   # Take off extensions.
		$dist =~ s{[.] zip}{}msx;
		$dist =~ s{.+\/}{}msx;         # Take off directories.
		( $name, $ver ) = $dist =~ m{(.*)-(?:v?)([\d._]*)}msx;
		$dist_list .= "    $name $ver\n";
	}

	my $dist_txt;
	my $vars = {
		dist      => $self,
		dist_list => $dist_list
	};

	my $tt = $self->patch_template();

	$tt->process( "${dist_file_name}.tt", $vars, \$dist_txt )
	  || PDWiX::Caught->throw(
		message => 'Template error',
		info    => $tt->error(),
	  );

	my $dist_file = catfile( $self->image_dir, $dist_file_name );
	my $fh = IO::File->new( $dist_file, 'w' );

	$self->trace_line( 2, "Creating distribution list at $dist_file\n" );

	if ( not defined $fh ) {
		PDWiX->throw(
"Could not open file $dist_file for writing [$OS_ERROR] [$EXTENDED_OS_ERROR]"
		);
	}
	$fh->print($dist_txt);
	$fh->close();

	# Create a fragment for the distribution list to go into.
	my $dist_file_list = File::List::Object->new()->add_file($dist_file);
	$self->insert_fragment( 'perl_dist_list', $dist_file_list );

	return 1;
} ## end sub create_distribution_list_file

no Moose;
__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=head1 DIAGNOSTICS

See L<Perl::Dist::WiX::Diagnostics|Perl::Dist::WiX::Diagnostics> for a list of
exceptions that this module can throw.

=head1 BUGS AND LIMITATIONS (SUPPORT)

Bugs should be reported via: 

1) The CPAN bug tracker at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>
if you have an account there.

2) Email to E<lt>bug-Perl-Dist-WiX@rt.cpan.orgE<gt> if you do not.

For other issues, contact the topmost author.

=head1 AUTHORS

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist::WiX|Perl::Dist::WiX>, 
L<http://ali.as/>, L<http://csjewell.comyr.com/perl/>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 - 2010 Curtis Jewell.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this distribution.

=cut
