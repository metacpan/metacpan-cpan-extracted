use Mojo::Base -strict;
use Test::More;
use Test::Exception;
use Mojo::Collection 'c';
use Mojo::Util 'dumper';

for my $method (qw(hashify_collect collect_by)) {
    note "Testing $method";

    lives_ok
        { c()->with_roles('+Transform')->$method(sub { $_ }) }
        'no options lives'
        ;

    lives_ok
        { c()->with_roles('+Transform')->$method({}, sub { $_ }) }
        'empty options lives'
        ;

    lives_ok
        { c()->with_roles('+Transform')->$method({flatten => 1}, sub { $_ }) }
        'flatten option with value 1 lives'
        ;

    lives_ok
        { c()->with_roles('+Transform')->$method({flatten => 0}, sub { $_ }) }
        'flatten option with value 0 lives'
        ;

    lives_ok
        { c()->with_roles('+Transform')->$method({flatten => undef}, sub { $_ }) }
        'flatten option with value undef lives'
        ;

    throws_ok
        { c()->with_roles('+Transform')->$method({flatten => 1, key => 'value'}, sub { $_ }) }
        qr/only one option can be provided/,
        'multiple options throws'
        ;

    note 'Test unknown options';
    my $unknown_option = {key => 'value'};
    my $dump = dumper $unknown_option;

    throws_ok
        { c()->with_roles('+Transform')->$method($unknown_option, sub { $_ }) }
        qr/unknown options provided: \Q$dump\E/,
        'unknown option throws'
        ;
}

done_testing;
