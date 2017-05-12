package PAR::Indexer;

use 5.006;
use strict;
use warnings;

use Carp qw/croak/;
use File::Spec ();
use File::Path ();
use Cwd ();
use PAR::Dist ();
use ExtUtils::Manifest;
require ExtUtils::MM;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = ();
our %EXPORT_TAGS = (
    all => [
        qw(scan_par_for_packages scan_par_for_scripts dependencies_from_meta_yml)
    ],
);
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our $VERSION = '0.91';

=head1 NAME

PAR::Indexer - Scan a PAR distro for packages and scripts

=head1 SYNOPSIS

  use PAR::Indexer qw(scan_par_for_packages scan_par_for_scripts dependencies_from_meta_yml);
  my $pkgs_hash    = scan_par_for_packages($parfile);
  my $scripts_hash = scan_par_for_scripts($parfile);
  
  my $dependencies = dependencies_from_meta_yml(\%meta_yml_hash);

=head1 DESCRIPTION

This module contains code for scanning a PAR distribution for
packages and scripts. The code was adapted from the PAUSE indexer.

This module is used by PAR::Repository for injection of new PAR
distributions.

=head2 EXPORT

None by default, but you can choose to export subroutines
with the typical C<Exporter> semantics.

=head1 FUNCTIONS

=cut

=head2 scan_par_for_packages

First argument must be the path and file name of a PAR
distribution. Scans that distribution for .pm files and scans
those for packages and versions. Returns a hash of
the package names as keys and hash refs as values. The hashes contain
the path to the file in the PAR as the key "file" and (if found)
the version of the package is the key "version".

Returns undef on error.

(The structure returned should be exactly what you get when you
transform the C<provides> section of a F<META.yml> file
into a Perl data structure using a YAML reader.)

=cut

sub scan_par_for_packages {
  my $par = shift;

  my $old_path = Cwd::cwd();

  my (undef, $tmpdir) = PAR::Dist::_unzip_to_tmpdir(dist => $par);
  chdir($tmpdir);
  my @pmfiles = grep { /\.pm$/i } keys %{ExtUtils::Manifest::manifind()};

  my %pkg;
  foreach my $pmfile (@pmfiles) {
    my $hash = _parse_packages_from_pm($pmfile);
    next if not defined $hash;
    foreach my $namespace (keys %$hash) {
      my $main_ns = $pkg{$namespace};
      my $this_pm = $hash->{$namespace};
      if (not defined $main_ns->{version} or $main_ns->{version} eq 'undef'
          or (
            defined $this_pm->{version}
            and $this_pm->{version} ne 'undef'
            and $main_ns->{version} < $this_pm->{version})
      ) {
        $pkg{$namespace} = $this_pm;
      }
    }
  }

  chdir($old_path);
  File::Path::rmtree([$tmpdir]);
  return \%pkg;
}


sub _parse_packages_from_pm {
  my $file = shift;
  my %pkg;
  open my $fh, '<', $file or return undef;

  # stealing from PAUSE indexer.
  local $/ = "\n";
  my $inpod = 0;
  PLINE: while (<$fh>) {
    chomp;
    my($pline) = $_;
    $inpod = $pline =~ /^=(?!cut)/ ? 1 : $pline =~ /^=cut/ ? 0 : $inpod;
    next if $inpod or substr($pline,0,4) eq "=cut";

    $pline =~ s/\#.*//;
    next if $pline =~ /^\s*$/;
    last PLINE if $pline =~ /\b__(END|DATA)__\b/;

    my $pkg;
    if (
        $pline =~ m{
        (.*)
        \bpackage\s+
        ([\w\:\']+)
        \s*
        ( $ | [\}\;] )
        }x) {
      $pkg = $2;
    }

    if ($pkg) {
      # Found something

      # from package
      $pkg =~ s/\'/::/;
      next PLINE unless $pkg =~ /^[A-Za-z]/;
      next PLINE unless $pkg =~ /\w$/;
      next PLINE if $pkg eq "main";
      $pkg{$pkg}{file} = $file;
      my $version = MM->parse_version($file);
      $pkg{$pkg}{version} = $version if defined $version;
    }
  }

  close $fh;
  return \%pkg;
}


=head2 scan_par_for_scripts

First argument must be the path and file name of a PAR
distribution. Scans that distribution for executable files
and scans
those for versions. Returns a hash of
the script names as keys and hash refs as values. The hashes contain
the path to the file in the PAR as the key "file" and (if found)
the version of the script as the key "version".

Returns undef on error.

=cut

sub scan_par_for_scripts {
  my $par = shift;

  my $old_path = Cwd::cwd();

  my (undef, $tmpdir) = PAR::Dist::_unzip_to_tmpdir(dist => $par);
  chdir($tmpdir);
  my @scripts = grep { /^script\/(?!\.)/i or /^bin\/(?!\.)/i }
  keys %{ExtUtils::Manifest::manifind()};

  my %scr;
  foreach my $script (@scripts) {
    (undef, undef, my $scriptname) = File::Spec->splitpath($script);

    my $version = MM->parse_version($script);
    if ( not defined $scr{$scriptname}{version}
         or (defined $version and $scr{$scriptname}{version} < $version) )
    {
      $scr{$scriptname} = {
        file => $script,
        version => $version,
      };
    }
  }

  chdir($old_path);
  File::Path::rmtree([$tmpdir]);
  return \%scr;
}


=head2 dependencies_from_meta_yml

Determine the dependencies declared in F<META.yml>. Expects
a reference to a hash containing the parsed YAML tree as
first argument.

Returns essentially the merged C<configure_requires>, C<build_requires>,
and C<requires> hashes from the F<META.yml>. The order of precedence
is C<<requires > build_requires > configure_requires>>. If none
of the three sections is found, the function returns false. If any one of
them was found (even if empty), a hash reference will be returned.

=cut

sub dependencies_from_meta_yml {
  my $meta = shift;
  return() unless defined $meta and ref($meta) eq 'HASH';

  return() if not exists $meta->{requires}
              and not exists $meta->{build_requires}
              and not exists $meta->{configure_requires};

  my $req = {};

  foreach my $source (qw(requires build_requires configure_requires)) {
    next
      if not exists $meta->{$source} or not ref($meta->{$source}) eq 'HASH';
    my $this_req = $meta->{$source};

    foreach my $module (keys %$this_req) {
      $req->{$module} = $this_req->{$module}
        if not exists $req->{$module};
    }
  }

  return $req;
}

1;
__END__

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

The original code for scanning modules was taken from the PAUSE
sources which were written by Andreas Koenig.

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2009 by Steffen Mueller

Except for the code copied from the PAUSE scanner which is
(C) Andreas Koenig.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
