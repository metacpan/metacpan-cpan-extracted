package PPIx::EditorTools::RenamePackageFromPath;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Change the package name based on the files path
$PPIx::EditorTools::RenamePackageFromPath::VERSION = '0.20';
use 5.008;
use strict;
use warnings;
use Carp;

use Class::XSAccessor accessors => {
	'replacement' => 'replacement',
	'filename'    => 'filename',
};

use base 'PPIx::EditorTools';
use PPIx::EditorTools::RenamePackage;
use Carp;
use File::Spec;
use File::Basename;


sub rename {
	my ( $self, %args ) = @_;
	$self->process_doc(%args);
	my $path = $args{filename} || croak "filename required";

	my $dir = dirname $path;
	my $file = basename $path, qw/.pm .PM .Pm/;

	my @directories =
		grep { $_ && !/^\.$/ } File::Spec->splitdir( File::Spec->rel2abs($dir) );
	my $replacement;
	if ( grep {/^lib$/} @directories ) {
		while ( shift(@directories) !~ /^lib$/ ) { }
	} else {
		@directories = grep { $_ && !/^\.$/ } File::Spec->splitdir($dir);
	}
	$replacement = join( '::', @directories, $file );

	return PPIx::EditorTools::RenamePackage->new( ppi => $self->ppi )->rename( replacement => $replacement );

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PPIx::EditorTools::RenamePackageFromPath - Change the package name based on the files path

=head1 VERSION

version 0.20

=head1 SYNOPSIS

    my $munged = PPIx::EditorTools::RenamePackageFromPath->new->rename(
        code        => "package TestPackage;\nuse strict;\nBEGIN {
	$^W = 1;
}\n1;\n",
        filename => './lib/Test/Code/Path.pm',
    );

    my $new_code_as_string = $munged->code;
    my $package_ppi_element = $munged->element;

=head1 DESCRIPTION

This module uses PPI to change the package name of code.

=head1 METHODS

=over 4

=item new()

Constructor. Generally shouldn't be called with any arguments.

=item rename( ppi => PPI::Document $ppi, filename => Str )

=item rename( code => Str $code, filename => Str )

Accepts either a C<PPI::Document> to process or a string containing
the code (which will be converted into a C<PPI::Document>) to process.
Replaces the package name with that supplied in the C<filename>
parameter and returns a C<PPIx::EditorTools::ReturnObject> with the
new code available via the C<ppi> or C<code> accessors, as a
C<PPI::Document> or C<string>, respectively.

An attempt will be made to derive the package name from the filename passed
as a parameter.  The filename's path will converted to an absolute path and
it will be searched for a C<lib> directory which will be assumed the start
of the package name. If no C<lib> directory can be found in the absolute
path, the relative path will be used.

Croaks with a "package name not found" exception if unable to find the
package name.

=back

=head1 SEE ALSO

This class inherits from C<PPIx::EditorTools>.
Also see L<App::EditorTools>, L<Padre>, and L<PPI>.

=head1 AUTHORS

=over 4

=item *

Steffen Mueller C<smueller@cpan.org>

=item *

Mark Grimes C<mgrimes@cpan.org>

=item *

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=item *

Gabor Szabo  <gabor@szabgab.com>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2014, 2012 by The Padre development team as listed in Padre.pm..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
