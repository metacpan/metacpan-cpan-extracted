
package R::YapRI::Data::Matrix;

use strict;
use warnings;
use autodie;

use Carp qw(croak cluck carp);
use R::YapRI::Base;
use R::YapRI::Interpreter::Perl qw( r_var );


###############
### PERLDOC ###
###############

=head1 NAME

R::YapRI::Data::Matrix.pm

A module to build and pass a Matrix to a YapRI command file

=cut

our $VERSION = '0.06';
$VERSION = eval $VERSION;

=head1 SYNOPSIS

  use R::YapRI::Base;
  use R::YapRI::Data::Matrix;

  ## Constructors:

  my $rmatrix = R::YapRI::Data::Matrix->new({ name => 'matrix1' });
  
  ## Accessors:

  my $matrixname = $rmatrix->get_name();
  $rmatrix->set_name('matrix');

  my $coln = $rmatrix->get_coln();
  $rmatrix->set_coln(3);

  my $rown = $rmatrix->get_rown();
  $rmatrix->set_rown(4);

  my @data = $rmatrix->get_data();
  $rmatrix->set_data(\@data);

  my @colnames = $rmatrix->get_colnames();
  $rmatrix->set_colnames(\@colnames);

  my @rownames = $rmatrix->get_colanmes();
  $rmatrix->set_colnames(\@rownames);

  ## Adding/deleting/changing data:

  $rmatrix->set_coldata($colname, [$y1, $y2, $y3, $y4]);
  $rmatrix->set_rowdata($rowname, [$x1, $x2, $x3]);
  
  $rmatrix->add_column($colname, [$yy1, $yy2, $yy3, $yy4]);
  $rmatrix->add_row($rowname, [$xx1, $xx2, $xx3]);

  my @oldcol = $rmatrix->remove_column($colname);
  my @oldrow = $rmatrix->remove_row($rowname);

  $rmatrix->change_columns($col_x, $col_z);
  $rmatrix->change_rows($row_x, $row_z);


  ## Parsers:
     
  my $rbase = R::YapRI::Base->new();
  $rmatrix->send_rbase($rbase, $mode);
 
  $rmatrix = R::YapRI::Data::Matrix->read_rbase($rbase, $block, $r_object_name);

  ## Slicers:

  my @col2 = $rmatrix->get_column($col_y);
  my @row3 = $rmatrix->get_row($row_x);
  my $elem2_3 = $rmatrix->get_element($row_x, $col_y);


=head1 DESCRIPTION

R::YapRI::Data::Matrix is a L<R::YapRI> to manipulate matrices, send to an
rbase object (L<R::YapRI::Base>) for further R manipulations.

This module pass perl variables to a R::YapRI::Data::Matrix object that convert
them in a R command line that it is passed to R::YapRI::Base object as a block.

 +-----------+    +----------------------+    +------------+    +---+--------+
 | PerlData1 | => | YaRI::Data::Matrix 1 | => |            | => |   | Input  |
 +-----------+    +----------------------+    | YaRI::Base |    | R |--------+
 | PerlData2 | <= | YaRI::Data::Matrix 2 |<=  |            | <= |   | Output |
 +-----------+    +----------------------+    +------------+    +---+--------+

It lets export data to R frame as: matrix (default), data.frames, vector 
(by_rows or by_columns) and list (by_rows or by_columns).

Rbase communication is based in two functions:

+ send_rbase, to add the matrix to a rbase block.

+ read_rbase, to create a R::YapRI::Data::Matrix based in a R matrix contained
in a rbase block.

=head1 AUTHOR

Aureliano Bombarely <aurebg@vt.edu>


=head1 CLASS METHODS

The following class methods are implemented:

=cut 



############################
### GENERAL CONSTRUCTORS ###
############################

=head1 (*) CONSTRUCTORS:

=head2 constructor new

  Usage: my $rmatrix = R::YapRI::Data::Matrix->new();

  Desc: Create a new R::YapRI::Data::Matrix object

  Ret: a R::YapRI::Data::Matrix object

  Args: A hash reference with the following parameters:
          name     => a scalar with the matrix name, 
          coln     => a scalar with the column number (int),
          rown     => a scalar with the row number (int),
          colnames => an array ref. with the column names,
          rownames => an array ref. with the row names,
          data     => an array ref. with the matrix data ordered by row.        
        
  Side_Effects: Die if the argument used is not a hash or its values arent 
                right.
                If no coln and rown are used, it will set to 0 by default.

  Example: my $rmatrix = R::YapRI::Data::Matrix->new(
                                     { 
                                       name     => 'matrix1',
                                       coln     => 3,
                                       rown     => 4,
                                       colnames => ['a', 'b', 'c'],
                                       rownames => ['W', 'X', 'Y', 'Z'],
                                       data     => [ 1, 1, 1, 2, 2, 2, 
                                                     3, 3, 3, 4, 4, 4,],
                                     }
                                   );

          
=cut

sub new {
    my $class = shift;
    my $args_href = shift;

    my $self = bless( {}, $class ); 

    my %permargs = (
	name     => '\w+',
	coln     => '^\d+$',
	rown     => '^\d+$',
        colnames => [],
        rownames => [],
        data     => [],
	);

    ## Check variables.

    my %args = ();
    if (defined $args_href) {
	unless (ref($args_href) eq 'HASH') {
	    croak("ARGUMENT ERROR: Arg. supplied to new() isnt HASHREF");
	}
	else {
	    %args = %{$args_href}
	}
    }

    foreach my $arg (keys %args) {
	unless (exists $permargs{$arg}) {
	    croak("ARGUMENT ERROR: $arg isnt permited arg for new() function");
	}
	else {
	    unless (defined $args{$arg}) {
		croak("ARGUMENT ERROR: value for $arg isnt defined for new()");
	    }
	    else {
		if (ref($permargs{$arg})) {
		    unless (ref($permargs{$arg}) eq ref($args{$arg})) {
			croak("ARGUMENT ERROR: $args{$arg} isnt permited val.");
		    }
		}
		else {
		    if ($args{$arg} !~ m/$permargs{$arg}/) {
			croak("ARGUMENT ERROR: $args{$arg} isnt permited val.");
		    }
		}
	    }
	}
    }

    ## Pass the arguments to the accessors functions

    my $name = $args{name} || '';
    $self->set_name($name);

    my $coln = $args{coln} || 0;
    $self->set_coln($coln);

    my $rown = $args{rown} || 0;
    $self->set_rown($rown);

    my $colnames = $args{colnames} || [];
    $self->set_colnames($colnames);

    my $rownames = $args{rownames} || [];
    $self->set_rownames($rownames);

    my $data = $args{data} || [];
    $self->set_data($data);

    
    return $self;
}


###############
## ACCESSORS ##
###############

=head1 (*) ACCESSORS:


=head2 get_name

  Usage: my $name = $matrix->get_name();

  Desc: Get the Matrix name for a R::YapRI::Data::Matrix object

  Ret: $name, a scalar

  Args: None    
        
  Side_Effects: None

  Example: my $name = $matrix->get_name();
          
=cut

sub get_name {
    my $self = shift;
    return $self->{name};
}

=head2 set_name

  Usage: $matrix->set_name($name);

  Desc: Set the Matrix name for a R::YapRI::Data::Matrix object

  Ret: None

  Args: $name, an scalar    
        
  Side_Effects: Die if undef value is used 

  Example: $matrix->set_name($name);
          
=cut

sub set_name {
    my $self = shift;
    my $name = shift;

    unless (defined $name) {
	croak("ERROR: No defined name argument was supplied to set_name()");
    }

    $self->{name} = $name;
}


=head2 get_coln

  Usage: my $coln = $matrix->get_coln();

  Desc: Get the matrix column number for a R::YapRI::Data::Matrix object

  Ret: $coln, a scalar

  Args: None    
        
  Side_Effects: None

  Example: my $coln = $matrix->get_coln();
          
=cut

sub get_coln {
    my $self = shift;
    return $self->{coln};
}

=head2 set_coln

  Usage: $matrix->set_coln($coln);

  Desc: Set the matrix column number for a R::YapRI::Data::Matrix object

  Ret: None

  Args: $coln, an scalar    
        
  Side_Effects: Die if undef value is used.
                Die if colnum number is not a digit

  Example: $matrix->set_coln($coln);
          
=cut

sub set_coln {
    my $self = shift;
    my $coln = shift;

    unless (defined $coln) {
	croak("ERROR: No defined coln argument was supplied to set_coln()");
    }

    ## Let use '' as empty value but if it match with any character it 
    ## should be a digit

    if ($coln =~ m/^.+/) {
	unless ($coln =~ m/^\d+$/) {
	    croak("ERROR: $coln supplied to set_coln() isnt a digit.");
	}
    }

    $self->{coln} = $coln;
}


=head2 get_rown

  Usage: my $rown = $matrix->get_rown();

  Desc: Get the matrix row number for a R::YapRI::Data::Matrix object

  Ret: $rown, a scalar

  Args: None    
        
  Side_Effects: None

  Example: my $rown = $matrix->get_rown();
          
=cut

sub get_rown {
    my $self = shift;
    return $self->{rown};
}

=head2 set_rown

  Usage: $matrix->set_rown($rown);

  Desc: Set the matrix row number for a R::YapRI::Data::Matrix object

  Ret: None

  Args: $rown, an scalar    
        
  Side_Effects: Die if undef value is used.
                Die if rown number is not a digit

  Example: $matrix->set_rown($rown);
          
=cut

sub set_rown {
    my $self = shift;
    my $rown = shift;

    unless (defined $rown) {
	croak("ERROR: No defined rown argument was supplied to set_rown()");
    }

    ## Let use '' as empty value but if it match with any character it 
    ## should be a digit

    if ($rown =~ m/^.+/) {
	unless ($rown =~ m/^\d+$/) {
	    croak("ERROR: $rown supplied to set_rown() isnt a digit.");
	}
    }

    $self->{rown} = $rown;
}


=head2 get_colnames

  Usage: my $colnames_aref = $matrix->get_colnames();

  Desc: Get the Matrix column names array for a R::YapRI::Data::Matrix object

  Ret: $colnames_aref, an array reference with the column names

  Args: None    
        
  Side_Effects: None

  Example: my @colnames = @{$matrix->get_colnames()};
          
=cut

sub get_colnames {
    my $self = shift;
    return $self->{colnames};
}

=head2 set_colnames

  Usage: $matrix->set_colnames(\@colnames);

  Desc: Set the matrix column names array for a R::YapRI::Data::Matrix object

  Ret: None

  Args: $col_names_aref, an array reference with the column names
        
  Side_Effects: Die if undef value is used
                Die if argument is not an array reference.
                Die if number of element in the array isnt equal to coln value.
                (except if colnumber is empty)

  Example: $matrix->set_colnames(['col1', 'col2']);
          
=cut

sub set_colnames {
    my $self = shift;
    my $colnam_aref = shift ||
	croak("ERROR: No colname_aref argument was supplied to set_colnames()");

    if (ref($colnam_aref) ne 'ARRAY') {
	croak("ERROR: $colnam_aref supplied to set_colnames() isnt ARRAYREF.");
    }
    my $namesn = scalar(@{$colnam_aref});
    
    ## Check that is has the same number of elelemnts than coln

    my $coln = $self->get_coln();
    if ($coln =~ m/^\d+$/ && $namesn > 0) {
	unless ($namesn == $coln) {
	    croak("ERROR: Different number of names and cols for set_colnames");
	}
    }
    elsif ($coln =~ m/^\d+$/ && $namesn == 0) {  ## Add by default colnames 
	my $n = 0;                               ## from 0 to coln-1
	while ($n + 1 <= $coln) {
	    push @{$colnam_aref}, $n;
	    $n++;
	}
    }

    $self->{colnames} = $colnam_aref;
}


=head2 get_rownames

  Usage: my $rownames_aref = $matrix->get_rownames();

  Desc: Get the Matrix row names array for a R::YapRI::Data::Matrix object

  Ret: $rownames_aref, an array reference with the row names

  Args: None    
        
  Side_Effects: None

  Example: my @rownames = @{$matrix->get_rownames()};
          
=cut

sub get_rownames {
    my $self = shift;
    return $self->{rownames};
}

=head2 set_rownames

  Usage: $matrix->set_rownames(\@rownames);

  Desc: Set the matrix row names array for a R::YapRI::Data::Matrix object

  Ret: None

  Args: $row_names_aref, an array reference with the row names
        
  Side_Effects: Die if undef value is used
                Die if argument is not an array reference.
                Die if number of element in the array isnt equal to rown value.
                (except if rownumber is empty)

  Example: $matrix->set_rownames(['row1', 'row2']);
          
=cut

sub set_rownames {
    my $self = shift;
    my $rownam_aref = shift ||
	croak("ERROR: No rowname_aref argument was supplied to set_rownames()");

    if (ref($rownam_aref) ne 'ARRAY') {
	croak("ERROR: $rownam_aref supplied to set_rownames() isnt ARRAYREF.");
    }
    my $namesn = scalar(@{$rownam_aref});
    
    ## Check that is has the same number of elelemnts than coln

    my $rown = $self->get_rown();
    if ($rown =~ m/^\d+$/ && $namesn > 0) {
	unless ($namesn == $rown) {
	    croak("ERROR: Different number of names and rows for set_rownames");
	}
    }
    elsif ($rown =~ m/^\d+$/ && $namesn == 0) {  ## Add by default rownames 
	my $n = 0;                               ## from 0 to coln-1
	while ($n + 1 <= $rown) {
	    push @{$rownam_aref}, $n;
	    $n++;
	}
    }

    $self->{rownames} = $rownam_aref;
}


=head2 get_data

  Usage: my $data_aref = $matrix->get_data();

  Desc: Get the matrix data array for a R::YapRI::Data::Matrix object.
        The data is stored as an array ordered by rows.

        Example: Matrix  |1 2 3|  => [1, 2, 3, 4, 5, 6]
                         |4 5 6|
 
  Ret: $data_aref, an array reference with the data as array

  Args: None    
        
  Side_Effects: None

  Example: my @data = @{$matrix->get_data()};
          
=cut

sub get_data {
    my $self = shift;
    return $self->{data};
}

=head2 set_data

  Usage: $matrix->set_data(\@data);

  Desc: Set the matrix data array for a R::YapRI::Data::Matrix object

  Ret: None

  Args: $data, an array reference with the data ordered by rows

         Example: Matrix  |1 2 3|  => [1, 2, 3, 4, 5, 6]
                          |4 5 6|
        
  Side_Effects: Die if undef value is used
                Die if argument is not an array reference.
                Die if number of element in the array isnt equal to  
                coln x rown (for example if coln=3 and rown=2, it should have
                6 elements)

  Example: $matrix->set_data([1, 2, 3, 4]);
          
=cut

sub set_data {
    my $self = shift;
    my $data_aref = shift ||
	croak("ERROR: No data_aref argument was supplied to set_data()");

    if (ref($data_aref) ne 'ARRAY') {
	croak("ERROR: $data_aref supplied to set_data() isnt ARRAYREF.");
    }
    my $data_n = scalar(@{$data_aref});
    
    ## Check that is has the same number of elements than coln x rown

    my $coln = $self->get_coln();
    my $rown = $self->get_rown();
    
    if ($coln =~ m/^\d+$/ && $rown =~ m/^\d+$/ && $data_n > 0) {
	my $elems = $coln * $rown;
	if ($data_n != $elems) {
	    croak("ERROR: data_n = $data_n != ($rown x $coln) to set_data().");
	}
    }
    $self->{data} = $data_aref;

    ## And set the indexes for the matrix

    my %indexes = $self->_index_matrix();
    $self->_set_indexes(\%indexes);
}

########################
## INTERNAL FUNCTIONS ##
########################

=head1 (*) INTERNAL MATRIX FUNCTIONS:


=head2 _get_indexes

  Usage: my $index_href = $matrix->_get_indexes();

  Desc: Get then matrix indexes for columns and rows, with the following 
        format:
          $index_href = { $row,$col => $array_element }
 
  Ret: $index_href, a hash reference with the matrix indexes.

  Args: None    
        
  Side_Effects: None

  Example: my %indexes = @{$matrix->_get_indexes()};
          
=cut

sub _get_indexes {
    my $self = shift;
    return $self->{_indexes};
}

=head2 _get_rev_indexes

  Usage: my $revindex_href = $matrix->_get_rev_indexes();

  Desc: Get then matrix indexes for columns and rows, with the following 
        format:
          $index_href = { $array_element => [ $row, $col ] }
 
  Ret: $rindex_href, a hash reference with the matrix indexes.

  Args: None    
        
  Side_Effects: None

  Example: my %revindexes = %{$matrix->_get_rev_indexes()};
          
=cut

sub _get_rev_indexes {
    my $self = shift;
    
    my %rev_index = ();
    my %indexes = %{$self->_get_indexes()};
    foreach my $i (keys %indexes) {
	my ($r, $c) = split(/,/, $i);
	$rev_index{$indexes{$i}} = [$r, $c];
    }
    return \%rev_index;
}



=head2 _set_indexes

  Usage: $matrix->_set_indexes(\%indexes);

  Desc: Set the matrix indexes for the data contained in the matrix

  Ret: None

  Args: \%indexes, a hash reference with key=$row,$col and value=$arrayposition
        
  Side_Effects: Die if undef value is used
                Die if argument is not an hash reference.
                Die if number of element in the hash isnt equal to  
                coln x rown (for example if coln=3 and rown=2, it should have
                6 elements)

  Example: $matrix->set_data([1, 2, 3, 4]);
          
=cut

sub _set_indexes {
    my $self = shift;
    my $ind_href = shift ||
	croak("ERROR: No index href argument was supplied to _set_indexes()");

    if (ref($ind_href) ne 'HASH') {
	croak("ERROR: $ind_href supplied to _set_indexes() isnt HASHREF.");
    }
    my $n = scalar(keys %{$ind_href});
    
    ## Check that is has the same number of elements than coln x rown

    my $coln = $self->get_coln();
    my $rown = $self->get_rown();
    
    if ($coln =~ m/^\d+$/ && $rown =~ m/^\d+$/ && $n > 0) {
	my $elems = $coln * $rown;
	if ($n != $elems) {
	    croak("ERROR: indexN = $n != ($rown x $coln) to _set_indexes().");
	}
    }

    $self->{_indexes} = $ind_href;
}

=head2 _index_matrix

  Usage: my %index_matrix = $self->_index_matrix();

  Desc: Index the matrix with an array to know segment the matrix in elements
        %index_matrix = ( $arrayposition => { row => $rowposition,
                                              col => $colposition 
                                            });
 
  Ret: The index matrix, a hash with the following elements:
       %index_matrix = ( $arrayposition => { $rowposition, $colposition })

  Args: None  
        
  Side_Effects: None

  Example: my %index_matrix = $self->_index_matrix();
          
=cut

sub _index_matrix {
    my $self = shift;

    ## Define index

    my %index = ();

    ## Get the rown, coln and data

    my $rown = $self->get_rown();
    my $coln = $self->get_coln();
    my @data = @{$self->get_data()};

    ## Assign positions

    my ($a, $r, $c) = (0, 0, 0);
    foreach my $data (@data) {
	$index{$r . ',' . $c} = $a;
	$a++;
	$c++;
	if ($c + 1 > $coln) {
	    $r++;
	    $c = 0;
	}
    }
    
    return %index;
}


=head2 _no_duplicate_names

  Usage: $rmatrix->_no_duplicate_names($method);

  Desc: Check if there are duplicate names for col or rows. Die if exists
        duplicates.
 
  Ret: None

  Args: $method, a scalar that can have 'col', 'row' or 'all'. (all by default)
        
  Side_Effects: Overwrite methods that are not 'col' or 'row' with 'all'. 
                Die if it find duplicates.

  Example: $rmatrix->_no_duplicate_names('col');
          
=cut

sub _no_duplicate_names {
    my $self = shift;
    my $method = shift
	|| 'all';
    
    my %methods = ( 
	col => $self->get_colnames(),
	row => $self->get_rownames(),
	); 
    
    my %dupl = ( col => [], row => []);

    foreach my $me (keys %methods) {
	my %exs = ();
	my @names = @{$methods{$me}};
	foreach my $name (@names) {
	    unless (exists $exs{$name}) {
		$exs{$name} = 1;
	    }
	    else {
		$exs{$name}++;
		if ($exs{$name} < 3) {
		    push @{$dupl{$me}}, $name;
		}
	    }
	}
    }

    ## With the list of duplicates

    my @coldupl = @{$dupl{col}};
    my @rowdupl = @{$dupl{row}};
    my $clist = join(',', @coldupl) || 'none';
    my $rlist = join(',', @rowdupl) || 'none';

    if ($method =~ m/^col$/i) {
	if (scalar(@coldupl) > 0) {
	    croak("ERROR: There are column duplicates ($clist).");
	}
    }
    elsif ($method =~ m/^row$/i) {
	if (scalar(@rowdupl) > 0) {	    
	    croak("ERROR: There are row duplicates ($rlist).");
	}
    }
    else {
	my $dupl = scalar(@coldupl) + scalar(@rowdupl);
	if ($dupl > 0) {
	    croak("ERROR: There are duplicate names (col=$clist, row=$rlist).");
	}
    }
}

#####################
## DATA FUNCTIONS ###
#####################

=head1 (*) DATA MANAGEMENT FUNCTIONS:


=head2 set_coldata

  Usage: $rmatrix->set_coldata($colname, \@col_data);

  Desc: Add data to an existing column, overwriting the old data
 
  Ret: None

  Args: $colname, a scalar with the name of the column
        $coldata_aref, an array ref. with the data of the column    
        
  Side_Effects: Die if no colname is used.
                Die if the number of elements in the data array is different
                than the rown

  Example: $rmatrix->set_coldata('col1', [1, 2]);
           $rmatrix->set_coldata($colnames[0], [1, 2]);
          
=cut

sub set_coldata {
    my $self = shift;
    my $colname = shift ||
	croak("ERROR: No colname was supplied to add_coldata()");
    
    my $col_aref = shift ||
	croak("ERROR: No column data aref. was supplied to add_coldata()");

    unless(ref($col_aref) eq 'ARRAY') {
	croak("ERROR: column data aref = $col_aref isnt a ARRAY REF.")
    }

    ## Check if the colname exists or the colposition, and asign a col. 
    ## position for the colname.
    
    my $colpos;
    
    my @colnames = @{$self->get_colnames()};
    my $n = 0;
    foreach my $col (@colnames) {
	if ($col eq $colname) {
	    $colpos = $n;
	}
	$n++;
    }
    unless (defined $colpos) {
	croak("ERROR: $colname doesnt exist for colnames list.")
    }    
    
    ## Now it will check that the elements number are equal to rown

    my $rown = $self->get_rown();
    if ($rown != scalar(@{$col_aref})) {
	croak("ERROR: data supplied to add_coldata dont have same row number");
    }

    ## With colpos it will replace the elements using the matrix index

    my $data_aref = $self->get_data();
    my %index = %{$self->_get_indexes()};

    foreach my $i (keys %index) {
	my ($r, $c) = split(',', $i);

	if ($c == $colpos) {
	    $data_aref->[$index{$i}] = $col_aref->[$r];
	}
    }
}


=head2 set_rowdata

  Usage: $rmatrix->set_rowdata($rowname, \@row_data);

  Desc: Add data to an existing row, overwriting the old data
 
  Ret: None

  Args: $colname, a scalar with the name of the row,
        $rowdata_aref, an array ref. with the data of the row   
        
  Side_Effects: Die if no rowname is used.
                Die if the number of elements in the data array is different
                than the column

  Example: $rmatrix->set_rowdata('row1', [1, 2]);
           $rmatrix->set_rowdata($rownames[0], [1, 2]);
          
=cut

sub set_rowdata {
    my $self = shift;
    my $rowname = shift ||
	croak("ERROR: No rowname was supplied to add_rowdata()");
    
    my $row_aref = shift ||
	croak("ERROR: No row data aref. was supplied to add_rowdata()");

    unless(ref($row_aref) eq 'ARRAY') {
	croak("ERROR: row data aref = $row_aref isnt a ARRAY REF.")
    }

    ## Check if the colname exists or the colposition, and asign a col. 
    ## position for the colname.
    
    my $rowpos;
    
    my @rownames = @{$self->get_rownames()};
    my $n = 0;
    foreach my $row (@rownames) {
	if ($row eq $rowname) {
	    $rowpos = $n;
	}
	$n++;
    }
    unless (defined $rowpos) {
	croak("ERROR: $rowname doesnt exist for rownames list.")
    }    
    
    ## Now it will check that the elements number are equal to coln

    my $coln = $self->get_coln();
    if ($coln != scalar(@{$row_aref})) {
	croak("ERROR: data supplied to add_rowdata dont have same col number");
    }

    ## With colpos it will replace the elements using the matrix index

    my $data_aref = $self->get_data();
    my %index = %{$self->_get_indexes()};

    foreach my $i (keys %index) {
	my ($r, $c) = split(',', $i);

	if ($r == $rowpos) {
	    $data_aref->[$index{$i}] = $row_aref->[$c];
	}
    }
}

=head2 add_column

  Usage: $rmatrix->add_column($colname, \@col_data);

  Desc: Add a new column to the object, rebuilding the indexes and edinting
        column number
 
  Ret: None

  Args: $colname, a scalar with the name of the column
        $coldata_aref, an array ref. with the data of the column    
        
  Side_Effects: Die if the number of elements in the data array is different
                than the row number
                Rebuild and reset the matrix indexes and the coln.

  Example: $rmatrix->add_column('col1', [1, 2]);
          
=cut

sub add_column {
    my $self = shift;
    my $colname = shift;
    
    ## Check variables

    my $coldata_aref = shift ||
	croak("ERROR: No column data was supplied to add a new column");

    unless (ref($coldata_aref) eq 'ARRAY') {
	croak("ERROR: column data aref = $coldata_aref isnt a ARRAY REF.")
    }
    else {
	my $rown = $self->get_rown();
	if ($rown != scalar(@{$coldata_aref})) {
	    croak("ERROR: element N. for col. data isnt equal to row N.");
	}
    }

    ## Now it will add a new coln

    my $old_coln = $self->get_coln();
    $self->set_coln($old_coln + 1);

    ## If it defined colname, it will add it

    if (defined $colname) {
	push @{$self->get_colnames()}, $colname;
    }
    else {
	push @{$self->get_colnames()}, $old_coln; 
    }

    ## Get the indexes to add new data and flip the hash

    my %rev_index = %{$self->_get_rev_indexes()};
	
    ## Prepare a new array data

    my @newdata = ();

    ## Use the old data, adding a new data from the column aref. after the
    ## element from the array

    my $a = 0;
    my @data = @{$self->get_data()};
    foreach my $el (@data) {
	
	my ($rr, $cc) = @{$rev_index{$a}};
	$a++;
	push @newdata, $el;
	if ($cc + 1 == $old_coln) {
	    push @newdata, $coldata_aref->[$rr];
	}
    }

    ## finally set_data (it will rebuild the indexes)
    $self->set_data(\@newdata);
}


=head2 add_row

  Usage: $rmatrix->add_row($rowname, \@row_data);

  Desc: Add a new row to the object, rebuilding the indexes and edinting
        row number
 
  Ret: None

  Args: $rowname, a scalar with the name of the row
        $rowdata_aref, an array ref. with the data of the row   
        
  Side_Effects: Die if the number of elements in the data array is different
                than the col number
                Rebuild and reset the matrix indexes and the rown.

  Example: $rmatrix->add_row('row3', [1, 2]);
          
=cut

sub add_row {
    my $self = shift;
    my $rowname = shift;
    
    ## Check variables

    my $rowdata_aref = shift ||
	croak("ERROR: No row data was supplied to add a new row");

    unless (ref($rowdata_aref) eq 'ARRAY') {
	croak("ERROR: row data aref = $rowdata_aref isnt a ARRAY REF.")
    }
    else {
	my $coln = $self->get_coln();
	if ($coln != scalar(@{$rowdata_aref})) {
	    croak("ERROR: element N. for row. data isnt equal to col N.");
	}
    }

    ## Now it will add a new rown

    my $old_rown = $self->get_rown();
    $self->set_rown($old_rown + 1);

    ## If it defined rowname, it will add it

    if (defined $rowname) {
	push @{$self->get_rownames()}, $rowname;
    }
    else {
	push @{$self->get_rownames()}, $old_rown; 
    }

    ## Get the indexes to add new data and flip the hash

    my %rev_index = %{$self->_get_rev_indexes()};
	
    ## It is ordered by row, so it will add everything after the last row
    ## that means that it will push the data. To mantain the same behaviour 
    ## than add_column it will create a new array;

    my @data = @{$self->get_data};
    push @data, @{$rowdata_aref};

    ## finally set_data (it will rebuild the indexes)
    $self->set_data(\@data);
}


=head2 delete_column

  Usage: my @coldata = $rmatrix->delete_column($colname);

  Desc: Delete a column to the object, rebuilding the indexes and edinting
        column number
 
  Ret: @coldata, an array with the column data deleted

  Args: $colname, a scalar with the name of the column  
        
  Side_Effects: Die if the column doesnt exist.
                Rebuild indexes and reset coln.

  Example: my @coldata = $rmatrix->delete_column('col1');
          
=cut

sub delete_column {
    my $self = shift;
    my $colname = shift ||
	croak("ERROR: No colname was supplied to delete_column()");

    my @newcolnames = ();
    my @oldcolnames = @{$self->get_colnames()};
    my $del = '';

    my $n = 0;
    foreach my $old (@oldcolnames) {
	unless ($colname eq $old) {
	    push @newcolnames, $old;
	}
	else {
	    $del = $n;  ## Keep the index for the deleted column
	}
	$n++;
    }

    ## Die if they have the same number of elements (doesnt exist colname)

    if (scalar(@newcolnames) == scalar(@oldcolnames)) {
	croak("ERROR: $colname used for delete_column() isnt in colname list");
    }

    ## Change the number of coln

    my $oldcoln = $self->get_coln();
    $self->set_coln($oldcoln - 1);

    ## And set the new names 

    $self->set_colnames(\@newcolnames);

    ## Finally it should remove the data

    my %revindex = %{$self->_get_rev_indexes()};

    my @deleted = ();
    my @newdata = ();
    my @data = @{$self->get_data()};

    my $a = 0;
    foreach my $data (@data) {
	my ($r, $c) = @{$revindex{$a}};
	if ($c != $del) {
	    push @newdata, $data;
	}
	else {
	    push @deleted, $data;
	}
	$a++;
    }
    
    ## And add to the object returning the deleted data

    $self->set_data(\@newdata);   
    return @deleted;
}
    

=head2 delete_row

  Usage: my @rowdata = $rmatrix->delete_row($rowname);

  Desc: Delete a row to the object, rebuilding the indexes and edinting
        row number
 
  Ret: @rowdata, an array with the row data deleted

  Args: $rowname, a scalar with the name of the row  
        
  Side_Effects: Die if the row doesnt exist.
                Rebuild indexes and reset rown.

  Example: my @rowdata = $rmatrix->delete_row('row1');
          
=cut

sub delete_row {
    my $self = shift;
    my $rowname = shift ||
	croak("ERROR: No rowname was supplied to delete_row()");

    my @newrownames = ();
    my @oldrownames = @{$self->get_rownames()};
    my $del = '';

    my $n = 0;
    foreach my $old (@oldrownames) {
	unless ($rowname eq $old) {
	    push @newrownames, $old;
	}
	else {
	    $del = $n;  ## Keep the index for the deleted row
	}
	$n++;
    }

    ## Die if they have the same number of elements (doesnt exist colname)

    if (scalar(@newrownames) == scalar(@oldrownames)) {
	croak("ERROR: $rowname used for delete_row() isnt in rowname list");
    }

    ## Change the number of coln

    my $oldrown = $self->get_rown();
    $self->set_rown($oldrown - 1);

    ## And set the new names 

    $self->set_rownames(\@newrownames);

    ## Finally it should remove the data

    my %revindex = %{$self->_get_rev_indexes()};

    my @deleted = ();
    my @newdata = ();
    my @data = @{$self->get_data()};

    my $a = 0;
    foreach my $data (@data) {
	my ($r, $c) = @{$revindex{$a}};
	if ($r != $del) {
	    push @newdata, $data;
	}
	else {
	    push @deleted, $data;
	}
	$a++;
    }
    
    ## And add to the object returning the deleted data

    $self->set_data(\@newdata);   
    return @deleted;
}

=head2 change_columns

  Usage: $rmatrix->change_columns($colname1, $colname2);

  Desc: Change the order of two columns
 
  Ret: None

  Args: $colname1, column name 1, 
        $colname2, column name 2,  
        
  Side_Effects: Die if the any of the column names used doesnt exist.

  Example: $rmatrix->change_columns('col1', 'col2');
          
=cut

sub change_columns {
    my $self = shift;
    my $colname1 = shift ||
	croak("ERROR: no colname1 arg. was supplied to change_columns()");

    my $colname2 = shift ||
	croak("ERROR: no colname2 arg. was supplied to change_columns()");


    my %col_index = ( $colname1 => '', $colname2 => '' );

    ## Get the index for this two colnames

    my @colnames = @{$self->get_colnames()};
    my ($n, $match) = (0, 0);
    foreach my $col (@colnames) {
	foreach my $selcol (keys %col_index) {
	    if ($col eq $selcol) {
		$col_index{$selcol} = $n;
		$match++;
	    }
	}
	$n++;
    }

    ## Die if match == 2

    if ($match != 2) {
	croak("ERROR: one or two of the colnames supplied isnt column list.");
    }

    ## Now, it has two col, so it will get the data

    my %col_data = ( $colname1 => [], $colname2 => [] );
    my @data = @{$self->get_data()};
    my %revindex = %{$self->_get_rev_indexes()};
    
    my $a = 0;
    foreach my $data (@data) {
	my ($r, $c) = @{$revindex{$a}};
	foreach my $colnm (sort keys %col_index) {
	    if ($col_index{$colnm} == $c) {
		push @{$col_data{$colnm}}, $data;
	    }
	}
	$a++;
    }


    ## Finally it will change the order in the colname array and it will set
    ## the coldata

    my %changed = ( 
	$colname2 => $colname1,
	$colname1 => $colname2,
	);

    foreach my $chname (sort keys %changed) {	
	$self->set_coldata($chname, $col_data{$changed{$chname}});
	
	my $old_idx = $col_index{$chname};
	my $new_idx = $col_index{$changed{$chname}};
	$self->get_colnames()->[$old_idx] = $changed{$chname};
    } 
}


=head2 change_rows

  Usage: $rmatrix->change_rows($rowname1, $rowname2);

  Desc: Change the order of two rows
 
  Ret: None

  Args: $rowname1, row name 1, 
        $rowname2, row name 2,  
        
  Side_Effects: Die if the any of the row names used doesnt exist.

  Example: $rmatrix->change_rows('row1', 'row2');
          
=cut

sub change_rows {
    my $self = shift;
    my $rowname1 = shift ||
	croak("ERROR: no rowname1 arg. was supplied to change_rows()");

    my $rowname2 = shift ||
	croak("ERROR: no rowname2 arg. was supplied to change_rows()");


    my %row_index = ( $rowname1 => '', $rowname2 => '' );

    ## Get the index for this two rownames

    my @rownames = @{$self->get_rownames()};
    my ($n, $match) = (0, 0);
    foreach my $row (@rownames) {
	foreach my $selrow (sort keys %row_index) {
	    if ($row eq $selrow) {
		$row_index{$selrow} = $n;
		$match++;
	    }
	}
	$n++;
    }

    ## Die if match == 2

    if ($match != 2) {
	croak("ERROR: one or two of the rownames supplied isnt row list.");
    }

    ## Now, it has two row, so it will get the data

    my %row_data = ( $rowname1 => [], $rowname2 => [] );
    my @data = @{$self->get_data()};
    my %revindex = %{$self->_get_rev_indexes()};
    
    my $a = 0;
    foreach my $data (@data) {
	my ($r, $c) = @{$revindex{$a}};
	foreach my $rownm (sort keys %row_index) {
	    if ($row_index{$rownm} == $r) {
		push @{$row_data{$rownm}}, $data;
	    }
	}
	$a++;
    }


    ## Finally it will change the order in the rowname array and it will set
    ## the coldata

    my %changed = ( 
	$rowname2 => $rowname1,
	$rowname1 => $rowname2,
	);

    foreach my $chname (sort keys %changed) {	
	$self->set_rowdata($chname, $row_data{$changed{$chname}});
	
	my $old_idx = $row_index{$chname};
	my $new_idx = $row_index{$changed{$chname}};
	$self->get_rownames()->[$old_idx] = $changed{$chname};
    } 
}

=head2 transpose

  Usage: my $newmatrix = $rmatrix->matrix($matrixname);

  Desc: Create a new matrix executing a transpose over the original matrix
 
  Ret: $newmatrix, a R::YapRI::Data::Matrix object

  Args: $matrixname, a new matrix name
        
  Side_Effects: Use tr_ . $rmatrix->get_name as default name.

  Example: my $newmatrix = $rmatrix->matrix();
          
=cut

sub transpose {
    my $self = shift;
    my $name = shift;

    unless (defined $name) {
	$name = 'tr_' . $self->get_name();
    }

    my $coln = $self->get_coln();
    my $rown = $self->get_rown();
    my @colnames = @{$self->get_colnames()};
    my @rownames = @{$self->get_rownames()};

    my @newdata = ();
    foreach my $col (@colnames) {
	push @newdata, $self->get_column($col);
    }

    my $newmatrix = __PACKAGE__->new({ name     => $name,
				       coln     => $rown,
				       rown     => $coln,
				       colnames => \@rownames, 
				       rownames => \@colnames,
				       data     => \@newdata,
				     });

    return $newmatrix
}



#############
## SLICERS ##
#############

=head2 get_column

  Usage: my @column = $rmatrix->get_column($colname);

  Desc: Get the column data for a concrete columnname
 
  Ret: @column, an array with the column data

  Args: $colname, a scalar with the column name
        
  Side_Effects: return an empty array if the column doesnt exist

  Example: my @column2 = $rmatrix->get_column('column2');
          
=cut

sub get_column {
    my $self = shift;
    my $colname = shift || '';

    ## Get the index

    my @colnames = @{$self->get_colnames()};
    my $ci;
    my $a = 0;
    foreach my $col (@colnames) {
	if ($col eq $colname) {
	    $ci = $a;
	}
	$a++;
    }

    ## Catch the data based in the index, and push into an array

    my @column_data = ();

    if (defined $ci) {
	my %revindex = %{$self->_get_rev_indexes()};
	my @data = @{$self->get_data()};
	my $n = 0;
	foreach my $data (@data) {
	    my ($r, $c) = @{$revindex{$n}};
	    if ($c == $ci) {
		push @column_data, $data;
	    }
	    $n++;
	}
    }
    return @column_data;
}

=head2 get_row

  Usage: my @row = $rmatrix->get_row($rowname);

  Desc: Get the row data for a concrete rowname
 
  Ret: @row, an array with the row data

  Args: $rowname, a scalar with the row name
        
  Side_Effects: return an empty array if the row doesnt exist

  Example: my @row3 = $rmatrix->get_row('row3');
          
=cut

sub get_row {
    my $self = shift;
    my $rowname = shift || '';

    ## Get the index

    my @rownames = @{$self->get_rownames()};
    my $ri;
    my $a = 0;
    foreach my $row (@rownames) {
	if ($row eq $rowname) {
	    $ri = $a;
	}
	$a++;
    }

    ## Catch the data based in the index, and push into an array

    my @row_data = ();

    if (defined $ri) {
	my %revindex = %{$self->_get_rev_indexes()};
	my @data = @{$self->get_data()};
	my $n = 0;
	foreach my $data (@data) {
	    my ($r, $c) = @{$revindex{$n}};
	    if ($r == $ri) {
		push @row_data, $data;
	    }
	    $n++;
	}
    }
    return @row_data;
}

=head2 get_element

  Usage: my $element = $rmatrix->get_element($rowname, $colname);

  Desc: Get the matrix element for concrete $rowname, $colname pair
 
  Ret: $element, a scalar with the element value

  Args: $rowname, a scalar with the row name
        $colname, a scalar with the column name
        
  Side_Effects: return undef if the row or/and column doesnt exist

  Example: my $element = $rmatrix->get_element($rowname, $colname);
          
=cut

sub get_element {
    my $self = shift;
    my $rowname = shift || '';
    my $colname = shift || '';

    my $element;
    my %selindex = ( row => '', col => '');
    my %el_index = ( row => $rowname, 
		     col => $colname );
    my %el_names = ( row => $self->get_rownames(), 
		     col => $self->get_colnames());

    ## Catch the indexes
    
    foreach my $idx (keys %el_index) {
	my $i = 0;
	my @names = @{$el_names{$idx}};
	foreach my $name (@names) {
	    if ($name eq $el_index{$idx}) {
		$selindex{$idx} = $i;
	    }
	    $i++;
	}
    }

    ## Get the data index

    my %index = %{$self->_get_indexes()};
    my $data_idx = $index{$selindex{row} . ',' . $selindex{col}};
    
    if (defined $data_idx) {
	my @data = @{$self->get_data()};
	$element = $data[$data_idx];
    }
    return $element;
}


###########################
## PARSERS AND R.WRITERS ##
###########################

=head1 (*) R. FUNCTIONS:


=head2 _matrix_cmd

  Usage: my $cmd = $rmatrix->_matrix_cmd();

  Desc: Build the command to add a new matrix 
 
  Ret: $cmd, a string with the R command

  Args: None
        
  Side_Effects: None

  Example: my $cmd = $rmatrix->_matrix_cmd();
          
=cut 

sub _matrix_cmd {
    my $self = shift;

    my $cmd = $self->get_name . ' <- matrix(';

    ## Add data using r_var function to convert in per R string
    
    $cmd .= r_var($self->get_data()) . ', ';
    
    ## add rown, coln and byrow=TRUE
    
    $cmd .= 'nrow=' . $self->get_rown() . ', ';
    $cmd .= 'ncol=' . $self->get_coln() . ', ';
    $cmd .= 'byrow=TRUE, ';

    ## Finally it will add the row and col names

    $cmd .= 'dimnames=list(';    
    $cmd .= r_var($self->get_rownames()) . ', ';
    $cmd .= r_var($self->get_colnames()) . ')';
    
    ## And close the matrix
    $cmd .= ')';

    return $cmd;
}


=head2 _dataframe_cmd

  Usage: my $cmd = $rmatrix->_dataframe_cmd();

  Desc: Build the command to add a new dataframe to R block
 
  Ret: $cmd, a string with the R command

  Args: None
        
  Side_Effects: If the column names are numeric (f.example: 1), it will
                add an X before (R doesnt accept numeric column names)

  Example: my $cmd = $rmatrix->_dataframe_cmd();
          
=cut 

sub _dataframe_cmd {
    my $self = shift;

    my $cmd;

    ## A data frame is build with R vectors of columns
    ## data.frame('col1'=c(coldata1), ... row.names=c(rownames))
    
    my $mtxname = $self->get_name();
    my @colnames = @{$self->get_colnames()};
    my @rownames = @{$self->get_rownames()};

    my @dataframe_data = ();
    foreach my $col (@colnames) {
	my @coldata = $self->get_column($col);
	if ($col =~ m/^\d+$/) {
	    $col = 'X' . $col;
	}
	push @dataframe_data, $col . '=' . r_var(\@coldata);
    }
    
    ## Now it will create the data frame
    my $dataline = join(', ', @dataframe_data);

    $cmd = $mtxname . ' <- data.frame( ' . $dataline;           ## Add data
    if (scalar(@rownames) > 0) {                               ## Add rownames
	$cmd .= ', row.names=' . r_var($self->get_rownames);
    } 
    $cmd .= ' )';                                              ## Close
    
    return $cmd;
}

=head2 _rowvectors_cmd

  Usage: my $cmds_aref = $rmatrix->_rowvectors_cmd();

  Desc: Build the command to add a list of vectors, parsing the matrix
        by rows 
 
  Ret: $cmds_aref, an array ref. with strings with the R command

  Args: None
        
  Side_Effects: Create as many vectors as rows has the matrix, with the
                row names as vector names. If the row names are numeric, 
                it will add an 'X' before the number (for example, 67 will
                be X67).

  Example: my @cmds = @{$rmatrix->_rowvectors_cmd()};
          
=cut 

sub _rowvectors_cmd {
    my $self = shift;

    my @cmds = ();

    my @rownames = @{$self->get_rownames()};
    foreach my $name (@rownames) {
	my @rowdata = $self->get_row($name);
	if ($name =~ m/^\d+$/) {
	    $name = 'X' . $name;
	}
	push @cmds, $name . ' <- ' .r_var(\@rowdata);
    }

    return \@cmds;
}


=head2 _colvectors_cmd

  Usage: my $cmds_aref = $rmatrix->_colvectors_cmd();

  Desc: Build the command to add a list of vectors, parsing the matrix
        by columns 
 
  Ret: $cmds_aref, an array ref. strings with the R command

  Args: None
        
  Side_Effects: Create as many vectors as cols has the matrix, with the
                col names as vector names. If the col names are numeric, 
                it will add an 'X' before the number (for example, 67 will
                be X67).

  Example: my @cmds = @{$rmatrix->_colvectors_cmd()};
          
=cut 

sub _colvectors_cmd {
    my $self = shift;

    my @cmds = ();

    my @colnames = @{$self->get_colnames()};
    foreach my $name (@colnames) {
	my @coldata = $self->get_column($name);
	if ($name =~ m/^\d+$/) {
	    $name = 'X' . $name;
	}
	push @cmds, $name . ' <- ' .r_var(\@coldata);
    }

    return \@cmds;
}


=head2 send_rbase

  Usage: $rmatrix->send_rbase($rbase, $block, $mode);

  Desc: Load the matrix data as a block in a rbase object (R::YapRI::Base)
        The R matrix name will the same than the perl matrix name.
        If block argument is used, it will add the command to this block.
        If block argument is undef or empty, it will create a new block with
        the argument name
 
  Ret: None

  Args: $rbase, a R::YapRI::Base object, 
        $block, block to create or add the data, an undef or empty value
                will create a new block with the matrix name.
        $mode, a scalar with the following possible values matrix, dataframe
               vectors_by_row and vectors_by_col (optional, matrix by default)
             
 
  Side_Effects: Die if no rbase object is used or if the argument used
                is not a R::YapRI::Base object

  Example: ## Default mode (R matrix in a new block with name=matrix_name)
              $rmatrix->send_rbase($rbase);

           ## Adding a matrix to BLOCK1
              $rmatrix->send_rbase($rbase, 'BLOCK1');

           ## Adding a data.frame to GRAPH1
              $rmatrix->send_rbase($rbase, 'GRAPH1', 'dataframe');

           ## Adding as vectors by row to a matrix name block 
              $rmatrix->send_rbase($rbase, '', 'vectors_by_row');
=cut

sub send_rbase {
    my $self = shift;
    my $rbase = shift ||
	croak("ERROR: No rbase argument was used for send_rbase function.");
    my $block = shift ||
	'';                              ## Default will be empty
    my $mode = shift ||
	'matrix';                        ## Matrix mode by default

    my %permmodes = (
	matrix         => '_matrix_cmd',
	dataframe      => '_dataframe_cmd',
	vectors_by_row => '_rowvectors_cmd', 
	vectosr_by_col => '_colvectors_cmd',
	);

    unless (exists $permmodes{$mode}) {
	my $l = join(',', keys %permmodes);
	croak("ERROR: $mode is an unknown mode ($l). Aborting send_rbase().");
    }

    ## Check that it is not using duplicate names

    $self->_no_duplicate_names();

    if (ref($rbase) ne 'R::YapRI::Base') {
	croak("ERROR: $rbase supplied to send_rbase() isnt R::YapRI::Base obj.");
    }

    ## Check if Block exist for rbase

    if ($block =~ m/./) {
	unless (defined $rbase->get_blocks($block)) {
	    croak("ERROR: $block isnt defined for $rbase. Aborting send_rbase");
	}
    }

    ## First get the data, and check if there are data

    my @data = @{$self->get_data()};

    unless (scalar(@data) > 0) {
	croak("ERROR: object $self doesnt have set any data to use rbase().")
    }

    ## Now it will build the R command to load a matrix

    my $mtx_name = $self->get_name;
    if ($mtx_name !~ m/\w+/) {
	croak("ERROR: Matrix=$self doesnt have any name to pass to R block");
    }
    
    ## It will create the block with the matrix name

    if ($block !~ m/./) {
	$rbase->create_block($self->get_name());
	$block = $self->get_name();
    }

    ## depending of the mode it will use different functions

    my $cmdfunc = $permmodes{$mode};
    my $cmd = $self->$cmdfunc();
    if (ref($cmd)) {                       ## For vectors_by_row and col.
	foreach my $subcmd (@{$cmd}) {
	    $rbase->add_command($subcmd, $block);
	}
    }
    else {                                 ## For matrix and dataframe.
	 $rbase->add_command($cmd, $block);
    }
}

=head2 read_rbase

  Usage: my $rmatrix = R::YapRI::Data::Matrix->read_rbase( $rbase, 
                                                        $block, 
                                                        $r_object_name);

  Desc: Create a new block with some R functions to get the data from the
        matrix. Combine it with the base block, run it and get the resultsfile.
        Parse the resultfile and get the data from it, loading it in a new
        matrix object. 
 
  Ret: A new matrix object (R::YapRI::Data::Matrix)

  Args: $rbase, a R::YapRI::Base object, 
        $block, a scalar with the name of the block that contains the R object
                to be read
        $r_object_name, name of the r_object to read
        
  Side_Effects: Die if no rbase object, block name or r_object_name is used.
                Die if rbase objects isnt a R::YapRI::Base object
                Die if block doesnt exist in the R::YapRI::Base object
                Die if the r_object_name doesnt exist in the R block used
                Die if the r_object_name isnt a matrix object.

  Example:  my $rmatrix = R::YapRI::Data::Matrix->read_rbase( $rbase, 
                                                           'BLOCK1', 
                                                           'mymatrix');
          
=cut

sub read_rbase {
    my $class = shift;
    my $rbase = shift ||
	croak("ERROR: No rbase object was supplied to read_rbase() function");
    my $block = shift ||
	croak("ERROR: No block name was supplied to read_rbase() function");
    my $r_obj = shift ||
	croak("ERROR: No r_object was supplied to read_rbase() function");

    ## Check object identity

    if (ref($rbase) ne 'R::YapRI::Base') {
    croak("ERROR: $rbase object supplied to read_rbase() isnt R::YapRI::Base");
    }

    ## Check that exists the block used

    unless (defined $rbase->get_blocks($block)) {
	croak("ERROR: Block=$block doesnt exist for $rbase object.");
    }

    ## First, check if exist the r_object

    my $rclass = $rbase->r_object_class($block, $r_obj);
    unless (defined $rclass) {
	croak("ERROR: $r_obj isnt defined for R block=$block.");
    }
    else {
	unless ($rclass =~ m/matrix/) {
	    croak("ERROR: $r_obj defined for block=$block isnt a r matrix obj");
	}
    }

    ## Second, build the command to catch the matrix object

    my %cmds = (
	1  => 'print("init_catch_matrix_' . $r_obj . '")',
	2  => 'print("init_rowcount")',
	3  => 'length(' . $r_obj . '[,1])',
	4  => 'print("end_rowcount")',
	5  => 'print("init_colcount")',
	6  => 'length(' . $r_obj . '[1,])',
	7  => 'print("end_colcount")',
	8  => 'print("init_rownames")',
	9  => 'rownames(' . $r_obj . ')',
	10 => 'print("end_rownames")',
	11 => 'print("init_colnames")',
	12 => 'colnames(' . $r_obj . ')',
	13 => 'print("end_colnames")',
	14 => 'print("init_matrix")',
	15 => 'c(t(' . $r_obj . '))',   ## R reads the matrix per col, so
	16 => 'print("end_matrix")',    ## it needs to transpose before read
	17 => 'print("end_catch_matrix_' . $r_obj . '")',
	);

    my $mblock = 'CATCH_MATRIX_' . $r_obj;
    $rbase->create_block($mblock, $block);
    foreach my $icmd (sort {$a <=> $b} keys %cmds) {
	$rbase->add_command($cmds{$icmd}, $mblock);
    }

    ## Run and get the result file

    $rbase->run_commands($mblock);
    my $rfile = $rbase->get_blocks($mblock)->get_result_file();

    ## Parse the result file and transfer the data to the perl vars.

    my $init = 0;

    my %parinit = (
	rownames => 0,
	colnames => 0,
	rowcount => 0,
	colcount => 0,
	matrix   => 0,
	);

    my %pardata = (
	rownames => [],
	colnames => [],
	rowcount => [],
	colcount => [],
	matrix   => [],
	);

    open my $rfh, '<', $rfile;
    while(<$rfh>) {
	chomp($_);
	if ($_ =~ m/"end_catch_matrix_$r_obj"/) {
	    $init = 0;
	}

	if ($init == 1) {
	   
	    ## Just remove [\d] at the beginning of each line and remove
	    ## extra spaces
	    $_ =~ s/^\s*\[\d+\]\s+//;
	    $_ =~ s/\s+/ /g;
	    
	    ## Check all the parser initiations for each class
	    foreach my $class_init (keys %parinit) {
		
		if ($_ =~ m/"end_$class_init"/) {
		    $parinit{$class_init} = 0;
		}
		if ($parinit{$class_init} == 1) {
		    
		    ## Also it will add an extra " for each " for words
		    $_ =~ s/"/""/g;
		    $_ =~ s/^\s*""/"/g;
		    $_ =~ s/""\s*$/"/g;

		    if ($_ !~ m/NULL/) {
			
			## Check if they are digits or words
			my @data = split(/"\s"/, $_);
			foreach my $data (@data) {

			    if ($data =~ m/^"(.+)"$/) {
				push @{$pardata{$class_init}}, $1;
			    }
			    else {
				my @subdata = split(/\s/, $data);
				push @{$pardata{$class_init}}, @subdata;
			    }
			} 
		    }
		}
		if ($_ =~ m/"init_$class_init"/) {
		    $parinit{$class_init} = 1;
		}
	    }
	}

	if ($_ =~ m/"init_catch_matrix_$r_obj"/) {
	    $init = 1;
	}
    }

    ## everything should be parsed, now it will create a new 
    ## R::YapRI::Data::Matrix object 
    
    my $matrix = $class->new({ 
	name     => $r_obj,
	rown     => $pardata{rowcount}->[0],
	coln     => $pardata{colcount}->[0],
	rownames => $pardata{rownames},
	colnames => $pardata{colnames},
	data     => $pardata{matrix},
			     });

    return $matrix;
}


=head1 ACKNOWLEDGEMENTS

Lukas Mueller

Robert Buels

Naama Menda

Jonathan "Duke" Leto

=head1 COPYRIGHT AND LICENCE

Copyright 2011 Boyce Thompson Institute for Plant Research

Copyright 2011 Sol Genomics Network (solgenomics.net)

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

=cut


####
1; #
####
