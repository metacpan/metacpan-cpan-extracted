package Su::Process;

use strict;
use warnings;
use Exporter;
use File::Path;
use Data::Dumper;
use Test::More;
use Carp;
use Fatal qw(open close);

use Su::Template;
use Su::Log;

our @ISA = qw(Exporter);

our @EXPORT = qw(comp gen generate_proc generate_process);

our $DEBUG = 0;

# not used
my $MODULE_PATH = __FILE__;

our $PROCESS_BASE_DIR = "./";

our $PROCESS_DIR = "Procs";

=pod

=head1 NAME

Su::Process - A module to generate and execute user process.

=head1 SYNOPSIS

use Su::Process;

# Generate the Process file.

 generate_proc('pkg/SomeProc');

# Execute the Process and get it's result.

 $ret = gen("pkg/SomeProc");
 $ret = comp("pkg/SomeProc");

=head1 DESCRIPTION

Su::Process has a method to generate the template of the Process
module to describe user process.  These Processes are called from the
method Su::resolve.  The user Processes are also called directry by
the method L<Su::Process::gen|gen>. The method
L<Su::Process::comp|comp> is an alias of the method
L<Su::Process::gen|gen> for embed to the template like a component.

=head1 ATTRIBUTES

=head2 C<$SUPRESS_LOAD_ERROR>

For suppress the load error because of the specified module file is not found.

 $Su::Process::SUPPRESS_LOAD_ERROR = 1;

=cut

our $SUPPRESS_LOAD_ERROR = 0;

=head1 FUNCTIONS

=over

=cut

=item new()

A Constructor.

=cut

sub new {
  my $self = shift;

  my %h = @_ if @_;
  my $log = Su::Log->new;
  $h{logger} = $log;
  return bless \%h, $self;
} ## end sub new

sub import {
  my $self = shift;

  # Save import list and remove from hash.
  my %tmp_h        = @_;
  my $imports_aref = $tmp_h{import};
  delete $tmp_h{import};
  my $base = $tmp_h{base};
  my $dir  = $tmp_h{dir};
  Su::Log->trace( "base:" . Dumper($base) );
  Su::Log->trace( "dir:" . Dumper($dir) );

  #  print "base:" . Dumper($base) . "\n";
  #  print "dir:" . Dumper($dir) . "\n";

  $PROCESS_BASE_DIR = $base if $base;
  $PROCESS_DIR      = $dir  if $dir;

  if ( $base || $dir ) {
    $self->export_to_level( 1, $self, @{$imports_aref} );
  } else {

# If 'base' or 'dir' is not passed, then all of the parameters are required method names.
    $self->export_to_level( 1, $self, @_ );
  }

} ## end sub import

=item generate_process()

This function is just a synonym of the method L<generate_proc>.

=cut

sub generate_process {

  my $self = shift if ( ref $_[0] eq __PACKAGE__ );
  if ($self) {
    $self->generate_proc(@_);
  } else {
    generate_proc(@_);
  }
} ## end sub generate_process

=item generate_proc()

Generate the Process file to describe your own code in the method 'process'.
This method can be used from the command line like the following.

 perl -MSu::Process -e '{generate_proc("MainProc")}'

If generation is success, this subroutine return the generated file
name, else should die or return undef.

=cut

sub generate_proc {
  my $self = shift if ( ref $_[0] eq __PACKAGE__ );
  my $PROCESS_BASE_DIR = $self->{base} ? $self->{base} : $PROCESS_BASE_DIR;
  my $PROCESS_DIR      = $self->{dir}  ? $self->{dir}  : $PROCESS_DIR;

  my ( $comp_id, $gen_type ) = @_;

  # Make directory path.
  my @arr = split( '/|::', $comp_id );
  my $comp_base_name = '';
  if ( scalar @arr > 1 ) {
    $comp_base_name = join( '/', @arr[ 0 .. scalar @arr - 2 ] );
  }

  my $dir;

# If class name is specified with package, then not use $PROCESS_DIR as a part of output path.
  if ( $comp_id =~ /::/ ) {
    $dir = $PROCESS_BASE_DIR . "/" . $comp_base_name;
  } else {
    $dir = $PROCESS_BASE_DIR . "/" . $PROCESS_DIR . "/" . $comp_base_name;
  }

  # Prepare directory for generate file.
  mkpath $dir unless ( -d $dir );

  # '$!' can't judge error correctly.
  #  $! and die "$!:" . $dir;
  if ( !-d $dir ) {
    die "Can't make dir:" . $!;
  }

  # Generate file.
  my $comp_id_filepath = $comp_id;
  $comp_id_filepath =~ s!::!/!g;
  my $fpath;

# If package name is specified with class name, then not use $PROCESS_DIR as output file path.
  if ( $comp_id =~ /::/ ) {
    $fpath = $PROCESS_BASE_DIR . "/" . $comp_id_filepath . ".pm";
  } else {
    $fpath =
      $PROCESS_BASE_DIR . "/" . $PROCESS_DIR . "/" . $comp_id_filepath . ".pm";
  }
  open( my $file, '>', $fpath );

  # Get the function contents.
  $comp_id =~ s/\//::/g;
  my $fun = '_template_' . ( $gen_type ? $gen_type : 'default' );
  my $contents = '';
  $contents = eval( "return " . $fun . "(\"$comp_id\");" );
  $@ and die $@;

  my $ret = print $file $contents;
  if ( $ret == 1 ) {
    print "generated:$fpath\n";
    return $fpath;
  } else {
    print "output fail:$fpath\n";
    return undef;
  }

} ## end sub generate_proc

=begin comment

Return the contents of a new Process which uses Su template.
This method is called by gen_proc via dinamic method call.

=end comment

=cut

sub _template_default {
  my $self = shift if ( ref $_[0] eq __PACKAGE__ );

  my $comp_id = shift;
  my $ret = expand( << '__HERE__', $comp_id );
% my $comp_id = shift;
package <%=$comp_id%>;
use strict;
use warnings;
use Su::Template;

my $model={};

sub new {
  return bless { model => $model }, shift;
}

# The main method for this process class.
sub process{
  my $self = shift if ($_[0] && ref $_[0] eq __PACKAGE__);
  my $self_module_name = shift if ($_[0] && $_[0] eq __PACKAGE__);
  my $model = keys %{ $self->{model} } ? $self->{model} : $model;

  my $param = shift;
#$Su::Template::DEBUG=1;
  my $ret = expand(<<'__TMPL__');

__TMPL__
#$Su::Template::DEBUG=0;
  return $ret;
}

# This method is called if specified as a map filter class.
sub map_filter{
  my $self = shift if ref $_[0] eq __PACKAGE__;
  my @results = @_;

  for ( @results ){
    
  }

  return @results;
}

# This method is called if specified as a reduce filter class.
sub reduce_filter{
  my $self = shift if ref $_[0] eq __PACKAGE__;
  my @results = @_;
  my $result;
  for ( @results ){
    
  }

  return $result;
}

# This method is called if specified as a scalar filter class.
sub scalar_filter{
  my $self = shift if ref $_[0] eq __PACKAGE__;
  my $result = shift;


  return $result;
}

sub model{
  my $self = shift if ref $_[0] eq __PACKAGE__;
  my $self_module_name = shift if $_[0] eq __PACKAGE__;
  my $arg = shift;
  if ($arg) {
    if ($self) { $self->{model} = $arg; }
    else {
      $model = $arg;
    }
  } else {
    if ($self) {
      return $self->{model};
    } else {
      return $model;
    }
  } ## end else [ if ($arg) ]
}

1;
__HERE__

  return $ret;
} ## end sub _template_default

=begin comment

Return the contents of a new Process which uses Mojo template.
This method is called by gen_proc via dinamic method call.

=end comment

=cut

sub _template_mojo {
  my $self = shift if ( ref $_[0] eq __PACKAGE__ );

  my $comp_id = shift;
  my $header  = "package $comp_id;";
  my $ret     = << '__HERE__';
use Mojo::Template;
use strict;
use warnings;

my $model = {};

sub process{
  if($_[0] eq __PACKAGE__){
    shift;
  }

  my $ctx_hash_ref = shift;
  my $mt = Mojo::Template->new;
  my $ret = $mt->render(<<'__TMPL__',$ctx_hash_ref);
% my $ctx_href = shift;


__TMPL__

  return $ret;
}

sub model{
  if($_[0] eq __PACKAGE__){
    shift;
  }
  my $arg = shift;
  if ($arg){
    $model = $arg;
  }else{
    return $model;
  }
}

1;
__HERE__

  return $header . "\n" . $ret;

} ## end sub _template_mojo

=item comp()

This method is just a alias of L<gen> metnod.

=cut

sub comp {
  return gen(@_);
}

=item gen()

 my $ret = gen('process_id');
 my $ret = gen('dir/process_id');
 my $ret = gen('dir::process_id');

Return the result of the process which coressponds to the passed
process id.
The process id is a qualified module name.
Note that the specified process is simply called it's C<process>
method and can't access to it's model field.

=cut

sub gen {
  my $self = shift if ( ref $_[0] eq __PACKAGE__ );
  my $PROCESS_BASE_DIR = $self->{base} ? $self->{base} : $PROCESS_BASE_DIR;
  my $PROCESS_DIR      = $self->{dir}  ? $self->{dir}  : $PROCESS_DIR;

  my $comp_id = shift;
  my @ctx     = @_;

  my $f      = $PROCESS_BASE_DIR . "/" . $PROCESS_DIR . "/" . $comp_id;
  my $suffix = _has_suffix($f);

  # If passed file has suffix, return file contents itself.
  if ( -f $f && $suffix and $suffix ne '.pm' ) {
    return _read_contents($f);
  }

  my $proc        = Su::Process->new;
  my $proc_module = $proc->load_module($comp_id);

  return $proc_module->process(@ctx);

} ## end sub gen

=item load_module()

 my $su_proc = Su::Process->new;
 my $proc_module = $su_proc->load_module($module_name);

=cut

sub load_module {
  my $self = shift if ( ref $_[0] eq __PACKAGE__ );
  my $PROCESS_BASE_DIR = $self->{base} ? $self->{base} : $PROCESS_BASE_DIR;
  my $PROCESS_DIR      = $self->{dir}  ? $self->{dir}  : $PROCESS_DIR;
  my $comp_id          = shift;
  my @ctx = @_ if @_;

  my $f = $comp_id;
  $f =~ s!::!/!g;
  $f .= ".pm";

  # Trim the head of dot slash(./) of the file path.
  $f =~ s!^\./(.+)!$1!;

  # Replace directory separator to package separator.
  $comp_id =~ s/\//::/g;

  # If $comp_id is a package which described in some module file whose
  # filename is not match $comp_id, then we can't load package
  # '$comp_id' from filename using require.  In such case, we hope
  # package may be already loaded, so we don't load and just return the
  # package id.
  eval { require $f; };

  # Note if $SUPRESS_LOAD_ERROR is set, don't throw error.
  croak $@ if $@ and !$SUPPRESS_LOAD_ERROR;

  my $ret;

  # TODO: Add mode to re-use instance.
  if ( exists &{ ( $comp_id . "::new" ) } ) {
    $ret = $comp_id->new;
  } else {
    $ret = $comp_id;
  }

  #  require $comp_id if $@;
  return $ret;

} ## end sub load_module

=begin comment

Read the contents of the passed file.

=end comment

=cut

sub _read_contents {
  my $self = shift if ( ref $_[0] eq __PACKAGE__ );

  my $path = shift;
  my $fh   = undef;
  open $fh, '<', $path or die "Can't open file:$!";
  my $ret = join '', <$fh>;
  close $fh;
  return $ret;
} ## end sub _read_contents

=begin comment

Return the suffix string if the passed string has some suffix.
If the passed string has not any suffix, then return undef.

=end comment

=cut

sub _has_suffix {
  my $self = shift if ( ref $_[0] eq __PACKAGE__ );

  my $path = shift;
  my @pass_elem = split( '/', $path );
  $path = @pass_elem[ scalar @pass_elem - 1 ] if scalar @pass_elem > 1;
  my $ridx = rindex( $path, '.' );
  return ( $ridx == -1 ? undef : substr( $path, $ridx ) );
} ## end sub _has_suffix

=pod

=back

=cut

1;

