use 5.008008;
use strict;
use warnings;

=head1 NAME

PSPP-Perl - Perl extension to PSPP

=head1 SYNOPSIS

  use PSPP;

=head1 DESCRIPTION

PSPP-Perl provides an interface to the libraries used by pspp to read and
write system files.  

=head1 EXPORT

None by default.

=cut
BEGIN {
	$PSPP::VERSION='0.7.2.20090730';
	require XSLoader;
	XSLoader::load('PSPP', $PSPP::VERSION);
}

PSPP::onBoot($PSPP::VERSION);

=pod

=head1 PROGRAMMER'S INTERFACE

The subroutines in this package return zero or unref on error.
When errors occur, a string describing the error is written 
to C<$PSPP::errstr>. 

=cut

package PSPP;
use POSIX ;

use constant { SYSMIS => -(POSIX::DBL_MAX), 
	       PERL_EPOCH => 12219379200 # Number of seconds between 
                   # 14th October 1582
		   # and 
		   # 1st January 1970 
	       };



package PSPP::Dict;

=pod

=head2 PSPP::Dict::new

Creates a new dictionary.  This returned dictionary will be empty.
Returns undef on failure.

=head3 set_documents ($string)

Sets the documents (comments) to C<string>.

=head3 add_document ($string)

Appends C<string> to the documents.

=head3 clear_documents ()

Removes all documents.

=head3 set_weight ($var)

Sets the weighting variable to C<var>.

=cut

sub new
{
    my $class = shift;
    my $self = pxs_dict_new ();
    bless ($self, $class);
    return $self;
}

=pod

=head3 get_var_cnt ()

Returns the number of variables in the dictionary.

=head3 get_var ($idx)

Returns the C<idx>th variable from the dictionary.
Returns undef if C<idx> is greater than or equal to the number
of variables in the dictionary.

=cut

sub get_var
{
    my $dict = shift;
    my $idx = shift;
    my $var = pxs_get_variable ($dict, $idx);

    if ( ref $var ) 
    {
	bless ($var, "PSPP::Var");
    }
    return $var;
}

=pod

=head3 get_var_by_name ($name)

Returns the variable from the dictionary whose name is C<name>.
If there is no such variable, a null reference will be returned.

=cut

sub get_var_by_name
{
    my $dict = shift;
    my $name = shift;
    my $var = pxs_get_var_by_name ($dict, $name);

    if ( ref $var ) 
    {
	bless ($var, "PSPP::Var");
    }
    return $var;
}


package PSPP::Fmt;

=pod

=head2 PSPP::Fmt

Contains constants used to denote variable format types.  
The identifiers are the same as  those used in pspp to denote formats.
For  example C<PSPP::Fmt::F> defines floating point format, and
C<PSPP::Fmt::A> denotes string format.

=cut

# These must correspond to the values in src/data/format.h
use constant {
    F =>        0,
    COMMA =>    1,
    DOT =>      2, 
    DOLLAR =>   3, 
    PCT =>      4, 
    E =>        5, 
    CCA =>      6, 
    CCB =>      7, 
    CCC =>      8, 
    CCD =>      9, 
    CCE =>      10, 
    N =>        11, 
    Z =>        12, 
    P =>        13, 
    PK =>       14, 
    IB =>       15, 
    PIB =>      16, 
    PIBHEX =>   17, 
    RB =>       18, 
    RBHEX =>    19, 
    DATE =>     20, 
    ADATE =>    21, 
    EDATE =>    22, 
    JDATE =>    23, 
    SDATE =>    24, 
    QYR =>      25, 
    MOYR =>     26, 
    WKYR =>     27, 
    DATETIME => 28, 
    TIME =>     29, 
    DTIME =>    30, 
    WKDAY =>    31, 
    MONTH =>    32, 
    A =>        33, 
    AHEX =>     34
};


=head2 PSPP::Var

=cut

package PSPP::Var;

=head3 new ($dict, $name, %input_fmt)

Creates and returns a new variable in the dictionary C<dict>.  The 
new variable will have the name C<name>.
The input format is set by the C<input_fmt> parameter 
(See L</PSPP::Fmt>).
By default, the write and print formats are the same as the input format.
The write and print formats may be changed (See L</set_write_format>), 
L</set_print_format>).  The input format may not be changed after
the variable has been created.
If the variable cannot be created, undef is returned.

=cut

sub new
{
    my $class = shift;
    my $dict = shift;
    my $name = shift;
    my %format = @_;
    my $self = pxs_dict_create_var ($dict, $name, \%format);
    if ( ref $self ) 
    {
	bless ($self, $class);
    }
    return $self;
}

=pod

=head3 set_label ($label)

Sets the variable label to C<label>.


=cut

=pod

=head3 set_write_format (%fmt)

Sets the write format to C<fmt>. <fmt> is a hash containing the keys:

=over 2

=item FMT

A constant denoting the format type.  See L</PSPP::Fmt>.

=item decimals

An integer denoting the number of decimal places for the format.

=item width

An integer denoting the width of the format.

=back

On error the subroutine returns zero.

=cut

sub set_write_format
{
    my $var = shift;
    my %format = @_;
    pxs_set_write_format ($var, \%format);
}

=pod

=head3 set_print_format (%fmt)

Sets the print format to C<fmt>.
On error the subroutine returns zero.

=cut

sub set_print_format
{
    my $var = shift;
    my %format = @_;
    pxs_set_print_format ($var, \%format);
}

=pod


=head3 get_write_format ()

Returns a reference to a hash containing the write format for the variable.


=head3 get_print_format ()

Returns a reference to a hash containing the print format for the variable.

=head3 set_output_format (%fmt)

Sets the write and print formats to C<fmt>.  This is the same as
calling set_write_format followed by set_print_format.
On error the subroutine returns zero.

=cut


sub set_output_format
{
    my $var = shift;
    my %format = @_;
    pxs_set_output_format ($var, \%format);
}

=pod

=head3 clear_value_labels ()

Removes all value labels from the variable.

=cut


=pod

=head3 add_value_label ($key, $label)

Adds the value label C<label> to the variable for the value C<key>.
On error the subroutine returns zero.

=head3 add_value_labels (@array)

=cut

sub add_value_labels
{
    my $var = shift;
    my %values = @_;
    my @li;

    my $n = 0;
    while ( @li = each %values ) 
    {
	if ( $var->add_value_label ($li[0], "$li[1]") ) 
	{
	    $n++;
	}
    }

    return $n;
}

=pod

=head3 set_value_labels ($key, $value)

C<Set_value_labels> is identical to calling L</clear_value_labels>
followed by L</add_value_labels>.
On error the subroutine returns zero.

=cut

sub set_value_labels
{
    my $self = shift;
    my %labels = @_;
    $self->clear_value_labels () ;
    $self->add_value_labels (%labels);
}

=pod

=head3 set_missing_values ($val1 [, $val2[, $val3] ])

Sets the missing values for the variable.  
No more than three missing values may be specified.

=head3 get_attributes()

Returns a reference to a hash of the custom variable attributes.
Each value of the hash is a reference to an array containing the 
attribute values.

=head3 get_name ()

Returns the name of the variable.

=head3 get_label ()

Returns the label of the variable or undef if there is no label.

=head3 get_value_labels ()

Returns a reference to a hash containing the value labels for the variable.
The hash is keyed by data values which correpond to the labels.

=cut

package PSPP::Sysfile;

=pod

=head2 PSPP::Sysfile

=head3 new ($filename, $dict [,%opts])

Creates a new system file from the dictionary C<dict>.  The file will
be written to the file called C<filename>.
C<opt>, if specified, is a hash containing optional parameters for the
system file.  Currently, the only supported parameter is
C<compress>. If C<compress> is non zero, then the system file written
will be in the compressed format.
On error, undef is returned.


=head3 append_case (@case)

Appends a case to the system file.
C<Case> is an array of scalars, each of which are the values of 
the variables in the dictionary corresponding to the system file.
The special value C<PSPP::SYSMIS> may be used to indicate that a value
is system missing.
If the array contains less elements than variables in the dictionary,
remaining values will be set to system missing.

=cut

sub new
{
    my $class = shift;
    my $filename = shift;
    my $dict = shift;
    my $opts = shift;

    my $self  = pxs_create_sysfile ($filename, $dict, $opts);

    if ( ref $self ) 
    {
	bless ($self, $class);
    }
    return $self;
}

=pod

=head3 close ()

Closes the system file.

This subroutine closes the system file and flushes it to disk.  No
further cases may be written once the file has been closed.
The system file will be automatically closed when it goes out of scope.

=cut

package PSPP::Reader;

=pod

=head2 PSPP::Reader

=cut

sub open
{
    my $class = shift;
    my $filename = shift;

    my $self  = pxs_open_sysfile ($filename);

    if ( ref $self ) 
    {
	bless ($self, $class);
    }
    return $self;
}

=pod

=head3 open ($filename)

Opens a system file for reading.

Open is used to read data from an existing system file. 
It creates and returns a PSPP::Reader object which can be used to read 
data and dictionary information from C<filename>.

=cut

sub get_dict
{
    my $reader = shift;

    my $dict = pxs_get_dict ($reader);

    bless ($dict, "PSPP::Dict");

    return $dict;
}

=pod

=head3 get_dict ()

Returns the dictionary associated with the reader.

=head3 get_next_case ()

Retrieves the next case from the reader.
This method returns an array of scalars, each of which are the values of 
the data in the system file.
The first call to C<get_next_case> after C<open> has been called retrieves
the first case in the system file.  Each subsequent call retrieves the next
case.  If there are no more cases to be read, the function returns an empty
list.

If the case contains system missing values, these values are set to the 
empty string.

=head2 Miscellaneous subroutines

The following subroutines provide (hopefully) useful information about the 
values retrieved from a reader.

=head3 PSPP::format_value ($value, $variable)

Returns a scalar containing a string representing C<value> formatted according 
to the print format of C<variable>.
In the most common ussage,  C<value> should be a value of C<variable>.


=head3 PSPP::value_is_missing ($value, $variable)

Returns non-zero if C<value> is either system missing, or if it matches the 
user missing criteria for C<variable>.

=cut

1;
__END__


=head1 AUTHOR

John Darrington, E<lt>john@darrington.wattle.id.auE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007, 2008, 2009 by Free Software Foundation

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
