package Module::Install::PodFromEuclid;


=head1 NAME

Module::Install::PodFromEuclid - Module::Install extension to make POD from
Getopt::Euclid-based scripts

=head1 SYNOPSIS

  # In Makefile.PL:
  use inc::Module::Install;
  author 'John Doe';
  license 'perl';
  pod_from 'scripts/my_script.pl';

=head1 DESCRIPTION

Module::Install::PodFromEuclid is a L<Module::Install> extension that generates
a C<POD> file automatically from an indicated script containing Getopt::Euclid
command-line specifications.

The POD file is generated using the --podfile option of Getopt::Euclid, but only
whenever authors run C<Makefile.PL>. While this extension will be bundled in
your distribution, the pod_from command does nothing on the user-side.

Note: Authors should make sure that C<Module::Install::PodFromEuclid> is
installed before running C<Makefile.PL>.

This module was inspired and borrows a lot from C<Module::Install::ReadmeFromPod>.

=head1 COMMANDS

This plugin adds the following Module::Install command:

=over

=item C<pod_from>

Does nothing on the user-side. On the author-side it will generate a C<POD>
file that has the same base name as the Perl file, using Getopt::Euclid's
--podfile feature:

  pod_from 'scripts/my_script.pl';  # generate scripts/my_script.pod

If you use the C<all_from> command, C<pod_from> will default to this value.

  all_from 'scripts/my_script.pl';
  pod_from;                         # create scripts/my_script.pod

=back

=head1 AUTHOR

Florent Angly <florent.angly@gmail.com>

=head1 LICENSE

Copyright Florent Angly

This module may be used, modified, and distributed under the same terms as Perl
itself. Please see the license that came with your Perl distribution for details.

=head1 SEE ALSO

L<Getopt::Euclid>

L<Module::Install>

L<Module::Install::ReadmeFromPod>

=cut


use 5.006;
use strict;
use warnings;
use File::Spec;
use Env qw(@INC);
use base qw(Module::Install::Base);

our $VERSION = '0.01';


sub pod_from {
   my ($self, $in_file) = @_;
   return unless $self->is_admin;
   if (not defined $in_file) {
      $in_file = $self->_all_from or die "Error: Could not determine file to make pod_from";
   }
   my @inc = map { ( '-I', File::Spec->rel2abs($_) ) } @INC;
   # use same -I included modules as caller
   my @args = ($^X, @inc, $in_file, '--podfile');
   system(@args) == 0 or die "Error: Could not run command ".join(' ',@args).": $?\n";
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


1;

