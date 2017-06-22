package Module::Reader;
BEGIN { require 5.006 }
use strict;
use warnings;

our $VERSION = '0.003003';
$VERSION = eval $VERSION;

use Exporter (); BEGIN { *import = \&Exporter::import }
our @EXPORT_OK = qw(module_content module_handle);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

use File::Spec ();
use Scalar::Util qw(reftype refaddr openhandle);
use Carp qw(croak);
use Config ();
use Errno qw(EACCES);
use constant _OPEN_LAYERS     => "$]" >= 5.008_000 ? ':' : '';
use constant _ABORT_ON_EACCES => "$]" >= 5.017_001;
use constant _ALLOW_PREFIX    => "$]" >= 5.008009;
use constant _VMS             => $^O eq 'VMS' && !!require VMS::Filespec;
use constant _WIN32           => $^O eq 'MSWin32';
use constant _PMC_ENABLED     => !(
  exists &Config::non_bincompat_options
    ? grep { $_ eq 'PERL_DISABLE_PMC' } Config::non_bincompat_options()
    : $Config::Config{ccflags} =~ /(?:^|\s)-DPERL_DISABLE_PMC\b/
);
use constant _FAKE_FILE_FORMAT => do {
  my $uvx = $Config::Config{uvxformat} || '';
  $uvx =~ tr/"\0//d;
  $uvx ||= 'lx';
  "/loader/0x%$uvx/%s"
};

sub _mod_to_file {
  my $module = shift;
  (my $file = "$module.pm") =~ s{::}{/}g;
  $file;
}

sub module_content {
  my $opts = ref $_[-1] eq 'HASH' && pop @_ || {};
  my $module = shift;
  $opts->{inc} = [@_]
    if @_;
  __PACKAGE__->new($opts)->module($module)->content;
}

sub module_handle {
  my $opts = ref $_[-1] eq 'HASH' && pop @_ || {};
  my $module = shift;
  $opts->{inc} = [@_]
    if @_;
  __PACKAGE__->new($opts)->module($module)->handle;
}

sub new {
  my $class = shift;
  my %options;
  if (@_ == 1 && ref $_[-1]) {
    %options = %{(pop)};
  }
  elsif (@_ % 2 == 0) {
    %options = @_;
  }
  else {
    croak "Expected hash ref, or key value pairs.  Got ".@_." arguments.";
  }

  $options{inc} ||= \@INC;
  $options{found} = \%INC
    if exists $options{found} && $options{found} eq 1;
  $options{pmc} = _PMC_ENABLED
    if !exists $options{pmc};
  $options{open} = 1
    if !exists $options{open};
  $options{abort_on_eacces} = _ABORT_ON_EACCES
    if !exists $options{abort_on_eacces};
  $options{check_hooks_for_nonsearchable} = 1
    if !exists $options{check_hooks_for_nonsearchable};
  bless \%options, $class;
}

sub module {
  my ($self, $module) = @_;
  $self->file(_mod_to_file($module));
}

sub modules {
  my ($self, $module) = @_;
  $self->files(_mod_to_file($module));
}

sub file {
  my ($self, $file) = @_;
  $self->_find($file);
}

sub files {
  my ($self, $file) = @_;
  $self->_find($file, 1);
}

sub _searchable {
  my $file = shift;
    File::Spec->file_name_is_absolute($file) ? 0
  : _WIN32 && $file =~ m{^\.\.?[/\\]}        ? 0
  : $file =~ m{^\.\.?/}                      ? 0
                                             : 1
}

sub _find {
  my ($self, $file, $all) = @_;

  my @found;
  eval {
    if (my $found = $self->{found}) {
      if (defined( my $full = $found->{$file} )) {
        my $open = length ref $full ? $self->_open_ref($full, $file)
                                    : $self->_open_file($full, $file);
        push @found, $open
          if $open;
      }
    }
  };
  if (!$all) {
    return $found[0]
      if @found;
    die $@
      if $@;
  }

  my $searchable = _searchable($file);
  if (!$searchable) {
    my $open = $self->_open_file($file);
    if ($all) {
      push @found, $open;
    }
    elsif ($open) {
      return $open;
    }
    else {
      croak "Can't locate $file";
    }
  }

  my $search = $self->{inc};
  for my $inc (@$search) {
    my $open;
    if (!$searchable) {
      last
        if !$self->{check_hooks_for_nonsearchable};
      next
        if !length ref $inc;
    }
    eval {
      if (!length ref $inc) {
        my $full = _VMS ? VMS::Filespec::unixpath($inc) : $inc;
        $full =~ s{/?$}{/};
        $full .= $file;
        $open = $self->_open_file($full, $file, $inc);
      }
      else {
        $open = $self->_open_ref($inc, $file);
      }
      push @found, $open
        if $open;
    };
    if (!$all) {
      return $found[0]
        if @found;
      die $@
        if $@;
    }
  }
  croak "Can't locate $file"
    if !$all;
  return @found;
}

sub _open_file {
  my ($self, $full, $file, $inc) = @_;
  $file = $full
    if !defined $file;
  for my $try (
    ($self->{pmc} && $file =~ /\.pm\z/ ? $full.'c' : ()),
    $full,
  ) {
    my $pmc = $full ne $try;
    if (-e $try) {
      next
        if -d _ || -b _;
      if (open my $fh, '<'._OPEN_LAYERS, $try) {
        return Module::Reader::File->new(
          filename        => $file,
          ($self->{open} ? (raw_filehandle => $fh) : ()),
          found_file      => $full,
          disk_file       => $try,
          is_pmc          => $pmc,
          (defined $inc ? (inc_entry => $inc) : ()),
        );
      }
    }

    croak "Can't locate $file:   $full: $!"
      if $self->{abort_on_eacces} && $! == EACCES && !$pmc;
  }
  return;
}

sub _open_ref {
  my ($self, $inc, $file) = @_;

  my @cb;
  {
    # strings in arrayrefs are taken as sub names relative to main
    package
      main;
    no strict 'refs';
    no warnings 'uninitialized';
    @cb = defined Scalar::Util::blessed $inc ? $inc->INC($file)
        : ref $inc eq 'ARRAY'                ? $inc->[0]->($inc, $file)
                                             : $inc->($inc, $file);
  }

  return
    unless length ref $cb[0];

  my $fake_file = sprintf _FAKE_FILE_FORMAT, refaddr($inc), $file;

  my $fh;
  my $prefix;
  my $cb;
  my $cb_options;

  if (_ALLOW_PREFIX && reftype $cb[0] eq 'SCALAR') {
    $prefix = shift @cb;
  }

  if ((reftype $cb[0]||'') eq 'GLOB' && openhandle $cb[0]) {
    $fh = shift @cb;
  }

  if ((reftype $cb[0]||'') eq 'CODE') {
    $cb = $cb[0];
    # only one or zero callback options will be passed
    $cb_options = @cb > 1 ? [ $cb[1] ] : undef;
  }
  elsif (!defined $fh && !defined $prefix) {
    return;
  }
  return Module::Reader::File->new(
    filename => $file,
    found_file => $fake_file,
    inc_entry => $inc,
    (defined $prefix ? (prefix => $prefix) : ()),
    (defined $fh ? (raw_filehandle => $fh) : ()),
    (defined $cb ? (read_callback => $cb) : ()),
    (defined $cb_options ? (read_callback_options => $cb_options) : ()),
  );
}

sub inc   { $_[0]->{inc} }
sub found { $_[0]->{found} }
sub pmc   { $_[0]->{pmc} }
sub open  { $_[0]->{open} }

{
  package Module::Reader::File;
  use constant _OPEN_STRING => "$]" >= 5.008 || !require IO::String;
  use Carp 'croak';

  sub new {
    my ($class, %opts) = @_;
    my $filename = $opts{filename};
    if (!exists $opts{module} && $opts{filename}
      && $opts{filename} =~ m{\A(\w+(?:/\w+)?)\.pm\z}) {
      my $module = $1;
      $module =~ s{/}{::}g;
      $opts{module} = $module;
    }
    bless \%opts, $class;
  }

  sub filename              { $_[0]->{filename} }
  sub module                { $_[0]->{module} }
  sub found_file            { $_[0]->{found_file} }
  sub disk_file             { $_[0]->{disk_file} }
  sub is_pmc                { $_[0]->{is_pmc} }
  sub inc_entry             { $_[0]->{inc_entry} }
  sub read_callback         { $_[0]->{read_callback} }
  sub read_callback_options { $_[0]->{read_callback_options} }
  sub raw_filehandle        {
    $_[0]->{raw_filehandle} ||= !$_[0]->{disk_file} ? undef : do {
      open my $fh, '<'.Module::Reader::_OPEN_LAYERS, $_[0]->{disk_file}
        or croak "Can't locate $_[0]->{disk_file}";
      $fh;
    };
  }

  sub content {
    my $self = shift;
    return $self->{content}
      if exists $self->{content};
    my $fh = $self->raw_filehandle;
    my $cb = $self->read_callback;
    my $content = defined $self->{prefix} ? ${$self->{prefix}} : '';
    if ($fh && !$cb) {
      local $/;
      $content .= <$fh>;
    }
    if ($cb) {
      my @params = @{$self->read_callback_options||[]};
      while (1) {
        local $_ = $fh ? <$fh> : '';
        $_ = ''
          if !defined;
        # perlfunc/require says that the first parameter will be a reference the
        # sub itself.  this is wrong.  0 will be passed.
        last if !$cb->(0, @params);
        $content .= $_;
      }
    }
    return $self->{content} = $content;
  }

  sub handle {
    my $self = shift;
    my $fh = $self->raw_filehandle;
    if ($fh && !$self->read_callback && -f $fh) {
      open my $dup, '<&', $fh
        or croak "can't dup file handle: $!";
      return $dup;
    }
    my $content = $self->content;
    if (_OPEN_STRING) {
      open my $fh, '<', \$content;
      return $fh;
    }
    else {
      return IO::String->new($content);
    }
  }
}

1;

__END__

=head1 NAME

Module::Reader - Find and read perl modules like perl does

=head1 SYNOPSIS

  use Module::Reader;

  my $reader      = Module::Reader->new;
  my $module      = $reader->module("My::Module");
  my $filename    = $module->found_file;
  my $content     = $module->content;
  my $file_handle = $module->handle;

  # search options
  my $other_reader = Module::Reader->new(inc => ["/some/lib/dir", "/another/lib/dir"]);
  my $other_reader2 = Module::Reader->new(found => { 'My/Module.pm' => '/a_location.pm' });

  # Functional Interface
  use Module::Reader qw(module_handle module_content);
  my $io = module_handle('My::Module');
  my $content = module_content('My::Module');


=head1 DESCRIPTION

This module finds modules in C<@INC> using the same algorithm perl does.  From
that, it will give you the source content of a module, the file name (where
available), and how it was found.  Searches (and content) are based on the same
internal rules that perl uses for F<require|perlfunc/require> and
F<do|perlfunc/do>.

=head1 EXPORTS

=head2 module_handle ( $module_name, @search_directories )

Returns an IO handle for the given module.

=head2 module_content ( $module_name, @search_directories )

Returns the content of a given module.

=head1 ATTRIBUTES

=over 4

=item inc

An array reference containing a list of directories or hooks to search for
modules or files.  This will be used in the same manner that
L<require|perlfunc/require> uses L<< C<@INC>|perlvar/@INC >>.  If not provided,
L<< C<@INC>|perlvar/@INC >> itself will be used.

=item found

A hash reference of module filenames (of C<My/Module.pm> format>) to files that
exist on disk, working the same as L<< C<%INC>|perlvar/%INC >>.  The values can
optionally be an L<< C<@INC> hook|perlfunc/require >>.  This option can also be
1, in which case L<< C<%INC>|perlfunc/%INC >> will be used instead.

=item pmc

A boolean controlling if C<.pmc> files should be found in preference to C<.pm>
files.  If not specified, the same behavior perl was compiled with will be used.

=item open

A boolean controlling if the files found will be opened immediately when found.
Defaults to true.

=item abort_on_eacces

A boolean controlling if an error should be thrown or if the path should be
skipped when encountering C<EACCES> (access denied) errors.  Defaults to true
on perl 5.18 and above, matching the behavior of L<require|perlfunc/require>.

=item check_hooks_for_nonsearchable

For non-searchable paths (absolute paths and those starting with C<./> or
C<../>) attempt to check the hook items (and not the directories) in C<@INC> if
the file cannot be found directly.  This matches the behavior of perl.  Defaults
to true.

=back

=head1 METHODS

=head2 module

Returns a L<file object|/FILE OBJECTS> for the given module name.  If the module
can't be found, an exception will be raised.

=head2 file

Returns a L<file object|/FILE OBJECTS> for the given file name.  If the file
can't be found, an exception will be raised.  For absolute paths, or files
starting with C<./> or C<../> (and C<.\> or C<..\> on Windows), no directory
search will be performed.

=head2 modules

Returns an array of L<file objects|/FILE OBJECTS> for a given module name.  This
will give every file that could be loaded based on the L</inc> options.

=head2 files

Returns an array of L<file objects|/FILE OBJECTS> for a given file name.  This
will give every file that could be loaded based on the L</inc> options.

=head1 FILE OBJECTS

The file objects returned represent an entry that could be found in
L<< C<@INC>|perlvar/@INC >>.  While they will generally be files that exist on
the file system somewhere, they may also represent files that only exist only in
memory or have arbitrary filters applied.

=head2 FILE METHODS

=head3 filename

The filename that was searched for.

=head3 module

If a module was searched for, or a file of the matching form (C<My/Module.pm>),
this will be the module searched for.

=head3 found_file

The path to the file found by L<require|perlfunc/require>.

This may not represent an actual file that exists, but the file name that perl
will use for the file for things like L<caller|perlfunc/caller> or
L<__FILE__|perlfunc/__FILE__>.

For C<.pmc> files, this will be the C<.pm> form of the file.

For L<< C<@INC> hooks|perlfunc/require >> this will be a file name of the form
C</loader/0x123456abcdef/My/Module.pm>, matching how perl treats them internally.

=head3 disk_file

The path to the file that exists on disk.  When the file is found via an
L<< C<@INC> hook|perlfunc/require >>, this will be undef.

=head3 content

The content of the found file.

=head3 handle

A file handle to the found file's content.

=head3 is_pmc

A boolean value representing if the file found was C<.pmc> variant of the file
requested.

=head3 inc_entry

The directory or L<hook|perlfunc/require> that was used to find the given file
or module.  If L</found> is used, this may be undef.

=head2 RAW HOOK DATA

File objects also have methods for the raw file handle and read callbacks used
to read a file.  Interacting with the handle or callback can impact the return
values of L</content> and L</handle>, and vice versa.  It should generally be
avoided unless you are introspecting the F<< C<@INC> hooks|perlfunc/require >>.

=head3 raw_filehandle

The raw file handle to the file found.  This will be either a file handle to a
file found on disk, or something returned by an
F<< C<@INC> hook|perlfunc/require >>.  The hook callback, if it exists, will not
be taken into account by this method.

=head3 read_callback

A callback used to read content, or modify a file handle from an C<@INC> hook.

=head3 read_callback_options

An array reference of arguments to send to the read callback whem reading or
modifying content from a file handle.  Will contain either zero or one entries.

=head1 SEE ALSO

Numerous other modules attempt to do C<@INC> searches similar to this module,
but no other module accurately represents how perl itself uses
L<< C<@INC>|perlvar/@INC >>.  Most don't match perl's behavior regarding
character and block devices, directories, or permissions.  Often, C<.pmc> files
are not taken into account.

Some of these modules have other use cases.  The following comments are
primarily related to their ability to search C<@INC>.

=over 4

=item L<App::moduleswhere>

Only available as a command line utility.  Inaccurately gives the first file
found on disk in C<@INC>.

=item L<App::whichpm>

Inaccurately gives the first file found on disk in C<@INC>.

=item L<Class::Inspector>

For unloaded modules, inaccurately checks if a module exists.

=item L<Module::Data>

Same caveats as L</Path::ScanINC>.

=item L<Module::Filename>

Inaccurately gives the first file found on disk in C<@INC>.

=item L<Module::Finder>

Inaccurately searches for C<.pm> and C<.pmc> files in subdirectories of C<@INC>.

=item L<Module::Info>

Inaccurately searches C<@INC> for files and gives inaccurate information for the
files that it finds.

=item L<Module::Locate>

Inaccurately searches C<@INC> for matching files.  Attempts to handle hooks, but
handles most cases wrong.

=item L<Module::Mapper>

Searches for C<.pm> and C<.pod> files in relatively unpredictable fashion,
based usually on the current directory.  Optionally, can inaccurately scan
C<@INC>.

=item L<Module::Metadata>

Primarily designed as a version number extractor.  Meant to find files on disk,
avoiding the nuance involved in perl's file loading.

=item L<Module::Path>

Inaccurately gives the first file found on disk in C<@INC>.

=item L<Module::Util>

Inaccurately searches for modules, ignoring C<@INC> hooks.

=item L<Path::ScanINC>

Inaccurately searches for files, with confusing output for C<@INC> hooks.

=item L<Pod::Perldoc>

Primarily meant for searching for related documentation.  Finds related module
files, or sometimes C<.pod> files.  Unpredictable search path.

=back

=head1 AUTHOR

haarg - Graham Knop (cpan:HAARG) <haarg@haarg.org>

=head2 CONTRIBUTORS

None yet.

=head1 COPYRIGHT

Copyright (c) 2013 the Module::Reader L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut
