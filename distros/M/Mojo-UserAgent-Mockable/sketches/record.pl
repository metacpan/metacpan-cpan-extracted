use 5.014;
use Mojo::UserAgent;
use Mojo::Message::Serializer;
use DDP;
my $ua = Mojo::UserAgent->new;


my $serializer = Mojo::Message::Serializer->new();
my ($req, $res);
my $start = $ua->on(
    start => sub {
        my ( $ua, $tx ) = @_;

        $req = $serializer->serialize($tx->req);
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

