# lib.pl
# Utility functions for the test suite.

use strict;
use SQL::Interp qw(:all);
use Data::Dumper;
use Carp;

#our $fake_mysql_dbh =
#    bless {Driver => {Name => 'mysql'}}, 'DBI::db';

# Return normalized string representation of SQL interpolation list.
sub sql_str
{
    my(@parts) = @_;

    my $out = Dumper(\@parts);

    # normalize
    $out =~ s/\s+/ /gs;
    $out =~ s/^.*?=\s*//;
    $out =~ s/;.*?$//;
    return $out;
}

# modified version of is_deeply
sub my_deeply
{
    # prevent warning "Argument \"...\" isn't numeric in numeric eq (==)"
    # caused by some problem in old versions of Test::More.
    local $SIG{__WARN__} = sub {
        warn $_[0] if $_[0] !~ /isn't numeric in numeric eq/;
    };
    is_deeply(@_) or carp Dumper(@_);
}

1
