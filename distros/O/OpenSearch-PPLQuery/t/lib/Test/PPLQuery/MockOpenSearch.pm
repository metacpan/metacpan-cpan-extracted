package Test::PPLQuery::MockOpenSearch;

use v5.36;

use HTTP::Daemon ();
use HTTP::Response ();
use Cpanel::JSON::XS ();

sub start {
    my $daemon = HTTP::Daemon->new(LocalAddr => '127.0.0.1', LocalPort => 9200, ReuseAddr => 1)
        or die "Cannot start mock OpenSearch on 127.0.0.1:9200: $!\n";
    pipe my $reader, my $writer or die "Cannot create mock OpenSearch readiness pipe: $!\n";
    my $pid = fork;
    die "Cannot fork mock OpenSearch: $!\n" if !defined $pid;
    if ($pid == 0) {
        close $reader;
        $SIG{TERM} = sub { exit 0 };
        print {$writer} "ready\n";
        close $writer;
        my %indices;
        while (my $connection = $daemon->accept) {
            while (my $request = $connection->get_request) {
                $connection->send_response(handle_request($request, \%indices));
            }
            $connection->close;
            undef $connection;
        }
        exit 0;
    }
    close $writer;
    my $ready = <$reader>;
    close $reader;
    die "Mock OpenSearch failed to start\n" if !defined($ready) || $ready ne "ready\n";
    return bless {pid => $pid}, __PACKAGE__;
}

sub stop {
    my ($self) = @_;
    return if !defined $self->{pid};
    kill 'TERM', $self->{pid};
    waitpid($self->{pid}, 0);
    delete $self->{pid};
}

sub handle_request {
    my ($request, $indices) = @_;
    my $path = $request->uri->path;
    return json_response(200, {version => {distribution => 'opensearch'}}) if $request->method eq 'GET' && $path eq '/';
    if ($request->method eq 'PUT' && $path =~ m{\A/([^/]+)\z}) {
        $indices->{$1} = {};
        return json_response(200, {acknowledged => Cpanel::JSON::XS::true});
    }
    if ($request->method eq 'DELETE' && $path =~ m{\A/([^/]+)\z}) {
        delete $indices->{$1};
        return json_response(200, {acknowledged => Cpanel::JSON::XS::true});
    }
    if ($request->method eq 'PUT' && $path =~ m{\A/([^/]+)/_doc/([^/]+)\z}) {
        my ($index, $id) = ($1, $2);
        my $document = eval { Cpanel::JSON::XS->new->utf8(1)->decode($request->content) };
        return json_response(400, {error => {type => 'parse_exception', reason => 'invalid document'}}) if !$document;
        $indices->{$index}{$id} = $document;
        return json_response(201, {result => 'created'});
    }
    if ($request->method eq 'POST' && $path eq '/_plugins/_ppl') {
        my $payload = eval { Cpanel::JSON::XS->new->utf8(1)->decode($request->content) };
        return json_response(400, {error => {type => 'parse_exception', reason => 'invalid PPL request'}}) if !$payload;
        return run_ppl($payload->{query}, $indices);
    }
    return json_response(404, {error => {type => 'not_found', reason => 'mock endpoint not found'}});
}

sub run_ppl {
    my ($query, $indices) = @_;
    if ($query =~ /\bfieldz\b/i) {
        return json_response(400, {error => {type => 'parse_exception', reason => "mismatched input 'fieldz' <-- HERE"}, status => 400});
    }
    if ($query =~ /\Adescribe\s+([\w.-]+)/i) {
        my $index = $1;
        my %fields;
        for my $document (values %{$indices->{$index} // {}}) {
            $fields{$_} = 'keyword' for keys %$document;
        }
        return json_response(200, {schema => [{name => 'COLUMN_NAME', type => 'keyword'}, {name => 'TYPE_NAME', type => 'keyword'}], datarows => [map { [$_, $fields{$_}] } sort keys %fields]});
    }
    my ($index) = $query =~ /\bsource\s*=\s*([\w.-]+)/i;
    my @documents = values %{$indices->{$index // ''} // {}};
    if ($query =~ /\bwhere\s+city\s*=\s*'([^']*)'/i) {
        @documents = grep { defined($_->{city}) && $_->{city} eq $1 } @documents;
    }
    my ($fields) = $query =~ /\bfields\s+([^\r\n|]+)/i;
    my @fields = $fields ? map { s/^\s+|\s+$//gr } split /,/, $fields : sort keys %{ $documents[0] // {} };
    return json_response(200, {schema => [map { {name => $_, type => 'keyword'} } @fields], datarows => [map { my $document = $_; [map { $document->{$_} } @fields] } @documents]});
}

sub json_response {
    my ($status, $document) = @_;
    my $response = HTTP::Response->new($status);
    $response->header('Content-Type' => 'application/json; charset=utf-8');
    $response->content(Cpanel::JSON::XS->new->utf8(1)->canonical(1)->encode($document));
    return $response;
}

1;
