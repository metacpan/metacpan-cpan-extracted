package Perl::Dist::WiX::Mixin::Patching;

=pod

=head1 NAME

Perl::Dist::WiX::Mixin::Patching - Provides routines for patching files in a Win32 perl distribution.

=head1 VERSION

This document describes Perl::Dist::WiX::Mixin::Patching version 1.500.

=head1 SYNOPSIS

	# This module is not to be used independently.
	# It provides methods to be called on a Perl::Dist::WiX object.
  

=head1 DESCRIPTION

This module provides methods for patching files within a distribution, 
either from Template Toolkit files or from edited files, for 
L<Perl::Dist::WiX|Perl::Dist::WiX>.

=cut

use 5.010;
use Moose;
use English qw(	-no_match_vars );
use Params::Util qw( _HASH );
use File::PathList qw();
use File::Spec::Functions qw( catdir catfile );
use File::Temp qw();
use Perl::Dist::WiX::DirectoryTree qw();
use Perl::Dist::WiX::Exceptions qw();

our $VERSION = '1.500';
$VERSION =~ s/_//ms;



=head1 METHODS

=head2 process_template

	# Loads up the template for merge module docs.
	$text = $self->process_template('Merge-Module.documentation.txt.tt');

Loads the file template passed in as the first parameter, using this object, 
and returns it as a string.

Additional entries (beyond the one given that 'dist' is the Perl::Dist::WiX 
object, and 'directory_tree' is the stringification of the current directory 
tree) for the second parameter of Template->process are given as a list of 
pairs following the first parameter.

=cut

sub process_template {
	my $self          = shift;
	my $template_file = shift;
	my @vars_in       = @_;

	my $tt = $self->patch_template();

	my $answer;
	my $tt_answer;
	my %vars = (
		@vars_in,
		dist => $self,
		directory_tree =>
		  Perl::Dist::WiX::DirectoryTree->instance()->as_string(),
	);

	$tt_answer = $tt->process( $template_file, \%vars, \$answer );

	if ( not $tt_answer ) {
		PDWiX::Caught->throw(
			info    => 'Template',
			message => $tt->error()->as_string() );
	}

#<<<
	# Delete empty lines.
	$answer =~ s{\R         # Replace a linebreak, 
				 \s*?       # any whitespace we may be able to catch,
				 \R}        # and a second linebreak
				{\r\n}msgx; # With one Windows linebreak.
#>>>

	# Combine it all
	return $answer;
} ## end sub process_template



=head2 patch_include_path

	my $directory_list_ref = $self->patch_include_path(); 

Returns an array reference containing a list of paths containing files
that are used to replace or patch files in the distribution.

=cut

# By default only use the default (as a default...)
sub patch_include_path {
	my $self     = shift;
	my $share    = File::ShareDir::dist_dir('Perl-Dist-WiX');
	my $path     = catdir( $share, 'default', );
	my $portable = catdir( $share, 'portable', );
	if ( not -d $path ) {
		PDWiX::Directory->throw(
			dir     => $path,
			message => 'Directory does not exist'
		);
	}
	if ( $self->portable() ) {
		if ( not -d $portable ) {
			PDWiX::Directory->throw(
				dir     => $portable,
				message => 'Directory does not exist'
			);
		}
		return [ $portable, $path ];
	} else {
		return [$path];
	}
} ## end sub patch_include_path



=head2 patch_pathlist

	my $pathlist = $self->patch_pathlist();

Returns the list of directories in C<patch_include_path> as a 
L<File::PathList|File::PathList> object.

=cut

sub patch_pathlist {
	my $self = shift;
	return File::PathList->new( paths => $self->patch_include_path(), );
}



=head4 patch_file

	$self->patch_file('Merge-Module.wxs');

C<patch_file> patches an individual file installed in the distribution
using a file from the directories returned from L</patch_pathlist>.

The file to patch from can either be a file that replaces the file named, 
or a Template Toolkit file with a '.tt' extension added to the file named.

=cut

sub patch_file {
	my $self     = shift;
	my $file     = shift;
	my $file_tt  = $file . '.tt';
	my $dir      = shift;
	my $to       = catfile( $dir, $file );
	my $pathlist = $self->patch_pathlist();

	# Locate the source file
	my $from    = $pathlist->find_file($file);
	my $from_tt = $pathlist->find_file($file_tt);
	if ( not( defined $from and defined $from_tt ) ) {
		PDWiX->throw(
			"Missing or invalid file $file or $file_tt in pathlist search"
		);
	}

	if ( $from_tt ne q{} ) {

		# Generate the file
		my $hash = _HASH(shift) || {};
		my ( $fh, $output ) =
		  File::Temp::tempfile( 'pdwXXXXXX', TMPDIR => 1 );
		$self->trace_line( 2,
			"Generating $from_tt into temp file $output\n" );
		$self->patch_template()
		  ->process( $from_tt, { %{$hash}, self => $self }, $fh, )
		  or PDWiX->throw("Template processing failed for $from_tt");

		# Copy the file to the final location
		$fh->close or PDWiX->throw("Could not close: $OS_ERROR");
		$self->copy_file( $output => $to );
		unlink $output
		  or PDWiX->throw("Could not delete $output: $OS_ERROR");

	} elsif ( $from ne q{} ) {

		# Simple copy of the regular file to the target location
		$self->copy_file( $from => $to );

	} else {
		PDWiX::File->throw(
			file    => $file,
			message => 'Failed to find file'
		);
	}

	return 1;
} ## end sub patch_file



=head4 patch_perl_file

	$self->patch_perl_file('makefile.mk')

C<patch_file> patches an individual file installed in the distribution
using a file from the perl plugin modules.

=cut



sub patch_perl_file {
	my $self    = shift;
	my $file    = shift;
	my $file_tt = $file . '.tt';
	my $dir     = shift;
	my $to      = catfile( $dir, $file );

	# Locate the source file
	my $from    = $self->_find_perl_file($file);
	my $from_tt = $self->_find_perl_file($file_tt);
	if ( not( defined $from or defined $from_tt ) ) {
		PDWiX->throw( "Missing or invalid file $file or "
			  . "$file_tt in perl version search" );
	}

	if ( defined $from_tt ) {

		# Generate the file
		my $hash = _HASH(shift) || {};
		my ( $fh, $output ) =
		  File::Temp::tempfile( 'pdwXXXXXX', TMPDIR => 1 );
		$self->trace_line( 2,
			"Generating $from_tt into temp file $output\n" );
		$self->patch_template()
		  ->process( $from_tt, { %{$hash}, self => $self }, $fh, )
		  or PDWiX->throw("Template processing failed for $from_tt");

		# Copy the file to the final location
		$fh->close or PDWiX->throw("Could not close: $OS_ERROR");
		$self->copy_file( $output => $to );
		unlink $output
		  or PDWiX->throw("Could not delete $output: $OS_ERROR");

	} elsif ( $from ne q{} ) {

		# Simple copy of the regular file to the target location
		$self->copy_file( $from => $to );

	} else {
		PDWiX::File->throw(
			file    => $file,
			message => 'Failed to find file'
		);
	}

	return 1;
} ## end sub patch_perl_file


no Moose;
__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>

For other issues, contact the author.

=head1 AUTHOR

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist::WiX|Perl::Dist::WiX>, 

=head1 COPYRIGHT AND LICENSE

Copyright 2009 - 2010 Curtis Jewell.

Copyright 2007 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this distribution.

=cut
