package Prancer::Session::Store::Database::Driver::Mock;

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
        require DBD::Mock;
    } catch {
        my $error = (defined($_) ? $_ : "unknown");
        croak "could not initialize session handler: could not load DBD::Mock: ${error}";
    };

    my $dsn = "dbi:Mock:";

    my $params = {
        'AutoCommit' => 0,
        'RaiseError' => 1,
        'PrintError' => 0,
    };

    # merge in any additional dsn_params
    $params = $self->_merge($params, $self->{'_dsn_extra'});

    $self->{'_dsn'} = [ $dsn, undef, undef, $params ];
    return $self;
}

1;
