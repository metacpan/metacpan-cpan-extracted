use Test::More tests => 3;

BEGIN {
    use_ok('Rose::HTMLx::Form::Field::Serial');
}

diag(
    "Testing Rose::HTMLx::Form::Field::Serial $Rose::HTMLx::Form::Field::Serial::VERSION"
);

ok( my $serial = Rose::HTMLx::Form::Field::Serial->new, "new serial field" );
ok( $serial->isa('Rose::HTML::Form::Field::Hidden'), "isa Hidden" );
