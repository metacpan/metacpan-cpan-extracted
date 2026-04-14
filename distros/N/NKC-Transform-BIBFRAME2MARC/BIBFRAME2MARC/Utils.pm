package NKC::Transform::BIBFRAME2MARC::Utils;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use File::Spec::Functions qw(catfile);
use File::Share ':all';
use Readonly;

Readonly::Array our @EXPORT_OK => qw(list_versions);

our $VERSION = 0.07;

sub list_versions {
	my $dir = shift;

	if (! defined $dir) {
		$dir = dist_dir('NKC-Transform-BIBFRAME2MARC');
	}

	opendir(my $dh, $dir) or err "Cannot open directory.";
	my @versions = sort {
			my ($a1, $a2, $a3) = split m/\./ms, $a;
			my ($b1, $b2, $b3) = split m/\./ms, $b;
			$a1 <=> $b1 or $a2 <=> $b2 or $a3 <=> $b3;
		}
		map { -f catfile($dir, $_) && m/^bibframe2marc-(.+)\.xsl$/ms ? $1 : () }
		readdir($dh);
	closedir($dh);

	return @versions;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

NKC::Transform::BIBFRAME2MARC::Utils - Utilities for bibframe2marc transformations.

=head1 SYNOPSIS

 use NKC::Transform::BIBFRAME2MARC::Utils qw(list_versions);

 my @versions = list_versions($dir);

=head1 SUBROUTINES

=head2 C<list_versions>

 my @versions = list_versions($dir);

Get list of installed versions of bibframe2marc transformations.

C<$dir> is optional. Default value of C<$dir> variables is installation
directory.

Returns list.

=head1 ERRORS

 list_versions():
         Cannot open directory.

=head1 EXAMPLE

=for comment filename=list_versions.pl

 use strict;
 use warnings;

 use File::Temp qw(tempdir);
 use File::Spec::Functions qw(catfile);
 use IO::Barf qw(barf);
 use NKC::Transform::BIBFRAME2MARC::Utils qw(list_versions);

 # Temporary directory.
 my $temp_dir = tempdir(CLEANUP => 1);

 # Create test files.
 barf(catfile($temp_dir, 'bibframe2marc-2.5.0.xsl'), '');
 barf(catfile($temp_dir, 'bibframe2marc-2.6.0.xsl'), '');
 barf(catfile($temp_dir, 'bibframe2marc-3.6.0.xsl'), '');

 # List versions.
 my @versions = list_versions($temp_dir);

 # Print versions.
 print join "\n", @versions;
 print "\n";

 # Output:
 # 2.5.0
 # 2.6.0
 # 3.6.0

=head1 DEPENDENCIES

L<Error::Pure>
L<Exporter>
L<File::Spec::Functions>,
L<File::Share>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<NKC::Transform::BIBFRAME2MARC>

bibframe2marc transformation class.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/NKC-Transform-BIBFRAME2MARC>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2024-2026 Michal Josef Špaček

BSD 2-Clause License

=head1 ACKNOWLEDGEMENTS

Development of this software has been made possible by institutional support
for the long-term strategic development of the National Library of the Czech
Republic as a research organization provided by the Ministry of Culture of
the Czech Republic (DKRVO 2024–2028), Area 11: Linked Open Data.

=head1 VERSION

0.07

=cut
