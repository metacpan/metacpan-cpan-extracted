package Row::Test2;
use Parse::FixedRecord;
extends 'Parse::FixedRecord::Row';

column foo => width => 5;
pic ' | ';
column bar => width => 5;

1;
