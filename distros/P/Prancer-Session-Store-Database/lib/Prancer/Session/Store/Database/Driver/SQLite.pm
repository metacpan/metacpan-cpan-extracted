package Prancer::Session::Store::Database::Driver::SQLite;

use strict;
use warnings FATAL => 'all';

use version;
our $VERSION = '1.01';

use Prancer::Session::Store::Database::Driver;
use parent qw(Prancer::Session::Store::Database::Driver);

use Try::Tiny;
use Carp;

# even though this *should* work automatically, it was not
our @CARP_NOT = qw(Prancer Try::Tiny);

sub new {
    my $class = shift;
    my $self = bless($class->SUPER::new(@_), $class);

    try {
        require DBD::SQLite;
    } catch {
        my $error = (defined($_) ? $_ : "unknown");
        croak "could not initialize session handler: could not load DBD::SQLite: ${error}";
    };

    my $database  = $self->{'_database'};
    my $charset   = $self->{'_charset'};
    my $table     = $self->{'_table'};

    my $dsn = "dbi:SQLite:dbname=${database}";

    my $params = {
        'AutoCommit' => 0,
        'RaiseError' => 1,
        'PrintError' => 0,
    };
    if ($charset && $charset =~ /^utf8$/xi) {
        $params->{'sqlite_unicode'} = 1;
    }

    # merge in any additional dsn_params
    $params = $self->_merge($params, $self->{'_dsn_extra'});

    $self->{'_dsn'} = [ $dsn, undef, undef, $params ];
    return $self;
}

1;
