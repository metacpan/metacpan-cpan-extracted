
package SQL::Admin::Driver::Base::DBI;

use strict;
use warnings;

our $VERSION = v0.5.0;

######################################################################

use DBI;
use SQL::Abstract;

my $sqla;

######################################################################
######################################################################
sub new {                                # ;
    my $class = shift;
    bless { @_ }, ref $class || $class;
}


######################################################################
######################################################################
sub options {                            # ;
    (
        'dbdns=s',
        'dbusr=s',
        'dbpwd=s',
    );
}


######################################################################
######################################################################
sub sqla {                               # ;
    $sqla ||= SQL::Abstract->new;
}


######################################################################
######################################################################
sub dbh {                                # ;
    my $self = shift;
    $self->{dbh} || $self->connect;
}


######################################################################
######################################################################
sub execute {                            # ;
    my ($self, $sql, @bind) = @_;

    my $sth = $self->dbh->prepare ($sql);
    $sth->execute (@bind);

    $sth;
}


######################################################################
######################################################################
sub connect {                            # ;
    my ($self, $dsn, $user, $password) = @_;

    $self->{dbh} ||= DBI->connect (
        $dsn      || $self->{dbdsn},
        $user     || $self->{dbusr},
        $password || $self->{dbpwd},
        { FetchHashKeyName => 'NAME_lc' },
    ) || die "Unable to connect: $DBI::errstr";
}


######################################################################
######################################################################
sub load {                               # ;
    my ($self, $catalog, @params) = @_;
    $self->connect || return;

    map $self->$_ ($catalog, @params),
      grep $self->can ($_), (
          'load_sequence',
          'load_table',
          'load_index',
          'load_table_column',
          'load_table_column_not_null',
          'load_table_column_default',
          'load_table_column_autoincrement',
          'load_constraint_primary_key',
          'load_constraint_unique',
          'load_constraint_foreign_key',
          'load_constraint_check',
#          'load_view',
#          'load_function',
#          'load_trigger',
#          'load_rule',
      );

    1;
}


######################################################################
######################################################################

package SQL::Admin::Driver::Base::DBI;

1;

