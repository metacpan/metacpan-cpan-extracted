package Mock::Plasp;

use Class::MOP;
use Role::Tiny;
use Path::Tiny qw(path);
use FindBin qw($Bin);
use File::Temp;
use File::Slurp qw(write_file);
use Plack::Request;
use Plack::Util;
use Plasp;
use Plasp::Exception::End;

use parent 'Exporter';
our @EXPORT = qw(
    mock_logger
    mock_req
    mock_asp
    mock_global_asa
);

my %mock_asp;
my $mock_logger;
my $mock_global_asa;

my @log_entries = ();

sub mock_logger {
    $mock_logger //= Class::MOP::Class->create_anon_class(
        methods => {
            fatal => sub { push @log_entries, { level => 'fatal', message => $_[1] } },
            error => sub { push @log_entries, { level => 'error', message => $_[1] } },
            warn => sub { push @log_entries, { level => 'warn', message => $_[1] } },
            info => sub { push @log_entries, { level => 'info', message => $_[1] } },
            debug => sub { push @log_entries, { level => 'debug', message => $_[1] } },
            level   => sub {'debug'},
            entries => sub { \@log_entries },
        },
    )->new_object();
}

sub mock_req {
    my $type = $_[0] || 'get';

    my $body_fh = File::Temp->new( 'body-XXXXXX', DIR => '/tmp', UNLINK => 1 );
    my $uri     = URI->new( 'http://127.0.0.1/welcome.asp?foobar=baz' );
    my %env     = (
        SCRIPT_NAME           => $uri->path,
        PATH_INFO             => $uri->path,
        REQUEST_URI           => $uri->path_query,
        QUERY_STRING          => $uri->query,
        SERVER_NAME           => '127.0.0.1',
        SERVER_PORT           => '80',
        SERVER_PROTOCOL       => 'HTTP/1.1',
        HTTP_CONTENT_ENCODING => '',
        HTTP_COOKIE           => 'foo=bar; foofoo=baz%3Dbar&bar%3Dbaz',
        HTTP_DATE             => 'Mon, 14 Sep 2020 00:00:00 GMT',
        HTTP_REFERER          => 'https://127.0.0.1/index.asp',
        HTTP_USER_AGENT => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:80.0) Gecko/20100101 Firefox/80.0',
        'psgi.version'       => [ 1, 1 ],
        'psgi.url_scheme'    => $uri->scheme,
        'psgi.input'         => $body_fh,
        'psgi.errors'        => \*STDERR,
        'psgi.multithreaded' => Plack::Util::TRUE,
        'psgi.run_once'      => Plack::Util::FALSE,
        'psgi.non_blocking'  => Plack::Util::FALSE,
        'psgi.streaming'     => Plack::Util::TRUE,
        'psgix.logger' => sub { my ( $l, $m ) = @{ $_[0] }{qw(level message)}; mock_logger->$l( $m ) },
        'psgix.session' => { SessionID => '1234567890abcdef0987654321fedcba' },
        'psgix.session.options' => { id => '1234567890abcdef0987654321fedcba' },
        'psgix.harakiri'        => Plack::Util::TRUE,
        'psgix.harakiri.commit' => Plack::Util::FALSE,
        'psgix.cleanup'         => Plack::Util::FALSE,
    );

    my $content = '';
    if ( $type eq 'get' ) {
        $env{REQUEST_METHOD} = 'GET';
    } elsif ( $type eq 'post' ) {
        $env{REQUEST_METHOD} = 'POST';
        $env{CONTENT_TYPE}   = 'application/x-www-form-urlencoded',
            $content         = 'foo=bar&bar=foo&baz=foobar';
    } elsif ( $type eq 'upload' ) {
        $env{REQUEST_METHOD} = 'POST';
        $env{CONTENT_TYPE} = 'multipart/form-data; boundary="plasp:test:boundary"',
            $content       = <<EOF;
--plasp:test:boundary\r
Content-Disposition: form-data; name="foofile"; filename="foo.txt"\r
Content-Type: text/plain\r
\r
ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789\r
--plasp:test:boundary--\r
EOF
    }
    $env{CONTENT_LENGTH} = length( $content );
    $body_fh->print( $content );
    $body_fh->seek( 0, SEEK_SET );
    Plack::Request->new( \%env );
}

sub mock_asp {
    my ( %options ) = @_;
    my $create_new  = delete $options{create_new};
    my $type        = delete $options{type} || 'get';

    if ( $create_new || !$mock_asp{$type} ) {
        $mock_asp{$type} = Plasp->new(
            req           => mock_req( $type ),
            DocumentRoot  => path( __FILE__, '../../TestApp/root' )->realpath,
            IncludesDir   => path( __FILE__, '../../TestApp/root' )->realpath,
            GlobalPackage => 'TestApp::ASP',
            Debug         => 1,
            %options,
        );
    }

    $mock_asp{$type};
}

sub mock_global_asa {
    $mock_global_asa //= Class::MOP::Class->create_anon_class(
        methods => {
            exists         => sub {1},
            execute_event  => sub {'does nothing!'},
            package        => sub { mock_asp->GlobalPackage },
            Script_OnParse => sub {'Script_OnParse event!'},
        },
    )->new_object();
}

1;
