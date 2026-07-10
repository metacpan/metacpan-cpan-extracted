use strictures 2;

use Test::More;

use Net::Blossom::BlobDescriptor;
use Net::Blossom::Server::BlobResult;

my $HASH = 'b1674191a88ec5cdd733e4240a81803105dc412d6c6708d53ab94fc248f4f553';

sub dies(&) {
    my ($code) = @_;
    my $ok = eval { $code->(); 1 };
    return $ok ? undef : $@;
}

{
    package Local::ReadStream;
    use strictures 2;

    sub new {
        my ($class, $data) = @_;
        return bless { data => $data, offset => 0 }, $class;
    }

    sub read {
        my ($self, undef, $length) = @_;
        return 0 if $self->{offset} >= length $self->{data};
        $_[1] = substr($self->{data}, $self->{offset}, $length);
        $self->{offset} += length $_[1];
        return length $_[1];
    }
}

{
    package Local::NotStream;
    use strictures 2;

    sub new {
        my ($class) = @_;
        return bless {}, $class;
    }
}

sub descriptor {
    my (%args) = @_;
    my $body = exists $args{body} ? $args{body} : 'hello body';
    return Net::Blossom::BlobDescriptor->new(
        url      => "https://cdn.example.com/$HASH",
        sha256   => $HASH,
        size     => exists $args{size} ? $args{size} : length($body),
        type     => 'text/plain',
        uploaded => 1725105921,
    );
}

subtest 'constructs blob results for scalar and chunked bodies' => sub {
    my $body = 'hello body';
    my $descriptor = descriptor(body => $body);
    my $result = Net::Blossom::Server::BlobResult->new(
        descriptor => $descriptor,
        body       => $body,
    );

    isa_ok($result, 'Net::Blossom::Server::BlobResult');
    is($result->descriptor, $descriptor, 'descriptor');
    is($result->body, $body, 'scalar body');

    my $chunked = Net::Blossom::Server::BlobResult->new(
        descriptor => descriptor(size => 10),
        body       => ['hello', ' body'],
    );
    is_deeply($chunked->body, ['hello', ' body'], 'array body');

    my $empty = Net::Blossom::Server::BlobResult->new(
        descriptor => descriptor(size => 0),
        body       => '',
    );
    is($empty->body, '', 'empty scalar body accepted');
};

subtest 'constructs blob results for stream bodies' => sub {
    my $stream = Local::ReadStream->new('hello body');
    my $descriptor = descriptor(body => 'hello body');
    my $result = Net::Blossom::Server::BlobResult->new(
        descriptor => $descriptor,
        body       => $stream,
    );

    is($result->body, $stream, 'stream body');
};

subtest 'validates blob result inputs' => sub {
    like(dies { Net::Blossom::Server::BlobResult->new(body => 'body') },
        qr/descriptor is required/, 'descriptor required');
    like(dies { Net::Blossom::Server::BlobResult->new(descriptor => {}, body => 'body') },
        qr/descriptor must be a Net::Blossom::BlobDescriptor/, 'descriptor class required');
    like(dies { Net::Blossom::Server::BlobResult->new(descriptor => descriptor()) },
        qr/body is required/, 'body required');
    like(dies { Net::Blossom::Server::BlobResult->new(descriptor => descriptor(), body => {}) },
        qr/body must be a scalar, array reference, or stream object/, 'body type rejected');
    like(dies { Net::Blossom::Server::BlobResult->new(descriptor => descriptor(), body => [{}]) },
        qr/body array values must be scalars/, 'array body values rejected');
    like(dies { Net::Blossom::Server::BlobResult->new(descriptor => descriptor(), body => Local::NotStream->new) },
        qr/body must be a scalar, array reference, or stream object/, 'non-stream object rejected');
    like(dies { Net::Blossom::Server::BlobResult->new(descriptor => descriptor(size => 99), body => 'body') },
        qr/body length must match descriptor size/, 'scalar size mismatch rejected');
    like(dies { Net::Blossom::Server::BlobResult->new(descriptor => descriptor(size => 99), body => ['body']) },
        qr/body length must match descriptor size/, 'array size mismatch rejected');
    like(dies { Net::Blossom::Server::BlobResult->new(descriptor => descriptor(), body => 'hello body', bogus => 1) },
        qr/unknown argument\(s\): bogus/, 'unknown argument rejected');
};

done_testing;
