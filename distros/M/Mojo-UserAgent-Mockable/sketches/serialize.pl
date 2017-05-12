use 5.014;
use Mojo::UserAgent;
use Data::Serializer;
use DDP;
my $ua = Mojo::UserAgent->new;


my $serializer = Data::Serializer->new();

my ($req, $res);
my $start = $ua->on(
    start => sub {
        my ( $ua, $tx ) = @_;
        say 'TX is a ', ref $tx;
        $tx->on(
            #            connection => sub {
            #                my ( $tx, $connection ) = @_;
            #                my $stream = $ua->ioloop->stream($connection);
            #                warn 'No stream' and return unless $stream;
            #
            #                my $read = $stream->on(
            #                    read => sub {
            #                        my ( $stream, $chunk ) = @_;
            #                        $res .= $chunk;
            #                    }
            #                );
            #                my $write = $stream->on(
            #                    write => sub {
            #                        my ( $stream, $chunk ) = @_;
            #                        $req .= $chunk;
            #                    }
            #                );
            #                $tx->on(
            #                    finish => sub {
            #                        $stream->unsubscribe( read  => $read );
            #                        $stream->unsubscribe( write => $write );
            #                    }
            #                );
            #            },
            request => sub {
                my $tx = shift;
                $req = $serializer->serialize($tx->req);
                1;
            },
        );
    }
);
my $tx = $ua->post(
    'http://requestb.in/t87607t8' => {
        'X-Zaphod-Last-Name'                => 'Beeblebrox',
        'X-Benedict-Cumberbatch-Silly-Name' => 'Bumbershoot Crinklypants'
        } => form =>
        { foo => 'bar', quux => 'quuy', thefile => { file => q{/Users/kipeters/Documents/sample resume.docx} } }
);
$ua->unsubscribe(start => $start);

