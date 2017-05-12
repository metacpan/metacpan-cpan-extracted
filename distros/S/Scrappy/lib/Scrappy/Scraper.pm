package Scrappy::Scraper;

BEGIN {
    $Scrappy::Scraper::VERSION = '0.94112090';
}

# load OO System
use Moose;

# load other libraries
use Data::Dumper;
use File::Util;
use Scrappy::Logger;
use Scrappy::Plugin;
use Scrappy::Queue;
use Scrappy::Scraper::Control;
use Scrappy::Scraper::Parser;
use Scrappy::Scraper::UserAgent;
use Scrappy::Session;
use Try::Tiny;
use URI;
use Web::Scraper;
use WWW::Mechanize;

# html content attribute
has 'content' => (
    is  => 'rw',
    isa => 'Any'
);

# access control object
has 'control' => (
    is      => 'ro',
    isa     => 'Scrappy::Scraper::Control',
    default => sub {
        Scrappy::Scraper::Control->new;
    }
);

# debug attribute
has 'debug' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1
);

# log object
has 'logger' => (
    is      => 'ro',
    isa     => 'Scrappy::Logger',
    default => sub {
        Scrappy::Logger->new;
    }
);

# parser object
has 'parser' => (
    is      => 'ro',
    isa     => 'Scrappy::Scraper::Parser',
    default => sub {
        Scrappy::Scraper::Parser->new;
    }
);

# plugins object
has 'plugins' => (
    is      => 'ro',
    isa     => 'Any',
    default => sub {
        Scrappy::Plugin->new;
    }
);

# queue object
has 'queue' => (
    is      => 'ro',
    isa     => 'Scrappy::Queue',
    default => sub {
        Scrappy::Queue->new;
    }
);

# session object
has 'session' => (
    is      => 'ro',
    isa     => 'Scrappy::Session',
    default => sub {
        Scrappy::Session->new;
    }
);

# user-agent object
has 'user_agent' => (
    is      => 'ro',
    isa     => 'Scrappy::Scraper::UserAgent',
    default => sub {
        Scrappy::Scraper::UserAgent->new;
    }
);

# www-mechanize object (does most of the heavy lifting, gets passed around alot)
has 'worker' => (
    is      => 'ro',
    isa     => 'WWW::Mechanize',
    default => sub {
        WWW::Mechanize->new;
    }
);

sub back {
    my $self = shift;

    # specify user-agent
    $self->worker->add_header("User-Agent" => $self->user_agent->name)
      if defined $self->user_agent->name;

    # set html response
    $self->content('');
    try {
        $self->worker->back;
        $self->content($self->worker->content);
    }
    catch {
        $self->log("error", "navigating to the previous page failed");
    };

    return unless $self->content;

    $self->log("info", "navigated back to " . $self->url . " successfully");

    $self->stash->{history} = [] unless defined $self->stash->{history};
    push @{$self->stash->{history}}, $self->url;
    $self->worker->{cookie_jar}->scan(
        sub {

            my ($version, $key,     $val,       $path,
                $domain,  $port,    $path_spec, $secure,
                $expires, $discard, $hash
            ) = @_;

            $self->session->stash('cookies' => {})
              unless defined $self->session->stash('cookies');

            $self->session->stash->{'cookies'}->{$domain}->{$key} = {
                version   => $version,
                key       => $key,
                val       => $val,
                path      => $path,
                domain    => $domain,
                port      => $port,
                path_spec => $path_spec,
                secure    => $secure,
                expires   => $expires,
                discard   => $discard,
                hash      => $hash
            };

            $self->session->write;

        }
    );

    return $self->url;
}

sub cookies {
    my $self = shift;
    $self->worker->{cookie_jar} = $_[0] if defined $_[0];
    return $self->worker->{cookie_jar};
}

sub domain {
    return shift->worker->base->host;
}

sub download {
    my $self = shift;
    my ($url, $dir, $file) = @_;

    $url = URI->new(@_);

    # specify user-agent
    $self->worker->add_header("User-Agent" => $self->user_agent->name)
      if defined $self->user_agent->name;

    # set html response
    if ($url && $dir && $file) {
        $dir =~ s/[\\\/]+$//;
        return unless $self->get($url);
        $self->store(join '/', $dir, $file);
        $self->log("info",
                "$url was downloaded to "
              . join('/', $dir, $file)
              . " successfully");
        $self->back;
    }
    elsif ($url && $dir) {
        $dir =~ s/[\\\/]+$//;
        return unless $self->get($url);
        my @chars = ('a' .. 'z', 'A' .. 'Z', 0 .. 9);
        my $filename = $self->worker->response->filename;
        $filename =
            $chars[rand(@chars)]
          . $chars[rand(@chars)]
          . $chars[rand(@chars)]
          . $chars[rand(@chars)]
          . $chars[rand(@chars)]
          . $chars[rand(@chars)]
          . '.downlaod'
          unless $filename;
        $self->store(join '/', $dir, $filename);
        $self->log("info",
                "$url was downloaded to "
              . join('/', $dir, $filename)
              . " successfully");
        $self->back;
    }
    elsif ($url) {
        return unless $self->get($url);
        my @chars = ('a' .. 'z', 'A' .. 'Z', 0 .. 9);
        my $filename = $self->worker->response->filename;
        $filename =
            $chars[rand(@chars)]
          . $chars[rand(@chars)]
          . $chars[rand(@chars)]
          . $chars[rand(@chars)]
          . $chars[rand(@chars)]
          . $chars[rand(@chars)]
          . '.downlaod'
          unless $filename;
        $dir = $url->path;
        $dir =~ s/^\///g;
        $dir =~ s/\/$filename$//;
        File::Util->new->make_dir($dir) unless -d $dir || !$dir;
        $self->store(join '/', $dir, $filename);
        $self->log("info",
                "$url was downloaded to "
              . join('/', $dir, $filename)
              . " successfully");
        $self->back;
    }
    else {
        croak(
            "To download data from a URI you must supply at least a valid URI "
              . "and download directory path");
    }

    $self->stash->{history} = [] unless defined $self->stash->{history};
    push @{$self->stash->{history}}, $url;

    $self->worker->{params} = {};
    $self->worker->{params} =
      {map { ($_ => $url->query_form($_)) } $url->query_form};

    sleep $self->pause;

    return $self;
}

sub dumper {
    shift;
    return Data::Dumper::Dumper(@_);
}

sub form {
    my $self = shift;
    my $url  = URI->new($self->url);

    # TODO: need to figure out how to determine the form action before submit

    # specify user-agent
    $self->worker->add_header("User-Agent" => $self->user_agent->name)
      if defined $self->user_agent->name;

    # set html response
    $self->content('');
    my @args = @_;
    try {
        $self->content($self->worker->submit_form(@args));
    };
    if ($self->content) {

        # access control
        if ($self->control->is_allowed($self->content)) {
            $self->log("warn", "$url was not fetched, the url is prohibited");
            return 0;
        }
        else {
            $self->log("info", "form posted from $url successfully", @_);
        }
    }
    else {
        $self->log("error", "error POSTing form from $url", @_);
    }

    #$self->stash->{history} = [] unless defined $self->stash->{history};
    #push @{$self->stash->{history}}, $url;

    $self->worker->{cookie_jar}->scan(
        sub {

            my ($version, $key,     $val,       $path,
                $domain,  $port,    $path_spec, $secure,
                $expires, $discard, $hash
            ) = @_;

            $self->session->stash('cookies' => {})
              unless defined $self->session->stash('cookies');

            $self->session->stash->{'cookies'}->{$domain}->{$key} = {
                version   => $version,
                key       => $key,
                val       => $val,
                path      => $path,
                domain    => $domain,
                port      => $port,
                path_spec => $path_spec,
                secure    => $secure,
                expires   => $expires,
                discard   => $discard,
                hash      => $hash
            };

            $self->session->write;

        }
    );

    $self->worker->{params} = {};
    $self->worker->{params} =
      {map { ($_ => $url->query_form($_)) } $url->query_form};

    sleep $self->pause;

    return $self;
}

sub get {
    my $self = shift;
    my $url  = URI->new(@_);

    # specify user-agent
    $self->worker->add_header("User-Agent" => $self->user_agent->name)
      if defined $self->user_agent->name;

    # set html response
    $self->content('');
    try {
        $self->content($self->worker->get($url));
    };
    if ($self->content) {

        # access control
        if (!$self->control->is_allowed($self->content)) {
            $self->log("warn", "$url was not fetched, the url is prohibited");
            return 0;
        }
        else {
            $self->log("info", "$url was fetched successfully");
        }
    }
    else {
        $self->log("error", "error GETing $url");
    }

    $self->stash->{history} = [] unless defined $self->stash->{history};
    push @{$self->stash->{history}}, $url;
    $self->worker->{cookie_jar}->scan(
        sub {

            my ($version, $key,     $val,       $path,
                $domain,  $port,    $path_spec, $secure,
                $expires, $discard, $hash
            ) = @_;

            $self->session->stash('cookies' => {})
              unless defined $self->session->stash('cookies');

            $self->session->stash->{'cookies'}->{$domain}->{$key} = {
                version   => $version,
                key       => $key,
                val       => $val,
                path      => $path,
                domain    => $domain,
                port      => $port,
                path_spec => $path_spec,
                secure    => $secure,
                expires   => $expires,
                discard   => $discard,
                hash      => $hash
            };

            $self->session->write;

        }
    ) if $self->session->file;

    $self->worker->{params} = {};
    $self->worker->{params} =
      {map { ($_ => $url->query_form($_)) } $url->query_form};

    sleep $self->pause;

    return $self;
}

sub page_data {
    my $self = shift;
    my ($data, @args);

    if (scalar(@_) % 2) {
        $data = shift;
        @args = @_;
    }
    else {
        if (@_ == 2) {
            @args = @_;
        }
        else {
            $data = shift;
        }
    }

    if ($data) {
        $self->worker->update_html($data);
    }

    return $self->worker->content(@args);
}

sub page_content_type {
    return shift->worker->content_type;
}

sub page_ishtml {
    return shift->worker->is_html;
}

sub page_loaded {
    return shift->worker->success;
}

sub page_match {
    my $self    = shift;
    my $pattern = shift;
    my $url     = shift || $self->url;
    $url = URI->new($url);
    my $options = shift || {};

    croak("route can't be defined without a valid URL pattern")
      unless $pattern;

    my $route = $self->stash->{patterns}->{$pattern};

    # does route definition already exist?
    unless (keys %{$route}) {

        $route->{on_match} = $options->{on_match};

        # define options
        if (my $host = $options->{host}) {
            $route->{host} = $host;
            $route->{host_re} = ref $host ? $host : qr(^\Q$host\E$);
        }

        $route->{pattern} = $pattern;

        # compile pattern
        my @capture;
        $route->{pattern_re} = do {
            if (ref $pattern) {
                $route->{_regexp_capture} = 1;
                $pattern;
            }
            else {
                $pattern =~ s!
                    \{((?:\{[0-9,]+\}|[^{}]+)+)\} | # /blog/{year:\d{4}}
                    :([A-Za-z0-9_]+)              | # /blog/:year
                    (\*)                          | # /blog/*/*
                    ([^{:*]+)                       # normal string
                !
                    if ($1) {
                        my ($name, $pattern) = split /:/, $1, 2;
                        push @capture, $name;
                        $pattern ? "($pattern)" : "([^/]+)";
                    } elsif ($2) {
                        push @capture, $2;
                        "([^/]+)";
                    } elsif ($3) {
                        push @capture, '__splat__';
                        "(.+)";
                    } else {
                        quotemeta($4);
                    }
                !gex;
                qr{^$pattern$};
            }
        };
        $route->{capture} = \@capture;
        $self->stash->{patterns}->{$route->{pattern}} = $route;
    }

    # match
    if ($route->{host_re}) {
        unless ($url->host =~ $route->{host_re}) {
            return 0;
        }
    }

    if (my @captured = ($url->path =~ $route->{pattern_re})) {
        my %args;
        my @splat;
        if ($route->{_regexp_capture}) {
            push @splat, @captured;
        }
        else {
            for my $i (0 .. @{$route->{capture}} - 1) {
                if ($route->{capture}->[$i] eq '__splat__') {
                    push @splat, $captured[$i];
                }
                else {
                    $args{$route->{capture}->[$i]} = $captured[$i];
                }
            }
        }
        my $match = +{
            (label => $route->{label}),
            %args,
            (@splat ? (splat => \@splat) : ())
        };
        if ($route->{on_match}) {
            my $ret = $route->{on_match}->($self, $match);
            return 0 unless $ret;
        }
        $match->{params} = {%args};
        $match->{params}->{splat} = \@splat if @splat;

        return $match;
    }

    return 0;
}

sub page_reload {
    my $self = shift;

    # specify user-agent
    $self->worker->add_header("User-Agent" => $self->user_agent->name)
      if defined $self->user_agent->name;

    # set html response
    $self->content('');
    try {
        $self->content($self->worker->reload);
    };
    $self->content
      ? $self->log("info",  "page reloaded successfully")
      : $self->log("error", "error reloading page");

    my $url = $self->url;

    $self->stash->{history} = [] unless defined $self->stash->{history};
    push @{$self->stash->{history}}, $url;
    $self->worker->{cookie_jar}->scan(
        sub {

            my ($version, $key,     $val,       $path,
                $domain,  $port,    $path_spec, $secure,
                $expires, $discard, $hash
            ) = @_;

            $self->session->stash('cookies' => {})
              unless defined $self->session->stash('cookies');

            $self->session->stash->{'cookies'}->{$domain}->{$key} = {
                version   => $version,
                key       => $key,
                val       => $val,
                path      => $path,
                domain    => $domain,
                port      => $port,
                path_spec => $path_spec,
                secure    => $secure,
                expires   => $expires,
                discard   => $discard,
                hash      => $hash
            };

            $self->session->write;

        }
    );

    return $self;
}

sub page_status {
    return shift->worker->status;
}

sub page_text {
    return shift->page_data(format => 'text');
}

sub page_title {
    return shift->worker->title;
}

sub plugin {
    my ($self, @plugins) = @_;
    foreach (@plugins) {
        with $self->plugins->load_plugin($_);
    }
    return $self;
}

sub post {
    my $self = shift;
    my $url  = URI->new($_[0]);

    # access control
    unless ($self->control->is_allowed($url)) {
        $self->log("warn", "$url was not fetched, the url is prohibited");
        return 0;
    }

    # specify user-agent
    $self->worker->add_header("User-Agent" => $self->user_agent->name)
      if defined $self->user_agent->name;

    # set html response
    $self->content('');
    my @args = @_;
    try {
        $self->content($self->worker->post(@args));
    };
    if ($self->content) {

        # access control
        if ($self->control->is_allowed($self->content)) {
            $self->log("warn", "$url was not fetched, the url is prohibited");
            return 0;
        }
        else {
            $self->log("info", "posted data to $_[0] successfully", @_);
        }
    }
    else {
        $self->log("error", "error POSTing data to $_[0]", @_);
    }

    $self->stash->{history} = [] unless defined $self->stash->{history};
    push @{$self->stash->{history}}, $url;
    $self->worker->{cookie_jar}->scan(
        sub {

            my ($version, $key,     $val,       $path,
                $domain,  $port,    $path_spec, $secure,
                $expires, $discard, $hash
            ) = @_;

            $self->session->stash('cookies' => {})
              unless defined $self->session->stash('cookies');

            $self->session->stash->{'cookies'}->{$domain}->{$key} = {
                version   => $version,
                key       => $key,
                val       => $val,
                path      => $path,
                domain    => $domain,
                port      => $port,
                path_spec => $path_spec,
                secure    => $secure,
                expires   => $expires,
                discard   => $discard,
                hash      => $hash
            };

            $self->session->write;

        }
    );

    $self->worker->{params} = {};
    $self->worker->{params} =
      {map { ($_ => $url->query_form($_)) } $url->query_form};

    sleep $self->pause;

    return $self;
}

sub proxy {
    my $self     = shift;
    my $proxy    = pop @_;
    my @protocol = @_;
    $self->worker->proxy([@protocol], $proxy);
    $self->log("info", "Set proxy $proxy using protocol(s) " . join ' and ',
        @protocol);
    return $self;
}

sub request_denied {
    my $self = shift;
    my ($last) = reverse @{$self->stash->{history}};
    return 1 if ($self->url ne $last);
}

sub select {
    my ($self, $selector, $html) = @_;
    my $parser = Scrappy::Scraper::Parser->new;
    $parser->html($html ? $html : $self->content);
    return $parser->select($selector);
}

sub log {
    my $self = shift;
    my $type = shift;
    my @args = @_;

    if ($self->debug) {
        if ($type eq 'info') {
            $self->logger->info(@args);
        }
        elsif ($type eq 'warn') {
            $self->logger->warn(@args);
        }
        elsif ($type eq 'error') {
            $self->logger->error(@args);
        }
        else {
            warn $type;
            $self->logger->event($type, @args);
        }

        return 1;
    }
    else {
        return 0;
    }
}

sub pause {
    my $self = shift;
    if (defined $_[0]) {
        if ($_[1]) {
            my @range = (($_[0] < $_[1] ? $_[0] : 0) .. $_[1]);
            $self->worker->{pause_range} = [$_[0], $_[1]];
            $self->worker->{pause} = $range[rand(@range)];
        }
        else {
            $self->worker->{pause} = $_[0];
            $self->worker->{pause_range} = [0, 0] unless $_[0];
        }
    }
    else {
        my $interval = $self->worker->{pause} || 0;

        # select the next random pause value from the range
        if (defined $self->worker->{pause_range}) {
            my @range = @{$self->worker->{pause_range}};
            $self->pause(@range) if @range == 2;
        }

        $self->log("info", "processing was halted for $interval seconds")
          if $interval > 0;
        return $interval;
    }
}

sub response {
    return shift->worker->response;
}

sub stash {
    my $self = shift;
    $self->{stash} = {} unless defined $self->{stash};

    if (@_) {
        my $stash = @_ > 1 ? {@_} : $_[0];
        if ($stash) {
            if (ref $stash eq 'HASH') {
                $self->{stash}->{$_} = $stash->{$_} for keys %{$stash};
            }
            else {
                return $self->{stash}->{$stash};
            }
        }
    }

    return $self->{stash};
}

sub store {

    # return shift->worker->save_content(@_);
    # oh no i didnt just rewrite www:mech save_content, oh yes i did
    # ... in hope to avoid content encoding issues

    my $self     = shift;
    my $filename = shift;

    open(my $fh, '>', $filename)
      or $self->worker->die("Unable to create $filename: $!");

    if (   $self->worker->content_type =~ m{^text/}
        || $self->worker->content_type
        =~ m{^application/(atom|css|javascript|json|rss|xml)})
    {

        # text
        $self->worker->response->decode;
        print {$fh} $self->worker->response->content
          or $self->worker->die("Unable to write to $filename: $!");
    }
    else {

        # binary
        binmode $fh;
        print {$fh} $self->worker->response->content
          or $self->worker->die("Unable to write to $filename: $!");
    }

    close $fh
      or $self->worker->die("Unable to close $filename: $!");

    return $self;
}

sub url {
    return $_[0]->worker->uri
      if $_[0]->content;
}

1;
