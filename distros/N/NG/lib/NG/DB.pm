package NewBie::Gift::DB;
use warnings;
use strict;
use base 'Object';
use Hashtable;
use SQL::Abstract;
use DBI;

sub new {
    my $pkg     = shift;
    my $options = {@_};
    return bless {
        dsn  => $options->{dsn}      || 'DBI:mysql:database=test;host=dbhost',
        user => $options->{username} || 'root',
        pass => $options->{password} || ''
    }, $pkg;
}

sub dbh {
    my $self = shift;
    return ref($self->dbh) eq 'DBI' ? $self->dbh : DBI->connect($self->{dsn}, $self->{user}, $self->{pass});
}

sub disconnect {
    shift->dbh->disconnect;
}

=head2 select
Just use SQL::Abstract to generate SQL, so watch SQL::Abstract for options.
For example:
    my fields => ['col1', 'col2'],
    my $where  => {
        user => 'nwiger',
        priority => [
            { '=', 2 },
            { '>', 5 },
        ],
    },
    my $order  => ['col1', {-desc => 'col2'}]
    select $table, $fields, $where, $order, sub {
	    my ($row) = @_;
	    $row->each(sub{
	        my ($colname, $colvalue) = @_;
	    })
    }
=cut
sub select {
    my $self = shift;
    $self->query('select', @_);
}

sub insert {
    my $self = shift;
    $self->query('insert', @_);
}

sub update {
    my $self = shift;
    $self->query('update', @_);
}

sub delete {
    my $self = shift;
    $self->query('delete', @_);
}

sub query {
    my ($self, $operator, $table, @options) = @_;
    my $cb;
    if (lc($operator) eq 'select') {
        $cb = pop @options;
    }

    my $dbh = $self->dbh;
    my $sql = SQL::Abstract->new;
    my ( $stmt, @bind ) = eval $sql->$operator( $table, @options );
    my $sth = $dbh->prepare($stmt);
    my $rv  = $sth->execute(@bind);

    if (lc($operator) eq 'select') {
        while (my $ref = $sth->fetchrow_hashref()) { 
            $cb->( Hashtable->new(%$ref) );
        };
    };

    $sth->finish();
    return $rv;

}

1;
