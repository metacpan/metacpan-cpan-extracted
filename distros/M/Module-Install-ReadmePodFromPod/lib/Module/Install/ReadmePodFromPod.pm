package Module::Install::ReadmePodFromPod;
use strict;
use warnings;
use base qw(Module::Install::Base);
use vars qw($VERSION);

$VERSION = '0.01';

sub readme_pod_from {
  my $self = shift;
  return unless $Module::Install::AUTHOR;
  my $file = shift || return;

  require Pod::Perldoc::ToPod;
  open my $out, '>', 'README.pod' or die "can not create README.pod file: $!";
  my $parser = Pod::Perldoc::ToPod->new;
  $parser->parse_from_file($file, $out);
  return 1;
}

'let README.pod render Pod as ... Pod!';
__END__

=for stopwords
github

=head1 NAME

Module::Install::ReadmePodFromPod - A Module::Install extension to automatically convert POD to a README.pod

=head1 SYNOPSIS

  # In Makefile.PL
  use Module::Install::ReadmePodFromPod;
  readme_pod_from 'lib/Some/Module.pm';

A C<README.pod> file will be generated from the POD of the indicated module file.

=head1 DESCRIPTION

Module::Install::ReadmePodFromPod is a L<Module::Install> extension that generates a C<README.pod> file
automatically from an indicated file containing POD, whenever the author runs C<Makefile.PL>.

With github Since POD rendering support entered I want to place README.pod automatically.

takes many test codes and documents from L<Module::Install::ReadmeFromPod>.

=head1 COMMANDS

This plugin adds the following Module::Install command:

=over

=item C<readme_pod_from>

Does nothing on the user-side. On the author-side it will generate a C<README.pod> file using L<perldoc> from the POD in the file passed as a parameter.

  readme_pod_from 'lib/Some/Module.pm';

=back

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo <at> shibuya <döt> plE<gt>

=head1 SEE ALSO

L<Module::Install>, L<Module::Install::ReadmeFromPod>, L<Pod::Perldoc::ToPod>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
