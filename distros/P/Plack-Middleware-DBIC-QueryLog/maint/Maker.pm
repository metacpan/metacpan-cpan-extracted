package # Hide from PAUSE
  Maker;

use strict;
use warnings;

our $_caller = scalar(caller(1));
sub is_script { !$_caller }

our $_has_errors = 0;
sub has_errors { $_has_errors }

our $has_been_imported = 0;
sub import {
  if($has_been_imported) {
    return 1;
  } else {
    strict->import;
    warnings->import;
    &use_module_install;
    $has_been_imported = 1;
  }
}

sub installer_mode { -e 'META.yml' }

sub _use_module_install {
  package main;
  require inc::Module::Install;
  inc::Module::Install->import;
}

sub _try_use_module_install {
  eval {
    _use_module_install;
    1;
  }
}

sub use_module_install {
  if( &installer_mode ) {
    _use_module_install;
  } else {
    _try_use_module_install
      || log_missing_author_dependencies('Module::Install');
  }
}

sub module_install_author_plugins {
  'Module::Install::ReadmeMarkdownFromPod' => 'readme_markdown_from_pod',
  'Module::Install::Repository' => 'auto_set_repository',
  'Module::Install::Homepage' => 'auto_set_homepage',
  'Module::Install::ManifestSkip' => [manifest_skip => qw(clean) ],
  'Module::Install::AutoManifest' => 'auto_manifest';
}

sub extra_author_dependencies {
  'App::cpanminus',
  'local::lib',
  'App::local::lib::helper',
  'Module::Install',
  'App::cpanoutdated',
  'CPAN::Uploader'
}

sub list_author_dependencies {
  my %module_install_author_plugins = module_install_author_plugins;
  my @deps = (&extra_author_dependencies, keys %module_install_author_plugins);
  print join "\n", @deps;
  print "\n";
}

sub finalize_makefile {
  unless( &installer_mode ) {
    my %module_install_author_plugins = module_install_author_plugins;
    my @missing = grep { !eval "package main; use $_; 1" } keys %module_install_author_plugins;
    log_missing_author_dependencies(@missing)
      if @missing;

    foreach my $method_proto (values %module_install_author_plugins) {
      my ($method, @args) = ref $method_proto ? @$method_proto : ($method_proto);
      SCOPE_NO_STRICT_REFS: {
        no strict 'refs';
        &{"main::$method"}(@args);
      }
    }
  }

  SCOPE_DO_POSTAMBLE: {
    no strict 'refs';
    &{"main::postamble"}(&generate_postamble);
  }

  SCOPE_DO_FINALIZE_CMDS: {
    no strict 'refs';
    &{"main::auto_install"}();
    &{"main::WriteAll"}();
  }
}

sub generate_postamble {
<<"EOP";

updatedeps :
\tcpan-outdated -p | cpanm

pushtags :
\tgit commit -a -m "Release commit for $(VERSION)"
\tgit tag v$(VERSION) -m "release $(VERSION)"
\tgit push --tags
\tgit push

EOP
}

sub log_missing_author_dependencies {
  my @missing_modules = map { "\t$_\n" } @_;
  $_has_errors = 1;
  print <<"ERR";

You are in author mode but are missing the following modules:

@missing_modules

You are getting an error message because you are in author mode and are missing
some author only dependencies.  You should only see this message if you have
checked this code out from a repository.  If you are just trying to install
the code please use the CPAN version.  If you are an author you will need to
install the missing modules, or you can bootstrap all the requirements using
Task::BeLike::JJNAPIORK with:

  cpanm Task::BeLike::JJNAPIORK

If you think you are seeing this this message in error, please report it as a
bug to the author.

ERR

  exit;

}

sub run {
  require Getopt::Long;
  require Pod::Usage;
  my $parser = Getopt::Long::Parser->new(
    config => [ "no_ignore_case", "pass_through" ],
  );

  my ($show_help, $show_authordeps);
  $parser->getoptions(
    'help|?' => \$show_help,
    'authordeps' => \$show_authordeps,
  );

  Pod::Usage::pod2usage(1) if $show_help;
  list_author_dependencies if $show_authordeps;

  return 1;
}

sub run_if_script {
  my @caller = caller(1);
  if(is_script) {
    &run;
  } elsif($caller[1] =~m/Makefile\.PL$/) {
    __PACKAGE__->import;
  } else {
    1;
  }
}

END {
  finalize_makefile
    unless is_script || has_errors;
}

__PACKAGE__->run_if_script;

__END__

=head1 NAME

Maker - Manage your Makefile.PL and authoring requirements

=head1 SYNOPSIS

perl Maker.pm  [options]

 Options:
   --help            brief help message
   --authordeps      list author only dependencies

=head1 OPTIONS

=over 4

=item --help

Print a brief help message and exits.

=item --authordeps

Gives you a newline separated list of all the dependencies you need to install
in order to be able to usefully develop on the distribution we are making.

You could, for example, install like so:

    perl Maker.pm --authordeps | cpanm

=back

=head1 DESCRIPTION

This is a module intended to wrap L<Module::Install> and make it a bit more
friendly, as well as encapsulate a few of my most common development workflow
patterns.  Hopefully it will also make it a bit easier for other people to
contribute to my CPAN modules

=cut

