# lib.pl
# Utility functions for the test suite.

use strict;
use SQL::Interpolate qw(:all);
use SQL::Interpolate::Macro qw(sql_flatten);
use Data::Dumper;

#our $fake_mysql_dbh =
#    bless {Driver => {Name => 'mysql'}}, 'DBI::db';

# Return normalized string representation of SQL interpolation list.
sub sql_str
{
    my(@parts) = @_;

    @parts = sql_flatten @parts;

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
    is_deeply(@_) or print STDERR Dumper(@_);
}

1
