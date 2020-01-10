package Parse::Readelf::Debug::Line;

# Author, Copyright and License: see end of file

=head1 NAME

Parse::Readelf::Debug::Line - handle readelf's debug line section with a class

=head1 SYNOPSIS

  use Parse::Readelf::Debug::Line;

  my $line_info = new Parse::Readelf::Debug::Line($executable);

  my $object_id = $line_info->object_id("mocdule.c");

  my $file_name = $line_info->file($object_id, $number);
  my $directory_name = $line_info->directory($object_id, $number);
  my $path = $line_info->path($object_id, $number);

  my $object_name = $line_info->object_name($object_id);

  my $file_count = $line_info->files($object_id);
  my @files = $line_info->files($object_id);
  my $directory_count = $line_info->directories($object_id);
  my @directories = $line_info->directories($object_id);
  my $path_count = $line_info->paths($object_id);
  my @paths = $line_info->paths($object_id);

=head1 ABSTRACT

Parse::Readelf::Debug::Line parses the output of C<readelf
--debug-dump=line> and stores its interesting details in an object to
be available.  Normally it's not used directly but by other modules of
L<C<Parse::Readelf>>.

=head1 DESCRIPTION

Normally an object of this class is constructed with the file name of
an object file to be parsed.  Upon construction the file is analysed
and all relevant information about its debug line section is stored
inside of the object.  This information can be accessed afterwards
using a bunch of getter methods, see L</"METHODS"> for details.

Currently only output for B<Dwarf versions 2 and 4> is supported.
Please contact the author for other versions and provide some example
C<readelf> outputs.

=cut

#########################################################################

use 5.006001;
use strict;
use warnings;
use Carp;

our $VERSION = '0.19';

#########################################################################

=head1 EXPORT

Nothing is exported by default as it's normally not needed to modify
any of the variables declared in the following export groups:

=head2 :all

all of the following groups

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw();

our %EXPORT_TAGS =
    (command => [ qw($command) ],
     fixed_regexps => [ qw($re_section_start $re_dwarf_version) ],
     versioned_regexps => [ qw(@re_directory_table
			       @re_file_name_table
			       @re_file_name_table_header) ]
    );
$EXPORT_TAGS{all} = [ map { @$_ } values(%EXPORT_TAGS) ];

our @EXPORT_OK = ( @{ $EXPORT_TAGS{all} } );

#########################################################################

=head2 :command

=over

=item I<$command>

is the variable holding the command to run C<readelf> to get the
information relevant for this module, normally C<readelf
--debug-dump=line>.

=back

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

our $command = 'readelf --debug-dump=line';

#########################################################################

=head2 :fixed_regexps

=over

=item I<$re_section_start>

is the regular expression that recognises the start of the line debug
output of C<readelf>.

=item I<$re_dwarf_version>

is the regular expression that recognises the Dwarf version line in a
line debug output of C<readelf>.  The version number must be an
integer number which will (must) be stored in C<$1>.

=back

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

our $re_section_start =
    qr(^(?:raw )?dump of debug contents of section \.debug_line:)i;

our $re_dwarf_version = qr(^\s*DWARF Version:\s+(\d+)\s*$)i;

#########################################################################

=head2 :versioned_regexps

=over

=item I<@re_directory_table>

is the version dependent regular expression that recognises the start
of the directory table in line debug output of C<readelf>.

=item I<@re_file_name_table>

is the version dependent regular expression that recognises the start
of the non-empty file name table in line debug output of C<readelf>.

=item I<@re_file_name_table_header>

is the version dependent regular expression that recognises the
heading line of the file name table in line debug output of
C<readelf>.  If this must be modified this probably means the parsing
will not work correctly!

=back

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

our @re_directory_table =
    ( undef, undef, qr(^\s*The Directory Table)i );

our @re_file_name_table =
    (  undef, undef, qr(^\s*The File Name Table:)i );

our @re_file_name_table_header =
    (  undef, undef, qr(^\s*Entry\s+Dir\s+Time\s+Size\s+Name)i );

#########################################################################

=head2 new - get readelf's debug line section into an object

    $line_info = new Parse::Readelf::Debug::Line($file_name);

=head3 example:

    $line_info1 = new Parse::Readelf::Debug::Line('program');
    $line_info2 = new Parse::Readelf::Debug::Line('module.o');

=head3 parameters:

    $file_name          name of executable or object file

=head3 description:

    This method parses the output of C<readelf --debug-dump=line> and
    stores its interesting details internally to be accessed later by
    getter methods described below.

=head3 global variables used:

    The method uses all of the variables described above in the
    L</"EXPORT"> section.

=head3 returns:

    The method returns the blessed Parse::Readelf::Debug::Line object
    or an exception in case of an error.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub new($$)
{
    my $this = shift;
    my $class = ref($this) || $this;
    my ($file_name) = @_;
    my %self = (objects => [],
		object_map => {},
		directories => [],
		file_names => []);
    local $_;

    # checks:
    if (! $file_name)
    { croak 'bad call to new of ', __PACKAGE__; }
    if (ref($this))
    { carp 'cloning of a ', __PACKAGE__, " object is not supported"; }
    if (! -f $file_name)
    { croak __PACKAGE__, " can't find ", $file_name; }

    # call readelf and prepare parsing output:
    open READELF, '-|', $command.' '.$file_name  or
	croak "can't parse ", $file_name, ' with "', $command, '" in ',
	    __PACKAGE__, ': ', $!;

    # find start of section:
    while (<READELF>)
    { last if m/$re_section_start/; }

    # parse section:
    my $version = -1;
    my @directory_list = ();
    while (<READELF>)
    {

	if (m/$re_dwarf_version/)
	{
	    $version = $1;
	    confess 'DWARF version ', $version, ' not supported in ',
		__PACKAGE__
		    unless (defined $re_directory_table[$version]  and
			    defined $re_file_name_table[$version]  and
			    defined $re_file_name_table_header[$version]);
	}
	next unless $version >= 0;

	if (m/$re_directory_table[$version]/)
	{
	    @directory_list = ('.');
	    while (<READELF>)
	    {
		s/^\s+//; s/\s+$//;
		last unless $_;
		push @directory_list, $_;
	    }
	}

	elsif (m/$re_file_name_table[$version]/)
	{
	    <READELF> =~ m/$re_file_name_table_header[$version]/  or
		confess 'aborting: head line of file name table ',
		    'not recognised in ', __PACKAGE__;
	    my @file_name_table = ();
	    my @directory_table = ();
	    while (<READELF>)
	    {
		s/[\r\n]+//;
		last unless m/\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(.*)/;
		my ($id, $directory_id, $time, $size, $name) =
		    ($1, $2, $3, $4, $5);
		if ($id == 1)
		{
		    push @{$self{objects}}, $name;
		    $self{object_map}{$name} = $#{$self{objects}};
		    push @{$self{directories}}, \@directory_table;
		    push @{$self{file_names}}, \@file_name_table;
		}
		$file_name_table[$id] = $name;
		$directory_table[$id] = $directory_list[$directory_id];
	    }
	    @directory_list = ();
	}
    }

    # now we're finished:
    close READELF  or
	croak 'error while attempting to parse ', $file_name,
	    ' (maybe not an object file?)';
    bless \%self, $class;
}

#########################################################################

=head2 object_id - get object ID of (named) source file

    $object_id = $line_info->object_id($file_name);

=head3 example:

    $object_id = $line_info->object_id('module.c');

=head3 parameters:

    $file_name          name of the source file (without directory)

=head3 description:

    This method returns the internal object ID of a module when given
    the name of its source file without directory.  This is a
    non-negative number.

=head3 returns:

    The method returns the object ID or -1 if no matching object was
    found.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub object_id($$)
{
    my $this = shift;
    my ($name) = @_;
    my $id = $this->{object_map}{$name};
    return defined $id ? $id : -1;
}

#########################################################################

=head2 object_name - get name of major source file for a given object ID

    $object_name = $line_info->object_name($object_id);

=head3 example:

    $object_name = $line_info->object_name(0);

=head3 parameters:

    $object_id          internal object ID of module

=head3 description:

    This method is the opposite method of L<|C<object_id>>, it returns
    the name of the major source file for the given internal object ID
    of a module.

=head3 returns:

    The method returns the source name or an empty string if no
    matching object was found.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub object_name($$)
{
    my $this = shift;
    my ($id) = @_;
    my $name = $this->{objects}[$id];
    return defined $name ? $name : '';
}

#########################################################################

=head2 file - get file name of source for a given ID combination

    $file_name = $line_info->file($object_id, $source_number, $relax);

=head3 example:

    $file_name = $line_info->file(0, 0);
    $file_name = $line_info->file(0, 0, 1); # Dwarf-4

=head3 parameters:

    $object_id          internal object ID of module
    $source_number      number of the source
    $relax              optional flag to enable fallback code for object ID

=head3 description:

    This method returns the file name (without directory) of the
    source file number C<$source_number> for the given internal object
    ID of a module.  The source number is a positive integer.  1 is
    the number of the major source file, all others are usually
    include files.  Note that 0 is not used!

    Newer Dwarf versions don't seem to use different tables for
    different object IDs and put all sources into one table.  The
    optional flag C<$relax> tells the method to use this one table in
    those cases.

=head3 returns:

    The method returns the source name or an empty string if no
    matching source was found in the object.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub file($$$;$)
{
    my $this = shift;
    my ($id, $source, $relax) = @_;
    # TODO: compilation unit and ID seem to be totally different
    # things and I've never seen 2 file name tables in Dwarf-4 so far:
    my $table = $this->{file_names}[$id];
    if (not defined $table  and  $relax)
    { $table = $this->{file_names}[0]; }
    return '' unless defined $table and ref($table) eq 'ARRAY';
    my $name = $table->[$source];
    return defined $name ? $name : '';
}

#########################################################################

=head2 files - list of all source file names for a given object ID

    @file_names = $line_info->files($object_id);
    $file_count = $line_info->files($object_id);

=head3 example:

    @file_names = $line_info->files(1);
    $number_of_files = $line_info->files($object_id);

=head3 parameters:

    $object_id          internal object ID of module

=head3 description:

    In list context this method returns a list of all file names
    (without directory parts) for the given internal object ID of a
    module.  In scalar context it returns how many elements this list
    would have.  As number 1 is the first source number actually used
    in the internal representation of the list the number returned in
    scalar context is also the last number you can pass to the
    L<|C<file>> method described above that returns a valid name (a
    non empty string).  Note also that the empty element 0 is not part
    of the list returned in list context.

=head3 returns:

    The method returns the list / the count as described above or an
    empty list / 0 if an unused or invalid object id was given.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub files($$)
{
    my $this = shift;
    my ($id) = @_;
    my $table = $this->{file_names}[$id];
    return wantarray ? () : 0 unless defined $table;
    if (wantarray)
    {
	return @{$table}[1..$#{$table}];
    }
    return $#{$table};
}

#########################################################################

=head2 directory - get directory name of source for a given ID combination

    $directory = $line_info->directory($object_id, $source_number);

=head3 example:

    $directory = $line_info->directory(0, 0);

=head3 parameters:

    $object_id          internal object ID of module
    $source_number      number of the source

=head3 description:

    This method returns the directory part of the file name of the
    source file number C<$source_number> for the given internal object
    ID of a module.  The source number is a positive integer.  1 is
    the number of the major source file, all others are usually
    include files.  Note that 0 is not used!

=head3 returns:

    The method returns the directory name or an empty string if no
    matching source was found in the object.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub directory($$$)
{
    my $this = shift;
    my ($id, $source) = @_;
    my $table = $this->{directories}[$id];
    return '' unless defined $table and ref($table) eq 'ARRAY';
    my $name = $table->[$source];
    return defined $name ? $name : '';
}

#########################################################################

=head2 directories - list of all directory names for a given object ID

    @directories = $line_info->directories($object_id);
    $dir_count = $line_info->directories($object_id);

=head3 example:

    @directories = $line_info->directories(1);
    $number_of_dirs = $line_info->directories($object_id);

=head3 parameters:

    $object_id          internal object ID of module

=head3 description:

    In list context this method returns a list of the directory parts
    of all file names for the given internal object ID of a module.
    As usually several used include files are found in the same
    directory this list normally will contain duplictes.  Those are NOT
    eliminated.  In scalar context it returns how many elements this
    list would have.  As number 1 is the first source number actually
    used in the internal representation of the list the number
    returned in scalar context is also the last number you can pass to
    the L<|C<directory>> method described above that returns a valid
    name (a non empty string).  Note also that the empty element 0 is
    not part of the list returned in list context.

=head3 returns:

    The method returns the list / the count as described above or an
    empty list / 0 if an unused or invalid object id was given.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub directories($$)
{
    my $this = shift;
    my ($id) = @_;
    my $table = $this->{directories}[$id];
    return wantarray ? () : 0 unless defined $table;
    if (wantarray)
    {
	return @{$table}[1..$#{$table}];
    }
    return $#{$table};
}

#########################################################################

=head2 path - get path to source file for a given ID combination

    $file_path = $line_info->path($object_id, $source_number);

=head3 example:

    $file_path = $line_info->path(0, 0);

=head3 parameters:

    $object_id          internal object ID of module
    $source_number      number of the source

=head3 description:

    This method returns the path (directory plus file name) of the
    source file number C<$source_number> for the given internal object
    ID of a module.  The source number is a positive integer.  1 is
    the number of the major source file, all others are usually
    include files.  Note that 0 is not used!

=head3 returns:

    The method returns the source name or an empty string if no
    matching source was found in the object.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub path($$$)
{
    my $this = shift;
    my ($id, $source) = @_;
    my $table = $this->{file_names}[$id];
    return '' unless defined $table  and  ref($table) eq 'ARRAY';
    my $name = $table->[$source];
    return '' unless defined $name;
    $table = $this->{directories}[$id];
    confess 'internal error: inconsistent table data for (',
	$id, ',', $source, ') in ', __PACKAGE__, '::path'
	    unless defined $table  and  ref($table) eq 'ARRAY';	# 1)
    my $name2 = $table->[$source];
    confess 'internal error: inconsistent name data for (',
	$id, ',', $source, ') in ', __PACKAGE__, '::path'
	    unless defined $name2; # 1)
    return $name2.'/'.$name;
}

#########################################################################

=head2 paths - list of paths to all sources for a given object ID

    @paths = $line_info->paths($object_id);
    $path_count = $line_info->paths($object_id);

=head3 example:

    @paths = $line_info->paths(1);
    $number_of_paths = $line_info->paths($object_id);

=head3 parameters:

    $object_id          internal object ID of module

=head3 description:

    In list context this method returns a list of all paths (directory
    plus file name) for the given internal object ID of a module.  In
    scalar context it returns how many elements this list would have.
    As number 1 is the first source number actually used in the
    internal representation of the list the number returned in scalar
    context is also the last number you can pass to the L<|C<file>>
    method described above that returns a valid name (a non empty
    string).  Note also that the empty element 0 is not part of the
    list returned in list context.

=head3 returns:

    The method returns the list / the count as described above or an
    empty list / 0 if an unused or invalid object id was given.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub paths($$)
{
    my $this = shift;
    my ($id) = @_;
    my $dir_table = $this->{directories}[$id];
    my $file_table = $this->{file_names}[$id];
    unless (defined $dir_table  and  defined $file_table)
    {
	confess 'internal error: inconsistent table data for (',
	    $id, ') in ', __PACKAGE__, '::paths'
		if defined $dir_table  or  defined $file_table;
	return wantarray ? () : 0;
    }
    confess 'internal error: inconsistent table structure for (',
	$id, ') in ', __PACKAGE__, '::paths'
	    unless (ref($dir_table) eq 'ARRAY'  and
		    ref($file_table) eq 'ARRAY');
    confess 'internal error: inconsistent name data for (',
	$id, ') in ', __PACKAGE__, '::paths'
	    unless $#{$dir_table} == $#{$file_table};
    return $#{$dir_table} unless wantarray();
    return
	map { $dir_table->[$_] . '/' . $file_table->[$_] }
	    (1..$#{$dir_table});
}

1;

#########################################################################

__END__

=head1 KNOWN BUGS

Only Dwarf versions 2 and 4 are supported.  Please contact the author
for other versions and provide some example C<readelf> outputs.

This has only be tested in a Unix like environment and uses Unix path
syntax in some places.

=head1 SEE ALSO

L<Parse::Readelf> and the C<readelf> man page

=head1 AUTHOR

Thomas Dorner, E<lt>dorner (AT) cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2020 by Thomas Dorner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
