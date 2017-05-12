package Perl::Dist::Inno::File;

=pod

=head1 NAME

Perl::Dist::Inno::File - Inno Setup Script [Files] Section Entry

=head1 DESCRIPTION

The B<Perl::Dist::Inno::File> class provides a data class that represents
an entry in the [Files] section of the Inno Setup Script.

=head1 METHODS

=cut

use 5.006;
use strict;
use warnings;
use Carp         qw{ croak               };
use Params::Util qw{ _IDENTIFIER _STRING };

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.16';
}

use Object::Tiny qw{
	source
	dest_dir
	ignore_version
	recurse_subdirs
	create_all_subdirs
	is_readme
};





#####################################################################
# Constructors

sub new {
	my $self = shift->SUPER::new(@_);

	# Apply defaults
	unless ( defined $self->ignore_version ) {
		$self->{ignore_version} = 1;
	}

	# Normalize params
	$self->{ignore_version}     = !! $self->ignore_version;
	$self->{recurse_subdirs}    = !! $self->recurse_subdirs;
	$self->{create_all_subdirs} = !! $self->create_all_subdirs;
	$self->{is_readme}          = !! $self->is_readme;

	# Check params
	unless ( _STRING($self->source) ) {
		croak("Missing or invalid source param");
	}
	unless ( _STRING($self->dest_dir) ) {
		croak("Missing or invalid dest_dir param");
	}

	return $self;
}





#####################################################################
# Main Methods

sub as_string {
	my $self  = shift;
	my @flags = ();
	push @flags, 'ignoreversion'    if $self->ignore_version;
	push @flags, 'recursesubdirs'   if $self->recurse_subdirs;
	push @flags, 'createallsubdirs' if $self->create_all_subdirs;
	push @flags, 'isreadme'         if $self->is_readme;
	return join( '; ',
		"Source: \""  . $self->source . "\"",
		"DestDir: \"" . $self->dest_dir . "\"",
		(scalar @flags)
			? ("Flags: " . join(' ', @flags))
			: (),
	);
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist>

=head1 COPYRIGHT

Copyright 2007 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
