use Test::More;
use strict;
use t::Foo;

my $foo = Regexp::Log::Foo->new();

ok( ref($foo) eq 'Regexp::Log::Foo', "It's a Regexp::Log::Foo" );

# check defaults
ok( $foo->format eq '%d %c %b', "Default format" );
my @capture = $foo->capture;
ok( @capture == 1, "Default capture" );
ok( $capture[0] eq 'c', "Default captured field" );
ok( $foo->comments == 0, "Default comments" );
ok( $foo->anchor_line ==  1, "Default anchor line");
ok( $foo->modifiers eq '', "Default modifiers" );

# check the anchor_line method
$foo = Regexp::Log::Foo->new( format => '%a' );
my $_xism = qr// =~ /^\(\?\^/ ? "^" : "-xism";
ok( $foo->regexp eq qq/(?$_xism\:^(?:\\d+)\$)/, "Ok for default anchors" );
ok( $foo->anchor_line(0) == 0, "Disabling anchors for line" );
ok( $foo->regexp eq qq/(?$_xism\:(?:\\d+))/ , "Ok for disabled anchors" );

# check modifiers
ok( $foo->modifiers('sim') eq q/sim/, "Ok to set modifiers" );
ok( $foo->regexp eq qq/(?$_xism\:(?sim:(?:\\d+)))/, "Modifiers configured" ); 

# check the format method
$foo = Regexp::Log::Foo->new();
ok( $foo->format('%a %b %c') eq '%a %b %c', "Format return new value" );
ok( $foo->format eq '%a %b %c', "new format value is set" );
my $r = $foo->regexp;

# check the format method with templates
$foo = Regexp::Log::Foo->new( format => ':default' );
is( $foo->regexp, $r, "Same regexp with ':default' and '%a %b %c'");

# check the fields method
my @fields = sort $foo->fields;
my $i      = 0;
for (qw(a b c cn cs d)) {
    ok( $fields[ $i++ ] eq $_, "Found field $_" );
}

# set the captures
@fields = $foo->capture(':none');
ok( @fields == 0, "Capture :none" );

@fields = sort $foo->capture(qw( b cs ));
ok( @fields == 2, "Capture only two fields" );
$i = 0;
for (qw( b cs )) {
    ok( $fields[ $i++ ] eq $_, "Field $_ is captured" );
}

$foo->format('%d %c %b');
@fields = sort $foo->capture(':all');
$i      = 0;
for (qw( b c cn cs d)) {
    ok( $fields[ $i++ ] eq $_, "Field $_ is captured by :all" );
}

# the comments method
ok( $foo->comments(1) == 1, "comments old value" );
ok( $foo->comments == 1, "comments new value" );

# the regexp method
ok( $foo->regex eq $foo->regexp, "regexp() is aliased to regex()" );

$foo->comments(0);
my $regexp = $foo->regexp;
ok( $regexp !~ /\(\?\#.*?\)/, "No comment in regexp" );
$foo->comments(1);

$foo->format('%d');
ok( @{ [ $foo->regexp =~ /(\(\?\#.*?\))/g ] } == 2,
    "2 comment for %d in regexp" );
$foo->format('%c');
ok( @{ [ $foo->regexp =~ /(\(\?\#.*?\))/g ] } == 6,
    "6 comments for %c in regexp" );
$foo->comments(0);

# test the regex on real log lines
@ARGV = ('t/foo1.log');
$foo->format("%a %b %c %d");
@fields = $foo->capture(":all");
$regexp = $foo->regexp;

my %data;
my @data = (
    {
        a  => 1,
        b  => 'this',
        c  => 'h4cker/31337',
        cs => 'h4cker',
        cn => 31337,
        d  => 'foo'
    },
    {
        a  => 2,
        b  => 'this',
        c  => 'cosmos/1999',
        cs => 'cosmos',
        cn => 1999,
        d  => 'foo'
    },
    {
        a  => 3,
        b  => 'that',
        c  => 'perec/11',
        cs => 'perec',
        cn => 11,
        d  => 'bar'
    },
    {
        a  => undef,
        b  => undef,
        c  => undef,
        cs => undef,
        cn => undef,
        d  => undef
    },
    {
        a  => 40,
        b  => 'this',
        c  => 'beast/666',
        cs => 'beast',
        cn => 666,
        d  => 'baz'
    },
);

$i = 0;
while (<>) {
    @data{@fields} = /$regexp/;
    is_deeply( \%data, $data[ $i++ ], "foo1.log line " . ( $i + 1 ) );
}

# check that metacharacters are correctly handled
@ARGV = ( 't/foo2.log' );
$foo->format('%a (%c) $ %d? [%b]');
@fields = $foo->capture(":all");
$regexp = $foo->regexp;

@data = (
    { a => 1, c => 'jay/123', cs => 'jay', cn => 123, d => 'foo', b => 'this' },
    {
        a  => 25,
        c  => 'garden/87',
        cs => 'garden',
        cn => 87,
        d  => 'bar',
        b  => 'that'
    }
);

$i = 0;
while (<>) {
    @data{@fields} = /$regexp/;
    is_deeply( \%data, $data[ $i++ ], "foo2.log line " . ( $i + 1 ) );
}

BEGIN { plan tests => 43 }
