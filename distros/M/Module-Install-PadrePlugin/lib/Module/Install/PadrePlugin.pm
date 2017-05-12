package Module::Install::PadrePlugin;

use strict;
use Module::Install::Base;

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.01';
	@ISA     = qw{Module::Install::Base};
}

=head1 NAME

Module::Install::PadrePlugin - Module::Install support for Padre plugins

=head1 SYNOPSIS

To add two useful "make" targets to your Padre plugin, just add the
C<is_padre_plugin;> line to your C<Makefile.PL>.

    use inc::Module::Install;
    
    name            'Padre::Plugin::Foo';
    all_from        'lib/Padre/Plugin/Foo.pm';
    
    is_padre_plugin;
     
    WriteAll;

=head1 DESCRIPTION

This module adds one directive to Module::Install
related to creating and installing Padre plugins as .par files and two
C<make> targets.

=head2 is_padre_plugin

If you add this directive to your C<Makefile.PL>, two new C<make> targets become
available to the user, see below.

=cut

sub is_padre_plugin {
    my ($self) = @_;
    my $class     = ref($self);
    my $inc_class = join('::', @{$self->_top}{qw(prefix name)});

    my $version = $self->version;
    my $distname = $self->name;
    $distname =~ s/^Padre-Plugin-//
      or die "This is not a Padre plugin The namespace doesn't start with Padre::Plugin::!";

    my $file = $distname;
    $file .= '.par';

    $self->postamble(<<"END_MAKEFILE");
# --- $class section:

$file: all test
\t\$(NOECHO) \$(PERL) "-M$inc_class" -e "make_padre_plugin(q($distname),q($file),q($version))"

plugin :: $file
\t\$(NOECHO) \$(NOOP)

installplugin :: $file
\t\$(NOECHO) \$(PERL) "-M$inc_class" -e "install_padre_plugin(q($file))"

END_MAKEFILE

}

=head1 NEW MAKE TARGETS

=head2 plugin

To generate a .par file from the Padre plugin at hand which
can be easily installed (see also below) into your Padre user
directory, you can simply type:

  perl Makefile.PL
  make plugin

Now you should have a shiny new C<FancyPlugin.par> file.

=head2 installplugin

To install the Padre plugin at hand as a single PAR file into your
Padre user/plugins directory, you can simply type:

  perl Makefile.PL
  make installplugin

Running C<make plugin> in between those two command isn't necessary,
it's run by C<installplugin> if necessary.

=cut

sub make_padre_plugin {
  my ($self, $distname, $file, $version) = @_;
  unlink $file if -f $file;

  unless ( eval { require PAR::Dist; PAR::Dist->VERSION >= 0.17 } ) {
    warn "Please install PAR::Dist 0.17 or above first.";
    return;
  }

  return PAR::Dist::blib_to_par(
    name => $distname,
    version => $version,
    dist => $file,
  );
}

sub install_padre_plugin {
  my ($self, $file) = @_;
  if (not -f $file) {
    warn "Cannot find plugin file '$file'.";
    return;
  }

  require Padre;
  my $plugin_dir = Padre::Config->default_plugin_dir;

  require File::Copy;
  return File::Copy::copy($file, $plugin_dir);
}

1;

=head1 AUTHOR

Steffen Mueller <smueller@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008. Steffen Mueller

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
