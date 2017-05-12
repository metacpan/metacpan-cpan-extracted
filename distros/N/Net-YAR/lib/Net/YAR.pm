package Net::YAR;

=head1 NAME

Net::YAR - Perl interface to the YAR (Yet Another Registrar) API

=cut

use strict;
use Carp qw(croak confess);
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Headers;
use vars qw(
    $AUTOLOAD
    $VERSION
    $JSON_ENCODE
    $JSON_DECODE
    $DEFAULT_RETRY_MAX
    $DEFAULT_RETRY_INTERVAL
);

$VERSION = sprintf "%d.%03d", q$Revision: 1.83 $ =~ /(\d+)/g;
$DEFAULT_RETRY_MAX = 3; # Retry up to this many times when network problems occur.
$DEFAULT_RETRY_INTERVAL = 15; # Seconds to wait after response failure before trying again.

sub new {
    my $class = shift;
    my $args  = shift || {};
    return bless {%$args}, $class;
}

sub api_user { my $self = shift; $self->{'api_user'} || $self->{'user'} || croak "Missing api_user" }
sub api_pass { my $self = shift; $self->{'api_pass'} || $self->{'pass'} || croak "Missing api_pass" }
sub api_host { my $self = shift; $self->{'api_host'} || $self->{'host'} || croak "Missing api_host" }
sub api_port { my $self = shift; $self->{'api_port'} || $self->{'port'} || ($self->use_ssl ? 443 : 80) }
sub api_path { my $self = shift; $self->{'api_path'} || $self->{'path'} || '/cgi/yar' }
sub use_ssl  { my $self = shift; $self->{'use_ssl'}  || $self->{'ssl'}  || 1 }
sub ssl_verify_hostname { shift->{'ssl_verify_hostname'} || 0 }
sub log_obj   {
    my $self = shift;
    if (! $self->{'log_obj'}) {
        if (my $file = $self->log_file) {
            require IO::File;
            if (my $io = new IO::File ">>$file") {
                $io->autoflush(1);
                $self->{'log_obj'} = $io;
            }
        }
    }
    return $self->{'log_obj'};
}
sub log_file { shift->{'log_file'} || undef }


sub serialize_type {
    return shift->{'serialize_type'} ||=
          eval { require JSON }            ? 'json'
        : eval { require YAML::Syck }      ? 'yaml'
        : eval { require YAML }            ? 'yaml'
        : eval { require XML::Simple }     ? 'xml'
        : eval { require Data::URIEncode } ? 'uri'
        : die "Can't find a module that can encode and decode (need one of JSON, YAML::Syck, YAML, Data::URIEncode, XML::Simple)";
}

###----------------------------------------------------------------###

sub play_method {
    my ($self, $meth, $args) = @_;
    $args ||= {};

    ### get connection details - these die if not initialized in new
    my $user = $self->api_user;
    my $pass = $self->api_pass;
    my $host = $self->api_host;
    my $port = $self->api_port;
    my $path = $self->api_path;

    ### setup the request
    local $args->{'method'} = $meth;
    die "Invalid method $meth" if $meth !~ /^[\w\.-]+$/;
    my $request = eval { $self->serialize_request($args) };
    if (! $request) {
        return Net::YAR::Fault->new({
            type            => 'serialize_error',
            method          => $meth,
            serialize_error => $@,
            serialize_args  => $args,
        });
    }

    ### send the request
    my $resp;
    my $proto = $self->use_ssl ? 'https' : 'http';
    my $url   = "$proto://$host:$port$path/$meth";
    my @head;
    if (! $args->{'authentication'}) {
        my $auth = "$user/$pass";
        $auth =~ s|([^\w.\-\:/])|sprintf('%%%02X', ord $1)|eg;
        push @head, (Cookie => "authentication=$auth;");
    }

    eval {
        my $req = HTTP::Request->new('POST', $url, HTTP::Headers->new(@head), $request);
        #warn $req->as_string;

        my $log_obj = $self->log_obj;
        if ($log_obj) {
            my $id = $args->{'domain'} || $args->{'contact_id'} || $args->{'user_id'} || "";
            $id = join ", ", @$id if ref($id) eq 'ARRAY';
            $log_obj->print(scalar(localtime).": REQUEST: $meth - $id\n",$request,"\n");
        }

        my $lwp_args = ref($args->{'lwp_args'}) eq 'HASH' ? $args->{'lwp_args'} : ref($args->{'lwp_args'}) eq 'ARRAY' ? {@{$args->{'lwp_args'}}} : {};
        local $lwp_args->{'ssl_opts'} = {} if ! $lwp_args->{'ssl_opts'};
        local $lwp_args->{'ssl_opts'}->{'verify_hostname'} = $self->ssl_verify_hostname if ! exists $lwp_args->{'ssl_opts'}->{'verify_hostname'};
        my $retries = defined $args->{'retry_max'}      ? $args->{'retry_max'}      : $DEFAULT_RETRY_MAX;
        my $interval= defined $args->{'retry_interval'} ? $args->{'retry_interval'} : $DEFAULT_RETRY_INTERVAL;
        $interval = 5 if $interval < 5;
        while (1) {
            $resp = LWP::UserAgent->new(%$lwp_args)->request($req);
            last if $resp && $resp->is_success;
            if ($retries-->0) {
                if ($log_obj) {
                    $log_obj->print(scalar(localtime).": FAILED RESPONSE (".(eval { $resp->code }).") with $retries retries left:\n".(eval { $resp->content })."\n\n");
                }
                sleep $interval;
                next;
            }
            last;
        }

        if ($log_obj) {
            $log_obj->print(scalar(localtime).": RESPONSE (".(eval { $resp->code })."):\n".(eval { $resp->content })."\n\n");
        }
    };
    if (! $resp || ! $resp->is_success) {
        return Net::YAR::Fault->new({
            type            => 'request_error',
            method          => $meth,
            request         => $request,
            request_url     => $url,
            request_error   => $@,
            request_code    => ($resp ? $resp->code : ''),
            request_message => ($resp ? $resp->message : ''),
        });
    }

    ### parse the result
    return $self->parse_response({
        method   => $meth,
        content  => $resp->content,
        response => $resp,
        request  => $request,
    });

}

sub serialize_request {
    my ($self, $args) = @_;

    ### what type of data serialization should we use
    my $type = $args->{'serialize'} || $args->{'serialize_type'} || $self->serialize_type;

    ### prepare the request
    my $request;
    if ($type eq 'yaml') {
        if (eval { require YAML::Syck }) {
            $request = YAML::Syck::Dump({request => $args});
        } else {
            require YAML;
            $request = YAML::Dump({request => $args});
        }
    } elsif ($type eq 'json') {
        require JSON;
        $JSON_ENCODE ||= JSON->VERSION > 1.98 ? 'encode' : 'objToJSon';
        if ($JSON_ENCODE eq 'encode') {
            $request = JSON->new->encode({request => $args});
        } else {
            $request = JSON->new->objToJSon({request => $args}, {autoconv => 0});
        }

    } elsif ($type eq 'xml') {
        require XML::Simple;
        $request = XML::Simple::XMLout({request => $args},
                                       XMLDecl       => 1,
                                       KeepRoot      => 1,
                                       KeyAttr       => [],
                                       NoAttr        => 1,
                                       SuppressEmpty => undef,
                                       GroupTags     => {
                                           nameservers        => 'nameserver',
                                           nameservers_add    => 'nameserver_add',
                                           nameservers_remove => 'nameserver_remove',
                                           where              => 'item',
                                           select             => 'item',
                                           group_by           => 'item',
                                           order_by           => 'item',
                                           fields             => 'field',
                                       });

    } elsif ($type eq 'uri') {
        require Data::URIEncode;
        $request = Data::URIEncode::complex_to_query({request => $args});

    } else {
        confess "Not sure how to encode or decode that type ($type)";
    }

    return $request;
}

sub parse_response {
    my ($self, $args) = @_;

    my $content = $args->{'content'};

    my $response;
    eval {
        my $data;
        if (!$content) {
            $data = { response => { type => "error", error => { code => "empty"} } };
        } elsif ($content =~ /\A \s* <\?xml /sx) {
            require XML::Simple;
            my $hash = XML::Simple::XMLin($content,
                                          SuppressEmpty => '',
                                          KeyAttr       => [],
                                          NoAttr        => 1,
                                          GroupTags     => {
                                              nameservers => 'nameserver',
                                              rows        => 'row',
                                              tlds        => 'tld',
                                              fields      => 'field',
                                          });
            foreach (qw(nameservers rows tlds)) {
                next if ! $hash->{'data'} || ! $hash->{'data'}->{$_} || ref $hash->{'data'}->{$_} ne 'HASH';
                $hash->{'data'}->{$_} = [$hash->{'data'}->{$_}];
            }
            $data = {response => $hash};

        } elsif ($content =~ /\A \s* \{ /sx) {
            require JSON;
            $JSON_DECODE ||= JSON->VERSION > 1.98 ? 'decode' : 'jsonToObj';
            local $JSON::UnMapping = 1;
            $data = JSON->new->$JSON_DECODE($content);

        } elsif ($content =~ /\A ---\s+ /sx) {
            if (eval {require YAML::Syck}) {
                $data = (YAML::Syck::Load($content))[0];
            } else {
                require YAML;
                $data = (YAML::Load($content))[0];
            }

        } elsif ($content =~ /\A [\w\.]+= /sx) {
            eval {
                require Data::URIEncode;
            } or do {
                require Carp;
                require Data::Dumper;
                Carp::confess(Data::Dumper::Dumper([$args, error => $@]));
            };
            $data = Data::URIEncode::query_to_complex($content);
        } else {
            die 'unknown_serialization';
        }

        $response = $data->{'response'} || confess "Invalid response";
    };

    ### store for later
    my $obj_args = $response || {
        type        => 'parse_error',
        parse_error => $@,
    };
    $obj_args->{'request'}  = $args->{'request'};
    $obj_args->{'response'} = $content;
    $obj_args->{'method'}   = $args->{'method'};

    ### return the appropriate object
    if (! $obj_args->{'type'} || $obj_args->{'type'} eq 'error' || $obj_args->{'type'} eq 'parse_error') {
        return Net::YAR::Fault->new($obj_args);
    } else {
        return Net::YAR::Response->new($obj_args);
    }
}

###----------------------------------------------------------------###
### dynamically handle all of the available YAR namespaces and methods

sub DESTROY {}

sub AUTOLOAD {
    my $self = shift;

    my $method = $AUTOLOAD =~ /::([\w.]+)$/ ? $1 : '';

    ### magically add _all capability to all searches
    if ($method =~ /^(\w+_search)_all$/) {
        return $self->_all_search($1, @_);

    }
    ### magically add _iter capability to all searches
    elsif ($method =~ /^(\w+_search)_iter$/) {
        return $self->_iter_search($1, @_);

    }
    ### handle all $yar->domain_register style commands
    elsif ($method =~ /^ (domain|contact|user|util|[^\W_]+) _+ (\w+) $/x) {
        my $yar_method = "$1.$2";
        my $failovers = eval {
            my $fails = $_[0]->{'failover'} or die "No failover";
            my $mod = ucfirst($1).ucfirst($2);
            require "Net/YAR/$mod.pm";
            if (my $default = UNIVERSAL::can("Net::YAR::$mod","lwp_args_yar_default")) {
                $_[0]->{'lwp_args'} ||= $default->();
            }
            $fails = [$fails] if "ARRAY" ne ref $fails;
            my @code_refs = ();
            foreach my $try (@$fails) {
                if (my $code = UNIVERSAL::can("Net::YAR::$mod",$method."_$try")) {
                    push @code_refs, $code;
                }
            }
            return \@code_refs if @code_refs;
            die "Net::Server::$mod - Unable to locate any failover for @$fails";
        };

        my $resp;
        if (eval { $resp = $self->play_method($yar_method, @_); 1 }) {
            if (!$resp) {
                # Normal YAR request failed.
                if ($failovers) {
                    # Try Net::Yar::$mod->method_$try for each failover
                    foreach my $code (@$failovers) {
                        if (my $new_resp = eval { $code->($self, $resp, @_) }) {
                            $resp = $new_resp;
                            last;
                        }
                        else { warn "FAILOVER CRASHED: $@"; }
                    }
                }
                $@ = "";
            }
            $@ = $resp if ! $resp;
            return $resp;
        }

        ### handle the yar errors
        my $err = $@;
        die $err if ! UNIVERSAL::can($err, 'type') || $err->type ne 'invalid_method';
    }

    ### die with normal invalid method error
    my $pkg = ref $self;
    croak "Can't locate object method \"$method\" via package \"$pkg\"";
}

###----------------------------------------------------------------###
### use the standard YAR API search method's pagination features
### to return all results for a given search

sub _all_search {
    my ($self, $meth, $args) = @_;

    my $N_ROWS = $args->{'rows_per_page'} || 10000;
    my $ROWS   = [];
    my $RESP   = Net::YAR::Response->new({method => "${meth}_all", type => 'success', data => {rows => $ROWS}});
    my $begin  = time;

    if (my $UNIQ_KEY = lc($args->{'unique_key'} || '')) {
        my %UNIQ;
        my $PAGE    = 1;
        my $N_EXTRA = 10;

        ### if we have a unique key - use extra_rows to allow for adds and deletes during the query
        while (1) {
            local $args->{'page'}          = $PAGE;
            local $args->{'rows_per_page'} = $N_ROWS;
            local $args->{'extra_rows'}    = $N_EXTRA;
            local $args->{'return_sql'};

            ### get the current page
            $RESP->data->{'n_requests'}++;
            my $resp = $self->$meth($args);
            if (! $resp) { # as soon as we get an error - return it
                $resp->data->{'rows'} = $RESP->data->{'rows'};
                return $resp;
            }

            my $_rows = $resp->data->{'rows'};
            my $i     = 0;
            my $found = 0;
            foreach my $row (@$_rows) {
                return Net::YAR::Fault->new({
                    method   => "${meth}_all",
                    type     => 'error',
                    code     => 'invalid_key',
                    key      => $UNIQ_KEY,
                    response => $resp,
                }) if ! exists $row->{$UNIQ_KEY};

                if (! $UNIQ{$row->{$UNIQ_KEY}}++) {
                    push @$ROWS, $row; # not found yet - add it
                } else {
                    $found++ if ++$i < $N_EXTRA;
                }
            }

            ### allow for us to modify what there is left to query
            if ($PAGE == 1) {
                $RESP->data->{'rows_per_page'}    = $resp->data->{'rows_per_page'};
                $RESP->data->{'n_rows_estimated'} = $resp->data->{'n_rows'};
                $RESP->{'request'}                = $resp->{'request'};
                $RESP->{'response'}               = "--discarded--\n";
            }

            if (@$_rows && ! $found && $PAGE > 1) { # didn't find any of the extra records - go back one page
                $PAGE -= 1;
                next;
            } elsif (@$_rows > $N_ROWS) { # had extra rows - loop to the next page
                $PAGE += 1;
                next;
            } else { # all done
                $RESP->data->{'n_pages'} = $PAGE;
                $RESP->data->{'n_rows'}  = @$ROWS;
                last;
            }
        }
    } else {
        my $PAGE    = 0;
        my $N_PAGES = 1;
        while (++$PAGE <= $N_PAGES) {
            local $args->{'page'}          = $PAGE;
            local $args->{'rows_per_page'} = $N_ROWS;
            local $args->{'extra_rows'};
            local $args->{'return_sql'};

            ### get the current page
            $RESP->data->{'n_requests'}++;
            my $resp = $self->$meth($args);
            if (! $resp) { # as soon as we get an error - return it
                $resp->data->{'rows'} = $RESP->data->{'rows'};
                return $resp;
            }

            push @$ROWS, @{ $resp->data->{'rows'} };

            ### allow for us to modify what there is left to query
            if ($PAGE == 1) {
                $N_ROWS = $RESP->data->{'rows_per_page'} = $resp->data->{'rows_per_page'} || return Net::YAR::Fault->new({
                    method   => "${meth}_all",
                    type     => 'error',
                    code     => 'missing_rows_per_page',
                    response => $resp,
                });
                $N_PAGES = $RESP->data->{'n_pages'} = $resp->data->{'n_pages'} || 0;
                $RESP->data->{'n_rows_estimated'} = $resp->data->{'n_rows'};
                $RESP->{'request'}  = $resp->{'request'};
                $RESP->{'response'} = "--discarded--\n";
            }
        }
        $RESP->data->{'n_rows'} = @$ROWS;
    }
    $RESP->data->{'elapsed'} = time - $begin;

    return $RESP;
}

###----------------------------------------------------------------###
### use the standard YAR API search method's pagination features to
### obtain all results for a given search one iteration at a time

sub _iter_search {
    my ($self, $meth, $args) = @_;

    $args->{'rows_per_page'} ||= 10_000;
    $args->{'page'}          ||= 1;
    $args->{'extra_rows'}    ||= 10;
    if (!$args->{'unique_key'}) {
        if (my $o = $args->{'order_by'}) {
            $o = [ $o ] unless ref $o eq "ARRAY";
            foreach my $field (@$o) {
                if ($field =~ /^(\w+)$/) {
                    $args->{'unique_key'} = $1;
                    last;
                }
            }
        }
    }
    croak "Arg [unique_key] could not be determined for ITER [$meth]" if !$args->{'unique_key'};
    my $response = $self->$meth($args);
    return $response if !$response;
    my %uniq = ();
    my $tie_obj = undef;
    eval {
        require DB_File;
        require Fcntl;
        my $unique_hash_file = $args->{'unique_hash_file'} || "/tmp/iter_[$args->{'unique_key'}]_$$.db";
        $tie_obj = tie(%uniq, "DB_File", $unique_hash_file, Fcntl::O_RDWR()|Fcntl::O_CREAT(), 0666) or die "$unique_hash_file: tie: $!";
        # Anonymous file backend so it will disappear once the process dies
        # but it's actually still on disk instead of wasting precious memory.
        unlink $unique_hash_file;
    } or warn "DB_File anonymous file tie failed: $@";
    my $iter = {
        %$response,
        yar      => $self,
        request  => $args,
        response => $response,
        method   => $meth."_iter",
        curr     => 0,
        i        => 0,
        tie_obj  => $tie_obj,
        uniq     => \%uniq,
    };
    return bless $iter, "Net::YAR::Iter";
}


###----------------------------------------------------------------###
### provide older shortcuts for common util operations

sub noop {        shift->play_method('util.noop',    @_) }
sub balance {     shift->play_method('util.balance', @_) }

###----------------------------------------------------------------###
### allow for $yar->util->noop type method calls

sub contact      { shift->new_chain_proxy('contact'     ) }
sub csr          { shift->new_chain_proxy('csr'         ) }
sub domain       { shift->new_chain_proxy('domain'      ) }
sub domainchange { shift->new_chain_proxy('domainchange') }
sub invoice      { shift->new_chain_proxy('invoice'     ) }
sub offer        { shift->new_chain_proxy('offer'       ) }
sub order        { shift->new_chain_proxy('order'       ) }
sub package      { shift->new_chain_proxy('package'     ) }
sub service      { shift->new_chain_proxy('service'     ) }
sub user         { shift->new_chain_proxy('user'        ) }
sub util         { shift->new_chain_proxy('util'        ) }
sub whois        { shift->new_chain_proxy('whois'       ) }
sub host         { shift->new_chain_proxy('host'        ) }
sub dns          { shift->new_chain_proxy('dns'         ) }

sub new_chain_proxy {
    my ($self, $type) = @_;
    return Net::YAR::_ChainProxy->new({yar => $self, type => $type});
}

{
    package Net::YAR::_ChainProxy;

    use strict;
    use Carp qw(croak confess);
    use vars qw($AUTOLOAD);

    sub new {
        my $class = shift || __PACKAGE__;
        my $args  = shift || {};
        croak "Missing yar" if ! $args->{'yar'};
        croak "Missing or invalid type" if ! $args->{'type'} || $args->{'type'} !~ /^\w+$/;
        return bless $args, $class;
    }

    sub DESTROY {}

    sub AUTOLOAD {
        my $self = shift;

        my $yar    = $self->{'yar'}  || croak __PACKAGE__." object modified since new - missing yar";
        my $type   = $self->{'type'} || croak __PACKAGE__." object modified since new - missing type";

        my $method = $AUTOLOAD =~ /::(\w+)$/ ? $1 : '';

        my $yar_method = $type .'_'. $method;

        return $yar->$yar_method(@_);
    }
}

###----------------------------------------------------------------###
### All returns from a YAR call should be wrapped in a Net::YAR::Response

{
    package Net::YAR::Response;

    use strict;
    use Carp qw(croak confess);
    use overload
        'bool'   => sub { ! shift->is_fault },
        '""'     => \&as_string,
        fallback => 1;

    sub new {
        my $class = shift || confess "Missing class";
        my $args  = shift || confess "Missing args";
        my $self = bless {%$args}, $class;
        $self->{'data'} ||= {};
        return $self;
    }

    sub type           { shift->{'type'}     || 'undefined' }
    sub code           { shift->{'code'}     || ''          }
    sub time           { shift->{'time'}     || ''          }
    sub data           { shift->{'data'}     || {}          }
    sub method         { shift->{'method'}   || 'unknown'   }
    sub request        { shift->{'request'}  || ''          }
    sub response       { shift->{'response'} || ''          }
    sub as_string {
        my $self  = shift;
        return ref($self) ." ". ($self->type eq 'error' ? $self->code : $self->type) ." (called with method ".$self->method.")";
    }
    sub is_fault { 0 }
}

{
    package Net::YAR::Fault;

    use strict;
    use base qw(Net::YAR::Response);

    sub is_fault { 1 }
}

{
    package Net::YAR::Iter;

    use strict;
    use Carp qw(croak confess);
    use base qw(Net::YAR::Response);

    sub next {
        my $self = shift;

        my $response = $self->response;
        if ($self->{'i'} < scalar @{ $response->data->{'rows'} }) {
            # Still more entries left since last query
            # so just return the next one in line.
            $self->{'curr'}++;
            my $result = $response->data->{'rows'}->[$self->{'i'}++];
            my $key = $self->request->{'unique_key'};
            return Net::YAR::Fault->new({
                method   => $self->method,
                type     => 'error',
                code     => 'invalid_key',
                key      => $key,
                response => $response,
            }) if ! exists $result->{$key};
            $result->{$key} = "" if !defined $result->{$key};
            if ($self->{'uniq'}->{$result->{$key}}) {
                $self->{'curr'}--;
                return $self->next;
            }
            $self->{'uniq'}->{$result->{$key}} = 1;
            return $result;
        }

        if ($self->{'i'} >= $self->data->{'rows_per_page'}) {
            # Hit the end of this page, but there is probably more, so query the next page
            $self->{'i'} = 0;
            $self->request->{'page'}++;
            my $meth = $self->method;
            $response = $self->{response} = $self->{'yar'}->$meth($self->request);
            if ($response) {
                # Recursive call
                return $self->next;
            }
            # Return whatever the failure is.
            return $response;
        }

        # Exhausted all rows
        return Net::YAR::Fault->new({
            method   => $self->method,
            type     => 'eos',
            code     => 'eos',
            key      => 'key',
            response => "--discarded--\n",
        });
    }

}

###----------------------------------------------------------------###

1;

__END__

=head1 SYNOPSIS

    use Net::YAR;

    my $yar = Net::YAR->new({
        api_user => 'my_user',
        api_pass => 'my_pass',
        api_host => 'api.fastdomain.com',
    });



    ### test if the server can connect

    my $resp = $yar->util->noop; # calls YAR method util.noop
    # OR
    # my $resp = $yar->util_noop;  # calls YAR method util.noop

    use Data::Dumper qw(Dumper);
    if (! $resp) { # error
        print Dumper $resp->code;
        print Dumper $resp;
    } else {
        print Dumper $resp->data;
    }


    ### information to register a domain in one pass

    my $domain_info = {
        user    => {
            username   => "some_username",
            password   => '123qwe',
            email      => 'foo@my.company.com',
            phone      => '+1.8017659400',
            first_name => 'George',
            last_name  => 'Jones',
        },
        domain     => 'sometestdomain.com',
        duration   => 2,
        registrant => {contact_id => 'admin'},
        admin      => {
            first_name   => 'George',
            last_name    => 'Jones',
            organization => 'My Company Test',
            email        => 'foo@my.company.com',
            street1      => 'Techway',
            street2      => '',
            city         => 'Provo',
            province     => 'UT',
            postal_code  => '84606',
            country      => 'US',
            phone        => '+1.8017659400',
            fax          => '',
        },
        billing    => {contact_id => 'admin'},
        tech       => {contact_id => 'admin'},
        nameservers => [
            "ns1.fastdomain.com",
            "ns2.fastdomain.com",
        ],
    };

    my $r = $yar->domain->register($domain_info);

    my $info = $r->data;
    # info now contains
    # $info->{'domain_id'}              The id of the created domain
    # $info->{'contact_id_admin'}       The admin contact handle id
    # $info->{'contact_id_registrant'}, The registrant contact handle id
    # $info->{'contact_id_billing'},    The billing contact handle id
    # $info->{'contact_id_tech'},       The tech contact handle id
    # $info->{'user_id'},               The id of the new user
    # $info->{'offer_id'},              The id of the offer used
    # $info->{'invoice_id'},            The id of the new invoice
    # $info->{'order_id'},              The id of the new order

=head1 DESCRIPTION

The Net::YAR module provides a perl interface to the FastDomain YAR
(Yet Another Registrar) API Service.  In order to use this module,
you must have an agent account setup at either FastDomain.com or
another registrar that supports the YAR API.  If you would like to
register domains using this API please contact either FastDomain.com
or the YAR API registrar of choice.

You will also need to have one of JSON, YAML, YAML::Syck, XML::Simple,
or Data::URIEncode installed to facilitate serializing and deserializing
the requests to the YAR service.

=head1 Net::YAR SPECIFIC METHODS

The following is the list of methods used for controlling connections
to the YAR server as well as setup of the Net::YAR object.

=over 4

=item new

Takes a hashref of arguments and returns an object blessed into
the Net::YAR class.

    my $yar = Net::YAR->new({
        api_user => $user,
        api_pass => $pass,
        api_host => $host,
        serialize_type => 'json',
        ssl      => 1,
    });

=item api_user

Should return the username of the Registrar Account to be logged in
under.  It may be initialized during the new method.

=item api_pass

Should return the password of the Registrar Account to be logged in
under.  It may be initialized during the new method.

=item api_host

Should return the host to connect to for YAR commands.  It may be initialized
during the new method.

=item api_port

Default 443 if use_ssl is true, 80 otherwise.  Should return the port
to connect to for YAR commands.

=item use_ssl

Defaults to $self->{use_ssl} which defaults to $self->{ssl} which defaults to 1.

Setting to a true value will perform requests across a secure connection.  Production
systems will only support ssl.

=item ssl_verify_hostname

Defaults to $self->{ssl_verify_hostname} which defaults 0.

Setting to a true value will perform certificate matching.

=item api_path

Default /cgi/yar.  Should return the path to locate on host for YAR commands.

=item log_file

Default undef.  If set to a true value, will be used by the log_obj
method to return an IO::File object that will be used to log the
methods that were called.

This may be initilized during the new method by passing log_file as a
named argument.

=item log_obj

Default action is to look for a file returned by the log_file method
and open an IO::File object on it.  Can be initialized during the
"new" method.  Should contain an object that can do the "print"
method.  Any external request and any external response that occurs
during play_method will be passed to the print method.

The following is a very simple base class that records the details in
a scalar, though it would be easy to log to a file or a database:

    package MyLogger;

    sub new { bless {str => ""}, __PACKAGE__ }

    sub print { shift->{'str'} .= join "", @_ }

    sub as_string { shift->{'str'} }

=item serialize_type

Should return the method of serialization.  The following types are supported:

    json
    yaml
    xml
    uri

If not set, the method will search for installed modules which support those types.
The modules will be searched in the following order:

    JSON (json)
    YAML::Syck (yaml)
    YAML (yaml)
    Data::URIEncode (uri)
    XML::Simple (xml)

If no installed modules can be found, the method will die.

=item play_method

Takes the YAR method name and a hashref of args to pass to the YAR method.  Takes
care of serializing the request and deserializing the response.  It will return
an object blessed into the Net::YAR::Response class for successful methods.  It
will return an object blessed into the Net::YAR::Fault class for failed methods.
Errors that occur during the external connection will result in a Net::YAR::Fault
response with a type of 'request_error.

=item serialize_request

Takes the passed data hashref and encodes it using the specified serialization type.
Errors caused by passed data will result in a Net::YAR::Fault response with a type
of 'serialize_error'.

=item parse_response

Takes the response from the server and parses it into the corresponding data
structure.  Errors that occur during parsing will result in a Net::YAR::Fault
response with a type of 'parse_error'.

=back

=head1 YAR METHODS

The YAR API provides various methods for manipulating domain, contact,
and other records at the FastDomain (or similar) registrar.  These
methods are organized into namespaces that group certain object types
together.  The following is a brief list of the available namespaces
through Net::YAR.

    Namespace    | Use
    ----------------------------------------------
    contact      | manage domain contact handles
    domain       | manage domain registrations
    invoice      | manage registration invoices
    offer        | browse available offers
    order        | manage domain orders
    user         | manage users (users own domains)
    util         | access various utility functions
    whois        | access parsed whois information

Not all methods are available to every agent that uses the YAR service.
Some require additional access or limits.  Please check with your YAR service
contact for more information.

The Net::YAR object allows access to methods in each of these methods
in three different ways.  The following code shows three ways to
access the "info" method of the "domain" namespace:

    # 1 - chained proxy object
    #     each namespace has a corresponding proxy method
    #     that allows you to access the namespace as a method.
    my $resp = $yar_obj->domain->info({domain => $domain});

    # 2 - pseudo method call
    my $resp = $yar_obj->domain_info({domain => $domain});

    # 3 - play_method call
    my $resp = $yar_obj->play_method('domain.info', {domain => $domain});

Though all three methods are equivalent, it is suggested that either option 1
or 2 is used.

The response returned by YAR API methods will be either a Net::YAR::Response
which is a success value, or they will be a Net::YAR::Fault which represents
an error.  The "data" method can be used to access information returned
from the response.  See the section on Net::YAR::Response and Net::YAR::Fault
for more information.

The following sections list the methods available in each namespace.  This
document is not intended to be a comprehensive list of posible request types,
return values, and codes.  For a full listing, please use the documentation
provided by the YAR service provider.

=head2 CONTACT METHODS

=over 4

=item create

Runs contact.create.  Used for creating new contact handles that
can be used to install domains.

    my $resp = $yar->contact->create({
        tld          => 'com',
        user_id      => $user_id,
        first_name   => 'George',
        last_name    => 'Jones',
        organization => 'My Company Test',
        email        => 'foo@my.company.com',
        street1      => 'Techway',
        street2      => '',
        city         => 'Provo',
        province     => 'UT',
        postal_code  => '84606',
        country      => 'US',
        phone        => '+1.8017659400',
        fax          => '',
    });

    # $resp->data = {
    #     contact_id => $contact_id,
    # };

The tld is the top level domain (com, net, org, etc) that this
contact will be able to be associated with.  Each registry maintains
their own listing of contacts.  The tld must match the tld of
domains that it is associated with.

The user_id is the user that created the id.  A domain may
be associated with any contact handle, but only the owner
user_id should be allowed to update the contact information.

The phone number may be cleaned up prior to this method call
using the util->phone method.

If the tld is on the US registry and the contact will be used on a
registrant contact, then addition nexus fields will need to be provided:

    tld              => 'us',
    nexus_purpose    => 'P1',  # see the full YAR documentation for more information
    nexus_category   => 'C21',
    #nexus_validator => 'us',  # required if category is C31 or C32

=item delete

Runs contact.delete.  Used for deleting a contact.

=item info

Runs contact.info.  Used for querying contact info.

=item registrar_info

Runs contact.registrar_info.  Used for getting information about
a contact directly from the registry for that contact id.  Returns an
error if the contact is not currently installed on the registry.

=item search

Runs contact.search.  Used for search for contacts.

   my $resp = $yar->contact->search({
       where => [{field => "user_id", op => '=', value => '736530'},
                 {field => "tld",     op => '=', value => 'com'},
                 ],
   });


See the full YAR API documentation for a full description of
available search terms.

=item search_all

Same as search - but automatically assembles rows from queries that
return on multiple pages.

=item update

Runs contact.update.  Used for updating contact information.

=back

=head2 DOMAIN METHODS

=over 4

=item check

Runs domain.check.  Used for checking if domain is available for
registration - or not.

   my $resp = $yar->domain->check({domain => $domain});

   # $resp->data = {
   #     rows => [{domain => $domain, available => 1}],
   # };

=item create

Runs domain.create.  It is suggested you use domain.register instead.
The create method requires you to already have a user_id,
order_id, and contact_ids before calling.  It also requires you to
add nameservers later.  domain.register does all of this for you.

=item delete

Runs domain.delete.  Used for deleting domains from the service.

    my $resp = $yar->domain->delete({domain => $domain});

    # OR

    my $resp = $yar->domain->delete({domain_id => $domain_id});

Take care when using this command because the registration for the
domain will be terminated.

=item drop_add

Runs domain.drop_add.  Used for trying to drop and add as close to
atomically as possible.  There is no guarantee made that the operation
will successfully re-add the domain.  If errors occur you are responsible
for trying to re-add the domain.

=item info

Runs domain.info.  Used for getting information about
a domain.  Returns an error if the domain is not installed
on the YAR server.

    my $info = $yar->domain->info({domain => $domain})->data;

    # OR

    my $info = $yar->domain->info({domain_id => $domain_id})->data;

=item register

Runs domain.register.  Used for registering new domains.  The register
method allows for a single method call to install a domain, including
possibly installing a user, searching for an offer, creating an invoice,
creating an order, creating the necessary contacts, and registering the
domain.

The following information shows a sample of information that
would install a user, invoice, order, contacts, and domain.

    my $domain_info = {
        user    => {
            username   => "some_username",
            password   => '123qwe',
            email      => 'foo@my.company.com',
            phone      => '+1.8017659400',
            first_name => 'George',
            last_name  => 'Jones',
        },
        domain     => 'sometestdomain.com',
        duration   => 2,
        registrant => {contact_id => 'admin'},
        admin      => {
            first_name   => 'George',
            last_name    => 'Jones',
            organization => 'My Company Test',
            email        => 'foo@my.company.com',
            street1      => 'Techway',
            street2      => '',
            city         => 'Provo',
            province     => 'UT',
            postal_code  => '84606',
            country      => 'US',
            phone        => '+1.8017659400',
            fax          => '',
        },
        billing    => {contact_id => 'admin'},
        tech       => {contact_id => 'admin'},
        nameservers => [
            "ns1.fastdomain.com",
            "ns2.fastdomain.com",
        ],
    };

=over 4

=item Specifying the user

If the user_id is known, then the user key value pair could be
deleted and replaced with either of the following items.

    user_id => $user_id,

    # OR

    user => {user_id => $user_id},

    # OR

    order_id => $order_id,

Passing in the user_id allows for multiple domains to be associated
with a single user.  If a newly created order_id is passed in, then
the user_id from the order will automatically be used.

=item Specifying duration, offer or order

The duration key value pair is used to determine how long
the domain should be registered for and should be presented in
integer years.  You may also pass the following key value pairs:

    offer_id => $offer_id

    # OR

    order_id => $order_id

If an offer_id is passed in, it will be verified and a new
invoice and order will be created.

If an order_id is passed in, it will be verified and the newly registered
domain will be attached to it.

If only the duration is passed in, a offer that matches will be searched for,
and an invoice and order will be created.

=item Specifying contacts

Each of the registrant, admin, billing, and tech contacts can be specified
by passing arguments in the following ways:

    # 1 - specify an existing contact handle
    #     (the handle must be installed with the YAR service
    #      for the same tld as the domain being registered
    contact_id_registrant => $contact_id,

    # 2 - specify existing handle 2
    #     (similar to #1 but uses registrant hash)
    registrant => {contact_id => $contact_id},

    # 3 - reference other contact
    #     in this sample the registrant will use
    #     the same contact id that the admin contact uses
    registrant => {contact_id => 'admin'},

    # 4 - pass all of the information necessary to create a new contact
    #     (the information passed is the same as that passed
    #      to contact->create except that the user_id and tld are
    #      automatically provided)
    registrant => {
            first_name   => 'George',
            last_name    => 'Jones',
            organization => 'My Company Test',
            email        => 'foo@my.company.com',
            street1      => 'Techway',
            street2      => '',
            city         => 'Provo',
            province     => 'UT',
            postal_code  => '84606',
            country      => 'US',
            phone        => '+1.8017659400',
            fax          => '',
     },

The YAR API only allows for one contact in each of the registrant, admin, billing,
and tech categories.

=item Specifying nameservers

You may pass in 2 to 13 nameservers to use for lookups on the newly registered
domain.  If no nameservers are passed, the new domain will default to use
the nameservers listed in the domain->agent_nameservers method call.

=back

The domain.register method will return the following pieces of information:

    domain_id                The id of the created domain
    contact_id_admin         The admin contact handle id
    contact_id_registrant    The registrant contact handle id
    contact_id_billing       The billing contact handle id
    contact_id_tech          The tech contact handle id
    user_id                  The id of the new user
    offer_id                 The id of the offer used
    invoice_id               The id of the new invoice
    order_id                 The id of the new order
    date_created_registry    The official creation date at the registry
    date_expiration_registry The official expiration date at the registry

=item registrar_info

Runs domain.registrar_info.  Used for getting information about
a domain directly from the registry for that domain.  Returns an
error if the domain is not currently installed on the Registry.

=item renew

Runs domain.renew.  Used for renewing existing domains.

Similar to the domain.register command, except that user_id,
contact_ids, and nameservers do not need to be passed.  The same
options are available for passsing in either duration, offer_id,
or order_id.

=item search

Runs domain.search.  Used for searching for domains.

    my $rows = $yar->domain->search({
         select => ['user_id', 'count(*)'],
         where => [{field => "user_id", op => '!=', value => 2},
                   {junction => 'OR'},
                   {field => "user_id", op => '!=', value => 3},
                   {where => [{field => "user_id", op => '!=', value => 4}]},
                  ],
         group_by => ['user_id'],
         order_by => ['count(*)', 'user_id'],
    })->data->{'rows'};

=item search_all

Same as search - but automatically assembles rows from queries that
return on multiple pages.

It is not required, but you should pass a unique_key to base the search on.  Without
this, the algorithm may exclude domains in the results if the number of records
doesn't remain constant.  Using a unique key will make sure that you always get
the full set of rows.  The unique key should be one of the columns being selected.

    my $rows = $yar->domain->search_all({unique_key => 'domain'})->data->{'rows'};

=item transfer_in_request

Runs domain.transfer_in_request.  Used for initiating
a transfer.  When called, the passed information is
verified, the Admin contact is looked up, and an email
is sent to the Admin contact email address to inform
them of the transfer request.

    my $resp = $yar->domain->transfer_in_request({
        user_id => $user_id,
        domain  => $domain,
    });

    # $resp->data = {
    #     transfer_in_id => $unique_transfer_in_id,
    #     admin_email    => $admins_email,
    #     user_id        => $user_id,
    #     order_id       => $order_id,
    #     invoice_id     => $invoice_id,
    #     contact_id_registrant => $reg_id,
    #     contact_id_admin      => $admin_id,
    #     contact_id_billing    => $bill_id,
    #     contact_id_tech       => $tech_id,
    # };

The passed user_id is used to associate the transfer to a user.
If the transfer belongs to a new user, the new user information
can be passed in a "user" hash.  The newly created user_id
is returned in the output.  See the user->create method for
possible options.

    my $resp = $yar->domain->transfer_in_request({
        user   => {
            username   => $username, # username is optional
            password   => '123qwe',  # password may be MD5'ed
            email      => 'foo@my.company.com',
            phone      => '+1.8017659400',
            first_name => 'George',
            last_name  => 'Jones',
        },
        domain => $domain,
    });

Contact ids or contact info that will be used for the domain once the
transfer has taken place can be passed in during this phase.  If the
domain is a com or net domain you are required to pass in the contact
information.  On all other domain types the YAR service will attempt
to get the information from the registries (you may still pass the new
contacts if you like).  You can pass in information for the
registrant, admin, billing, and tech contacts in the same ways listed
in the domain->register method.

Sample transfer_in_request:

    my $resp = $yar->domain->transfer_in_request({
        domain     => $domain,
        user_id    => $user_id,
        registrant => {
            first_name   => 'George',
            last_name    => 'Jones',
            organization => 'My Company Test',
            email        => 'foo@my.company.com',
            street1      => 'Techway',
            city         => 'Provo',
            province     => 'UT',
            postal_code  => '84606',
            country      => 'US',
            phone        => '+1.8017659400',
        },
        admin => {contact_id => 'registrant'},
        contact_id_billing => 'registrant',
        contact_id_tech    => 'FAST-12312',
    });

If the registrar would like to handle sending the admin
email themselves, the "skip_send_email" flag can be passed.
In this case the transfer_in verification_id will be returned
in the data.  This verification_id is normally sent to the
admin email and must be passed to the domain_transfer_in_approve
method.

    my $resp = $yar->domain->transfer_in_request({
        domain          => $domain,
        user_id         => $user_id,
        skip_send_email => 1,
    });

    # $resp->data = {
    #     transfer_in_id  => $unique_transfer_in_id,
    #     verification_id => $verification_id,
    # };

If the EPP auth_code is passed in it will be verified before sending
the admin email.  The epp_auth_code is required on org and info domain
during this phase.  If not passed here for all other domains domains it will
be required during the domain_transfer_in_approve command.

    my $resp = $yar->domain->transfer_in_request({
        domain        => $domain,
        user_id       => $user_id,
        epp_auth_code => $epp_auth_code,
    });

If the EPP auth_code is invalid, the type of error
will be transfer_blocked and the invalid_epp_auth_code
flag will be set.

    # $resp->data->{'flags'} = {
    #     invalid_epp_auth_code => $true_int_flag
    # };

If the domain is currently locked from transfer the
domain_locked flag will be set.

    # $resp->data->{'flags'} = {
    #     domain_locked => $true_int_flag
    # };

If you would like to test the data without actually causing
any transfer to occur, you can pass the validate_only flag.

    my $resp = $yar->domain->transfer_in_request({
        domain        => $domain,
        user_id       => $user_id,
        epp_auth_code => $epp_auth_code,
        validate_only => 1,
    });

    # $resp->data = {
    #     no_operation_taken => 1,
    #     validated          => 1,
    # };

You normally cannot transfer a domain you already own to yourself.  If
you are testing the transfer process you can pass the
"test_local_transfer" flag.  No registry operations will take place
but the normal transfer process will be followed.

=item transfer_in_approve

Runs domain.transfer_in_approve.  Used for verifying the
admin was notified of the transfer request, and then initiates
the transfer at the registry.  See the domain_transfer_in_request
for information on how the verification id is sent to the admin.

    my $resp = $yar->domain->transfer_in_approve({
        domain          => $domain,
        verification_id => $id_sent_to_admin,
    });

    # $resp->data = {};

If the EPP auth_code was not previously sent in the domain_transfer_in_request
method, it must be supplied at this point.

    my $resp = $yar->domain->transfer_in_approve({
        domain          => $domain,
        verification_id => $id_sent_to_admin,
        epp_auth_code   => $epp_auth_code,
    });

If you would like to test the data before actually initiating the transfer
you may pass the validate_only flag.

    my $resp = $yar->domain->transfer_in_approve({
        domain          => $domain,
        verification_id => $id_sent_to_admin,
        epp_auth_code   => $epp_auth_code,
        validate_only   => 1,
    });

    # $resp->data = {
    #     no_operation_taken => 1,
    #     validated          => 1,
    # };

=item transfer_in_finalize

Runs domain.transfer_in_finalize.  Used by the YAR service
to finish transfering domains into the service.  Takes a domain and
an operation.  The operation should be one of approve, reject, or
cancel.  An approve operation will only work if the
domain has been successfully transfered at the registry.  A reject
operation will only work if the domain is not currently in a
pending state.  (Both the approve and reject are to be used to
finalize the transfer of a domain that is already approved or rejected.
Generally they are only used to hasten the transfer process - the registrar
will run the command in time).
The cancel operation can be used to stop a transfer that has previously
been requested with transfer_in_request and approved with transfer_in_approve.

    my $resp = $yar->domain->transfer_in_finalize({
        domain    => $domain,
        operation => 'approve',
    });

    # $resp->data = {};

=item transfer_out_approve

Note that there is no transfer_out_request method.  Transfer out
may only be requested by another registrar.  The YAR service
will receive notification of the tranfer out request and will
take appropriate action.

Runs domain.transfer_out_approve.  If an out going transfer
request notification is received, the Registrant and Admin
contacts will be sent an email informing them that the transfer
is about to take place and will take place if action is not taken
within a few days.  The email also contains a verification id
and link that can used to hasten the transfer process.  It also
gives them a link that can be used to reject the transfer.  These
links are configurable by the reseller.

To approve the transfer either of the following will do:

    my $resp = $yar->domain->transfer_out_approve({
        domain          => $domain,
    });

    # $resp->data = {};

    # OR

    my $resp = $yar->domain->transfer_out_approve({
        domain          => $domain,
        verification_id => $id_sent_to_admin,
    });

    # $resp->data = {};

The verification_id is not required - but is suggested so
that the registrant and admin can be identified properly.  Both
the admin and the registrant will receive the same verification
id.

If you would like to verify the information without actually
accepting the transfer, you can pass the validate_only flag.

    my $resp = $yar->domain->transfer_out_approve({
        domain          => $domain,
        verification_id => $id_sent_to_admin,
        validate_only   => 1,
    });

    # $resp->data = {
    #     no_operation_taken => 1,
    #     validated          => 1,
    # };

=item transfer_out_reject

Runs domain.transfer_out_approve.  All passed arguments
are the same as for domain_transfer_out_approve.  This
command is used for rejecting a requested transfer.

=item transfer_status

Check status on a previously requested transfer request.

    my $resp = $yar->domain->transfer_status({
        domain=> $domain,
    });

=item update

Runs domain.update.  Used for updating nameservers, contacts,
and locking on domains.

    my $resp = $yar->domain->update({
        domain      => $domain,
        domain_lock => 0,
    });

=item whois

Runs domain.whois.  Used for getting all whois information for
a domain that is registered through the YAR service.  Returns an
error if the domain is not installed on the YAR service.

    my $resp = $yar->domain->update({
        domain      => $domain,
    });

=back

=head2 INVOICE METHODS

=over 4

=item create

Runs invoice.create.  Can create a new invoice for a user.
Generally you will not call this method as the domain.register,
domain.transfer, and domain.renew methods can create the orders
for you automatically.  See the YAR API documetation.

=item delete

Runs invoice.delete.  Deletes an invoice that has not been
completed and that has 0 or more orders that have not
been completed.  Generally only used during testing.

=item info

Runs invoice.info.  Returns information associated with
the invoice.

    my $resp = $yar->invoice->info({invoice_id => $invoice_id});

=item search

Runs invoice.search.  Allows for searching through invoices.

    my $rows = $yar->invoice->search({
         select => ['invoice_id', 'date_completed'],
         where  => [{
             field => "date_completed",
             op => '>',
             value => '2007-03-01',
         }],
     })->data->{'rows'};

=item search_all

Same as search - but automatically assembles rows from queries that
return on multiple pages.

=back

=head2 OFFER METHODS

=over 4

=item info

Runs offer.info.  Returns information associated with
the offer.

    my $resp = $yar->offer->info({offer_id => $offer_id});

=item search

Runs offer.search.  Allows for searching through offers.

    my $rows = $yar->offer->search({
        select => [qw(duration offer_id agent_price)],
        where  => [
            {field => 'tld', value => 'com'},
            {field => 'service_code', value => 'domain_reg'}
        ],
    })->data->{'rows'};

=item search_all

Same as search - but automatically assembles rows from queries that
return on multiple pages.

=back

=head2 ORDER METHODS

=over 4

=item create

Runs order.create.  Can create a new order for a user.
Generally you will not call this method as the domain.register,
domain.transfer, and domain.renew methods can create the orders
for you automatically.  See the YAR API documetation.

=item delete

Runs order.delete.  Deletes an order that has not been
completed and that does not have a domain or other service
associated with it.  Generally only used during testing.

=item info

Runs order.info.  Returns information associated with
the order.

    my $resp = $yar->order->info({order_id => $order_id});

=item search

Runs order.search.  Allows for searching through orders.

    my $rows = $yar->order->search({
         select => ['order_id', 'date_completed'],
         where  => [{
             field => "date_completed",
             op => '>',
             value => '2007-03-01',
         }],
         rows_per_page => 10,
         order_by => ['date_completed'],
     })->data->{'rows'};

=item search_all

Same as search - but automatically assembles rows from queries that
return on multiple pages.

=back

=head2 USER METHODS

=over 4

=item create

Runs user.create.  Used to install a new user.

    $yar->user->create($args);
    $yar->user_create($args);

    my $resp = $yar->user->create({
        username   => $username, # username is optional
        password   => '123qwe',  # password may be MD5'ed
        email      => 'foo@my.company.com',
        phone      => '+1.8017659400',
        first_name => 'George',
        last_name  => 'Jones',
    });

    # $r->data = {
    #     user_id => 789553
    # };

The username is optional but must be unique on any particular
agent.

The password may be 1 to 30 characters.  It will be used to
give the user access to manage there domains at the YAR service
provider (depending upon the agent contract).  Either the password
or the md5 of the password may be passed.

The phone number must be in the '+1.8885551234' format.  You can
use the util->phone method to clean up the phone number.

=item delete

Runs user.delete.  Used to delete a user.

    $resp = $yar->user_delete({
        username => $username,
    });

    # $resp->data = {
    #     n_rows => 1,
    # };

If the user is already deleted, a true response
will be returned but n_rows will be 0.

Either the username or the user_id may be used to select
the user to delete.

A user cannot be deleted if it has associated domains,
contacts, invoices, orders, or domain revenue history.

=item info

Runs user.info.  Used to return the information of a user.  May
pass either the username or the user_id.

    $resp = $yar->user_info({
        username => $username, # can pass user_id instead
    });

    # $resp->data = {
    #     agent_id     => 145654,
    #     date_created => "2006-09-13 20:53:51",
    #     date_created_epoch => "1158180831",
    #     email        => "foo\@fastdomain.com",
    #     first_name   => "George",
    #     last_name    => "Jones",
    #     password     => "123qwe",
    #     phone        => "+1.8017659400",
    #     user_id      => 789459,
    #     username     => "01_user.t"
    # };

If a user does not exist, then the response $resp will be defined
but false.

    $resp = $yar->user_info({
        user_id => 1, # user_id 1 doesn't exist
    });

    # $resp is false
    # $resp->is_fault is true
    # $resp->code eq 'not_found'

=item search

Runs user.search.  Used for searching for users.

    my $rows = $yar->user->search({
         select => ['user_id', 'count(*)'],
         where  => [{field => "username", op => 'IS NULL'},
                    {field => "password", op => '=', value => ''},
                  ],
         group_by => ['user_id'],
         order_by => ['count(*)', 'user_id'],
    })->data->{'rows'};

See the full YAR API documentation for the list of
possible search capabilities.

=item search_all

Same as search - but automatically assembles rows from queries that
return on multiple pages.

=item update

Runs user.update.  Used to update the user information.

    $resp = $yar->user_update({
        username => $username,
        password => 'ewq321',
        email    => 'bar@my.company.com',
    });

    # $resp->data = {
    #     n_rows => 1,
    # };

If the data was already updated, a true response
will be returned but n_rows will be 0.

Either the username or the user_id may be used to
select the user to update.  Any of the fields submitted
during the user_create may be updated.

The username can be updated by submitting both the user_id
as well as the new username.

    $resp = $yar->user_update({
        user_id  => $user_id,
        username => $new_username,
    });

    # $resp->data = {
    #     n_rows => 1,
    # };

=back

=head2 UTIL METHODS

=over 4

=item balance

Runs util.balance.  Can be used to get the current balance for the registrar.

    $yar->util->balance;
    $yar->util_balance;
    $yar->balance; # special direct method

    my $balance = $yar->util->balance->data->{'balance'};

=item noop

Runs util.noop.  Used as a non-operation command to test for connectivity.

    $yar->util->noop;
    $yar->util_noop;
    $yar->noop; # special direct method

    my $resp = $yar->noop;

    # $resp will be true but $resp->data will be empty

Noop also has a basic echo feature that will return an arrayref of passed argument
keys and values.  This can be used for testing data encoding.

=item phone

Runs util.phone.  Can be used to pre-validate and cleanup phone numbers.

    $yar->util->phone($args);
    $yar->util_phone($args);

    my $resp = $yar->util->phone({country => 'USA', phone => '(801) 765-9400'});

    # $resp->data contains {country => 'US', phone => '+1.8017659400'}

An optional flag "allow_anything" may be passed which will return the phone number
in a state that will pass later validation - even if it doesn't appear to be a valid
number.

=item server_time

Returns the current time on the YAR server.  The time returned is in the GMT timezone.

    $yar->util->server_time;
    $yar->util_server_time;

    my $time = $yar->util->server_time->data->{'server_time'};

=back

=head2 WHOIS METHODS

=over 4

=item info

Parses the whois output into various useful fields.

    my $resp = $yar->whois->info({domain => $domain});

    # $resp->data = {
    #   domain     => $domain,
    #   creation   => [date],
    #   expiration => [date],
    #   obtained   => [date],
    #   privacy    => { 0 | 1 },
    #   adminemail    => ...,
    #   adminname     => ...,
    #   adminstreet   => ...,
    #   admincity     => ...,
    #   adminprovince => ...,
    #   adminpostal   => ...,
    #   admincountry  => ...,
    #   adminphone    => ...,
    #   adminfax      => ...,
    # }

=item raw

If you just need the raw whois string or wish to parse the output yourself
instead of using the whois_info method, use this to return the entire string.
Note: This informtaion is cached on the server in order to help reduce whois
query loads for external registrars.

    my $resp = $yar->whois_raw({
        domain          => $domain,
    });

    # $resp->data = {
    #   domain     => $domain,
    #   obtained   => [date],
    #   raw        => $whois_string,
    # }

=back

=head1 AUTHOR

Paul Seamons <paul@fastdomain.com>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.

=cut
