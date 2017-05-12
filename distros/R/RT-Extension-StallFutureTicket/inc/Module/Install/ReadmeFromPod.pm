package Module::Install::ReadmeFromPod;

use 5.006;
use strict;
use warnings;
use base qw(Module::Install::Base);
use vars qw($VERSION);

$VERSION = '0.12';

sub readme_from {
  my $self = shift;
  return unless $self->is_admin;

  my $file = shift || $self->_all_from
    or die "Can't determine file to make readme_from";
  my $clean = shift;

  print "Writing README from $file\n";

  require Pod::Text;
  my $parser = Pod::Text->new();
  open README, '> README' or die "$!\n";
  $parser->output_fh( *README );
  $parser->parse_file( $file );
  if ($clean) {
    $self->clean_files('README');
  }
  return 1;
}

sub _all_from {
  my $self = shift;
  return unless $self->admin->{extensions};
  my ($metadata) = grep {
    ref($_) eq 'Module::Install::Metadata';
  } @{$self->admin->{extensions}};
  return unless $metadata;
  return $metadata->{values}{all_from} || '';
}

'Readme!';

__END__

=head1 NAME

Module::Install::ReadmeFromPod - A Module::Install extension to automatically convert POD to a README

=head1 SYNOPSIS

  # In Makefile.PL

  use inc::Module::Install;
  author 'Vestan Pants';
  license 'perl';
  readme_from 'lib/Some/Module.pm';

A C<README> file will be generated from the POD of the indicated module file.

Note that the author will need to make sure
C<Module::Install::ReadmeFromPod> is installed
before running the C<Makefile.PL>.  (The extension will be bundled
into the user-side distribution).

=head1 DESCRIPTION

Module::Install::ReadmeFromPod is a L<Module::Install> extension that generates a C<README> file 
automatically from an indicated file containing POD, whenever the author runs C<Makefile.PL>.

=head1 COMMANDS

This plugin adds the following Module::Install command:

=over

=item C<readme_from>

Does nothing on the user-side. On the author-side it will generate a C<README> file using L<Pod::Text> from
the POD in the file passed as a parameter.

  readme_from 'lib/Some/Module.pm';

If a second parameter is set to a true value then the C<README> will be removed at C<make distclean>.

  readme_from 'lib/Some/Module.pm' => 'clean';

If you use the C<all_from> command, C<readme_from> will default to that value.

  all_from 'lib/Some/Module.pm';
  readme_from;              # Create README from lib/Some/Module.pm
  readme_from '','clean';   # Put a empty string before 'clean'

=back

=head1 AUTHOR

Chris C<BinGOs> Williams

=head1 LICENSE

Copyright E<copy> Chris Williams

This module may be used, modified, and distributed under the same terms as Perl itself. Please see the license that came with your Perl distribution for details.

=head1 SEE ALSO

L<Module::Install>

L<Pod::Text>

=cut

