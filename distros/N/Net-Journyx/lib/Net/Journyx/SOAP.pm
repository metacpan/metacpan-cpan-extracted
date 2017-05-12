package Net::Journyx::SOAP;
use Moose;

use XML::Compile::Util qw/pack_type/;

#use Log::Report mode => 'DEBUG';
use Data::Dumper;

has jx => (
    is       => 'rw',
    isa      => 'Net::Journyx',
    required => 1,
    weak_ref => 1,
);

my $current_wsdl = '';
my %API_CACHE = (
);

has wsdl => (
    is       => 'ro',
    lazy     => 1,
    default  => sub { return shift->jx->wsdl },
);

has wsdl_document => (
    is       => 'rw',
    lazy     => 1,
    default  => sub {
        my $self = shift;

        return $API_CACHE{'document'} if $API_CACHE{'document'};

        require File::Temp;
        my $tmp = new File::Temp;

        my $url = $self->wsdl;
        my $ua = $self->jx->ua;
        my $response = $ua->get( $url, ':content_file' => "$tmp" );
        unless ( $response->is_success ) {
            die "Request to '$url' failed. Server response:\n". $response->status_line ."\n";
        }

        $tmp->seek(0,0);

        require XML::LibXML;
        my $parser = new XML::LibXML;
        return $API_CACHE{'document'} = $parser->parse_fh( $tmp );
    },
);

has transport => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        require XML::Compile::Transport::SOAPHTTP;
        return XML::Compile::Transport::SOAPHTTP->new(
            address => $self->jx->site,
            user_agent => $self->jx->ua,
            keep_alive => 1,
        )->compileClient;
    },
);

has batch_transport => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $address = $self->jx->site;
        $address =~ s/jxapi\.pyc$/soap_cgi.pyc/;
        require XML::Compile::Transport::SOAPHTTP;
        return XML::Compile::Transport::SOAPHTTP->new(
            address => $address,
            user_agent => $self->jx->ua,
            keep_alive => 1,
        )->compileClient;
    },
);

has client => (
    is      => 'rw',
    isa     => 'XML::Compile::SOAP::Client',
    lazy    => 1,
    default => sub {
        my $self = shift;

        return $API_CACHE{'client'} if $API_CACHE{'client'};

        require XML::Compile::SOAP11::Client;
        my $res = new XML::Compile::SOAP11::Client;
        $res->schemas->importDefinitions( $self->wsdl_document );
        return $API_CACHE{'client'} = $res;
    },
);

has schema => (
    is      => 'rw',
#    isa     => 'XML::Compile::SOAP::Client',
    lazy    => 1,
    default => sub {
        return (shift->wsdl_document->findnodes('//xsd:schema'))[0];
    },
);

has encoder => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->client->compileMessage(SENDER => style => 'rpc-encoded');
    },
);

has decoder => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->client->compileMessage(RECEIVER => style => 'rpc-encoded');
    },
);

has namespace => (
    is      => 'rw',
    default => sub { 'urn:jxapi' },
);

has API => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;

        return $API_CACHE{'API'} if $API_CACHE{'API'};

        my %res = ();

        my $doc = $self->wsdl_document;
        my @ops = $doc->findnodes('//wsdl:portType/wsdl:operation');
        foreach my $op ( @ops ) {
            my $name = $op->getAttribute("name");
            my $order = $op->getAttribute("parameterOrder");
            $res{$name}{'order'} = [ split /\s+/, $order ];

            foreach my $dir (qw(input output)) {
                my $type  = $op->find("wsdl:$dir")->shift->getAttribute('name');
                my @parts = $doc->findnodes('//wsdl:message[@name = "'.$type.'"]/wsdl:part');
                foreach my $part ( @parts ) {
                    $res{$name}{$dir .'_type'}{ $part->getAttribute('name') }
                        = $part->getAttribute('type');
                }
            }
        }

        return $API_CACHE{'API'} = \%res;
    },
);

sub BUILD {
    return unless my $jx = $_[1]->{'jx'};
    unless ( $current_wsdl eq $jx->wsdl ) {
        %API_CACHE = ();
        $current_wsdl = $jx->wsdl;
    }
}

sub install_basic {
    my $self = shift;
    my $into = shift || caller;

    foreach my $operation ( @_ ) {
        my $name = $self->nocapitals( $operation );

        $into->meta->add_method(
            $name => sub {
                return (shift)->soap->basic_call($operation, @_)
            },
        );
    }
}

our $IN_LOGIN_RETRY = 0;
sub basic_call {
    my $self = shift;
    my $op = shift;
    my %args = @_;

    my ($answer, $trace) = $self->call( $op => %args );
    unless ( exists $answer->{ $op .'Response' } ) {
        if ( $op ne 'logout' && $op ne 'login'
            && !$IN_LOGIN_RETRY
            && $answer->{'Fault'}{'faultstring'} eq 'session timed out or invalid token'
        ) {
            $self->jx->clear_session;
            local $IN_LOGIN_RETRY = 1;
            return $self->basic_call( $op => %args );
        }
        my $exception = 'XXX IMPLEMENT ME!';
        die "Couldn't run function $op: ". Dumper( $answer );
    }
    my $res = $answer->{ $op .'Response' };
    return ($res, $trace) if wantarray;
    return $res;
}

sub call {
    return (shift)->create_call(shift)->( @_ );
}

sub batch_call {
    my $self = shift;
    my ($answer, $trace) = $self->create_batch_call->( @_ );
    unless ( exists $answer->{ 'jxAPIBatchResponse' }{'Result'} ) {
        if ( !$IN_LOGIN_RETRY && $answer->{'Fault'}{'faultstring'} eq 'session timed out or invalid token' ) {
            $self->jx->clear_session;
            local $IN_LOGIN_RETRY = 1;
            return $self->batch_call( @_ );
        }
        my $exception = 'XXX IMPLEMENT ME!';
        die "Couldn't run function jxAPIBatch: ". Dumper( $answer );
    }
    my $res = $answer->{ 'jxAPIBatchResponse' }{'Result'}{'results'};
    $res = [ $res ] unless ref $res eq 'ARRAY';
    return $res;
}

sub create_call {
    my $self = shift;
    my $name = shift;

    my $out = sub {
        my ($soap, $doc, $data) = @_;
        my $ns = $self->namespace;
        $soap->encAddNamespace( typens => $ns );
        return $soap->struct(
            pack_type($ns, $name),
            $self->pack_method_arguments(
                soap => $soap,
                name => $name,
                arguments => { @$data }
            ), 
        );
    };

    my $in = sub {
        my ($soap, @msgs) = @_;
        # XXX: refactor me into something more elegant
        require Net::Journyx::SOAP::Encoding;
        my $old = ref $soap;
        bless $soap, 'Net::Journyx::SOAP::Encoding';
        my $rv;
        my $tree = $soap->dec(@msgs);
        $rv = $soap->decSimplify($tree) if $tree;
        bless $soap, $old;
        return $rv? $rv : ();
    };

    return $self->_create_call( $name, $out, $in );
}

sub create_batch_call {
    my $self = shift;

    my $out = sub {
        my ($soap, $doc, $data) = @_;

        my $ns = $self->namespace;
        $soap->encAddNamespace( typens => $ns );
        $soap->encAddNamespace( 'SOAP-ENC' => 'http://schemas.xmlsoap.org/soap/encoding/' );

        my @commands;
        while ( my $method = shift @$data ) {
            push @commands, $soap->struct(
                'item',
                $soap->element( string => 'methodName' => $method ),
                $soap->struct(
                    'methodArgs',
                    $self->pack_method_arguments(
                        soap => $soap,
                        name => $method,
                        arguments => shift @$data,
                        skip_session => 1,
                    ),
                ),
            );
        }

        my $commands = $soap->struct('commands', @commands);
        #$commands->setAttribute( 'SOAP-ENC:arrayType' => 'xsd:instance['. scalar(@commands) .']' );
        $commands->setAttribute( 'xsi:type' => 'SOAP-ENC:Array' );

        return $soap->struct(
            pack_type($ns, 'jxAPIBatch'),
            $soap->struct(
                'jxAPICommandSet',
                $soap->element( string => 'session' => $self->jx->session ),
                $soap->element( int => 'stop_on_error' => 0 ),
                $commands,
            ),
        );
    };

    my $in = sub {
        my ($soap, @msgs) = @_;
        # XXX: refactor me into something more elegant
        require Net::Journyx::SOAP::Encoding;
        my $old = ref $soap;
        bless $soap, 'Net::Journyx::SOAP::Encoding';
        my $rv;
        my $tree = $soap->dec(@msgs);
        $rv = $soap->decSimplify($tree) if $tree;
        bless $soap, $old;
        return $rv? $rv : ();
    };

    return $self->client->compileClient(
        name      => 'jxAPIBatch',
        rpcout    => $out,
        rpcin     => $in,

        encode    => $self->encoder,
        decode    => $self->decoder,
        transport => $self->batch_transport,
    );
}

sub jxapi_type {
    my $self = shift;
    my $type = shift;

    my $schema = $self->schema;
    my ($type_node) = $schema->findnodes('.//xsd:complexType[@name = "'.$type.'"]');
    die "couldn't find type '$type' in the schema" unless $type_node;

    my %res = (order => []);

    my @elements = $type_node->findnodes('.//xsd:element');
    foreach my $el ( @elements ) {
        my $name = $el->getAttribute('name');
        my $el_type = $el->getAttribute('type');

        #warn "found element '$name' of type '$el_type' for jxapi $type";

        push @{ $res{'order'} }, $name;
        $res{'type'}{$name} = $el_type;
    }

    return \%res;
}

sub records {
    my $self = shift;

    my $schema = $self->schema;
    my (@types) = $schema->findnodes('.//xsd:complexType');
    die "couldn't find types in the schema" unless @types;

    my @res;
    foreach my $t ( @types ) {
        next unless ($t->findnodes('.//xsd:extension[@base="typens:Record"]'))[0];
        push @res, $t->getAttribute('type');
    }
    return @res;
}

sub record_columns {
    my $self = shift;
    my $record = shift;
    return %{ $self->jxapi_type( $record )->{'type'} };
}

sub encode {
    my $self = shift;
    my @ret;

    for my $text (@_) {
        my $text = shift;

        if (!ref($text) && !$self->jx->allows_utf8) {
            $text = join '', map { ord($_) > 127 ? '?' : $_ } split '', $text;
        }

        push @ret, $text;
    }

    return @ret if wantarray;
    return $ret[0];
}

sub pack_method_arguments {
    my $self = shift;
    my %args = (
        soap => undef,
        name => undef,
        arguments => {},
        skip_session => 0,
        @_
    );

    my $api = $self->API->{$args{'name'}} or die "no operation '$args{'name'}'";

    my $ns = $self->namespace;

    my @elements;
    foreach my $arg ( @{ $api->{'order'} } ) {
        my $type = $api->{'input_type'}{ $arg };
        my $value = delete $args{'arguments'}{ $arg };

        if ( $arg =~ /^s(?:ession_)?key$/ ) {
            next if $args{'skip_session'};
            $value = $self->jx->session
                unless defined $value;
        }

        my ($type_ns, $type_name) = split(/:/, $type, 2);
        if ( $type_ns eq 'xsd' ) {
            #warn "building '$value' as argument $arg (type: $type) for operation $args{'name'}";
            $value = $self->encode($value);
            push @elements, $args{'soap'}->element( $type_name => $arg => $value );
        } elsif ( $type_ns eq 'typens' ) {
            # XXX: here we want autorecords from our Record objects
            die "$args{'name'}'s argument is of complex type '$type_name', pass hash reference"
                unless ref($value) eq 'HASH';

            push @elements, $self->pack_complex_type(
                argument => pack_type($ns, $arg),
                value    => $value,
                meta     => $self->jxapi_type( $type_name ),
                soap     => $args{'soap'},
            );
        } else {
            die "XXX: can not handle";
        }
    }

    return @elements;
}

sub pack_complex_type {
    my $self = shift;
    my %args = (
        argument => undef,
        value    => undef,
        meta     => undef,
        soap     => undef,
        @_
    );

    my ($meta, $soap) = @args{'meta', 'soap'};

    my @elements;
    foreach my $arg ( @{ $meta->{'order'} } ) {
        my $type = $meta->{'type'}{$arg};
        unless ( exists $args{'value'}{ $arg } ) {
            #warn "argument '$arg' is not provided, skipping";
            next;
        }

        my ($type_ns, $type_name) = split(/:/, $type, 2);
        if ( $type_ns eq 'xsd' ) {
            my $value = $self->encode($args{value}{$arg});
            push @elements, $soap->element( $type_name => $arg => $value );
        } elsif ( $type_ns eq 'typens' ) {
            die "recursive complex schema types are not supported";
        } else {
            die "XXX: can not handle name space $type_ns";
        }
    }

    return $soap->struct($args{'argument'}, @elements);
}

sub _create_call {
    my $self = shift;
    my ($name, $out, $in ) = @_;
    return $self->client->compileClient(
        name      => $name,
        rpcout    => $out,
        rpcin     => $in,

        encode    => $self->encoder,
        decode    => $self->decoder,
        transport => $self->transport,
    );
}

sub nocapitals {
    my $self = shift;
    my $res = shift;
    $res =~ s/(?<=[a-z])([A-Z]+)/"_" . lc($1)/eg;
    $res =~ tr/A-Z/a-z/;
    return $res;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
