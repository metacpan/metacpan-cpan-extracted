use strict;
use warnings;

package Module::Install::AutoManifest;

use Module::Install::Base;

BEGIN {
  our $VERSION = '0.003';
  our $ISCORE  = 1;
  our @ISA     = qw(Module::Install::Base);
}

sub auto_manifest {
  my ($self) = @_;

  return unless $Module::Install::AUTHOR;

  die "auto_manifest requested, but no MANIFEST.SKIP exists\n"
    unless -e "MANIFEST.SKIP";

  if (-e "MANIFEST") {
    unlink('MANIFEST') or die "Can't remove MANIFEST: $!";
  }

  $self->postamble(<<"END");
create_distdir: manifest_clean manifest

distclean :: manifest_clean

manifest_clean:
\t\$(RM_F) MANIFEST
END

}

1;
__END__

=head1 NAME

Module::Install::AutoManifest - generate MANIFEST automatically

=head1 VERSION

Version 0.003

=cut

=head1 SYNOPSIS

In Makefile.PL:

  auto_manifest;

In MANIFEST.SKIP:

  # put your list of patterns here
  ^\.git/
  ^your-crazy-files-whatever$

In MANIFEST:

  Nothing, remove it

=head1 METHODS

=head2 auto_manifest

This extension to L<Module::Install> adds behavior for automatically generating
MANIFEST.

Before C<make distdir>, C<make manifest> will be run for you automatically.
Likewise, C<make distclean> will remove your automatically-generated MANIFEST.

=head1 AUTHOR

Hans Dieter Pearcey, C<< <hdp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-module-install-automanifest at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-Install-AutoManifest>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Module::Install::AutoManifest


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Install-AutoManifest>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Module-Install-AutoManifest>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Module-Install-AutoManifest>

=item * Search CPAN

L<http://search.cpan.org/dist/Module-Install-AutoManifest>

=back


=head1 SEE ALSO

L<Module::Install>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Hans Dieter Pearcey, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Module::Install::AutoManifest
