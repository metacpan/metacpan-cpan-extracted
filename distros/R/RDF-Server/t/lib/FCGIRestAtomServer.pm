package FCGIRestAtomServer;

use RDF::Server;

protocol 'FCGI';
interface 'REST';
semantic 'Atom';

render xml => 'Atom';
render rdf => 'RDF';

if( not not eval "require JSON::Any" ) {
    render 'json' => 'JSON';
}


use LWP::UserAgent;
use Log::Log4perl qw(:easy);
use t::lib::utils;

Log::Log4perl -> easy_init($INFO);

###
# for testing
###

my($prog, $errorlog, $pidfile, $pid);
BEGIN {
$prog = $0; $prog =~ s{[^A-Za-z0-9]}{-}g;
$errorlog = File::Spec->rel2abs("tmp/$prog.errors");
$pidfile = File::Spec->rel2abs("tmp/$prog.pid");
}


BEGIN {
my $fh = Path::Class::File->new($errorlog)->open('a+');
sub log_pid {
    my($msg) = @_;
    $fh -> say("$$ $msg") if $fh;
}
}


sub fork_and_return_ua {
    my($class, %options) = @_;

    die "Unable to find lighttpd" unless utils::find_lighttpd();

    my $SOCKET = $options{socket} || '/tmp/fcgi_rest_atom.socket';

    my $prev_pid = $$;
    $pid = fork;
    die "Unable to fork: $!" unless defined $pid;

    END {
        if ($pid) {
            utils::stop_lighttpd();

            kill 2, $pid or warn "Unable to kill $pid: $!";
            sleep 2;
            if( -e $pidfile ) {
                my $p = Path::Class::File->new($pidfile)->slurp(chomp=>1);
                kill 9, $p or warn "Unable to kill $p: $!";
            }
        }
    }


    ######################################################################
    if($pid) {                      # we are the parent
        print STDERR "$$: Sleep 2...";
        sleep 2;
        print STDERR " continue\n";

        utils::start_lighttpd('t/lighttpd_confs/fcgi_rest_atom.conf');

        if( -e $SOCKET ) {
            return LWP::UserAgent -> new;
        }
        else {
            return;
        }
    }
    ######################################################################
    else {                          # we are the child
        #my $prog = $0; $prog =~ s{[^A-Za-z0-9]}{-}g;
        #my $errorlog = File::Spec->rel2abs("tmp/$prog.errors");
        #my $pidfile = File::Spec->rel2abs("tmp/$prog.pid");

        my $daemon = $class->create_server(errorlog => $errorlog, pidfile => $pidfile, socket => $SOCKET, %options);

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
    return $daemon;
}


1;
