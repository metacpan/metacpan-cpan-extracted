use Test::More;
use FindBin;

use Parser::FIT;

my $callbackGotCalled = 0;

my $parser;
$parser = Parser::FIT->new(
    on => {
        record => sub {
            my $msg = shift;
            is("HASH", ref $msg, "messages are hash refs");

            ok(exists $msg->{timestamp}, "message has a timestamp field");
            my $timestampField = $msg->{timestamp};

            ok(exists $timestampField->{fieldDescriptor}, "timestamp field has a fieldDescriptor");
            ok(exists $timestampField->{value}, "timestamp field has a value");
            ok(exists $timestampField->{rawValue}, "timestamp field has a rawValue");

            is(1587412580, $timestampField->{value}, "contains the expected post processed value");
            is(956346980, $timestampField->{rawValue}, "contains the expected raw value");

            my $fieldDescriptor = $timestampField->{fieldDescriptor};

            ok(exists $fieldDescriptor->{id}, "fieldDescriptor has an id");
            ok(exists $fieldDescriptor->{name}, "fieldDescriptor has a name");
            ok(exists $fieldDescriptor->{unit}, "fieldDescriptor has an unit");
            ok(exists $fieldDescriptor->{scale}, "fieldDescriptor has a scale");
            ok(exists $fieldDescriptor->{offset}, "fieldDescriptor has an offset");

            # ignore upcoming records.
            $parser->on("record", 0);

            $callbackGotCalled = 1;
        }
    }
);

my $testFile = $FindBin::Bin . "/test-files/activity_multisport.fit";
my $result = $parser->parse($testFile);

ok($callbackGotCalled, "the record callback got called");

done_testing;