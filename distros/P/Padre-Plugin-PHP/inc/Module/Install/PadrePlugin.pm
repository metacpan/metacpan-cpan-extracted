#line 1
package Module::Install::PadrePlugin;

use strict;
use Module::Install::Base;

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '0.01';
	@ISA     = qw{Module::Install::Base};
}

#line 41

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

#line 96

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

#line 143
