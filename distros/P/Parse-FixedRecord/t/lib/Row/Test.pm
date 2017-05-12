package Row::Test;
use Parse::FixedRecord;
extends 'Parse::FixedRecord::Row';

column first    => width => 4;
pic    ' ';
column middle   => width => 1;
pic    ' ';
column last     => width => 6;
pic    ' | ';
column date     => width => 10, isa =>'Date';
pic    ' | ';
column duration => width => 5, isa =>'Duration';

1;
