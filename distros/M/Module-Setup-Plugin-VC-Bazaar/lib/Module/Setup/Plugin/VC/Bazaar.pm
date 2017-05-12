package Module::Setup::Plugin::VC::Bazaar;
use strict;
use warnings;
use base 'Module::Setup::Plugin';

our $VERSION = '0.03';
# this code is variation of Module::Setup::Plugin::VC::Git for VC::Bazaar. thx.

sub register
{
  my $self = shift;
  $self->add_trigger( check_skeleton_directory => \&check_skeleton_directory );
  $self->add_trigger( append_template_file     => sub { $self->append_template_file(@_) } );
}

sub check_skeleton_directory
{
  my $self = shift;
  return unless $self->dialog("Bzr init? [Yn] ", 'y') =~ /[Yy]/;

  !$self->system(qw/bzr init/)  or die $?;
  !$self->system(qw/bzr add/)   or die $?;

  !$self->system(qw/bzr commit -m/, 'initial commit') or die $?;
}

1;

=head1 NAME

Module::Setup::Plugin::VC::Bazaar - Bazaar plugin

=head1 SYNOPSIS

  module-setup --init --plugin=VC::Bazaar

=head1 AUTHOR

turugina E<lt>turugina {at} cpan.orgE<gt>

=head1 SEE ALSO

L<Module::Setup>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__DATA__

---
  file: .bzrignore
  template: |
    cover_db
    META.yml
    Makefile
    blib
    inc
    pm_to_blib
    MANIFEST
    Makefile.old
    nytprof.out
    MANIFEST.bak
    *.sw[po]
