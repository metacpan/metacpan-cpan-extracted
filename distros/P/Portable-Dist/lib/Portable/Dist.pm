package Portable::Dist;

=pod

=head1 NAME

Portable::Dist - Modify a Perl distribution to make it portable

=head1 DESCRIPTION

The L<Portable> family of modules provides functionality that allows
Perl to operate from arbitrary and variable paths.

B<Portable::Dist> is used to apply the necesary modifications to an
existing Perl distribution to convert it to a Portable Perl.

=head2 Portability Warning

This module is designed for use only on a distribution that is not
currently in use. Thus, you should not execute the modification
process using the distribution you wish to modify.

This module is also currently only designed to run on Windows (to
support the production of Strawberry Perl Portable and other
Perl::Dist-related distributions).

If you wish to use this module for other operating systems, please
contact the author.

=head1 METHODS

=cut

use 5.008;
use strict;
use Carp                 ();
use File::Spec           ();
use File::Path           ();
use File::Slurp          qw(read_file write_file);
use File::Find::Rule     ();
use File::IgnoreReadonly ();
use Params::Util         '_STRING'; 

our $VERSION = '1.06';

use constant MSWin32 => ( $^O eq 'MSWin32' );

use Object::Tiny qw{
	perl_root
	perl_bin
	perl_lib
	perl_sitelib
	perl_vendorlib
	perl_sitebin
	perl_vendorbin
	pl2bat
	config_pm
	cpan_config
	file_homedir
	file_homedir_v
	minicpan_dir
	minicpan_conf
};





#####################################################################
# Constructor and Accessors

sub new {
	my $self = shift->SUPER::new(@_);

	# Check params
	unless ( _DIRECTORY($self->perl_root) ) {
		Carp::croak("Missing or invalid perl_root directory");
	}

	$self->{perl_bin} ||= File::Spec->catdir( $self->perl_root, 'bin' );
	unless ( _DIRECTORY($self->perl_bin) ) {
		Carp::croak("Missing or invalid perl_bin directory");
	}

	$self->{perl_lib} ||= File::Spec->catdir( $self->perl_root, 'lib' );
	unless ( _DIRECTORY($self->perl_lib) ) {
		Carp::croak("Missing or invalid perl_lib directory");
	}

	$self->{perl_sitelib} ||= File::Spec->catdir( $self->perl_root, 'site', 'lib' );
	unless ( _DIRECTORY($self->perl_sitelib) ) {
		Carp::croak("Missing or invalid perl_sitelib directory");
	}

	$self->{perl_vendorlib} ||= File::Spec->catdir( $self->perl_root, 'vendor', 'lib' );
	unless ( _DIRECTORY($self->perl_sitelib) ) {
		Carp::croak("Missing or invalid perl_vendorlib directory");
	}

	$self->{perl_sitebin} ||= File::Spec->catdir( $self->perl_root, 'site', 'bin' );
	#unless ( _DIRECTORY($self->perl_sitebin) ) {
	#	Carp::croak("Missing or invalid perl_sitebin directory");
	#}

	$self->{perl_vendorbin} ||= File::Spec->catdir( $self->perl_root, 'vendor', 'bin' );
	#unless ( _DIRECTORY($self->perl_sitebin) ) {
	#	Carp::croak("Missing or invalid perl_vendorbin directory");
	#}

	# Find some particular files
	$self->{pl2bat}          = File::Spec->catfile( $self->perl_bin,       'pl2bat.bat'         );
	$self->{config_pm}       = File::Spec->catfile( $self->perl_lib,       'Config.pm'          );
	$self->{cpan_config}     = File::Spec->catfile( $self->perl_lib,       'CPAN', 'Config.pm'  );
	$self->{file_homedir}    = File::Spec->catfile( $self->perl_sitelib,   'File', 'HomeDir.pm' );
	$self->{file_homedir_v}  = File::Spec->catfile( $self->perl_vendorlib, 'File', 'HomeDir.pm' );
	$self->{minicpan_dir}    = File::Spec->catfile( $self->perl_vendorlib, 'CPAN'               );
	$self->{minicpan_conf}   = File::Spec->catfile( $self->minicpan_dir,   'minicpan.conf'      );

	return $self;
}

sub run {
	my $self = shift;

	# Modify the files we need to hack
	$self->modify_config;
	$self->modify_cpan_config;
	$self->modify_file_homedir;

	# Create the minicpan configuration file
	$self->create_minicpan_conf;

	# Convert all existing batch files to portable
	$self->modify_batch_files;

	# Modify pl2bat so new batch files get created properly
	$self->modify_pl2bat;

	return 1;
}





#####################################################################
# Modification Functions

# Apply modifications to Config.pm
sub modify_config {
	my $self   = shift;
	my $file   = $self->config_pm;
	my $append = <<'END_PERL';
eval {
	require Portable;
	Portable->import('Config');
};

1;
END_PERL

	# Apply the change to the file
	my $guard = File::IgnoreReadonly->new( $file );
	my $content = read_file($file,  binmode=>':utf8') or die "Couldn't read $file";
	$content .= $append;
	write_file($file, {binmode=>':utf8'}, $content);

	return 1;	
}

# Apply modifications to CPAN::Config
sub modify_cpan_config {
	my $self   = shift;
	my $file   = $self->cpan_config;
	my $append = <<'END_PERL';
eval {
	require Portable;
	Portable->import('CPAN');
};
END_PERL

	# Apply the change to the file
	my $guard = File::IgnoreReadonly->new( $file );
        my $content = read_file($file,  binmode=>':utf8') or die "Couldn't read $file";
	$content =~ s/\n1;/$append\n\n1;/;
	write_file($file, {binmode=>':utf8'}, $content);

	return 1;
}

# Apply modifications to File::HomeDir
sub modify_file_homedir {
	my $self   = shift;
	my $file;
	my $append = <<'END_PERL';
eval {
	require Portable;
	Portable->import('HomeDir');
};
END_PERL

	if (-f $self->file_homedir_v) {
		$file = $self->file_homedir_v;
	} else {
		$file = $self->file_homedir;
	}

	# Apply the change to the file
	my $guard = File::IgnoreReadonly->new( $file );
        my $content = read_file($file,  binmode=>':utf8') or die "Couldn't read $file";
	$content =~ s/\n1;/$append\n\n1;/;
	write_file($file, {binmode=>':utf8'}, $content);

	return 1;
}

# Create the minicpan configuration file
sub create_minicpan_conf {
	my $self = shift;
	my $dir  = $self->minicpan_dir;
	my $file = $self->minicpan_conf;

	# Create the directory
	File::Path::mkpath( $dir, { verbose => 0 } );

	# Write the file
	my $guard = -f $file ? File::IgnoreReadonly->new( $file ) : 0;
	write_file(
		$file,
		"class: CPAN::Mini::Portable\n",
		"skip_perl: 1\n",
		"no_conn_cache: 1\n",
	);

	# Make the file readonly
	if ( MSWin32 ) {
		require Win32::File::Object;
		Win32::File::Object->new( $file, 1 )->readonly(1);
	} else {
		require File::chmod;
		File::chmod::chmod( 'a-w', $file );
	}

	return 1;
}

# Modify existing batch files
sub modify_batch_files {
	my $self  = shift;
	my @files;
	push @files, File::Find::Rule->name('*.bat')->file->in($self->perl_bin);
	push @files, File::Find::Rule->name('*.bat')->file->in($self->perl_sitebin) if -d $self->perl_sitebin;
	push @files, File::Find::Rule->name('*.bat')->file->in($self->perl_vendorbin) if -d $self->perl_vendorbin;
	unless ( @files ) {
		Carp::croak("Failed to find any batch files");
	}

	# Process the files
	foreach my $file ( @files ) {
		# Apply the change to the file
		my $guard = File::IgnoreReadonly->new( $file );
		my $content = read_file($file,  binmode=>':utf8') or die "Couldn't read $file";
		$content =~ s/([\r\n])(perl )(-x[^\r\n]*)/$1 . _perl_cmd($3)/sge;
		$content =~ s/(#line )(\d+)/$1 . ($2+14)/e;  # we have added extra 14 lines
		write_file($file, {binmode=>':utf8'}, $content);
	}

	return 1;
}

sub modify_pl2bat {
	my $self    = shift;
	my $file    = $self->pl2bat;

	# Apply the change to the file
	my $guard   = File::IgnoreReadonly->new( $file );
	my $content = read_file($file,  binmode=>':utf8') or die "Couldn't read $file";
	$content =~ s/\bperl \$OPT\{'(a|o|n)'\}/_perl_cmd('$OPT{\'' . $1 .'\'}', 1, 1)/esg;
	write_file($file, {binmode=>':utf8'}, $content);

	return 1;
}

#####################################################################
# Support Functions

sub _DIRECTORY {
	(defined _STRING($_[0]) and -d $_[0]) ? $_[0] : undef;
}

sub _perl_cmd {
  my ($arg, $tab, $quote) = @_;
  my $rv = <<'MARKER';
IF EXIST "%~dp0perl.exe" (
"%~dp0perl.exe" XXX_XXX
) ELSE IF EXIST "%~dp0..\..\bin\perl.exe" (
"%~dp0..\..\bin\perl.exe" XXX_XXX
) ELSE (
perl XXX_XXX
)
MARKER
  $rv =~ s/XXX_XXX/$arg/sg;
  $rv =~ s/([\%\\])/\\$1/sg if $quote;
  $rv =~ s/([\r\n]+)/$1\t/sg if $tab;
  return $rv;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker.

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Portable-Dist>

For other issues, or commercial support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Portable>, L<http://win32.perl.org/>, L<http://strawberryperl.com/>

=head1 COPYRIGHT

Copyright 2008 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
