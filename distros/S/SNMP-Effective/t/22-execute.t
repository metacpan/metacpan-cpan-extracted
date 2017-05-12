use warnings;
use strict;
use lib qw(lib);
use Test::More;
use SNMP::Effective;

plan skip_all => 'not yet written';

__END__

my $effective = SNMP::Effective->new;

    dispatch()
    _set()
    _get()
    _getnext()
    _end()
    _walk()

{

    is($effective->execute, 0, 'execute() == 0 because of no targets');

    # master_timeout + timeout
    is($effective->execute, 0, 'execute() == 0 because of no targets');

    # master_timeout
    is($effective->execute, 0, 'execute() == 0 because of no targets');

    # withou master_timeout
    is($effective->execute, 0, 'execute() == 0 because of no targets');

}

