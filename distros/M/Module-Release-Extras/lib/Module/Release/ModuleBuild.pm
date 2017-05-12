package Module::Release::ModuleBuild;

use strict;
use warnings;

use base qw(Exporter Module::Release);
our @EXPORT = qw(clean build_makefile);

=head1 NAME

Module::Release::ModuleBuild - grok Module::Build when using Module::Release

=head1 SYNOPSIS

In F<.releaserc>

  release_subclass Module::Release::Build

In your subclasses of Module::Release:

  use base qw(Module::Release::Build);

=head1 DESCRIPTION

Module::Release::ModuleBuild subclasses Module::Release, and rewrites
some methods so that modules that build using Module::Build (with a
Build.PL, and so on) can be released using Module::Release.

These methods are B<automatically> exported in to the callers namespace
using Exporter.

=cut

sub clean {
  my $self = shift;

  if(-e 'Build') {
    print "Cleaning directory... ";

    $self->run("$self->{perl} Build realclean 2>&1");
    print "done\n";
  } else {
    $self->SUPER::clean();
  }
}

sub build_makefile {
  my $self = shift;

  # If Build.PL exists then assume the module uses Module::Build.  If
  # this is the case, "make <anything>" should be "perl Build <anything>",
  # and the initial "perl Makefile.PL" becomes "perl Build.PL"
  #
  # In addition, many of the methods in Module::Release check for the
  # existence of Makefile.PL, even if they don't do anything with it.
  # So create a dummy Makefile.PL if one doesn't exist, to keep them
  # quiet.
  #
  # Otherwise, fall back to the default behaviour
  if(-e 'Build.PL') {
    print "Recreating build file... ";
    $self->{make} = 'perl Build';
    $self->run("$self->{perl} Build.PL 2>&1");
    print "done\n";

    if(! -e 'Makefile.PL') {
      print "Creating dummy Makefile.PL... ";
      open(F, '> Makefile.PL') or die "open() failed: $!\n";
      print F "# This is an automatically created file\n";
      close(F);
      print "done\n";
    }
  } else {
    $self->SUPER::build_makefile();
  }
}

=head1 AUTHOR

Nik Clayton <nik@FreeBSD.org>

Copyright 2004 Nik Clayton.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 BUGS

None known.

Bugs should be reported to me via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module::Release::Extras>.

=head1 SEE ALSO

Module::Release

=cut

1;
