
# purpose: tests Mnet::Report::Table errors

# required modules
use warnings;
use strict;
use Mnet::Report::Table;
use Test::More tests => 11;



#
# check for Mnet::Report::Table->new errors
#

# subroutine to catch Mnet::Report::Table->new opts errors
#   some systems return 'error at ... line x' and some with a dot at end
sub new_errors {
    my $opts = shift;
    eval { Mnet::Report::Table->new($opts) };
    my $error = $@ // return "";
    $error =~ s/ at \S+ line \d+\.?$//;
    return "\n$error";
}

# missing opts column key
Test::More::is(new_errors({ table => "x" }), '
missing opts input columns key
', 'new method missing opts column key');

# invalid opts column key
Test::More::is(new_errors({ table => "x", columns => {} }), '
invalid opts input columns key
', 'new method invalid opts column key');

# invalid opts column data
Test::More::is(new_errors({ table => "x", columns => [] }), '
missing opts input column data
', 'new method missing opts column data');

# missing opts column name
Test::More::is(new_errors({ table => "x", columns => [ undef ] }), '
missing column name
', 'new method missing column name');

# missing opts column type
Test::More::is(new_errors({ table => "x", columns => [ a => "string", "foo" ] }), '
missing column type
', 'new method missing column type');

# missing opts column type
Test::More::is(new_errors({ table => "x", columns => [ a => "foo" ] }), '
column type foo is invalid
', 'new method invalid column name');

# missing opts column type
Test::More::is(new_errors({ table => "x", columns => [ a => "string" ], output => "foo" }), '
DIE - Mnet::Report::Table invalid output option foo
', 'new method invalid output type');



#
# check for Mnet::Report::Table->row errors
#

# subroutine to catch Mnet::Report::Table->row errors
#   some systems return 'error at ... line x' and some with a dot at end
sub row_errors {
    my $data = shift;
    eval {
        my $table = Mnet::Report::Table->new({
            table => "table",
            columns => [ error => "error", time => "time", int => "integer" ],
        });
        $table->row($data);
    };
    my $error = $@ // return "";
    $error =~ s/ at \S+ line \d+\.?$//;
    return "\n$error";
}

# missing row data arg
Test::More::is(row_errors(), '
missing data arg
', 'row method missing data arg');

# invalid error column
Test::More::is(row_errors({ error => "error" }), '
invalid error column error
', 'row method invalid error column');

# invalid time column
Test::More::is(row_errors({ time => "time" }), '
invalid time column time
', 'row method invalid time column');

# invalid integer column
Test::More::is(row_errors({ int => "1.0" }), '
invalid integer column int value "1.0"
', 'row method invalid integer column');



# finished
exit;

