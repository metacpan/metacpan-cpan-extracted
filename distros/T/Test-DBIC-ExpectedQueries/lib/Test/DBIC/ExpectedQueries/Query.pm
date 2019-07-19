package Test::DBIC::ExpectedQueries::Query;
$Test::DBIC::ExpectedQueries::Query::VERSION = '2.000';
use Moo;



has sql         => ( is => "ro", required => 1 );
has stack_trace => ( is => "ro", required => 1 ); # Just a string
has table       => ( is => "rw" );
has operation   => ( is => "rw" );

sub BUILD { shift->analyze_sql() }

sub analyze_sql {
    my $self = shift;
    my $sql = $self->sql;

    my $table = qr/
        [^\w.]*     # optional quote
        ([\w.]+)  # capture table
    /x;

    if($sql =~ /^ \s* insert\s+ into \s+ $table /ixsm) {
        $self->table($1);
        $self->operation("insert");
    }
    elsif($sql =~ /^ \s* update\s+ $table /ixsm) {
        $self->table($1);
        $self->operation("update");
    }
    elsif($sql =~ /^ \s* delete\s+ from \s+ $table /ixsm) {
        $self->table($1);
        $self->operation("delete");
    }
    elsif($sql =~ /^ \s* select\s+ .+? \s? from \s+ $table /ixsm) {
        $self->table($1);
        $self->operation("select");
    }

    return $self;
}

sub display_sql {
    my $self = shift;
    return "SQL: (" . $self->sql . ")";
}

sub display_stack_trace {
    my $self = shift;
    return "     " . $self->stack_trace;
}

1;
