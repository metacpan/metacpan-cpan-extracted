package Spreadsheet::TieExcel;

our $VERSION = '0.75';
our $DEBUG = 1;

use strict;
use warnings;
no warnings qw(uninitialized);

use Carp;

use Win32::OLE;
$Win32::OLE::Warn = 3;

our $xl;

sub BEGIN {
    #============================================================
    # Check Excel is open and there is an active spreadsheet
    #============================================================
    $xl = Win32::OLE->GetActiveObject('Excel.Application') or
	croak "Couldn't find an active Excel application";

    $xl->Workbooks->Count or 
	croak "Couldn't find an active sheet";
}

sub getRange {
    my $range = shift;

    #============================================================
    # Returns an Excel range, whatever you pass to it
    #============================================================ 

    #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # No range? return current selection
    #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    unless ($range) {
	return $xl->Selection ||
	    croak "No valid Excel range";
    }

    #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # Got a range: let's check what it is
    #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    my ($row, $col, $sheet, $width, $height);

    for (ref $range) {
	#--------------------------------------------------
	# a proper range
	#--------------------------------------------------
	/^Win32::OLE$/ && do {
	    unless ((join '::', Win32::OLE->QueryObjectType($range)) eq 'Excel::Range') {
		croak "Doesn't look like a range";
	    } else {
		return $range;
	    }
	};
	#--------------------------------------------------
	# an array
	#--------------------------------------------------
	/^ARRAY$/ && do {
	    ($row, $col, $sheet) = @{$range};
	};
	#--------------------------------------------------
	# a hash
	#--------------------------------------------------
	/^HASH$/ && do {
	    $row = $range->{row} || $range->{start_row};
	    $col = $range->{column} ||
		$range->{col} ||
		$range->{start_col} ||
		$range->{start_column};

	    $width = $range->{width}; $width-- if $width;
	    $height = $range->{height}; $height-- if $height;
	    $sheet = $range->{sheet} || $range->{worksheet};
	};
	#--------------------------------------------------
	# a scalar
	#--------------------------------------------------
	/^$/ && do {
	    $row = $range;
	    ($col, $sheet) = @_;
	};
    }

    #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # a lot of checking
    #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    croak "Row '$row', column '$col' is not a valid address"
	if (($col <= 0) || ($row <= 0));
    
    my $ws;
    if ($sheet) {
	croak "Worksheet $sheet not found"
	    unless eval { $ws = $xl->ActiveWorkbook->Worksheets($sheet) };
    } else {
 	croak "No worksheet not found"
 	    unless eval { $ws = $xl->ActiveSheet };
    }

    return $ws->Range($ws->Cells($row, $col), $ws->Cells($row + $height, $col + $width));
}

sub getBook {
    my $xl = Win32::OLE->GetActiveObject('Excel.Application') or
	croak "Couldn't find an active Excel application";

    return $xl->ActiveWorkbook
	|| croak "No active workbook found";
}


{

package Spreadsheet::TieExcel::Array;

use strict;
use Carp;

use Spreadsheet::TieExcel;

sub TIEARRAY {
    my $class = shift;
    my $range = Spreadsheet::TieExcel::getRange(shift);

    return bless {
	SEL => $range
    }, $class;
}

sub STORE {
    my($self, $idx, $value) = @_;

    return $self->{SEL}->Cells($idx + 1)->{Value} = $value;
}

sub FETCH {
    my($self, $idx) = @_;
    return $self->{SEL}->Cells($idx + 1)->{Value};
}

sub FETCHSIZE {
    my($self) = @_;

    $self->{SEL}->Cells->Count
}

sub STORESIZE {
    carp "Can't resize Excel array";
}

1;

}



{

package Spreadsheet::TieExcel::File;;

use Carp;
use strict;

use Spreadsheet::TieExcel;

sub TIEHANDLE {
    my $class = shift;
    my $range = Spreadsheet::TieExcel::getRange(shift);

    return bless {
	rows => $range->Rows->Count,
	cols => $range->Columns->Count,
	start => $range->Row,
	rrow => 0, 
	frow => $range->Row,
	prow => $range->Row - 1,
	fcol => $range->Column,
	lcol => $range->Column + $range->Columns->Count - 1,
	sheet => $range->Worksheet
    }, $class
}

sub READLINE {
    my $self = shift;

    if ($self->{rrow} < $self->{rows}) {

	$self->{rrow}++;
	if ($self->{cols} > 1) {
	    return wantarray ? 
		@{$self->{sheet}->Range(
			     $self->{sheet}->Cells($self->{frow} + $self->{rrow} - 1, $self->{fcol}),
			     $self->{sheet}->Cells($self->{frow} + $self->{rrow} - 1, $self->{lcol}),
			     )->{Value}->[0]}
	    :
		$self->{sheet}->Range(
			   $self->{sheet}->Cells($self->{frow} + $self->{rrow} - 1, $self->{fcol}),
			   $self->{sheet}->Cells($self->{frow} + $self->{rrow} - 1, $self->{lcol}),
			   )->{Value}->[0];
	} else {
	    return $self->{sheet}->Cells($self->{frow} + $self->{rrow} - 1, $self->{fcol})->{Value};
	}
    } else {
	return;
    }
}

sub PRINT {
    my $self = shift;
    my $ro = $#_;

    $self->{prow}++;
    $self->{sheet}->Range(
	       $self->{sheet}->Cells($self->{prow}, $self->{fcol}),
	       $self->{sheet}->Cells($self->{prow}, $self->{fcol})->Offset(0, $ro),
	       )->{Value} = [@_];
}


sub DESTROY {
    my $self = shift;
    $self = undef;
    Win32::OLE->Uninitialize;
}

1;

}

{

package Spreadsheet::TieExcel::Scalar;

use Carp;
use strict;

use Spreadsheet::TieExcel;

sub TIESCALAR {
    my $class = shift;
    my $range = Spreadsheet::TieExcel::getRange(@_);
    return bless {
	range => $range,
	application => $range->Application,
	sheet => $range->Worksheet
    }, $class
}

sub FETCH {
    my $self = shift;

    return $self->{range}->{value};
}

sub STORE {
    my $self = shift;
    my $value = shift;

    return $self->{range}->{value} = $value;
}

sub DESTROY {
    my $self = shift;
    $self = undef;
    Win32::OLE->Uninitialize;
}

#######################################################################
# Experimental part
#######################################################################

use overload
    '>>' => sub { shift->move(0, shift) },
    '<<' => sub { shift->move(0, -shift) },
    '++' => sub { shift->move(1, 0) },
    '--' => sub { shift->move(-1, 0) },

    '+' => sub { shift->move(shift, 0) },
    '-' => sub { shift->move(-shift, 0) };

sub _tor_move {
    my ($row, $move, $max) = @_;
    return (((($row - 1) + $move) % $max) + 1);

}

sub move {
    my $self = shift;

    my ($row, $col);

    $row = &_tor_move ($self->{range}->Row, $_[0], $self->{range}->Worksheet->Rows->Count);
    $col = &_tor_move ($self->{range}->Column,  $_[1], $self->{range}->Worksheet->Columns->Count);

    $self->{range} = $self->{range}->Worksheet->Cells($row, $col);
}

sub set {
    my $self = shift;
    my $val = pop @_;
    eval '$self->{range}->{' . (join '}->{', @_) . '} = $val';
}

sub row {
    my $self = shift;
    if (my $row = shift) {
	$self->{sheet}->Cells($row, $self->column)->Select;
	$self->{range} = $self->{application}->Selection;
    } else {
	return $self->{range}->{row};
    }
}

sub column {
    my $self = shift;
    if (my $col = shift) {
	$self->{sheet}->Cells($self->row, $col)->Select;
	$self->{range} = $self->{application}->Selection;
    } else {
	return $self->{range}->{column};
    }
}

our $AUTOLOAD;

sub AUTOLOAD {
    my $self = shift;

    my $type = ref($self)
	or croak "$self is not an object";

    return if $AUTOLOAD =~ /::DESTROY$/;

    my $name = $AUTOLOAD;
    $name =~ s/(.+)::(.+)$/$2/;

    if (@_) {
	return $self->{range}->{$name} = $_[0];
    } else {
	return $self->{range}->{$name};
    }
}

1;

}

{

package Spreadsheet::TieExcel::Hash;

use strict;
use Carp;

use Spreadsheet::TieExcel;

sub TIEHASH {
    my $class = shift;

    my $wb = Spreadsheet::TieExcel::getBook;
    my $self = bless {
	book => $wb,
	list => {}
    }, $class;

    for (1..$self->{book}->Names->Count) {
	my $name = $self->{book}->Names($_)->Name;
	$self->{list}->{$name} = $self->{book}->Names($_)->RefersToRange;
    }
    return $self;
}

sub FETCH {
    my $self = shift;
    my $name = shift;
    if ($self->exists($name)) {
	return $self->names($name)->{Value};
    } else {
    }
}

sub STORE {
    my $self = shift;
    my ($name, $value) = @_;

    if ($self->exists($name)) {
	$self->names($name)->{Value} = $value;
    } else {
 	my $range = Spreadsheet::TieExcel::getRange($value);
	$self->add($name, $range);
    }
}

sub DELETE {
    my $self = shift;
    my $name = shift;
    return $self->delete($name);
}

sub CLEAR {
}

sub EXISTS {
    return shift->exists(shift);
}

sub FIRSTKEY {
    my $self = shift;

    $a = keys %{ $self->names };
    return each %{ $self->names }
}

sub NEXTKEY {
    my $self = shift;
    return each %{ $self->names }
}

sub exists {
    my $self = shift;
    my $name = shift;
    return $self->names->{$name}
}

sub length {
    return scalar keys %{ shift->names };
}

sub names {
    my $self = shift;
    my $name = shift;
    for (1..$self->{book}->Names->Count) {
	my $name = $self->{book}->Names($_)->Name;
	$self->{list}->{$name} = $self->{book}->Names($_)->RefersToRange;
	$self->{book}->Names($_)->RefersToRange;
    }
    return $name ? $self->{list}->{$name} : $self->{list};
}

sub delete {
    my $self = shift;
    my $name = shift;

    if ($self->exists($name)) {
	delete $self->names->{$name};
	return $self->{book}->Names($name)->Delete;
    }
}

sub add {
    my $self = shift;
    my ($name, $range, $value) = @_;

    my $address = $range->Address(1, 1, 1, 1);
    $address =~ /\](.+)/; $address = $1;
    if (eval { $self->{book}->Names->Add({Name => $name, RefersTo => "=$address"}) }) {
	$self->names->{$name} = $range;
    } else {
	carp "Could not add name referring to range $address";
    }

}

1

}
