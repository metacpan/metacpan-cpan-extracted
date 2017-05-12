package Prancer::Session::Store::Database::Driver::MySQL;

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
        require DBD::mysql;
    } catch {
        my $error = (defined($_) ? $_ : "unknown");
        croak "could not initialize session handler: could not load DBD::mysql: ${error}";
    };

    my $database  = $self->{'_database'};
    my $username  = $self->{'_username'};
    my $password  = $self->{'_password'};
    my $hostname  = $self->{'_hostname'};
    my $port      = $self->{'_port'};
    my $charset   = $self->{'_charset'};
    my $table     = $self->{'_table'};

    my $dsn = "dbi:mysql:dbname=${database}";
    $dsn .= ";host=${hostname}" if defined($hostname);
    $dsn .= ";port=${port}" if defined($port);

    my $params = {
        'AutoCommit' => 0,
        'RaiseError' => 1,
        'PrintError' => 0,
    };
    if ($charset && $charset =~ /^utf8$/xi) {
        $params->{'mysql_enable_utf8'} = 1;
    }

    # merge in any additional dsn_params
    $params = $self->_merge($params, $self->{'_dsn_extra'});

    $self->{'_dsn'} = [ $dsn, $username, $password, $params ];
    return $self;
}

1;
