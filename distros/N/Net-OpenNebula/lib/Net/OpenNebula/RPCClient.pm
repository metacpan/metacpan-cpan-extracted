use strict;
use warnings;

# packge the DummyLogger together with the RPCClient package
package Net::OpenNebula::DummyLogger; ## no critic
$Net::OpenNebula::DummyLogger::VERSION = '0.316.0';
sub new {
    my $that = shift;
    my $proto = ref($that) || $that;
    my $self = { @_ };

    bless($self, $proto);

    return $self;
}

# Mock basic methods of Log4Perl getLogger instance
no strict 'refs'; ## no critic
foreach my $i (qw(error warn info verbose debug)) {
    *{$i} = sub {}
}
use strict 'refs';


package Net::OpenNebula::RPCClient;
$Net::OpenNebula::RPCClient::VERSION = '0.316.0';

use RPC::XML;
use RPC::XML::Client;
use Data::Dumper;
use XML::Parser;

use version;

if(! defined($ENV{XML_SIMPLE_PREFERRED_PARSER})) {
    $ENV{XML_SIMPLE_PREFERRED_PARSER} = 'XML::Parser';
};

my $has_libxml;
eval "use XML::LibXML::Simple qw(XMLin);"; ## no critic (BuiltinFunctions::ProhibitStringyEval)
if ($@) {
    use XML::Simple qw(XMLin XMLout);
    $has_libxml = 0;
} else {
    use XML::Simple qw(XMLout);
    $has_libxml = 1;
};

use RPC::XML::ParserFactory (class => $has_libxml ? 'XML::LibXML' : 'XML::Parser');

# Caching
# data_cache
my $_cache = {};
my $_cache_methods = {};

# options
#    user: user to connect
#    password: password for user
#    url: the RPC url to use
#    log: optional log4perl-like instance
#    fail_on_rpc_fail: die on RPC error or not
#    useragent: options passed to LWP::UserAgent (via RPC::XML useragent option)
#    ca: CA file or dir, is passed as SSL_ca_file or SSL_ca_path via useragent
#        does not override useragent settings; enables verify_hostname
sub new {
    my $that = shift;
    my $proto = ref($that) || $that;
    my $self = { @_ };

    if (! exists($self->{log})) {
        $self->{log} = Net::OpenNebula::DummyLogger->new();
    }

    # legacy behaviour
    if (! exists($self->{fail_on_rpc_fail})) {
        $self->{fail_on_rpc_fail} = 1;
    }

    bless($self, $proto);

    $self->{log}->debug(2, "Initialised with user $self->{user} and url $self->{url}");
    $self->{log}->debug(2, ($has_libxml ? "U" : "Not u")."sing XML::LibXML(::Simple)");
    $self->{log}->debug(2, "Using preferred XML::Simple parser $ENV{XML_SIMPLE_PREFERRED_PARSER}.");

    # Cache and test rpc
    $self->version();

    return $self;
}

# Enable the caching of all methods calls (cache is per method/args combo)
sub add_cache_method {
    my ($self, $method) = @_;
    $_cache_methods->{$method} = 1;
}


# Remove the caching method and cache
sub remove_cache_method {
    my ($self, $method) = @_;
    $_cache_methods->{$method} = 0;
    $_cache->{$method} = {};
}


sub _rpc_args_to_txt {
    my ($self, @args) = @_;

    my @txt;
    foreach my $arg (@args) {
        push(@txt, join(", ", @$arg));
    };
    my $args_txt = join("], [", @txt);

    return "[$args_txt]";
}

sub _rpc {
    my ($self, $meth, @params) = @_;

    my $req_txt = "method $meth args ".$self->_rpc_args_to_txt(@params);

    $self->debug(4, "_rpc called with $req_txt");

    if ($_cache_methods->{$meth}) {
        if ($_cache->{$meth} && exists($_cache->{$meth}->{$req_txt})) {
            $self->debug(1, "Returning cached data for $meth / $req_txt");
            return $_cache->{$meth}->{$req_txt};
        }
    }

    my $cli = $self->{__cli};
    my %opts;

    if (exists($self->{ca})) {
        my $optname = "SSL_ca_" . (-f $self->{ca} ? 'file' : 'path');
        my $set_verify_hostname = 1;
        my $set_optname = 1;
        if (exists($self->{useragent}) && exists ($self->{useragent}->{ssl_opts})) {
            my $ssl_opts = $self->{useragent}->{ssl_opts};
            $set_verify_hostname = ! exists($ssl_opts->{verify_hostname});
            $set_optname = ! exists($ssl_opts->{$optname});
        }
        $self->{useragent}->{ssl_opts}->{verify_hostname} = 1 if $set_verify_hostname;
        $self->{useragent}->{ssl_opts}->{$optname} = $self->{ca} if $set_optname;
    }
    # RPC::XML::Client expects that useragent is an arrayref, which is passed
    # as an array to LWP::UserAgent, which interprets it as a hash
    $opts{useragent} = [%{$self->{useragent}}] if exists($self->{useragent});

    if (! $cli) {
        $self->{__cli} = RPC::XML::Client->new($self->{url}, %opts);
        $cli = $self->{__cli};
    };

    my @params_o = (RPC::XML::string->new($self->{user} . ":" . $self->{password}));
    for my $p (@params) {
        my $klass = "RPC::XML::" . $p->[0];
        push(@params_o, $klass->new($p->[1]));
    }

    my $req = RPC::XML::request->new($meth, @params_o);

    my $reqstring = $req->as_string();
    my $password = XMLout($self->{password}, rootname => "x");
    if ($password =~ m!^\s*<x>(.*)</x>\s*$!) {
        $password = quotemeta $1;
        $reqstring =~ s/$password/PASSWORD/g;
        $self->debug(5, "_rpc RPC request $reqstring");
    } else {
        $self->debug(5, "_rpc RPC request not shown, failed to convert and replace password");
    }

    my $resp = $cli->send_request($req);

    if(!ref($resp)) {
        $self->error("_rpc send_request failed with message: $resp");
        return;
    }

    my $ret = $resp->value;

    if(ref($ret) ne "ARRAY") {
        $self->error("_rpc failed to make request faultCode $ret->{faultCode} faultString $ret->{faultString} $req_txt");
        return;
    }

    elsif($ret->[0] == 1) {
        $self->debug(5, "_rpc RPC answer $ret->[1]");
        if($ret->[1] =~ m/^(\d|\.)+$/) {
            my $parsed = $ret->[1];
            if ($_cache_methods->{$meth}) {
                $_cache->{$meth}->{$req_txt} = $parsed;
                $self->debug(5, "Result for $meth / $req_txt cached");
            };
            return $parsed;
        }
        else {
            my $opts = {
                ForceArray => $has_libxml ? ['ID', 'NAME', 'STATE', qr{.}] : 1,
                KeyAttr => [],
            };

            my $parsed = XMLin($ret->[1], %$opts);
            if ($_cache_methods->{$meth}) {
                $_cache->{$meth}->{$req_txt} = $parsed;
                $self->debug(5, "Result for $meth / $req_txt cached");
            };

            return $parsed;
        }
    }

    else {
        $self->error("_rpc Error sending request $req_txt: $ret->[1] (code $ret->[2])");
        if( $self->{fail_on_rpc_fail}) {
            die("error sending request.");
        } else {
            return;
        }
    }

}


sub version {
    my ($self) = @_;

    # cached value
    if(exists($self->{_version})) {
        return $self->{_version};
    }
    my $version = $self->_rpc("one.system.version");

    if(defined($version)) {
        $self->verbose("Version $version found");
        $self->{_version} = version->new($version);
        return $self->{_version};
    } else {
        $self->error("Failed to retrieve version");
        return;
    }
}


# add logging shortcuts
no strict 'refs'; ## no critic
# The Log4Perl methods
foreach my $i (qw(error warn info debug)) {
    *{$i} = sub {
        my ($self, @args) = @_;
        return $self->{log}->$i(@args);
    };
};
# verbose fallback for Log4Perl
*{verbose} = sub {
    my ($self, @args) = @_;
    my $verbose = $self->{log}->can('verbose') ? 'verbose' : 'debug';
    return $self->{log}->$verbose(@args);
};

use strict 'refs';

1;
