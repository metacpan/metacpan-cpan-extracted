
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::IO::Matlab;

our @EXPORT_OK = qw(matlab_read matlab_write matlab_print_info );
our %EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   our $VERSION = '0.006';
   our @ISA = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::IO::Matlab $VERSION;





=head1 NAME

PDL::IO::Matlab -- Read and write Matlab format data files.

=head1 DESCRIPTION

This module provides routines to read and write pdls to and from
data files in Matlab formats. The module uses the matio C library.
Both functional and OO interface are provided.

Only real, multi-dimensional arrays corresponding to PDL data types are supported.
Compression for both reading and writing is supported.

See the section L</CAVEATS> for important information on potential problems when using
this module.

=head1 SYNOPSIS

 use PDL;
 use PDL::IO::Matlab qw( matlab_read matlab_write matlab_print_info);

 # write two pdls in matlab 5 format
 matlab_write('file.dat', $x, $y);

 # read an array of piddles 
 # from file in matlab 4, 5, or 7.3 format.
 my @pdls =  matlab_read('file.dat');
 
 # write pdl in matlab 7.3 format.
 matlab_write('file.dat', 'MAT73', $x);

 matlab_print_info('file.dat');

=cut

$PDL::onlinedoc->scan(__FILE__) if $PDL::onlinedoc;

use strict;
use warnings;

use PDL::LiteF;
use PDL::NiceSlice;
use PDL::Options;
use Data::Dumper;








my %Format_list =  (
    MAT73 => 0,
    MAT5 => 1,
    MAT4 => 2
    );

my %Inv_format_list =  (
    0 => 'MAT73',
    1 => 'MAT5',
    2 => 'MAT4'
   );

# non-OO functions

=head1 FUNCTIONS

The functional interface.

=head2 B<matlab_read>

=head3 Usage

Return all arrays in C<$filename>

 @pdls = matlab_read($filename);
 @pdls = matlab_read($filename, {OPTIONS});

Return first array in C<$filename>

 $x = matlab_read($filename);

Do not automatically convert C<1xn> and C<nx1> arrays
to 1-d arrays.

 @pdls = matlab_read($filename, { onedr => 0 } );

Reads all data in the file C<$filename>.
Formats 4, 5, and 7.3 are supported. Options
are passed to L</B<new>>.

=cut

sub matlab_read {
    my ($filename,$opts) = @_;
    my $mat = PDL::IO::Matlab->new($filename, '<', $opts || {});
    my @res = $mat->read_all;
    $mat->close;
    wantarray ? @res : $res[0];
}


=head2 B<matlab_write>

=head3 Usage

 matlab_write($filename,$x1,$x2,...);
 matlab_write($filename,$format,$x1,$x2,...);

Automatically convert C<n> element, 1-d piddles to C<1xn> matlab
variables.

 matlab_write($filename,$x1,$x2,..., {onedw => 1} );

Automatically convert to C<nx1> matlab
variables.

 matlab_write($filename,$x1,$x2,..., {onedw => 2} );

Use zlib compression

 matlab_write($filename,$x1,$x2,..., {compress => 1} );

This method writes pdls C<$x1>, C<$x2>,.... If present, C<$format>
must be either C<'MAT5'> or C<'MAT73'>.

=cut

sub matlab_write {
    my @strings;
    my @hashes;
    my @refs;
    while(@_) {
        my $v = shift;
        if ( ref($v)  ) {
            if ( ref($v) eq 'HASH' ) {
                push @hashes, $v;
            }
            else {
                push @refs, $v;
            }
        }
        else {
            push @strings, $v;
        }
    }
    barf 'matlab_write: ' . scalar(@strings) . 
        ' string arguments given. One or two expected.'
        if @strings < 1 or @strings > 2 ;
    my $filename = $strings[0];
    my $format = $strings[1] || 'MAT5';
    my $opth = { format => $format };
    foreach (keys %{$hashes[0]}) { $opth->{$_} = $hashes[0]->{$_} }
    my $mat = PDL::IO::Matlab->new($filename, '>', $opth);
    $mat->write(@refs) if @refs;
    $mat->close;
    scalar(@refs);
}

=head2 B<matlab_print_info>

=head3 Usage

 # print names and dimensions of variables.
 matlab_print_info($filename);
 # also print a small amount of the data.
 matlab_print_info($filename, { data => 1 });
 # This does the same thing.
 matlab_print_info($filename,  data => 1 );

Print information about the contents of the matlab file C<$filename>,
including the name, dimension and class type of the variables.

=cut

sub matlab_print_info {
    my $name = shift;
    my $mat = PDL::IO::Matlab->new($name, '<');
    $mat->print_all_var_info(@_);
    $mat->close;
}

=head1 METHODS

=head2 B<new>

=head3 Usage

 # open for writing
 $mat = PDL::IO::Matlab->new('file.dat', '>', {format => 'MAT5'});

 # default format is MAT5
 $mat = PDL::IO::Matlab->new('file.dat', '>');

 # may use 'w' or '>'
 $mat = PDL::IO::Matlab->new('file.dat', 'w');

 # supply header
 $mat = PDL::IO::Matlab->new('file.dat', '>', { header => 'some text'} );

 # read-write  with rw or <>
 $mat = PDL::IO::Matlab->new('file.dat', 'rw');  

 # open for reading
 $mat = PDL::IO::Matlab->new('file.dat', '<');

=head3 Options

=over

=item format

Either C<'MAT5'> or C<'MAT73'>.

=item compress

Either C<1> for yes, or C<0> for no.

=item header

A header (a string) to write into the file.

=item namekey

A hash key that will be used to store the matlab name
for a variable read from a file in the header of a piddle.
The default value is 'NAME'. Thus, the name can be accessed
via C<< $pdl->hdr->{NAME} >>.

=item varbasew

The base of the default matlab variable name that will be
written in the matlab file along with each piddle. An
integer will be appended to the base name. This integer is
initialized to zero and is incremented after writing each
variable.

=back

The option C<compress> enables zlib compression if the zlib library
is available and if the data file format is C<'MAT5'>.

=cut

sub new {
    my $class = shift;
    my ($filename,$mode,$iopts) = @_;
    my $opt = new PDL::Options(
        {
            format => undef,
            header => undef,
            namekey => 'NAME',
            varbasew => 'variable',
            onedw => 1,
            onedr => 1,
            compress => 0
        });
    $iopts ||= {};

    my $obj = $opt->options($iopts);

    my %exobj = ( 
        filename => undef, 
        mode => undef,
        handle => undef,
        wvarnum => 0,
    );

    foreach (keys %exobj) { $obj->{$_} = $exobj{$_} };

    bless $obj, $class;

    $obj->set_filename($filename) if $filename;

    if ( defined $mode ) {
      if ($mode eq 'r' or $mode eq '<') {
        $obj->set_mode('r');
      }
      elsif ($mode eq 'w' or $mode eq '>') {
        $obj->set_mode('w');
      }
      elsif ($mode eq 'rw' or $mode eq '<>') {
        $obj->set_mode('rw');
      }
      else {
        barf "PDL::IO::Matlab::open unknown mode '$mode'";
      }
    }
    elsif (defined $filename) {
      barf("PDL::IO::Matlab::new filename given, but no access mode.");
    }
    barf("PDL::IO::Matlab::new unknown file format")
       if defined $obj->{format} and not exists $Format_list{$obj->{format}};
    $obj->open() if defined $filename;
    $obj;
}

# may want to keep track of state at some point,
# an automatically close.
sub DESTROY {
    my $self = shift;
#    $self->close;
}

sub open {
    my $self = shift;
    my $mode = $self->get_mode();
    my $filename = $self->get_filename();
    my $handle;
    if ( $mode eq 'r' ) {
        $handle = _mat_open_read($filename);
    }
    elsif ( $mode eq 'w' ) {
        $self->get_format || $self->set_format('MAT5');
        my $header = $self->get_header();
        my $header_flag = defined $header ?  1 : 0;
        $header = '' unless defined $header;
        $handle = _mat_create_ver(
            $filename, $header, $Format_list{$self->get_format}, $header_flag);
    }
    elsif ( $mode eq 'rw' ) {
        $handle = _mat_open_read_write($filename);
    }
    else {
        barf "PDL::IO::Matlab::open unknown mode '$mode'";
    }
    barf "PDL::IO::Matlab::open Can't open '$filename' in mode $mode" unless $handle;
    $self->set_handle($handle);
    $self->get_format || $self->set_format($self->get_version);
    $self;
}

=head2 B<close>

=head3 Usage

$mat->close;

Close matlab file and free memory associated with C<$mat>.

=cut

sub close {
    my $self = shift;
   _mat_close($self->get_handle() );
   $self;
}

=head2 B<read_next>

=head3 Usage

 my $x = $mat->read_next;
 print "End of file\n" unless ref($x);

 my ($err,$x) = $mat->read_next;
 print "End of file\n" if $err;

Read one pdl from file associated with object C<$mat>.

=cut

sub read_next {
    my $self = shift;
    my ($pdl,$matlab_name) = _convert_next_matvar_to_pdl($self->get_handle,
        $self->get_onedr);
    my $err = ref($pdl) ? 0 : 1;
    $pdl->hdr->{$self->get_namekey} = $matlab_name if defined $matlab_name;
    return ($err,$pdl);
}

=head2 B<read_all>

=head3 Usage

 my @pdls = $mat->read_all;

Read all remaining pdls from file associated with object C<$mat>.

=cut

sub read_all {
    my $self = shift;
    my @res;
    while(1) {
        my ($err,$pdl) = read_next($self);
        last if $err;
        push @res, $pdl;
    }
    @res;
}

=head2 B<write>

=head3 Usage

 $x2->hdr->{NAME} = 'variablename';

 $mat->write($x1,$x2,...);

 $mat->write($x1,$x2,...,{OPTIONS});

Append pdls to open file associated with C<$mat>.

If a piddle has a matlab name stored in the header
it will be used as the matlab name written to the file
with this piddle. The key is in C<< $pdl->{namekey} >>,
with default value C<'NAME'>. If the name is not in
the piddle's header, then a default value will be used.

=head3 Options

=over

=item onedw

In order to write a file that is compatible with Matlab and Octave,
C<onedw> must be either C<1> or C<2>.  If C<onedw> is C<1> then a 1-d
pdl of length n is written as a as an C<nx1> pdl (a C<1xn> matlab
variable). If C<onedw> is C<2> then the output piddle is C<1xn> and
the matlab variable C<nx1>.  If C<onedw> is zero (the default), then
the 1-d pdl is written as a 1-d piddle. In the last case, Octave will
print an error and fail to read the variable.

=item compress

If C<compress> is C<1> then zlib compression is used, if the library
is available and if the format is C<'MAT5'>.

=back

=cut

sub _make_write_var_name {
    my $self = shift;
    my $varname = $self->get_varbasew . $self->get_wvarnum;
    $self->set_wvarnum($self->get_wvarnum + 1);
    $varname;
}

sub write {
   my $self = shift;
   my @pdls;
   my @hashes;
   while (@_) {
       my $arg = shift;
       if (ref($arg) eq 'HASH') {
           push @hashes, $arg;
       }
       else {
           push @pdls, $arg;
       }
   }
#   my %opts = parse( {onedw => 0 },  @hashes ? $hashes[0] : {} );
   my $opts = @hashes ? $hashes[0] : {} ;
   my $onedw = exists $opts->{onedw} ? $opts->{onedw} : $self->get_onedw;
   $onedw = 1 if $onedw == 0 and $self->get_format eq 'MAT73'; # else crash
   my $compress = exists $opts->{compress} ? $opts->{compress} : $self->get_compress;
   foreach (@pdls) {
       my $name = exists $_->hdr->{$self->get_namekey} ?
           $_->hdr->{$self->get_namekey} : $self->_make_write_var_name;
       _write_pdl_to_matlab_file($self->get_handle,$_, $name, $onedw, $compress);
   }
   return $self;
}

=head2 B<rewind>

=head3 Usage

 $mat->rewind

Reset pointer to the head of the file.

=cut

sub rewind {
    my $self = shift;
    _mat_rewind($self->get_handle);
}

=head2 B<get_filename>

=head3 Usage

 $mat->get_filename

Return name of file associated with C<$mat>.

=cut

=head2 B<get_header>

=head3 Usage

 $mat->get_header

Return the header string from the matlab data file associated with
C<$mat>.

=cut

sub get_header {
    my $self = shift;
    return defined $self->{header} ? 
        $self->{header} : defined $self->{handle} ?
        _mat_get_header($self->{handle}) : undef;
}

sub set_header {
    my $self = shift;
    $self->{header} = shift;
}

=head2 B<get_format>

=head3 Usage

 $mat->get_format

Return matlab data file format for file associated with
C<$mat>. One of C<'MAT4'>, C<'MAT5'>, or C<'MAT73'>.

=cut

# I am not using this ??
# version here means file format, use get_format instead
sub get_version {
    my $self = shift;
    my $val = _mat_get_version($self->get_handle);
    $Inv_format_list{$val};
}

=head2 B<print_all_var_info>

=head3 Usage

 $mat->print_all_var_info;

 # also print a small amount of data from each variable.
 $mat->print_all_var_info( data => 1 );

Print a summary of all data in the file associated
with C<$mat> (starting from the next unread variable.)

=cut

sub print_all_var_info {
    my $self = shift;
    my $len = scalar(@_);
    my $user_options = {};
    if ( $len == 1 ) {
        $user_options = $_[0];
    }
    elsif ( $len > 1 ) {
        my %user_option_hash = @_;
        $user_options = \%user_option_hash;
    }
    my %opts = parse( {data => 0} , $user_options);
    my $printdata = $opts{data} ? 1 : 0;
    my $handle = $self->get_handle;
    _extra_matio_print_all_var_info($handle,$printdata);
}





    sub get_handle {
        my $self = shift;
       barf 'PDL::IO::Matlab::get_handle: handle not defined.' unless
          defined $self->{handle};
            $self->{handle};
    }
  
    sub set_handle {
       my $self = shift;
       $self->{handle} = shift;
    }
     

    sub get_mode {
        my $self = shift;
       barf 'PDL::IO::Matlab::get_mode: mode not defined.' unless
          defined $self->{mode};
            $self->{mode};
    }
  
    sub set_mode {
       my $self = shift;
       $self->{mode} = shift;
    }
     

    sub get_filename {
        my $self = shift;
       barf 'PDL::IO::Matlab::get_filename: filename not defined.' unless
          defined $self->{filename};
            $self->{filename};
    }
  
    sub set_filename {
       my $self = shift;
       $self->{filename} = shift;
    }
     

    sub get_format {
        my $self = shift;
            $self->{format};
    }
  
    sub set_format {
       my $self = shift;
       $self->{format} = shift;
    }
     

    sub get_varbasew {
        my $self = shift;
       barf 'PDL::IO::Matlab::get_varbasew: varbasew not defined.' unless
          defined $self->{varbasew};
            $self->{varbasew};
    }
  
    sub set_varbasew {
       my $self = shift;
       $self->{varbasew} = shift;
    }
     

    sub get_onedw {
        my $self = shift;
       barf 'PDL::IO::Matlab::get_onedw: onedw not defined.' unless
          defined $self->{onedw};
            $self->{onedw};
    }
  
    sub set_onedw {
       my $self = shift;
       $self->{onedw} = shift;
    }
     

    sub get_onedr {
        my $self = shift;
       barf 'PDL::IO::Matlab::get_onedr: onedr not defined.' unless
          defined $self->{onedr};
            $self->{onedr};
    }
  
    sub set_onedr {
       my $self = shift;
       $self->{onedr} = shift;
    }
     

    sub get_namekey {
        my $self = shift;
       barf 'PDL::IO::Matlab::get_namekey: namekey not defined.' unless
          defined $self->{namekey};
            $self->{namekey};
    }
  
    sub set_namekey {
       my $self = shift;
       $self->{namekey} = shift;
    }
     

    sub get_wvarnum {
        my $self = shift;
       barf 'PDL::IO::Matlab::get_wvarnum: wvarnum not defined.' unless
          defined $self->{wvarnum};
            $self->{wvarnum};
    }
  
    sub set_wvarnum {
       my $self = shift;
       $self->{wvarnum} = shift;
    }
     

    sub get_compress {
        my $self = shift;
       barf 'PDL::IO::Matlab::get_compress: compress not defined.' unless
          defined $self->{compress};
            $self->{compress};
    }
  
    sub set_compress {
       my $self = shift;
       $self->{compress} = shift;
    }
     

=head1 ACCESSOR METHODS

The following are additional accessor methods for the matlab file objects
PDL::IO::Matlab.

get_handle set_handle get_mode set_mode get_filename set_filename get_format set_format get_varbasew set_varbasew get_onedw set_onedw get_onedr set_onedr get_namekey set_namekey get_wvarnum set_wvarnum get_compress set_compress
=cut




=head1 CAVEATS

=head2 complicating factors

There are two complicating factors when using matlab files with PDL.
First, matlab does not support one-dimensional vectors. Thus, a 1-d pdl
must be represented as either a C<1 x n> of a C<n x 1> matlab variable. Second,
matlab stores matrices in column-major order, while pdl stores them
in row-major order.

=over

=item B<one-dimensional pdls>

You can write 1-d pdls to a file with this module. This module can then read the
file. But, Octave will fail to read the file and print an error message.
See L</B<write>> for how this is handled.

=item B<column- vs. row major>

Data written by Octave (PDL) will be read by PDL (Octave) with indices transposed.
On the todo list is an option to physically or logically transpose the data on
reading and writing.

=item B<Octave requires distinct matlab variable names>

With this module, you may write more than one
variable, each with the same name, (the matlab name; not the
pdl identifier, or variable, name), to a file in MAT5
format. This module is then able to read all pdls from this file.
But, Octave, when reading this file, will overwrite all but
the last occurrence of the variable with the last
occurrence. See the method L</B<write>>.

Trying to write two pdls with the same matlab variable name in MAT73 format will cause
an error.

=back

=head2 other missing features, bugs

When trying to read an unsupported matlab data type from a file, this module will
throw an error. Supporting other data types or optionally skipping them is on
the todo list.

Random access of variables in a file is on the todo list. The underlying B<matio>
library supports this.

This module is currently built with some hardcoded data from a PDL installation, that
may contain platform-specific (linux) features. It may fail to
build or function correctly when used on other platforms.

=head1 AUTHOR

John Lapeyre, C<< <jlapeyre at cpan.org> >>

The matio library was written by Christopher C. Hulbert.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 John Lapeyre.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

The matio library included here is 
Copyright 2011 Christopher C. Hulbert. All rights reserved.
See the file matio-1.5/COPYING in the source distribution
of this module.

=cut

# broken
#sub print_all_var_info_new {
#    my $self = shift;
#    my $handle = $self->get_handle;
#    _extra_matio_print_all_var_info($handle,1,10,10);
#}

###########################################################################



;



# Exit with OK status

1;

		   