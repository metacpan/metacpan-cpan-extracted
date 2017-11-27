use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use Test::More;
use t::scan::Util;

test(<<'TEST'); # NEKOKAK/DBIx-Class-StorageReadOnly-0.05/lib/DBIx/Class/StorageReadOnly/TT.pm
    package DBIx::Class::Storage::DBI;
    use tt (subs => [qw/insert update delete/]);
    [% FOR sub IN subs %]
    {
        no warnings 'redefine';
        no strict 'refs'; ## no critic
        my $[%- sub -%]_code_org = DBIx::Class::Storage::DBI->can('[%- sub -%]');
        *{"DBIx\::Class\::Storage\::DBI\::[%- sub -%]"} = sub {
            my $self = shift;
            if ($self->_search_readonly_info) {
                croak("This connection is read only. Can't [%- sub -%].");
            }
            return $self->$[%- sub -%]_code_org(@_);
        };
    }
    [% END %]
    no tt;
TEST

done_testing;
