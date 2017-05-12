package Prancer::Plugin::Database::Driver::Mock;

use strict;
use warnings FATAL => 'all';

use version;
our $VERSION = '1.04';

use Prancer::Plugin::Database::Driver;
use parent qw(Prancer::Plugin::Database::Driver);

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
        croak "could not initialize database connection '${\$self->{'_connection'}}': could not load DBD::Mock: ${error}";
    };

    my $database = $self->{'_database'};

    # if autocommit isn't configured then enable it by default
    my $autocommit = (defined($self->{'_autocommit'}) ? ($self->{'_autocommit'} =~ /^(1|true|yes)$/ix ? 1 : 0) : 1);

    my $dsn = "dbi:Mock:";

    my $params = {
        'AutoCommit' => $autocommit,
        'RaiseError' => 1,
        'PrintError' => 0,
    };

    # merge in any additional dsn_params
    $params = $self->_merge($params, $self->{'_dsn_extra'});

    $self->{'_dsn'} = [ $dsn, undef, undef, $params ];
    return $self;
}

1;
