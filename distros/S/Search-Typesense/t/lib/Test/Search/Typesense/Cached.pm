package Test::Search::Typesense::Cached;

use Moo;
use Test::Most ();
use Mojo::File;
use Digest::MD5 qw(md5_hex);
use Mojo::UserAgent::Mockable;
use FindBin;
use Search::Typesense::Types qw(
  InstanceOf
);

extends 'Search::Typesense';

has '+_ua' => (
    is  => 'rw',
    isa => InstanceOf ['Mojo::UserAgent'],
);

sub BUILD {
    my $self = shift;
    my @tdir = ( $FindBin::Bin, '..', 't' );
    my @host = (
        $self->_make_slug( $self->host ),
        $self->_make_slug( $self->port )
    );

    # where we cache our Typesense results
    my $cache = Mojo::File->new( @tdir, 'cache', 'data', @host )->make_path;

    # checksums of our test files. If the md5 sum of the file contents is
    # different, we know we can't rely on the cached results
    my $checksum
      = Mojo::File->new( @tdir, 'cache', 'checksums', @host )->make_path;

    my $test_program = Mojo::File->new($0);
    $cache    = $cache->child( $test_program->basename('.t') );
    $checksum = $checksum->child( $test_program->basename('.t') );

    # checksum of the actual test file
    my $current_checksum = md5_hex( $test_program->slurp );
    my $ua   = $self->_get_user_agent( $cache, $checksum, $current_checksum );
    my $mode = $ua->can('mode') ? $ua->mode : '';

    my $url = $self->_url( [] );
    if ( 'record' eq $mode ) {
        $checksum->spurt($current_checksum);
        Test::Most::explain(
            "\nRecording all traffic to and from $url. This will be cached in $cache.\n\n"
        );
    }
    elsif ( 'playback' eq $mode ) {
        Test::Most::explain(
            "\nPlaying back cached traffic to and from $url from $cache.\n\n"
        );
    }
    else {
        Test::Most::explain(
            "\nWe are neither recording traffic nor playing it back.\n\n");
    }
    if ( my $app = $ua->server->app ) {

        # if we don't include this, we get tons of extra log lines spit out to
        # STDERR when running tests. Note we test for the existence of the app
        # brecause record mode doesn't use an app
        $app->log->level('fatal');
    }

    my $key = $self->api_key;
    $ua->on(
        start => sub {
            my ( $ua, $tx ) = @_;
            $tx->req->headers->header( 'Content-Type' => 'application/json' )
              ->header( 'X-TYPESENSE-API-KEY' => $key );
        }
    );
    $self->_ua($ua);
}

sub _get_user_agent {
    my ( $self, $cache, $checksum, $current_checksum ) = @_;

    # if we have PERL_TEST_TYPESENSE_MODE, assume that's the correct behavior
    # for Mojo::UserAgent, regardless of cache existence.

    my $mode = 'record';
    if ( defined( my $override_mode = $ENV{PERL_TEST_TYPESENSE_MODE} ) ) {
        if ( 'devel' eq $override_mode ) {
            return Mojo::UserAgent->new;
        }
        elsif ( 'record' eq $override_mode || 'playback' eq $override_mode ) {
            $mode = $override_mode;
        }
        else {
            croak(
                "PERL_TEST_TYPESENSE_MODE set to unknown value: '$override_mode'"
            );
        }
    }

    # otherwise, we'll default to 'record' for the useragent mode, unless we
    # have a cache and the test checksum is unchanged. In that case, we'll
    # assume the mode is 'playback'
    elsif ( -e $cache && -s _ ) {

        # The cache exists and is not empty. We assume it's good (famous last
        # words)
        if ( -e $checksum ) {
            my $cached_checksum = $checksum->slurp;
            if ( $current_checksum eq $cached_checksum ) {
                $mode = 'playback';
            }
        }
    }

    return Mojo::UserAgent::Mockable->new( mode => $mode, file => $cache );
}

sub _make_slug {
    my ( $self, $name ) = @_;
    $name = lc($name);
    $name =~ s/^\s+|\s+$//g;
    $name =~ s/\s+/_/g;
    $name =~ tr/-/_/;
    $name =~ s/__*/_/g;
    $name =~ s/\W//g;
    $name =~ tr/_/-/;
    $name =~ s/--/-/g;
    return $name;
}

1;
__END__

=head1 NAME

Test::Search::Typesense::Cached - Cache Typesense responses per test file

=head1 SYNOPSIS

    my $test       = Test::Search::Typesense->new;
    my $typesense  = $test->typesense;  # this is cached
    $typesense->collection->delete_all;

You don't instantiate this directly. Instead, you call
C<< Test::Search::Typesense->new >> and use the C<< ->typesense >> method
to fetch an instance of this module.

=head1 BEHAVIOR

This will behave just like L<Search::Typesense>, except that when you run
tests, you I<probably> don't need a Typesense server running any more.
Instead, the tests will playback responses cached in C<t/cache/data>. You
shouldn't have to worry about this.

If you're developing, you probably want to set the C<PERL_TEST_TYPESENSE_MODE>
environment variable to C<devel>:

    PERL_TEST_TYPESENSE_MODE=devel prove -lv t

That will stop all caching or playback of cached output.

To force recording output, use C<record>:

    PERL_TEST_TYPESENSE_MODE=record prove -lv t

To force reading playback (probably not a great idea):

    PERL_TEST_TYPESENSE_MODE=playback prove -lv t
