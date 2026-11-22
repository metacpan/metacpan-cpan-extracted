package Mogura::Scanner::Client;
use Mojo::Base -base;
use Mojo::UserAgent;
use Mojo::Asset::File;
use Digest::SHA;
use Fcntl qw(O_RDONLY O_NOFOLLOW);
use IO::Socket::SSL 2.009;

has 'config';
has ua => sub {
    Mojo::UserAgent->new->insecure(0)
        ->max_redirects(0)
        ->connect_timeout(10)
        ->inactivity_timeout(30)
        ->max_response_size(262144);
};

sub initialize {
    my ($self) = @_;
    sysopen my $fh, $self->config->token_file, O_RDONLY | O_NOFOLLOW or die "Open token file: $!";
    my @st = stat $fh;
    die 'Token file must be private and owned by the scanner user'
        unless -f $fh && $st[4] == $> && !($st[2] & 0077) && $st[7] <= 65;
    my $token = <$fh> // '';
    chomp $token;
    die 'Invalid token file' unless $token =~ /\A[a-f0-9]{64}\z/;
    $self->{token} = $token;
    return $self;
}

sub request {
    my ($self, $method, $route, $data, $file) = @_;
    my $tx = $self->ua->build_tx(
        $method => $self->config->server . '/api'
            . $route => {Authorization => 'Bearer ' . $self->{token}},
        (defined $data ? (json => $data) : ())
    );
    if (defined $file) {
        open my $fh, '<:raw', $file or die "Open artifact: $!";
        $tx->req->headers->header(
            'X-Content-SHA256' => Digest::SHA->new(256)->addfile($fh)->hexdigest);
        $tx->req->headers->content_type('application/octet-stream');
        $tx->req->content->asset(Mojo::Asset::File->new(path => "$file"));
    }
    my $res =
        $self->ua->request_timeout(defined($file) ? $self->config->upload_timeout : 15)
        ->start($tx)
        ->result;
    return {expired => 1} if $res->code == 410 && $route =~ m{/claim\z};
    die "Server $method $route: HTTP " . $res->code . "\n" unless $res->is_success;
    my $reply = $res->json;
    die "Invalid server acknowledgement for $route" unless ref($reply) eq 'HASH';
    if ($route =~ m{\A/jobs/([^/]+)/([^/]+)/(.+)\z}) {
        my ($id, $run, $action) = ($1, $2, $3);
        die 'Wrong execution acknowledgement'
            unless ($reply->{id} // '') eq $id && ($reply->{run} // '') eq $run;
        if (defined $file) {
            die 'Wrong artifact receipt'
                unless $action eq 'files/' . ($reply->{kind} // '')
                && ($reply->{sha256} // '') eq $tx->req->headers->header('X-Content-SHA256');
        }
        elsif ($action ne 'claim') {
            die 'Wrong state acknowledgement' unless ($reply->{action} // '') eq $action;
        }
    }
    return $reply;
}
1;
