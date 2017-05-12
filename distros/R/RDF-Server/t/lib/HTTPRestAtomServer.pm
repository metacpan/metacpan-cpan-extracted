package HTTPRestAtomServer;

use RDF::Server;

protocol 'HTTP';
interface 'REST';
semantic 'Atom';

render xml => 'Atom';
render rdf => 'RDF';

if( not not eval "require JSON::Any" ) {
    render 'json' => 'JSON';
}

use LWP::UserAgent;
use Log::Log4perl qw(:easy);

Log::Log4perl -> easy_init($INFO);

###
# for testing
###

sub fork_and_return_ua {
    my($class, %options) = @_;

    my $PORT = $options{port} || 2080;

    my $pid = fork;
    die "Unable to fork: $!" unless defined $pid;

    END {
        if ($pid) {
            kill 2, $pid or warn "Unable to kill $pid: $!";
        }
    }

    ######################################################################
    if($pid) {                      # we are the parent
        print STDERR "$$: Sleep 2...";
        sleep 2;
        print STDERR " continue\n";

        my $UA = LWP::UserAgent -> new;
        return $UA;
    }
    ######################################################################
    else {                          # we are the child
        my $prog = $0; $prog =~ s{[^A-Za-z0-9]}{-}g;
        my $errorlog = File::Spec->rel2abs("tmp/$prog.errors");
        my $pidfile = File::Spec->rel2abs("tmp/$prog.pid");

        my $daemon = $class->create_server(errorlog => $errorlog, pidfile => $pidfile, port => $PORT, %options);

        $daemon -> start;
    }
}

sub create_server {
    my($class,%options) = @_;

    my $daemon = $class -> new(
        public_uri_base => 'http://example.org/',
        foreground => 1,
        loglevel => 7,
        %options
    );
}


1;
