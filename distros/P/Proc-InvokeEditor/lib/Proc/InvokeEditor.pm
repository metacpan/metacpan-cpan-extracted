package Proc::InvokeEditor;

use strict;
use warnings;

use File::Temp qw(tempfile);
use File::Spec;
use IPC::Cmd qw(can_run);
use Carp::Assert;
use Fcntl;
File::Temp->safe_level( File::Temp::HIGH );

require Exporter;

use vars qw(@ISA %EXPORT_TAGS @EXPORT_OK @EXPORT $VERSION
            @DEFAULT_EDITORS);

@ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Proc::InvokeEditor ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw(
	
);
$VERSION = '1.07';

@DEFAULT_EDITORS = ( $ENV{'VISUAL'}, $ENV{'EDITOR'}, '/usr/bin/vi',
                     '/bin/vi', '/bin/ed',
                     map({ can_run($_) } qw(vi ed))
);

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {
                'editors' => \@DEFAULT_EDITORS,
                'cleanup' => 1,
                'keep_file' => 0,
  };
  croak("$class requires an even number of parameters") if @_ % 2;
  my %args = @_;
  foreach my $param (qw(editors cleanup keep_file)) {
    if ($args{$param}) {
      $self->{$param} = $args{$param};
    }
  }
  bless ($self, $class);
  return $self;
}

sub editors {
  my $self = shift;
  my $editors = shift;
  if (defined $editors) {
    assert(ref($editors) eq 'ARRAY');
    $self->{'editors'} = $editors;
  }
  return $self->{'editors'};
}

sub editors_prepend {
  my $self = shift;
  my $edit = shift;
  assert(ref($edit) eq 'ARRAY');
  my @editors = @{$self->{'editors'}};
  unshift @editors, @$edit;
  $self->{'editors'} = \@editors;
}

sub editors_env {
  my $self = shift;
  my $edit = shift;
  assert(ref($edit) eq 'ARRAY');
  my @editors;
  if (@$edit) {
    foreach my $e (@$edit) {
      if (exists $ENV{$e} and defined $ENV{$e}) {
        push @editors, $ENV{$e};  
      }
    }
    my @editors_list = @{$self->{'editors'}};
    unshift @editors_list, @editors;
    $self->{'editors'} = \@editors_list;
  }
  return $self->{'editors'};
}

sub cleanup {
  my $self = shift;
  my $cleanup = shift;
  $self->{'cleanup'} = $cleanup if defined $cleanup;
  return $self->{'cleanup'};
}

sub keep_file {
  my $self = shift;
  my $keep_file = shift;
  $self->{'keep_file'} = $keep_file if defined $keep_file;
  return $self->{'keep_file'};
}

sub edit {
  my $self = shift;
  my $arg = shift;
  my $suff = shift;
  # if the argument supplied is a reference to an array of lines,
  # join it together based on the input record separator
  if (ref($arg) eq 'ARRAY') {
    $arg = join $/, @$arg;
  }
  my $result;
  if (ref($self)) {
    ($result, $self->{'filename'}) = _edit(
      $arg,
      $self->{'editors'},
      $self->{'cleanup'},
      $self->{'keep_file'},
      $self->{'filename'},
      $suff,
    );
  } else {
    ($result) = _edit($arg, \@DEFAULT_EDITORS, 1, 0, undef, $suff);
  }
  if (wantarray) {
    my @result = split m|$/|, $result;
    return @result;
  } else {
    return $result;
  }
}

sub first_usable {
  my $self = shift;
  my $er = shift;
  my @editors;
  if (defined $er) {
    @editors = @$er;
  } else {
    if (ref $self) {
      @editors = @{$self->{'editors'}};
    } else {
      @editors = @DEFAULT_EDITORS;
    }
  }

  my $chosen_editor;
  my @path = File::Spec->path;
  EDITORS: foreach my $editor (@editors) {
    next unless defined $editor;
    my @editor_bits = split /\s+/, $editor;
    next unless defined $editor_bits[0];
    if (File::Spec->file_name_is_absolute($editor_bits[0])
        and -x $editor_bits[0]) {
      $chosen_editor = \@editor_bits;
      last;
    } else {
      foreach my $dir (@path) {
         my $file = File::Spec->catfile($dir, $editor_bits[0]);
         if (-x $file) { 
           $editor_bits[0] = $file;
           $chosen_editor = \@editor_bits;
           last EDITORS;
         }
      }
    }
  }
  die "Couldn't find an editor: $!" unless defined $chosen_editor;

  return $chosen_editor;
}

sub _edit {
  my $string = shift;
  my $er = shift;
  my $unlink = shift;
  my $keep_file = shift;
  my $filename = shift;
  my $suff = shift;

  assert(ref($er) eq 'ARRAY');
  assert(defined $unlink);
  my @editors = @$er; 
  # Find an editor

  my $chosen_editor = first_usable(undef, $er); 

  my @suff;
  @suff = (SUFFIX => $suff) if $suff;

  # get a temp file, and write the text to it
  if (defined($filename) && $keep_file) {
    open my $fh, '>', $filename or die "Couldn't open tempfile [$filename]; $!";
    print $fh $string;
    close $fh or die "Couldn't close tempfile [$filename]; $!";
  }
  else {
    my $fh;
    ($fh, $filename) = tempfile(UNLINK => $unlink, @suff);
    print $fh $string;
    close $fh or die "Couldn't close tempfile [$filename]; $!";
  }
  # start the editor
  my $rc = system @$chosen_editor, $filename;
  # check what happened - die if it all went wrong.
  unless ($rc == 0) {
    my ($exit_value, $signal_num, $dumped_core);
    $exit_value = $? >> 8;
    $signal_num = $? & 127;
    $dumped_core = $? & 128;
    die "Error in editor - exit val = $exit_value, signal = $signal_num, coredump? = $dumped_core: $!";
  }

  # read the temp file
  sysopen(FH, $filename, O_RDONLY) or die "Couldn't sysopen $filename: $!";
  my $result;
  { local $/; $result = <FH>; }
  close FH or die "Couldn't close [$filename]: $!";
  # return as string
  if ($keep_file) {
    return ($result, $filename);
  }
  else {
    return ($result);
  }
}

1;
__END__

=head1 NAME

Proc::InvokeEditor - Perl extension for starting a text editor

=head1 SYNOPSIS

  use Proc::InvokeEditor;
  my $edited_text = Proc::InvokeEditor->edit($unedited_text);

=head1 DESCRIPTION

This module provides the ability to supply some text to an external
text editor, have it edited by the user, and retrieve the results.

The File::Temp module is used to provide secure, safe temporary
files, and File::Temp is set to its highest available level of
security. This may cause problems on some systems where no secure
temporary directory is available.

When the editor is started, no subshell is used. Your path will
be scanned to find the binary to use for each editor if the string
given does not exist as a file, and if a named editor contains whitespace,
eg) if you try to use the editor C<xemacs -nw>, then the string will
be split on whitespace and anything after the editor name will be passed
as arguments to your editor. A shell is not used but this should cover
most simple cases.

=head1 METHODS

=head2 new(editors => [ editor list ], cleanup => 1)

This method creates a new Proc::InvokeEditor object. It takes two optional
arguments in key => value form:

=over 4

=item C<editors>

This should be a reference to an array of possible editor filenames
to use. Each editor listed will be tried in turn until a working
editor is found. If this argument is not supplied, an internal
default list will be used.

=item C<cleanup>

This specifies whether the temporary file created should be unlinked
when the program exits. The default is to unlink the file.

=item C<keep_file>

This specifies whether to reuse the same temporary file between invocations
of C<edit> on the same Proc::InvokeEditor object. The default is to use a
new file each time.

=back

=head2 editors()

This method gets or sets the list of editors to use.
If no argument is supplied, it returns the current value from the
object, if an argument is supplied, it changes the value and
returns the new value.
The argument should be a reference to a list of text editor filenames.

=head2 editors_env($arrayref)

Takes a reference to an array of C<%ENV> keys to use as possible editors.
Each C<$ENV{$key}> value is only used if that key exits in C<%ENV> and
the value is defined. The new values are prepended to the currently
stored list of editors to use.

=head2 editors_prepend($arrayref)

Takes a reference to an array of editors to use, and prepends them
to the currently stored list.

=head2 cleanup()

This method gets or sets whether to cleanup temporary files after the
program exits. If no argument is supplied, it returns the current value
from the object. If an argument is supplied, it changes the value and
returns the new object. The argument should be any true or false value.

=head2 keep_file()

This method gets or sets whether to reuse temporary files. If no
argument is supplied, it returns the current value from the object. If
an argument is supplied, it changes the value and returns the new
object. The argument should be any true or false value.

=head2 first_usable()

This method can be called either as a class method, in which it
returns the first usable editor of the default list of editors, or as an
object method, in which case it returns the first usable editor of
the currently configured list.

The return is a reference to an array, the first element of which is a
filename, and the other elements of which are appropriate arguments to
the the command.

If this method can not find any usable editor, it will die.

=head2 edit($unedited_text)

This can be called as either a class method or an object method.

When called as a class method, it starts an external text editor
in the text supplied, and returns the result to you. The text to
edit can be supplied either as a scalar, in which case it will be
treated as a simple string, or as a reference to an array, in which
case it will be treated as an array of lines.

Example use of this form is as follows:

  my $result = Proc::InvokeEditor->edit($string);

  my @lines = Proc::InvokeEditor->edit(\@unedited_lines);

  my @lines = Proc::InvokeEditor->edit($string);

When called as an object method, it behaves identically, but uses
configuration parameters from the object:

  my $editor = new Proc::InvokeEditor(editors => [ '/usr/bin/emacs' ]);
  $editor->cleanup(0);
  my $result = $editor->edit($string);

A optional second argument is available $suff - example usage:

	my $reuslt = Proc::InvokeEditor->edit($string, '.xml');

This specifies a filename suffix to be used when the editor is launched - this
can be useful if the data in the file is of a particular type and you want to
trigger an editor's syntax highlighting mode.

=head1 TODO

=over 4

=item *

Write a test suite.

=back

=head1 AUTHOR

Michael Stevens E<lt>mstevens@etla.orgE<gt>. Also incorporating
suggestions and feedback from Leon Brocard and Phil Pennock.

Patches supplied by Tim Booth.

=head1 SEE ALSO

L<perl>.

=cut
