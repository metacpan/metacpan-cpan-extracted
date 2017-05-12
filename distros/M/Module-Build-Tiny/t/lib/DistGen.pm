package DistGen;

use strict;

our $VERSION = '0.01';
our $VERBOSE = 0;

use Carp;

use Cwd ();
use File::Basename ();
use File::Find ();
use File::Path ();
use File::Spec ();
use File::Temp ();
use IO::File ();
use Data::Dumper ();
use Exporter 5.57 'import';

our @EXPORT_OK = qw(undent);

sub undent {
  my ($string) = @_;

  my ($space) = $string =~ m/^(\s+)/;
  $string =~ s/^$space//gm;

  return($string);
}

sub chdir_all ($) {
  # OS/2 has "current directory per disk", undeletable;
  # doing chdir() to another disk won't change cur-dir of initial disk...
  chdir('/') if $^O eq 'os2';
  chdir shift;
}

########################################################################

my $orig_cwd = Cwd::cwd;
END { chdir_all($orig_cwd); }

sub new {
  my $self = bless {}, shift;
  $self->reset(@_);
}

sub reset {
  my $self = shift;
  my %options = @_;

  $options{name} ||= 'Simple';
  $options{dir} ||= File::Spec->rel2abs(File::Temp::tempdir(
    DIR => File::Spec->curdir, CLEANUP => 1
  ));

  my %data = (
    %options,
  );
  %$self = %data;

  $self->{filedata} = {};
  $self->{pending}{change} = {};

  # start with a fresh, empty directory
  if ( -d $self->dirname ) {
    warn "Warning: Removing existing directory '@{[$self->dirname]}'\n";
    File::Path::rmtree( $self->dirname );
  }
  File::Path::mkpath( $self->dirname );

  $self->_gen_default_filedata();

  return $self;
}

sub remove {
  my $self = shift;
  $self->chdir_original if($self->did_chdir);
  File::Path::rmtree( $self->dirname );
  return $self;
}

sub revert {
  my ($self, $file) = @_;
  if ( defined $file ) {
    delete $self->{filedata}{$file};
    delete $self->{pending}{$_}{$file} for qw/change remove/;
  }
  else {
    delete $self->{filedata}{$_} for keys %{ $self->{filedata} };
    for my $pend ( qw/change remove/ ) {
      delete $self->{pending}{$pend}{$_} for keys %{ $self->{pending}{$pend} };
    }
  }
  $self->_gen_default_filedata;
}

sub _gen_default_filedata {
  my $self = shift;

  # TODO maybe a public method like this (but with a better name?)
  my $add_unless = sub {
    my $self = shift;
    my ($member, $data) = @_;
    $self->add_file($member, $data) unless($self->{filedata}{$member});
  };

  $self->$add_unless('Build.PL', undent(<<"      ---"));
      use lib 'inc'; use Module::Build::Tiny;Build_PL(\@ARGV);
      ---

  my $module_filename =
    join( '/', ('lib', split(/::/, $self->{name})) ) . '.pm';

  my $module_name = $self->{name};
  (my $dist_name = $module_name) =~ s/::/-/g;

  $self->$add_unless($module_filename, undent(<<"      ---"));
      package $module_name;

      use vars qw( \$VERSION );
      \$VERSION = '0.01';

      use strict;

      use Carp 0 ();

      1;

      __END__

      =head1 NAME

      $module_name - Perl extension for blah blah blah

      =head1 DESCRIPTION

      Stub documentation for $module_name.

      =head1 AUTHOR

      A. U. Thor, a.u.thor\@a.galaxy.far.far.away

      =cut
      ---

  $self->$add_unless('t/basic.t', undent(<<"    ---"));
    use Test::More 0.23 tests => 1;
    use strict;

    use $module_name;
    ok 1;
    ---

  $self->$add_unless('META.yml', undent(<<"    ----"));
    ---
    name: $dist_name
    version: 0.001
    author:
      - 'David Golden <dagolden\@cpan.org>'
      - 'Leon Timmermans <leont\@cpan.org>'
    abstract: 'A testing dist'
    license: perl
    requires:
      perl: 5.006
      Module::Build::Tiny: 0
    generated_by: Leon Timmermans
    dynamic_config: 0
    meta-spec:
      url: http://module-build.sourceforge.net/META-spec-v1.4.html
      version: 1.4
    ----
}

sub name { shift()->{name} }

sub dirname {
  my $self = shift;
  my $dist = join( '-', split( /::/, $self->{name} ) );
  return File::Spec->catdir( $self->{dir}, $dist );
}

sub _real_filename {
  my $self = shift;
  my $filename = shift;
  return File::Spec->catfile( split( /\//, $filename ) );
}

sub regen {
  my $self = shift;
  my %opts = @_;

  my $dist_dirname = $self->dirname;

  if ( $opts{clean} ) {
    $self->clean() if -d $dist_dirname;
  } else {
    # TODO: This might leave dangling directories; e.g. if the removed file
    # is 'lib/Simple/Simon.pm', the directory 'lib/Simple' will be left
    # even if there are no files left in it. However, clean() will remove it.
    my @files = keys %{$self->{pending}{remove}};
    foreach my $file ( @files ) {
      my $real_filename = $self->_real_filename( $file );
      my $fullname = File::Spec->catfile( $dist_dirname, $real_filename );
      if ( -e $fullname ) {
        1 while File::Path::rmtree($fullname, 0, 0);
      }
      print "Unlinking pending file '$file'\n" if $VERBOSE;
      delete( $self->{pending}{remove}{$file} );
    }
  }

  foreach my $file ( keys( %{$self->{filedata}} ) ) {
    my $real_filename = $self->_real_filename( $file );
    my $fullname = File::Spec->catfile( $dist_dirname, $real_filename );

    if  ( ! -e $fullname ||
        (   -e $fullname && $self->{pending}{change}{$file} ) ) {

      print "Changed file '$file'.\n" if $VERBOSE;

      my $dirname = File::Basename::dirname( $fullname );
      unless ( -d $dirname ) {
        File::Path::mkpath( $dirname ) or do {
          die "Can't create '$dirname'\n";
        };
      }

      if ( -e $fullname ) {
        1 while unlink( $fullname );
      }

      my $fh = IO::File->new(">$fullname") or do {
        die "Can't write '$fullname'\n";
      };
      print $fh $self->{filedata}{$file};
      close( $fh );
    }

    delete( $self->{pending}{change}{$file} );
  }

  return $self;
}

sub clean {
  my $self = shift;

  my $here  = Cwd::abs_path();
  my $there = File::Spec->rel2abs( $self->dirname() );

  if ( -d $there ) {
    chdir( $there ) or die "Can't change directory to '$there'\n";
  } else {
    die "Distribution not found in '$there'\n";
  }

  my %names;
  foreach my $file ( keys %{$self->{filedata}} ) {
    my $filename = $self->_real_filename( $file );
    my $dirname = File::Basename::dirname( $filename );

    $names{$filename} = 0;

    print "Splitting '$dirname'\n" if $VERBOSE;
    my @dirs = File::Spec->splitdir( $dirname );
    while ( @dirs ) {
      my $dir = ( scalar(@dirs) == 1
                  ? $dirname
                  : File::Spec->catdir( @dirs ) );
      if (length $dir) {
        print "Setting directory name '$dir' in \%names\n" if $VERBOSE;
        $names{$dir} = 0;
      }
      pop( @dirs );
    }
  }

  File::Find::finddepth( sub {
    my $name = File::Spec->canonpath( $File::Find::name );

    if ( not exists $names{$name} ) {
      print "Removing '$name'\n" if $VERBOSE;
      File::Path::rmtree( $_ );
    }
  }, File::Spec->curdir );


  chdir_all( $here );
  return $self;
}

sub add_file {
  my $self = shift;
  $self->change_file( @_ );
}

sub remove_file {
  my $self = shift;
  my $file = shift;
  unless ( exists $self->{filedata}{$file} ) {
    warn "Can't remove '$file': It does not exist.\n" if $VERBOSE;
  }
  delete( $self->{filedata}{$file} );
  $self->{pending}{remove}{$file} = 1;
  return $self;
}

sub change_file {
  my $self = shift;
  my $file = shift;
  my $data = shift;
  $self->{filedata}{$file} = $data;
  $self->{pending}{change}{$file} = 1;
  return $self;
}

sub get_file {
  my $self = shift;
  my $file = shift;
  exists($self->{filedata}{$file}) or croak("no such entry: '$file'");
  return $self->{filedata}{$file};
}

sub chdir_in {
  my $self = shift;
  $self->{original_dir} ||= Cwd::cwd; # only once!
  my $dir = $self->dirname;
  chdir($dir) or die "Can't chdir to '$dir': $!";
  return $self;
}
########################################################################

sub did_chdir { exists shift()->{original_dir} }

########################################################################

sub chdir_original {
  my $self = shift;

  my $dir = delete $self->{original_dir};
  chdir_all($dir) or die "Can't chdir to '$dir': $!";
  return $self;
}
########################################################################

1;

# vim:ts=2:sw=2:et:sta
__END__


=head1 NAME

DistGen - Creates simple distributions for testing.

=head1 SYNOPSIS

  use DistGen;

  # create distribution and prepare to test
  my $dist = DistGen->new(name => 'Foo::Bar');
  $dist->chdir_in;

  # change distribution files
  $dist->add_file('t/some_test.t', $contents);
  $dist->change_file('MANIFEST.SKIP', $new_contents);
  $dist->remove_file('t/some_test.t');
  $dist->regen;

  # undo changes and clean up extraneous files
  $dist->revert;
  $dist->clean;

  # start over as a new distribution
  $dist->reset( name => 'Foo::Bar' );
  $dist->chdir_in;

=head1 USAGE

A DistGen object manages a set of files in a distribution directory.

The C<new()> constructor initializes the object and creates an empty
directory for the distribution. It does not create files or chdir into
the directory.  The C<reset()> method re-initializes the object in a
new directory with new parameters.  It also does not create files or change
the current directory.

Some methods only define the target state of the distribution.  They do B<not>
make any changes to the filesystem:

  add_file
  change_file
  change_build_pl
  remove_file
  revert

Other methods then change the filesystem to match the target state of
the distribution:

  clean
  regen
  remove

Other methods are provided for a convenience during testing. The
most important is the one to enter the distribution directory:

  chdir_in

=head1 API

=head2 Constructors

=head3 new()

Create a new object and an empty directory to hold the distribution's files.
If no C<dir> option is provided, it defaults to MBTest->tmpdir, which sets
a different temp directory for Perl core testing and CPAN testing.

The C<new> method does not write any files -- see L</regen()> below.

  my $dist = DistGen->new(
    name        => 'Foo::Bar',
    dir         => MBTest->tmpdir,
  );

The parameters are as follows.

=over

=item name

The name of the module this distribution represents. The default is
'Simple'.  This should be a "Foo::Bar" (module) name, not a "Foo-Bar"
dist name.

=item dir

The (parent) directory in which to create the distribution directory.  The
distribution will be created under this according to the "dist" form of C<name>
(e.g. "Foo-Bar".)  Defaults to a temporary directory.

  $dist = DistGen->new( dir => '/tmp/MB-test' );
  $dist->regen;

  # distribution files have been created in /tmp/MB-test/Simple

=back

The following files are added as part of the default distribution:

  Build.PL
  lib/Simple.pm # based on name parameter
  t/basic.t

The C<reset> method re-initializes the object as if it were generated
from a fresh call to C<new>.  It takes the same optional parameters as C<new>.

  $dist->reset( name => 'Foo::Bar', xs => 0 );

=head2 Adding and editing files

Note that C<$filename> should always be specified with unix-style paths,
and are relative to the distribution root directory, e.g. C<lib/Module.pm>.

No changes are made to the filesystem until the distribution is regenerated.

=head3 add_file()

Add a $filename containing $content to the distribution.

  $dist->add_file( $filename, $content );

=head3 change_file()

Changes the contents of $filename to $content. No action is performed
until the distribution is regenerated.

  $dist->change_file( $filename, $content );

=head3 change_build_pl()

A wrapper around change_file specifically for setting Build.PL.  Instead
of file C<$content>, it takes a hash-ref of Module::Build constructor
arguments:

  $dist->change_build_pl(
    {
      module_name         => $dist->name,
      dist_version        => '3.14159265',
      license             => 'perl',
      create_readme       => 1,
    }
  );

=head3 get_file

Retrieves the target contents of C<$filename>.

  $content = $dist->get_file( $filename );

=head3 remove_file()

Removes C<$filename> from the distribution.

  $dist->remove_file( $filename );

=head3 revert()

Returns the object to its initial state, or given a $filename it returns that
file to its initial state if it is one of the built-in files.

  $dist->revert;
  $dist->revert($filename);

=head2 Changing the distribution directory

These methods immediately affect the filesystem.

=head3 regen()

Regenerate all missing or changed files.  Also deletes any files
flagged for removal with remove_file().

  $dist->regen(clean => 1);

If the optional C<clean> argument is given, it also calls C<clean>.  These
can also be chained like this, instead:

  $dist->clean->regen;

=head3 clean()

Removes any files that are not part of the distribution.

  $dist->clean;

=head3 remove()

Changes back to the original directory and removes the distribution
directory (but not the temporary directory set during C<new()>).

  $dist = DistGen->new->chdir->regen;
  # ... do some testing ...

  $dist->remove->chdir_in->regen;
  # ... do more testing ...

This is like a more aggressive form of C<clean>.  Generally, calling C<clean>
and C<regen> should be sufficient.

=head2 Changing directories

=head3 chdir_in

Change directory into the dist root.

  $dist->chdir_in;

=head3 chdir_original

Returns to whatever directory you were in before chdir_in() (regardless
of the cwd.)

  $dist->chdir_original;

=head2 Command-line helpers

These use Module::Build->run_perl_script() to ensure that Build.PL or Build are
run in a separate process using the current perl interpreter.  (Module::Build
is loaded on demand).  They also ensure appropriate naming for operating
systems that require a suffix for Build.

=head2 Properties

=head3 name()

Returns the name of the distribution.

  $dist->name: # e.g. Foo::Bar

=head3 dirname()

Returns the directory where the distribution is created.

  $dist->dirname; # e.g. t/_tmp/Simple

=head2 Functions

=head3 undent()

Removes leading whitespace from a multi-line string according to the
amount of whitespace on the first line.

  my $string = undent("  foo(\n    bar => 'baz'\n  )");
  $string eq "foo(
    bar => 'baz'
  )";

=cut

