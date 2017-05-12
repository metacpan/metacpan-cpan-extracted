use TAP::Stream;
use Test::Most;

#subtest 'foo' => sub {
#    pass 'foo 1';
#    pass 'foo 2';
#};
#subtest 'bar' => sub {
#    pass 'bar 1';
#    pass 'bar 2';
#    pass 'bar 3';
#};

my $stream = TAP::Stream->new;
$stream->add_to_stream(
    TAP::Stream::Text->new(
        name => 'foo tests',
        text => <<'END' )
ok 1 - foo 1
ok 2 - foo 2
1..2
END
);
$stream->add_to_stream(
    TAP::Stream::Text->new(
        name => 'bar tests',
        text => <<'END' )
ok 1 - bar 1
ok 2 - bar 2
    ok 1 - bar subtest 1
    ok 2 - bar subtest 2
    not ok 2 - bar subtest 3 #TODO ignore
ok 3 - bar subtest
ok 4 - bar 4
1..4
END
);

my $parent_stream = TAP::Stream->new( name => 'parent stream' );
$parent_stream->add_to_stream($stream);
$parent_stream->add_to_stream($stream); # yes, you can add it twice
my $master_stream = TAP::Stream->new( name => 'master stream' );
$master_stream->add_to_stream($parent_stream);

pass 'checking';
explain $master_stream->to_string;

done_testing;

__END__
    ok 1 - foo 1
    ok 2 - foo 2
    1..2
ok 1 - foo
    ok 1 - bar 1
    ok 2 - bar 2
    ok 3 - bar 3
    1..3
ok 2 - bar
1..2
ok
