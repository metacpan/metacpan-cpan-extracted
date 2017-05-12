use strict;
use warnings;
use Test::More;
use Test::Exception;
use String::Incremental;

sub new {
    my $str = String::Incremental->new( @_ );
    return $str;
}

tie my $str, 'String::Incremental', ( format =>'%=%=', orders => [ 'abc', '123' ] );
ok tied $str;
isa_ok $str, 'String::Incremental';

subtest 'properties' => sub {
    is $str->format, '%s%s';
    is scalar( @{$str->items} ), 2;
    isa_ok $str->items->[0], 'String::Incremental::Char';
    isa_ok $str->items->[1], 'String::Incremental::Char';
    is scalar( @{$str->chars} ), 2;
    for ( @{$str->chars} ) {
        isa_ok $_, 'String::Incremental::Char';
    }
};

done_testing;
