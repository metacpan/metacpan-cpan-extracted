package Review::Helper::Server;
use v5.36;

our $VERSION = '0.001';

use Carp qw/croak/;
use Encode qw/decode FB_DEFAULT/;
use File::Spec();
use Plack::Request();
use Router::Simple();
use Socket();
use Sys::Hostname();

use Review::Helper();
use Review::Helper::DB();
use Review::Helper::Feedback();
use Review::Helper::Registry();
use Review::Helper::VCS();
use Review::Helper::Split();
use Review::Helper::Util qw/json_encode json_decode/;
use Cpanel::JSON::XS();

# JSON columns come out of the database as character strings, not UTF-8 bytes.
my $COLUMN_JSON = Cpanel::JSON::XS->new;

use Object::HashBase qw{
    <db_path
    <db
    <repo
    <share_dir
    <router
    <reviewer
    <allow_hosts
    <token
};

my %CONTENT_TYPES = (
    css  => 'text/css; charset=utf-8',
    gif  => 'image/gif',
    html => 'text/html; charset=utf-8',
    ico  => 'image/x-icon',
    jpeg => 'image/jpeg',
    jpg  => 'image/jpeg',
    js   => 'text/javascript; charset=utf-8',
    json => 'application/json; charset=utf-8',
    md   => 'text/plain; charset=utf-8',
    png  => 'image/png',
    svg  => 'image/svg+xml',
    txt  => 'text/plain; charset=utf-8',
    webp => 'image/webp',
);

my %IMAGE_TYPES = map { ($_ => $CONTENT_TYPES{$_}) } qw/gif ico jpeg jpg png svg webp/;

my @ROUTES = (
    [GET  => '/',                                           'page_index'],
    [GET  => '/static/*',                                   'page_static'],
    [GET  => '/api/review',                                 'api_review'],
    [GET  => '/api/file/{id:[0-9]+}',                       'api_file'],
    [GET  => '/api/diff/{id:[0-9]+}',                       'api_diff'],
    [GET  => '/api/resolution/{id:[0-9]+}',                 'api_resolution'],
    [GET  => '/api/content/{revision:[0-9A-Za-z]{4,64}}/*', 'api_content'],
    [GET  => '/api/feedback',                               'api_feedback_export'],
    [POST => '/api/feedback',                               'api_feedback_add'],
    [POST => '/api/feedback/{id:[0-9]+}',                   'api_feedback_edit'],
    [POST => '/api/request',                                'api_request_add'],
    [POST => '/api/flag/{id:[0-9]+}',                       'api_flag'],
    [POST => '/api/close',                                  'api_close'],
);

my @FEEDBACK_TARGETS = qw/review commit file section line flag/;
my @REQUEST_TARGETS  = qw/review commit file section/;
my @REQUEST_KINDS    = qw/debate split/;
my @FEEDBACK_STATES  = qw/open addressed declined/;

my @COMMIT_FIELDS  = qw/id revision parent position merge_id topic subject message author authored what why how order_set/;
my @FILE_FIELDS    = qw/id path old_path status kind size_unit size_before size_after added removed changed read_position split_source what object_system paradigms/;
my @SECTION_FIELDS = qw/id position name package deleted added removed changed what/;
my @RANGE_FIELDS   = qw/ranges doc_ranges old_ranges/;

sub init($self) {
    croak "'db_path' is a required attribute" unless $self->{+DB_PATH};

    $self->{+DB}   //= Review::Helper::DB->open($self->{+DB_PATH});
    $self->{+REPO} //= Review::Helper::VCS->detect($self->{+DB_PATH});

    $self->{+SHARE_DIR} //= $self->_default_share_dir;
    $self->{+REVIEWER} = $self->_default_reviewer unless defined($self->{+REVIEWER}) && $self->{+REVIEWER} =~ m/\S/;

    $self->{+ALLOW_HOSTS} //= [];
    $self->{_hosts} = {map { ($self->_host_key($_) => 1) } qw/127.0.0.1 localhost ::1/, @{$self->{+ALLOW_HOSTS}}};

    my $router = $self->{+ROUTER} = Router::Simple->new;
    $router->connect($_->[1], {action => $_->[2]}, {method => $_->[0]}) for @ROUTES;
}

sub to_app($self) {
    return sub ($env) { $self->handle($env) };
}

sub handle($self, $env) {
    my $req = Plack::Request->new($env);
    return $self->_error(403, 'Requests must address 127.0.0.1, localhost or an allowed host') unless $self->_host_ok($req);

    my $requester = $self->_requester($req) // return $self->_unauthorized;
    return $self->_token_login($req) if $requester->{via} eq 'url';

    my $match  = $self->{+ROUTER}->match($env) or return $self->_error(404, 'Not found');
    my $action = delete $match->{action};

    if ($req->method eq 'POST') {
        return $self->_error(415, 'POST bodies must be application/json') unless $self->_json_type_ok($req);
        return $self->_error(403, 'Cross-origin requests are refused')    unless $self->_origin_ok($req);
    }

    my $res;
    my $ok  = eval { $res = $self->$action($req, $match); 1 };
    my $err = $@;
    return $res                                           if $ok;
    return $self->_error($err->{status}, $err->{message}) if ref($err) eq 'HASH' && $err->{status};

    # The details can name paths and internals, so only loopback clients see
    # them; the server's own STDERR always gets them.
    warn $err;
    return $self->_error(500, "Internal error: $err") if $self->is_loopback($req->address);
    return $self->_error(500, 'Internal error; the details are in the server output');
}

# {{{ Pages and assets

sub page_index($self, $req, $match) {
    return $self->_send_file(File::Spec->catfile($self->{+SHARE_DIR}, 'ux', 'html', 'index.html'));
}

# Only the page's own assets: ux/ also holds its tests and agent notes.
sub page_static($self, $req, $match) {
    my $rel = $match->{splat}[0];
    $self->_fail(404, 'Not found') unless $self->_safe_path($rel) && $rel =~ m{\A(?:css|js|html)/};
    return $self->_send_file(File::Spec->catfile($self->{+SHARE_DIR}, 'ux', split m{/} => $rel));
}

# }}} Pages and assets

# {{{ Read routes

sub api_review($self, $req, $match) {
    my $db     = $self->{+DB};
    my $it     = $self->_iteration($req);
    my $review = $db->review;
    my $export = Review::Helper::Feedback->new(db => $db)->export;
    my %seen;
    push @{$seen{$_->{flag}}} => {reviewer => $_->{reviewer}, at => $_->{at}} for @{$db->flag_seen($it->{number})};

    my @commits = map {
        my $commit = $_;
        my $files  = $db->files($commit->{id});

        # Only merges have resolutions, and a merge lists no files.
        my $resolved = !@$files && @{$self->_resolutions($commit->{revision}, $it)};
        +{
            (map { ($_ => $commit->{$_}) } @COMMIT_FIELDS),
            files      => [map { +{%{$self->_file_json($_)}, section_names => $self->_section_names($_)} } @$files],
            resolution => $resolved ? \1 : \0,
        };
    } @{$db->commits($it->{number})};
    my $flags = $db->flags($it->{number});
    my $steps = $db->guide_steps($it->{number});

    return $self->_json({
        standard_version => Review::Helper->STANDARD_VERSION,
        review           => {map { ($_ => $review->{$_}) } qw/id title source state/},
        identity         => $self->_identity,
        iteration        => $it->{number},
        iterations       => [map { +{$self->_iteration_json($_)} } @{$db->iterations}],
        summary          => {map { ($_ => $it->{$_}) } qw/what why how/},
        commits          => \@commits,
        flags            => [map { +{%{$self->_flag_json($_)}, seen => $seen{$_->{id}} // []} } @$flags],
        guide            => [map { $self->_guide_json($_) } @$steps],
        journal          => [map { $self->_journal_json($_) } @{$db->journal_entries($it->{number})}],
        content_kinds    => $self->_content_kinds(\@commits, $flags, $steps),
        feedback         => $export->{feedback},
        requests         => $export->{requests},
    });
}

# A split stores its untouched sections too, for the next split to start
# from; the page shows only the sections the commit changed.
sub api_file($self, $req, $match) {
    my ($file, $commit) = $self->_file_and_commit($match->{id});
    my $sections = [map { $self->_section_json($_) } $self->_touched_sections($file)];
    $self->_add_doc_html($file, $commit, $sections) if $file->{kind} eq 'perl';

    return $self->_json({
        file     => $self->_file_json($file),
        commit   => $commit->{revision},
        parent   => $commit->{parent},
        sections => $sections,
    });
}

sub api_diff($self, $req, $match) {
    my ($file, $commit) = $self->_file_and_commit($match->{id});
    my $section = $req->query_parameters->get('section');
    $self->_fail(400, "Invalid section id") if defined($section) && $section !~ m/\A[0-9]+\z/;

    require Review::Helper::Diff;
    my $repo  = $self->{+REPO};
    my $bytes = $repo->range_diff($commit->{parent} // $repo->empty_revision, $commit->{revision}, $file->{path}, $file->{old_path});
    my $diff  = Review::Helper::Diff::parse_diff(decode('UTF-8', $bytes, FB_DEFAULT));
    my $hunks = $diff->{hunks};

    if (defined $section) {
        my $sections = [map { $self->_section_json($_) } @{$self->{+DB}->sections($file->{id})}];
        my ($index) = grep { $sections->[$_]{id} == $section } 0 .. $#$sections;
        $self->_fail(404, "File $file->{id} has no section $section") unless defined $index;

        $hunks = Review::Helper::Diff::section_hunks($hunks, $self->_new_lines($file, $commit) // [], $sections, $index);
    }

    return $self->_json({binary => $diff->{binary} ? \1 : \0, hunks => $hunks});
}

sub api_resolution($self, $req, $match) {
    my $db     = $self->{+DB};
    my $commit = $db->commit_entry($match->{id}) // $self->_fail(404, "No commit with id $match->{id}");
    $self->_fail(404, "Commit $match->{id} is not in this repository") unless $self->{+REPO}->has_revision($commit->{revision});
    $self->_fail(404, "Commit $match->{id} is not a merge")            unless @{$self->{+REPO}->parents($commit->{revision})} > 1;

    return $self->_json({commit => $commit->{revision}, files => $self->_resolutions($commit->{revision}, $db->iteration($commit->{iteration}))});
}

sub api_content($self, $req, $match) {
    my $rel = $match->{splat}[0];
    $self->_fail(404, 'Not found') unless $self->_safe_path($rel);

    my $bytes = $self->{+REPO}->file($match->{revision}, decode('UTF-8', $rel, FB_DEFAULT));
    $self->_fail(404, 'No such file at that commit') unless defined $bytes;

    my ($ext) = $rel =~ m/\.([^.\/]+)\z/;
    my $type = $IMAGE_TYPES{lc($ext // '')};
    $type //= index(substr($bytes, 0, 8000), "\0") < 0 ? 'text/plain; charset=utf-8' : 'application/octet-stream';

    # Reviewed content is untrusted: never let a browser run it on this origin.
    return [
        200,
        [
            'Content-Type'            => $type,
            'X-Content-Type-Options'  => 'nosniff',
            'Content-Security-Policy' => 'sandbox',
        ],
        [$bytes],
    ];
}

sub api_feedback_export($self, $req, $match) {
    return $self->_json(Review::Helper::Feedback->new(db => $self->{+DB})->export);
}

# }}} Read routes

# {{{ Write routes

# Feedback on a flag also marks the flag seen by its writer.
sub api_feedback_add($self, $req, $match) {
    my $in = $self->_body($req);
    my $it = $self->_post_iteration($in);
    my ($flag, %anchor) = ($in->{target} // '') eq 'flag' ? $self->_flag_anchor($in, $it) : (undef, $self->_anchor($in, $it, \@FEEDBACK_TARGETS));

    if ($anchor{target} eq 'line') {
        my $line = $in->{line};
        $self->_fail(400, "'line' must be a positive integer") unless defined($line) && !ref($line) && $line =~ m/\A[1-9][0-9]*\z/;
        $self->_fail(400, "'side' must be 'old' or 'new'")     unless $self->_one_of($in->{side}, qw/old new/);
        @anchor{qw/line side/} = ($line + 0, $in->{side});
    }

    my $body = $self->_text($in, 'body', 1);
    my $db   = $self->{+DB};
    my $id   = $db->txn(sub {
        $db->set_flag_seen($flag->{id}, $self->{+REVIEWER}, 1) if $flag;
        $db->add_feedback(%anchor, iteration => $it->{number}, body => $body, reviewer => $self->{+REVIEWER});
    });
    return $self->_json({id => $id});
}

sub api_feedback_edit($self, $req, $match) {
    my $in = $self->_body($req);
    my %fields;
    $fields{body} = $self->_text($in, 'body', 1) if exists $in->{body};
    if (exists $in->{status}) {
        $self->_fail(400, "'status' must be one of: @FEEDBACK_STATES") unless $self->_one_of($in->{status}, @FEEDBACK_STATES);
        $fields{status} = $in->{status};
    }
    $self->_fail(400, "Give 'body', 'status', or both") unless %fields;

    my $db = $self->{+DB};
    my $fb = $db->feedback($match->{id}) // $self->_fail(404, "No feedback with id $match->{id}");
    $self->_fail(403, "Only $fb->{reviewer} can edit this feedback") unless $self->_may_edit($fb);
    $db->update_feedback($fb->{id}, %fields);
    return $self->_json({});
}

sub api_request_add($self, $req, $match) {
    my $in   = $self->_body($req);
    my $it   = $self->_post_iteration($in);
    my $kind = $in->{kind};
    $self->_fail(400, "'kind' must be one of: @REQUEST_KINDS") unless $self->_one_of($kind, @REQUEST_KINDS);

    my %anchor = $self->_anchor($in, $it, \@REQUEST_TARGETS);
    $self->_fail(400, "A '$kind' request must target a file") if $kind ne 'debate' && $anchor{target} ne 'file';
    $self->_check_splittable($it, \%anchor) unless $kind eq 'debate';

    my $note = $self->_text($in, 'note', 0);
    my $id   = $self->{+DB}->add_request(%anchor, iteration => $it->{number}, kind => $kind, note => $note, reviewer => $self->{+REVIEWER});
    return $self->_json({id => $id});
}

# Set whether this server's reviewer has seen a flag. Returns who has.
sub api_flag($self, $req, $match) {
    my $in   = $self->_body($req);
    my $db   = $self->{+DB};
    my $flag = $db->flag($match->{id}) // $self->_fail(404, "No flag with id $match->{id}");
    $self->_fail(400, "'seen' must be true or false") unless Cpanel::JSON::XS::is_bool($in->{seen});

    $db->set_flag_seen($flag->{id}, $self->{+REVIEWER}, $in->{seen} ? 1 : 0);
    my $it = $db->commit_entry($flag->{commit_id})->{iteration};
    return $self->_json({
        seen => [map { +{reviewer => $_->{reviewer}, at => $_->{at}} } grep { $_->{flag} == $flag->{id} } @{$db->flag_seen($it)}],
    });
}

sub api_close($self, $req, $match) {
    my $registry = Review::Helper::Registry->new(repo => $self->{+REPO});
    $registry->close_review($self->{+DB}, $self->{+DB_PATH});
    return $self->_json({});
}

# }}} Write routes

sub _default_share_dir($self) { Review::Helper::Util::share_dir() }

sub _login($self) { scalar(getpwuid($<)) // getlogin() }

# REVIEW_HELPER_REVIEWER, else the user's VCS name and email, else the login,
# else "unknown".
sub _default_reviewer($self) {
    my $env = $ENV{REVIEW_HELPER_REVIEWER};
    return $env if defined($env) && $env =~ m/\S/;
    return $self->{+REPO}->user // $self->_login // 'unknown';
}

# Only the author edits their feedback; a row with no reviewer, written
# before reviewers were recorded, is anyone's.
sub _may_edit($self, $row) {
    my $by = $row->{reviewer};
    return !defined($by) || $by !~ m/\S/ || $by eq $self->{+REVIEWER};
}

sub _fail($self, $status, $message) { die {status => $status, message => $message} }

sub _json($self, $data, $status = 200) {
    return [$status, ['Content-Type' => 'application/json; charset=utf-8'], [json_encode($data)]];
}

sub _error($self, $status, $message) { $self->_json({error => $message}, $status) }

sub _one_of($self, $value, @allowed) {
    return 0 unless defined($value) && !ref($value);
    return !!grep { $_ eq $value } @allowed;
}

sub is_loopback($class, $addr) {
    return defined($addr) && $addr =~ m/\A(?:127\.[0-9.]+|::1|::ffff:127\.[0-9.]+)\z/i ? 1 : 0;
}

# Who is asking, as {via => ...}, or undef when no one we know. Without a
# token every client is let in (the server listens on loopback only). With
# one, a loopback client needs nothing; any other needs the token, in the URL
# (once) or in the cookie that URL sets. Tokens of their own, mapped to a
# reviewer, would be looked up here too.
sub _requester($self, $req) {
    my $token = $self->{+TOKEN};
    return {via => 'open'} unless defined $token;
    return {via => 'loopback'} if $self->is_loopback($req->address);

    my $given = $req->query_parameters->get('token');
    return {via => 'url'} if defined($given) && $self->_same_secret($given, $token);

    my $cookie = $req->cookies->{$self->_cookie_name($req)};
    return {via => 'cookie'} if defined($cookie) && $self->_same_secret($cookie, $token);
    return undef;
}

# Compares in time that depends only on the length, not on where they differ.
sub _same_secret($self, $given, $secret) {
    return 0 unless length($given) == length($secret);
    my $diff = 0;
    $diff |= ord(substr($given, $_, 1)) ^ ord(substr($secret, $_, 1)) for 0 .. length($secret) - 1;
    return $diff == 0 ? 1 : 0;
}

# Browsers share cookies across ports, so each server needs its own name or
# two open reviews log each other out.
sub _cookie_name($self, $req) { 'rh_token_' . ($req->env->{SERVER_PORT} // 0) }

# Trade the token in the URL for a cookie, and drop it from the address bar
# and history.
# The token URL goes to the page, whatever path and query came with it: the
# printed URL is the root, and nothing from the request reaches Location.
sub _token_login($self, $req) {
    my $jar = $self->_cookie_name($req) . "=$self->{+TOKEN}; Path=/; HttpOnly; SameSite=Lax";
    return [303, ['Location' => '/', 'Set-Cookie' => $jar, 'Cache-Control' => 'no-store', 'Content-Type' => 'text/plain; charset=utf-8'], ['']];
}

sub _unauthorized($self) {
    my $text = "This review server needs a token from another machine.\n" . "Open the URL review-helper printed when it started, the one ending in ?token=...;\n" . "it sets a cookie so this browser can use the page.\n";
    return [401, ['Content-Type' => 'text/plain; charset=utf-8', 'Cache-Control' => 'no-store'], [$text]];
}

sub _host_ok($self, $req) {
    my $host = $req->env->{HTTP_HOST} // return 0;
    $host =~ m/\A(?:\[([0-9A-Fa-f:.]+)\]|([^:\[\]]+))(?::[0-9]+)?\z/ or return 0;
    return $self->{_hosts}{$self->_host_key($1 // $2)} ? 1 : 0;
}

# One spelling per host: lower case, an IPv6 address without brackets and in
# its shortest form.
sub _host_key($self, $name) {
    $name = lc($name) =~ s/\A\[(.*)\]\z/$1/r;
    my $packed = $name =~ m/:/ ? Socket::inet_pton(Socket::AF_INET6(), $name) : undef;
    return $packed ? Socket::inet_ntop(Socket::AF_INET6(), $packed) : $name;
}

# A form on any other page could post here. A JSON body needs a CORS
# preflight this server never grants.
sub _json_type_ok($self, $req) {
    my $type = $req->content_type // return 0;
    return $type =~ m{\A\s*application/json\s*(?:;|\z)}i ? 1 : 0;
}

sub _origin_ok($self, $req) {
    my $origin = $req->env->{HTTP_ORIGIN} // return 1;
    my $host   = $req->env->{HTTP_HOST}   // return 0;
    return lc($origin) eq lc("http://$host") ? 1 : 0;
}

# A relative path with no empty, '.' or '..' segments and no NUL or backslash.
sub _safe_path($self, $rel) {
    return 0 unless defined($rel) && length($rel);
    return 0 if $rel =~ m{[\0\\]};
    return 0 if grep { $_ eq '' || $_ eq '.' || $_ eq '..' } split m{/} => $rel, -1;
    return 1;
}

sub _send_file($self, $file) {
    $self->_fail(404, 'Not found') unless -f $file;
    open(my $fh, '<:raw', $file) or die "Cannot open '$file': $!";
    my ($ext) = $file =~ m/\.([^.\/]+)\z/;
    return [200, ['Content-Type' => $CONTENT_TYPES{lc($ext // '')} // 'application/octet-stream'], $fh];
}

sub _iteration($self, $req) {
    my $number = $req->query_parameters->get('iteration');
    return $self->_find_iteration($number);
}

sub _post_iteration($self, $in) { $self->_find_iteration($in->{iteration}) }

sub _find_iteration($self, $number) {
    my $db = $self->{+DB};
    unless (defined $number) {
        return $db->latest_iteration // $self->_fail(404, 'The review has no iterations');
    }
    $self->_fail(400, "'iteration' must be a positive integer") if ref($number) || $number !~ m/\A[1-9][0-9]*\z/;
    return $db->iteration($number) // $self->_fail(404, "No iteration $number");
}

sub _body($self, $req) {
    my $raw = $req->content;
    my $data;
    my $ok = eval { $data = json_decode(length($raw) ? $raw : '{}'); 1 };
    $self->_fail(400, 'The request body must be a JSON object') unless $ok && ref($data) eq 'HASH';
    return $data;
}

sub _text($self, $in, $key, $required) {
    my $value = $in->{$key};
    return undef if !defined($value) && !$required;
    $self->_fail(400, "'$key' must be a non-empty string") unless defined($value) && !ref($value) && $value =~ m/\S/;
    return $value;
}

# Validate the target and anchor of new feedback or a request against the
# iteration; returns the columns to store.
sub _anchor($self, $in, $it, $targets) {
    my $target = $in->{target};
    $self->_fail(400, "'target' must be one of: @$targets") unless $self->_one_of($target, @$targets);
    return (target => $target) if $target eq 'review';

    my $db       = $self->{+DB};
    my $revision = $in->{commit};
    $self->_fail(400, "'commit' must be a commit's revision id") unless defined($revision) && !ref($revision);
    my $entries = $db->commits_by_revision($it->{number}, $revision);
    $self->_fail(400, "Commit '$revision' is not in iteration $it->{number}") unless @$entries;
    return (target => $target, revision => $revision, topic => $self->_topic($in, $revision, $entries)) if $target eq 'commit';

    my $path = $in->{path};
    $self->_fail(400, "'path' must be a string") unless defined($path) && !ref($path);
    my $file   = $self->_entry_file($entries, $path) // $self->_fail(400, "Commit '$revision' does not change '$path'");
    my %anchor = (target => $target, revision => $revision, path => $path);

    my $section = $in->{section};
    $self->_fail(400, "A section target needs 'section'") if $target eq 'section' && !defined($section);
    return %anchor unless defined $section;

    $self->_fail(400, "'section' must be an object with 'name' and 'package'") unless ref($section) eq 'HASH' && defined($section->{name}) && !ref($section->{name});
    my ($name, $package) = @{$section}{qw/name package/};
    my $known = grep { $_->{name} eq $name && ($_->{package} // '') eq ($package // '') } $self->_touched_sections($file);
    $self->_fail(400, "'$path' has no section '$name' with a change to show") unless $known;

    return (%anchor, section_name => $name, section_package => $package);
}

# A flag target: the iteration's flag with the note id given, anchored at
# its commit and path (and, for a whole-commit flag, its entry's topic, as a
# commit target is). Returns the flag row, then the columns to store.
sub _flag_anchor($self, $in, $it) {
    my $note = $in->{flag};
    $self->_fail(400, "'flag' must be a flag's note id") unless defined($note) && !ref($note);
    my $flag = $self->{+DB}->flag_by_note($it->{number}, $note) // $self->_fail(400, "Iteration $it->{number} has no flag '$note'");
    return ($flag, target => 'flag', flag => $note, flag_sentence => $flag->{sentence}, revision => $flag->{revision}, path => $flag->{path}, topic => defined($flag->{path}) ? undef : $flag->{topic});
}

# The topic a commit target names. A squashed iteration split into topics
# has one entry per topic, all with the head's revision, so the topic picks one;
# any other commit has one entry and no topic.
sub _topic($self, $in, $revision, $entries) {
    my $topic = $in->{topic};
    $self->_fail(400, "'topic' must be a string or null") if ref $topic;
    my ($entry) = grep { ($_->{topic} // "\0") eq ($topic // "\0") } @$entries;
    return $entry->{topic} if $entry;
    $self->_fail(400, "Commit '$revision' has no topic '$topic'") if defined $topic;
    $self->_fail(400, "Commit '$revision' is split into topics; give 'topic'");
}

# The file change of a path in a commit's entries: in a squashed iteration
# split into topics, the path is in the one topic holding it.
sub _entry_file($self, $entries, $path) {
    my $db = $self->{+DB};
    my ($file) = map { $db->file_by_path($_->{id}, $path) // () } @$entries;
    return $file;
}

# The names of the sections the page shows for a file, so it can tell
# section feedback it has no card for.
sub _section_names($self, $file) {
    return [map { +{name => $_->{name}, package => $_->{package}} } $self->_touched_sections($file)];
}

# The file's sections the commit changed, the only ones the page shows.
sub _touched_sections($self, $file) {
    my $db = $self->{+DB};
    return grep { $db->section_touched($_) } @{$db->sections($file->{id})};
}

# Only a file with lines on its new side can be split, and only when its
# commit added it or changed its lines: the files the fill sheet gives a
# split item (see Review::Helper::Sheet split_item).
sub _check_splittable($self, $it, $anchor) {
    my $file = $self->_entry_file($self->{+DB}->commits_by_revision($it->{number}, $anchor->{revision}), $anchor->{path});
    $self->_fail(400, "'$anchor->{path}' has no lines to split: it is deleted, an image, or binary") unless $file->{size_unit} eq 'lines' && $file->{status} ne 'D';
    return if $file->{status} eq 'A' || $file->{added} || $file->{removed} || $file->{changed};
    $self->_fail(400, "'$anchor->{path}' has nothing to split: a rename or mode change alone leaves its content as it was");
}

sub _file_and_commit($self, $id) {
    my $db     = $self->{+DB};
    my $file   = $db->file_change($id) // $self->_fail(404, "No file with id $id");
    my $commit = $db->commit_entry($file->{commit_id});
    return ($file, $commit);
}

# The file's lines after the commit, or undef when it has none.
sub _new_lines($self, $file, $commit) {
    return undef if $file->{status} eq 'D';
    my $bytes = $self->{+REPO}->file($commit->{revision}, $file->{path}) // return undef;
    return [split /\n/, decode('UTF-8', $bytes, FB_DEFAULT), -1];
}

# A Perl unit's documentation as HTML, for reading beside its summary. Only
# when every range starts as POD: a parser would drop comments after a =cut.
sub _add_doc_html($self, $file, $commit, $sections) {
    my @documented = grep { @{$_->{doc_ranges}} } @$sections or return;
    my $lines      = $self->_new_lines($file, $commit) // return;
    for my $section (@documented) {
        my @docs = map { join "\n" => @{$lines}[$_->[0] - 1 .. $_->[1] - 1] } @{$section->{doc_ranges}};
        next if grep { !m/\A=[a-zA-Z]/ } @docs;
        $section->{doc_html} = $self->_pod_html(join "\n\n" => @docs);
    }
    return;
}

# Reviewed POD is untrusted: no raw HTML targets, no links that leave the
# page (L<> renders as its text), and no ids that could clash with the page's.
sub _pod_html($self, $pod) {
    require Pod::Simple::XHTML;

    # A unit's documentation is an excerpt; an item needs a list around it.
    $pod = "=over 4\n\n$pod\n\n=back" if $pod =~ m/\A=item\b/;

    my $parser = Pod::Simple::XHTML->new;
    $parser->unaccept_targets(qw/html HTML/);
    $parser->html_header('');
    $parser->html_footer('');
    $parser->no_errata_section(1);
    $parser->complain_stderr(0);
    $parser->output_string(\my $html);
    $parser->parse_string_document("=pod\n\n$pod\n\n=cut\n");

    $html =~ s/<a\b[^>]*>/<a>/g;
    $html =~ s/ id="[^"]*"//g;
    return $html;
}

# Whose review this is, so a reader who opened someone else's port can tell.
sub _identity($self) {
    return {
        user     => $self->_login,
        host     => Sys::Hostname::hostname(),
        repo     => $self->{+REPO}->root,
        reviewer => $self->{+REVIEWER},
    };
}

# A merge's resolutions per file, as diff hunks; empty for a clean merge, for
# a commit that is not a merge or not in the repository, and when the VCS
# cannot show them. A revision never changes, so each is computed once per
# server; an absent commit is not cached, as it may be fetched while the
# server runs.
sub _resolutions($self, $revision, $it) {
    my $paths = $it->{paths};
    my $hit   = $self->{_resolutions}{$revision}{$paths // ''};
    return $hit if $hit;
    return [] unless $self->{+REPO}->has_revision($revision);
    return $self->{_resolutions}{$revision}{$paths // ''} = do {
        my $repo = $self->{+REPO};
        my @files;
        require Review::Helper::Diff;
        for my $change (@{$repo->resolution_changes($revision, defined($paths) ? $COLUMN_JSON->decode($paths) : undef)}) {
            my $bytes = $repo->resolution_diff($revision, @{$change}{qw/path old_path/});
            my $diff  = Review::Helper::Diff::parse_diff(decode('UTF-8', $bytes, FB_DEFAULT));
            push @files => {
                (map { ($_ => $change->{$_}) } qw/path old_path status/),
                binary => $diff->{binary} ? \1 : \0,
                hunks  => $diff->{hunks},
            };
        }
        \@files;
    };
}

# The kind of each file the page may show whole at a commit that did not
# change it (a guide view step, a flag), keyed "REV:PATH": the kind a file
# change would get, from its content. Content at a commit never changes, so a
# kind found is kept for later loads; a failure to read it gives plain text
# this time rather than failing the whole review.
sub _content_kinds($self, $commits, $flags, $steps) {
    my %changed = map {
        my $c = $_;
        map { ("$c->{revision}:$_->{path}" => 1) } @{$c->{files}}
    } @$commits;
    my @shown = (
        (map { [$_->{revision}, $_->{path}] } grep { defined $_->{path} } @$flags),
        (map { [$_->{commit},   $_->{path}] } grep { $_->{type} eq 'view' } map { $COLUMN_JSON->decode($_->{target}) } @$steps),
    );

    my $known = $self->{_content_kinds} //= {};
    my %kinds;
    for my $at (@shown) {
        my $key = join ':' => @$at;
        next if $changed{$key} || exists $kinds{$key};
        next if defined($kinds{$key} = $known->{$key});

        my $ok = eval {
            my $bytes = $self->{+REPO}->file(@$at);
            $kinds{$key} = $known->{$key} = defined($bytes) ? $self->_content_kind($at->[1], $bytes) : undef;
            1;
        };
        $kinds{$key} = 'text' unless $ok;
    }
    return \%kinds;
}

# The binary test git uses: a NUL in the first 8000 bytes.
sub _content_kind($self, $path, $bytes) {
    my ($first) = split /\n/, $bytes, 2;
    my $kind    = Review::Helper::Split->kind_for($path, $first);
    return $kind ne 'image' && index(substr($bytes, 0, 8000), "\0") >= 0 ? 'binary' : $kind;
}

sub _iteration_json($self, $it) {
    return (
        (map { ($_ => $it->{$_}) } qw/number base head created note/),
        available => $self->{+REPO}->has_revision($it->{head}) ? \1 : \0,
    );
}

sub _file_json($self, $file) {
    return {map { ($_ => $file->{$_}) } @FILE_FIELDS};
}

sub _section_json($self, $section) {
    return {
        (map { ($_ => $section->{$_}) } @SECTION_FIELDS),
        (map { ($_ => $COLUMN_JSON->decode($section->{$_})) } @RANGE_FIELDS),
    };
}

sub _flag_json($self, $flag) {
    return {
        commit  => $flag->{revision},
        entry   => $flag->{commit_id},
        pending => $flag->{pending} ? \1 : \0,
        map { ($_ => $flag->{$_}) } qw/id note_id path line_start line_end color color_reason kind sentence detail/,
    };
}

sub _journal_json($self, $entry) {
    return {map { ($_ => $entry->{$_}) } qw/id kind path unit sentence detail created/};
}

sub _guide_json($self, $step) {
    return {
        position   => $step->{position},
        target     => $COLUMN_JSON->decode($step->{target}),
        highlight  => $COLUMN_JSON->decode($step->{highlight}),
        commentary => $step->{commentary},
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Review::Helper::Server - The review web app.

=head1 DESCRIPTION

A PSGI application serving one review file: the static page from the share
directory and a JSON API over the review and its repository. Diffs and file
contents are read live from the repository (L<Review::Helper::VCS>).

Every request must carry a C<Host> header naming C<127.0.0.1>, C<localhost>,
C<[::1]>, or one of C<allow_hosts> (any port, any case, an IPv6 address in
any spelling); anything else gets 403. This keeps DNS-rebinding pages out:
they reach the server under the attacker's own name.

Without a C<token> (the server listens on loopback only) nothing more is
asked: any local user can open the page, which shows whose review it is.
With one, a client whose address is loopback still needs nothing; any other
needs the token. A request carrying C<?token=TOKEN> is answered with 303 to
C</>, whatever its path and the rest of its query, setting the C<rh_token_PORT>
cookie (C<HttpOnly>, C<SameSite=Lax>, C<Path=/>; PORT is the server's
port, so servers on different ports keep separate cookies); later requests
carry that cookie. Anything else gets 401 and a short text page saying to
open the printed URL. Tokens are compared in constant time. A reverse proxy
on this machine reaches the server from loopback, so everyone who can reach
the proxy gets in without the token and sees internal error details.

POST requests must have C<Content-Type: application/json> (415 otherwise),
and an C<Origin> header, when present, must be C<http://> plus the C<Host>
(403 otherwise). This keeps pages served from other local ports from
posting to the API.

=head2 Routes

    GET  /                    the page (ux/html/index.html in the share directory)
    GET  /static/PATH         a file under ux/css, ux/js or ux/html in the share directory
    GET  /api/review          the review, an iteration and everything in it
    GET  /api/file/ID         a file change and the sections its commit changed
    GET  /api/diff/ID         the file's hunks; ?section=ID gives that section's diff
    GET  /api/resolution/ID   a merge's conflict resolutions, per file
    GET  /api/content/REV/PATH  a file's raw content at a revision
    GET  /api/feedback        the feedback export, as review-helper feedback prints it
    POST /api/feedback        add feedback: {target, commit, topic, path, section, flag, line, side, body}
    POST /api/feedback/ID     edit feedback: {body, status}, either or both
    POST /api/request         add a request: {kind, target, commit, topic, path, section, note}
    POST /api/flag/ID         mark a flag seen or not: {seen}
    POST /api/close           close the review

C<GET /api/review> takes C<?iteration=N> (default: the latest). The POST
routes for feedback and requests accept an optional C<iteration> in the body,
also defaulting to the latest; the commit and path given must exist in it, and
a section given must be one the commit changed (touched), the only sections
the page shows. In a squashed iteration split into topics, every topic's entry
has the head's revision: a C<commit> target names its C<topic>, or none for the
files not yet in a topic (400 without one otherwise), and a path picks the
topic holding it; C<topic> is stored only on a C<commit> target, or a
C<flag> target on a whole-commit flag. Bad input
gets 400 and C<< {"error": "..."} >>; unknown ids get 404. A C<split> request
must name a file the fill sheet gives a split item: a text file its commit
added or changed a line of, not one only renamed or with only its mode changed
(400 otherwise). A C<flag> target gives only C<flag>, the note id of a flag
of the iteration; the server stores that flag's sentence, commit and path
(and topic, for a whole-commit flag) with it, and marks the flag seen by its
reviewer.

C<GET /api/review> also gives C<standard_version>, the version of the standard
this server implements (L<Review::Helper/STANDARD_VERSION>); C<identity>:
C<user> (the login name the server runs as), C<host> (the host name), C<repo>
(the repository root) and C<reviewer> (see C<reviewer> below), and C<journal>:
the iteration's journal entries, oldest first, each with C<id>, C<kind>,
C<path>, C<unit>, C<sentence>, C<detail> and C<created>. Each flag carries
C<seen>: the reviewers who have seen it, as C<< [{reviewer, at}] >>, oldest
first; C<pending>, true while the agent has still to decide on a flag carried
onto changed code; and C<entry>, the id of the commit entry it is on
(C<commit> is its revision id, which every topic of a squashed iteration
shares). Each commit carries its C<topic>, null outside a squashed iteration
split into topics. C<content_kinds> gives the kind of each file the page may
show whole at a commit that did not change it (a C<view> guide step's, a
flag's), as C<< {"REV:PATH": kind} >>: the kind a file change would get (see
L<Review::Helper::Split>), C<binary> for content with a NUL byte in its first
8000 bytes, null when the file is not at that commit, and C<text> when it
cannot be read.

New feedback and requests record the server's C<reviewer>.
C<POST /api/feedback/ID> edits only feedback that reviewer wrote, or feedback
with no reviewer (written before reviewers were recorded); anyone else's gets
403 and C<< {"error": "..."} >>. There is no route to delete feedback or to
edit a request.

C<POST /api/flag/ID> takes C<seen>, true or false: it sets or removes the
reviewer's seen mark on flag ID (a mark already there keeps its time). It
returns C<< {seen} >> as above, and 404 for an unknown flag.

Each commit carries C<resolution>, true for a merge with resolutions
(L<Review::Helper::VCS/resolution_changes>): hand-made conflict resolutions
or other changes made in the merge. C<GET /api/resolution/ID> takes a commit id and returns
C<< {commit, files} >>, each file a C<path>, C<old_path>, C<status>, C<binary>
and C<hunks> as C</api/diff> gives them; ID must be a merge in the repository
(404 otherwise). When the VCS cannot show them, or the commit is not in the
repository, a merge has no resolutions. They are computed once per server
and kept, and follow the iteration's path specs.

Each file in C<GET /api/review> also has C<section_names>: C<name> and
C<package> of each section the page shows for it (those the commit changed),
so the page can tell section feedback it has no card for.

Feedback and request entries use the shape of the feedback export; requests
also carry C<iteration>, C<case_for> and C<case_against>. C<GET /api/review>
lists them from every iteration, whichever iteration is selected.

A section's diff is L<Review::Helper::Diff>'s C<section_hunks>: its whole
code and whole documentation, each hunk with a C<part> of C<code> or
C<docs>.

In a Perl file, C<GET /api/file/ID> gives each unit whose C<doc_ranges> are
POD (each range's first line starts with C<=> and a letter) a C<doc_html>: its
documentation lines rendered by L<Pod::Simple::XHTML>, with
C<html> targets refused, every link reduced to its text and no element ids,
since reviewed POD is untrusted.

File content is served with an image content type by extension, else as
C<text/plain; charset=utf-8> unless they contain a NUL byte. They carry
C<Content-Security-Policy: sandbox> so reviewed content never runs as part of
the page.

=head1 SYNOPSIS

    use Review::Helper::Server;

    my $server = Review::Helper::Server->new(db_path => $file);
    my $app    = $server->to_app;

=head1 ATTRIBUTES

=over 4

=item $path = $server->db_path()

The review file. Required.

=item $db = $server->db()

The open L<Review::Helper::DB>. Defaults to opening C<db_path>.

=item $repo = $server->repo()

The repository holding the review file, a L<Review::Helper::VCS>. Defaults
to the one C<detect> finds from C<db_path>.

=item $dir = $server->share_dir()

The share directory; the page's assets are under its F<ux> directory.
Defaults to L<Review::Helper::Util/share_dir>.

=item $who = $server->reviewer()

Who is reviewing, recorded on feedback, requests and seen marks
the page writes. Defaults to the C<REVIEW_HELPER_REVIEWER> environment variable, else
the repository's user (L<Review::Helper::VCS/user>), else the login
name, else C<unknown>. A blank value counts as not given.

=item $hosts = $server->allow_hosts()

Host names and addresses to accept in the C<Host> header besides the
loopback ones, as an array ref; IPv6 addresses with or without brackets.
Default: none. L<Review::Helper::CLI::Serve> fills it when listening beyond
loopback.

=item $token = $server->token()

The secret that clients other than loopback must present. Default: none,
and then every client is let in.

=item $router = $server->router()

The L<Router::Simple> holding the routes. Built by the constructor.

=back

=head1 PUBLIC METHODS

=over 4

=item $bool = Review::Helper::Server->is_loopback($addr)

True for a loopback address: C<127.0.0.0/8>, C<::1>, or C<127.0.0.0/8>
mapped into IPv6. False for undef.

=item $app = $server->to_app()

The PSGI application.

=item $res = $server->handle($env)

Answer one PSGI request. C<to_app> calls this. An unexpected error is
warned to STDERR and answered with a 500 that carries its text only for a
loopback client.

=item $res = $server->page_index($req, $match)

=item $res = $server->page_static($req, $match)

=item $res = $server->api_review($req, $match)

=item $res = $server->api_file($req, $match)

=item $res = $server->api_diff($req, $match)

=item $res = $server->api_resolution($req, $match)

=item $res = $server->api_content($req, $match)

=item $res = $server->api_feedback_export($req, $match)

=item $res = $server->api_feedback_add($req, $match)

=item $res = $server->api_feedback_edit($req, $match)

=item $res = $server->api_request_add($req, $match)

=item $res = $server->api_flag($req, $match)

=item $res = $server->api_close($req, $match)

The route handlers. Each takes the L<Plack::Request> and the router's match
and returns a PSGI response. They die with C<< {status, message} >> on bad
input, which C<handle> turns into an error response.

=back

=head1 SOURCE

The source code repository for Review-Helper can be found at
L<https://github.com/exodist/Review-Helper>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
