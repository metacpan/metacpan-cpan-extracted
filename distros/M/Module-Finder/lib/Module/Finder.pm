package Module::Finder;
$VERSION = v0.1.5;

use warnings;
use strict;
use Carp;

use File::Find ();
use File::Spec ();
use constant {fs => 'File::Spec'};

BEGIN {
package Module::Finder::Info;
use File::Spec ();
use constant {fs => 'File::Spec'};

use Class::Accessor::Classy;
with 'new';
#with 'clone'; # todo for C::A::C ?
ro 'filename';    # absolute path
ro 'module_path'; # relative to search directory (part 2 of filename)
ro 'inc_path';    # other part of filename
ro 'module_name'; # My::Module::Name
no  Class::Accessor::Classy;

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  $self->{inc_path} = fs->rel2abs($self->{inc_path});
  $self->{filename} = fs->catfile(
    $self->{inc_path},
    $self->{module_path}
  );
  return($self);
} # end sub new
} # end Module::Finder::Info package

=head1 NAME

Module::Finder - find and query modules in @INC and/or elsewhere

=head1 SYNOPSIS

  use Module::Finder;
  my $finder = Module::Finder->new(
    dirs => ['/usr/local/junk/', '/junk/', @INC],
    paths => {
      'Module::Name::Prefix' => '-',   # no recursion - just *.pm
      'This::Path'           => '-/-', # only This/Path/*/*.pm
      'My'                   => '*',   # everything below My/
    },
  );

  # dirs searches @INC only if it is blank

  # the first request will cache search results
  my @modnames = $finder->modules;

  my @modinfos = $finder->module_infos;

  my $info = $finder->module_info('My::Found');

  # if you're creating/installing code, you might want to rescan
  $finder->reset;

=cut

use Class::Accessor::Classy;
with 'new';
ro 'paths';
ro 'name';
no  Class::Accessor::Classy;

=head2 new

  my $finder = Module::Finder->new(%args);

=over

=item globs

This isn't the same as shell glob syntax.  These globs say how deep (or
not) you want to look in a given path and whether you want to pickup
modules that appear along the way.  A list of shell glob equivalents
follows each one.

  /      just recurse              (*, */*, */*/*, ...)
  +      just this directory       (*)
  -/+    only one level down       (*/*)
  -/-/+  two levels down           (*/*/*)
  -/+/+  one and two levels down   (*/*, */*/*)
  +/+/+  zero thru two levels down (*, */*, */*/*)

If the glob spec is more that just "+", the trailing plus (which is
required to make sense) may be omitted (e.g. '-/+' and '-/' are
equivalent.)

=back

=cut

sub new {
  my $class = shift;
  (@_ % 2) and croak('odd number of elements in argument list');
  my %args = @_;

  my $self = {%args};
  bless($self, $class);
  $self->reset;
  return($self);
} # end subroutine new definition
########################################################################

=head2 _find

  $finder->_find;

=cut

sub _find {
  my $self = shift;

  exists($self->{_module_infos}) and return(%{$self->{_module_infos}});
  my $infos = $self->{_module_infos} = {};
  my @lookdirs = $self->_which_dirs;
  foreach my $look (@lookdirs) {
    my ($dir, $part, $nglob) = @$look;
    (-d $dir) or next;
    my $search_in = fs->catdir($dir, $part);
    if(my @globs = $self->_glob_parse($nglob)) {
      my $ret_dir = fs->rel2abs(fs->curdir);
      #warn "return to $ret_dir";
      chdir($dir) or die "cannot be in $dir";
      # things should be fairly sane once we're in the libdir
      # (famous last words?)
      foreach my $glob (map({$_, $_ . 'c'} @globs)) {
        my $look = join('/', fs->splitdir($part), $glob);
        foreach my $modpath (glob($look)) {
          (-e $modpath) or next;
          my $modname = join('::', fs->splitdir($modpath));
          $modname =~ s/\.pmc?$//;
          # TODO should I?
          # if(($modpath =~ m/\.pmc$/) and
          #   $infos->{$modname} and
          #   ($infos->{$modname}->inc_path eq $dir)) {
          #   next;
          # }
          my $obj = Module::Finder::Info->new(
            module_path => $modpath,
            inc_path    => '.', #$dir, # will get absolute in new()
            module_name => $modname,
          );
          $infos->{$modname} ||= [];
          push(@{$infos->{$modname}}, $obj);
        }
      }
      chdir($ret_dir) or die "ack";
    }
    else {
      my $wanted = sub {
        my $modpath = fs->abs2rel($_, $dir);
        return if($modpath eq $part);
        #warn "look $modpath";
        m/\.pmc?$/ or return;
        my $modname = join('::', fs->splitdir($modpath));
        $modname =~ s/\.pmc?$//;
        my $obj = Module::Finder::Info->new(
          module_path => $modpath,
          inc_path    => $dir,
          module_name => $modname,
        );
        $infos->{$modname} ||= [];
        push(@{$infos->{$modname}}, $obj);
      };
      # do the find
      (-e $search_in) or next;
      File::Find::find({wanted => $wanted, no_chdir => 1}, $search_in);
    }
  }

  return(%$infos);
} # end subroutine _find definition
########################################################################

=head2 _which_dirs

  my @dirs = $self->_which_dirs;

=cut

sub _which_dirs {
  my $self = shift;

  my @dirs = @{$self->{dirs}};
  my $paths = $self->paths;
  my $name = $self->name;
  if(defined($name)) { # make the glob be that filename
    $name =~ s#::#/#g;
    $name .= '.pm';
  }

  unless($paths) {
    return(map({[$_, '', ($name ? $name : '/')]} @dirs));
  }

  # TODO maybe bail if we get here and have $name
  # e.g. $path + $name is just $path::$name
  # somewhat sensible for multiple paths, but wouldn't that be a 'names'
  # thing instead?

  my @look_dirs;
  foreach my $dir (@dirs) {
    foreach my $path (keys(%$paths)) {
      #warn "check for $dir/$path";
      my $pathdir = fs->catdir(split(/::/, $path));
      if(-d fs->catdir($dir, $pathdir)) {
        push(@look_dirs,
          [
            $dir,
            $pathdir,
            ($name ? $name : $paths->{$path})
          ]
        );
      }
      #else {warn `pwd` ."-- no $dir/$path"};
    }
  }
  return(@look_dirs);
} # end subroutine _which_dirs definition
########################################################################

=head2 _glob_parse

  my $glob = $self->_glob_parse($glob);

=cut

sub _glob_parse {
  my $self = shift;
  my ($glob) = @_;
  (defined($glob) and length($glob)) or croak('glob must be defined');
  ($glob eq '/') and return; # recurse
  ($glob =~ m/\.pm$/) and return($glob); # explicit
  my @parts = split(/\//, $glob, -1);
  if($parts[-1] ne '') {
    ($parts[-1] eq '+') or
      croak("explicit trailing glob part must be + not '$parts[-1]'");
  }
  else {
    $parts[-1] = '+';
  }
  (1 == @parts) and return('*.pm');
  my @globs;
  my $base = '';
  foreach my $part (@parts) {
    $base .= '/*';
    if($part eq '+') {
      push(@globs, $base);
    }
    elsif($part eq '-') {
      # pass
    }
    else {
      croak "'$part' is not a valid glob segment";
    }
  }
  foreach my $glob (@globs) {
    $glob =~ s#^/##;
    $glob .= '.pm';
  }
  return(@globs);
} # end subroutine _glob_parse definition
########################################################################

=head2 reset

  $finder->reset;

=cut

sub reset {
  my $self = shift;

  if(my $dirs = $self->{dirs}) {
    ((ref($dirs) || '') eq 'ARRAY') or
      croak("'dirs' argument must be an array ref");
    my %seen;
    @$dirs = grep({exists($seen{$_}) ? 0 : ($seen{$_} = 1)} @$dirs);
  }
  else {
    $self->{dirs} = [@INC];
  }

  delete($self->{_module_infos});
} # end subroutine reset definition
########################################################################

=head2 modules

  my @modnames = $finder->modules;

=cut

sub modules {
  my $self = shift;

  my %infos = $self->_find;
  return(keys(%infos));
} # end subroutine modules definition
########################################################################

=head2 module_infos

Returns the info for the first hit of every found module.

  my %modinfos = $finder->module_infos;

=cut

sub module_infos {
  my $self = shift;
  my %infos = $self->_find;
  return(map({$_ => $infos{$_}[0]} keys(%infos)));
} # end subroutine module_infos definition
########################################################################

=head2 all_module_infos

Returns the info for all hits of every found module.  Each element of
the returned hash will be an array ref with one or more info objects.

  my %modinfos = $finder->all_module_infos;

=cut

sub all_module_infos {
  my $self = shift;
  my ($module) = @_;
  my %infos = $self->_find;
  return(%infos);
} # end subroutine all_module_infos definition
########################################################################

=head2 module_info

  my $info = $finder->module_info('My::Found');

=cut

sub module_info {
  my $self = shift;
  my ($module) = @_;
  my %infos = $self->_find;
  exists($infos{$module}) or return;
  my $inf = $infos{$module};
  return($inf->[0]);
} # end subroutine module_info definition
########################################################################

=head2 all_module_info

  my @info = $finder->all_module_info('My::Found');

=cut

sub all_module_info {
  my $self = shift;
  my ($module) = @_;
  my %infos = $self->_find;
  exists($infos{$module}) or return;
  my $inf = $infos{$module};
  return(@$inf);
} # end subroutine all_module_info definition
########################################################################


=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2006 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatseover.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

This module is inspired and/or informed by the following.  Maybe they do
what you want.

  File::Find
  File::Finder
  Module::Find
  Module::Require
  Module::Locate
  Module::Pluggable::Object
  Module::List

=cut

# vi:ts=2:sw=2:et:sta
1;
