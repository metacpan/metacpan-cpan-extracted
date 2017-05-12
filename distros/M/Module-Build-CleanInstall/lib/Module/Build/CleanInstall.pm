package Module::Build::CleanInstall;

use strict;
use warnings;

our $VERSION = '0.05';
$VERSION = eval $VERSION;

use parent 'Module::Build';
use ExtUtils::Installed;

sub ACTION_uninstall {
  my $self = shift;
  my $module = $self->module_name;

  if ( my $packlist = $self->_get_packlist($module) ) {
    print "Removing old copy of $module\n";
    $self->_uninstall($packlist);
  }
}

sub ACTION_install {
  my $self = shift;
  $self->depends_on('uninstall');
  $self->SUPER::ACTION_install;
}

sub _get_packlist {
  my $self = shift;
  my ($module) = @_;

  my $installed = ExtUtils::Installed->new;
  my $packlist = eval { $installed->packlist($module)->packlist_file };

  return $packlist || '';
}

sub _uninstall {
  my $self = shift;
  my ($packlist, $dont_execute) = @_;

  require ExtUtils::Install;
  ExtUtils::Install::uninstall( $packlist, 1, !!$dont_execute );
}

1;

=head1 NAME

Module::Build::CleanInstall - Subclass of Module::Build which removes the old module before installing the new one

=head1 SYNOPSIS

 use strict;
 use warnings;

 use Module::Build::CleanInstall;
 my $builder = Module::Build::CleanInstall->new(
   ... # same as Module::Build
 );
 $builder->create_build_script;

=head1 DESCRIPTION

L<Module::Build::CleanInstall> is a subclass of L<Module::Build> with one additional feature, before upgrading the module from and old version to a new one, it first removes the files installed by the previous version. This is useful especially when the new version will not contain some files that the old one did, and it is necessary that those files do not remain in place.

Since it is a subclass of L<Module::Build> it is used exactly like that module. This module does provide an additional action C<uninstall>, but it need not be called separately; the action C<install> will call it when invoked.

The uninstalling is done by removing the files in the installed module's L<packlist|ExtUtils::Packlist> which is created when the module is first installed.

=head1 SEE ALSO

=over

=item L<Module::Build>

=item L<File::ShareDir::Tarball>

=back

=head1 SOURCE REPOSITORY

L<http://github.com/jberger/Module-Build-CleanInstall>

=head1 AUTHOR

Joel Berger, E<lt>joel.a.berger@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Joel Berger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
