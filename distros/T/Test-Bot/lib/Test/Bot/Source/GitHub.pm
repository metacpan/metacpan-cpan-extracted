package Test::Bot::Source::GitHub;

use Any::Moose 'Role';
with 'Test::Bot';
with 'Test::Bot::Source';

use AnyEvent;
use Twiggy::Server;
use Plack::Request;
use JSON;
use DateTime::Format::ISO8601;
use Test::Bot::Commit;
use Carp qw/croak/;

has '_http_server' => (
    is  => 'rw',
    isa => 'Twiggy::Server',
);

has 'port' => (
    is => 'rw',
    isa => 'Int',
    default => 4000,
);

# run a simple HTTP server listening for github post-commit pings
sub watch {
    my ($self) = @_;
    
    my $server = Twiggy::Server->new(
        port => $self->port,
    );

    my $app = sub {
        my $env = shift;
        my $req = Plack::Request->new($env);
        my $res = $req->new_response(200);

        $res->content_type('text/html; charset=utf-8');

        if ($req->path eq '/') {
            # index page
            $res->content("Yup, server sure is running!");
        } elsif ($req->path eq '/post_receive') {
            my $payload = $req->param('payload');
            if ($payload) {
                $self->parse_payload($payload);
            } else {
                $res->status(400);
                $res->content("invalid request");
            }
        } else {
            # unknown path
            $res->content("Unknown path " . $req->path);
            warn "test-github bot 404, path: " . $req->path . "\n";
            $res->code(404);
        }

        $res->finalize;
    };
    
    $server->register_service($app);
    $self->_http_server($server);

    print "Listening for post_receive hook on port " . $self->port . "\n";
}

# got a set of commits
sub parse_payload {
    my ($self, $payload) = @_;

    my $parsed = decode_json($payload) or return;

    my @commits;
    foreach my $commit_info (@{ $parsed->{commits} || []}) {
        # fields for our Test::Bot::Commit object
        my %c;

        # stringify author name
        my $author = $commit_info->{author} || {};
        my $name = $author->{name};
        my $email = $author->{email};
        if ($name) {
            $name .= " <$email>" if $email;
            $c{author} = $name;
        }

        # parse commit date
        my $timestamp = $commit_info->{timestamp};
        if ($timestamp) {
            my $dt = DateTime::Format::ISO8601->parse_datetime($timestamp);
            $c{timestamp} = $dt if $dt;
        }

        $c{message} = $commit_info->{message} if $commit_info->{message};

        # find list of modified files
        my @files = ( map { @{ $commit_info->{$_} || [] } } qw/added removed modified/ );
        $c{files} = \@files;

        $c{id} = $commit_info->{id};

        my $commit = Test::Bot::Commit->new(%c);
        push @commits, $commit;
    }

    $self->test_and_notify(@commits);
}

sub install {
    my ($self) = @_;

    # add to repo post-receive hooks

}

1;
