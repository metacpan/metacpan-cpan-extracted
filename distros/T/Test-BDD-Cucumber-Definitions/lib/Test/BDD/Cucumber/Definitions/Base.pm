package Test::BDD::Cucumber::Definitions::Base;

use strict;
use warnings;

use DBI;
use DDP ( show_unicode => 1 );
use Exporter qw(import);
use Test::BDD::Cucumber::Definitions qw(S :validator);
use Test::More;

our $VERSION = '0.41';

our @EXPORT_OK = qw(Base);

## no critic [Subroutines::RequireArgUnpacking]

sub Base {
    return __PACKAGE__;
}

sub param_set {
    my $self = shift;
    my ( $param, $value ) = validator_ns->(@_);

    S->{Base} = __PACKAGE__;

    S->{_Base}->{params}->{$param} = $value;

    return 1;
}

sub request_send {
    my $self = shift;
    my ($request) = validator_n->(@_);

    my $dsn = sprintf(
        'DBI:%s:database=%s;host=%s;port=%s',
        S->{_Base}->{params}->{driver}, S->{_Base}->{params}->{base},
        S->{_Base}->{params}->{host},   S->{_Base}->{params}->{port},
    );

    my $dbh
        = DBI->connect( $dsn, S->{_Base}->{params}->{user}, S->{_Base}->{params}->{password}, { PrintError => 0 } );

    if ( !ok( $dbh, 'Connection to the database was established' ) ) {
        diag("Connect failed: $DBI::err $DBI::errstr");
        diag( 'Params: ' . np S->{_Base}->{params} );
    }

    S->{_Base}->{response} = $dbh->selectall_arrayref( $request, { Slice => {} } );

    if ( !ok( S->{_Base}->{response}, 'Base request was sent' ) ) {
        diag("Request failed: $DBI::err $DBI::errstr");
        diag( 'SQL: ' . np $request );
    }

    return 1;
}

sub response {
    my $self = shift;

    return S->{_Base}->{response};
}

1;
