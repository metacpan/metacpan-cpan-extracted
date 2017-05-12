package Net::Jifty;
use Any::Moose;

our $VERSION = '0.14';

use LWP::UserAgent;
use URI;

use YAML;

use Encode;
use Fcntl qw(:mode);

has site => (
    is            => 'rw',
    isa           => 'Str',
    required      => 1,
    documentation => "The URL of your application",
    trigger       => sub {
        # this canonicalizes localhost to 127.0.0.1 because of an (I think)
        # HTTP::Cookies bug. cookies aren't sent out for localhost.
        my ($self, $site) = @_;

        if ($site =~ s/\blocalhost\b/127.0.0.1/) {
            $self->site($site);
        }
    },
);

has cookie_name => (
    is            => 'rw',
    isa           => 'Str',
    required      => 1,
    documentation => "The name of the session ID cookie. This can be found in your config under Framework/Web/SessinCookieName",
);

has appname => (
    is            => 'rw',
    isa           => 'Str',
    documentation => "The name of the application, as it is known to Jifty",
);

has email => (
    is            => 'rw',
    isa           => 'Str',
    documentation => "The email address to use to log in",
);

has password => (
    is            => 'rw',
    isa           => 'Str',
    documentation => "The password to use to log in",
);

has sid => (
    is  => 'rw',
    isa => 'Str',
    documentation => "The session ID, from the cookie_name cookie. You can use this to bypass login",
    trigger => sub {
        my $self = shift;

        my $uri = URI->new($self->site);
        $self->ua->cookie_jar->set_cookie(0, $self->cookie_name,
                                          $self->sid, '/',
                                          $uri->host, $uri->port,
                                          0, 0, undef, 1);
    },
);

has ua => (
    is      => 'rw',
    isa     => 'LWP::UserAgent',
    default => sub {
        my $args = shift;

        my $ua = LWP::UserAgent->new;

        $ua->cookie_jar({});
        push @{ $ua->requests_redirectable }, qw( POST PUT DELETE );

        # Load the user's proxy settings from %ENV
        $ua->env_proxy;

        return $ua;
    },
);

has config_file => (
    is            => 'rw',
    isa           => 'Str',
    default       => "$ENV{HOME}/.jifty",
    predicate     => 'has_config_file',
    documentation => "The place to look for the user's config file",
);

has use_config => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    documentation => "Whether or not to use the user's config",
);

has config => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
    documentation => "Storage for the user's config",
);

has use_filters => (
    is            => 'rw',
    isa           => 'Bool',
    default       => 1,
    documentation => "Whether or not to use config files in the user's directory tree",
);

has filter_file => (
    is            => 'rw',
    isa           => 'Str',
    default       => ".jifty",
    documentation => "The filename to look for in each parent directory",
);

has strict_arguments => (
    is            => 'rw',
    isa           => 'Bool',
    default       => 0,
    documentation => "Check to make sure mandatory arguments are provided, and no unknown arguments are included",
);

has action_specs => (
    is            => 'rw',
    isa           => 'HashRef',
    default       => sub { {} },
    documentation => "The cache for action specifications",
);

has model_specs => (
    is            => 'rw',
    isa           => 'HashRef',
    default       => sub { {} },
    documentation => "The cache for model specifications",
);

sub BUILD {
    my $self = shift;

    $self->load_config
        if $self->use_config && $self->has_config_file;

    $self->login
        unless $self->sid;
}

sub login {
    my $self = shift;

    return if $self->sid;

    confess "Unable to log in without an email and password."
        unless $self->email && $self->password;

    confess 'Your email did not contain an "@" sign. Did you accidentally use double quotes?'
        if $self->email !~ /@/;

    my $result = $self->call(Login =>
                                address  => $self->email,
                                password => $self->password);

    confess "Unable to log in."
        if $result->{failure};

    $self->get_sid;
    return 1;
}

sub call {
    my $self    = shift;
    my $action  = shift;
    my %args    = @_;
    my $moniker = 'fnord';

    my $res = $self->ua->post(
        $self->site . "/__jifty/webservices/yaml",
        {   "J:A-$moniker" => $action,
            map { ( "J:A:F-$_-$moniker" => $args{$_} ) } keys %args
        }
    );

    if ( $res->is_success ) {
        return YAML::Load( Encode::decode_utf8($res->content) )->{$moniker};
    } else {
        confess $res->status_line;
    }
}

sub form_url_encoded_args {
    my $self = shift;

    my $uri = '';
    while (my ($key, $value) = splice @_, 0, 2) {
        $uri .= join('=', map { $self->escape($_) } $key, $value) . '&';
    }
    chop $uri;

    return $uri;
}

sub form_form_data_args {
    my $self = shift;

    my @res;
    while (my ($key, $value) = splice @_, 0, 2) {
        my $disposition = 'form-data; name="'. Encode::encode( 'MIME-Q', $key ) .'"';
        unless ( ref $value ) {
            push @res, HTTP::Message->new(
                ['Content-Disposition' => $disposition ],
                $value,
            );
            next;
        }
        
        if ( $value->{'filename'} ) {
            $value->{'filename'} = Encode::encode( 'MIME-Q', $value->{'filename'} );
            $disposition .= '; filename="'. delete ( $value->{'filename'} ) .'"';
        }
        push @res, HTTP::Message->new(
            [
                'Content-Type' => $value->{'content_type'} || 'application/octet-stream',
                'Content-Disposition' => $disposition,
            ],
            delete $value->{content},
        );
    }
    return @res;
}

sub method {
    my $self   = shift;
    my $method = lc(shift);
    my $url    = shift;
    my @args   = @_;

    $url = $self->join_url(@$url)
        if ref($url) eq 'ARRAY';

    # remove trailing /
    $url =~ s{/+$}{};

    my $uri = $self->site . '/=/' . $url . '.yml';

    my $res;

    if ($method eq 'get' || $method eq 'head') {
        $uri .= '?' . $self->form_url_encoded_args(@args)
            if @args;

        $res = $self->ua->$method($uri);
    }
    else {
        my $req = HTTP::Request->new(
            uc($method) => $uri,
        );

        if (@args) {
            if ( grep ref $_, @args ) {
                $req->header('Content-type' => 'multipart/form-data');
                $req->add_part( $_ ) foreach $self->form_form_data_args(@args);
            } else {
                $req->header('Content-type' => 'application/x-www-form-urlencoded');
                $req->content( $self->form_url_encoded_args(@args) );
            }
        }

        $res = $self->ua->request($req);

        # XXX Compensation for a bug in Jifty::Plugin::REST... it doesn't
        # remember to add .yml when redirecting after an update, so we will
        # try to do that ourselves... fixed in a Jifty coming to stores near
        # you soon!
        if ($res->is_success && $res->content_type eq 'text/html') {
            $req = $res->request->clone;
            $req->uri($req->uri . '.yml');
            $res = $self->ua->request($req);
        }
    }

    if ($res->is_success) {
        return YAML::Load( Encode::decode_utf8($res->content) );
    } else {
        confess $res->status_line;
    }
}

sub post {
    my $self = shift;
    $self->method('post', @_);
}

sub get {
    my $self = shift;
    $self->method('get', @_);
}

sub act {
    my $self   = shift;
    my $action = shift;

    $self->validate_action_args($action => @_)
        if $self->strict_arguments;

    return $self->post(["action", $action], @_);
}

sub create {
    my $self  = shift;
    my $model = shift;

    $self->validate_action_args([create => $model] => @_)
        if $self->strict_arguments;

    return $self->post(["model", $model], @_);
}

sub delete {
    my $self   = shift;
    my $model  = shift;
    my $key    = shift;
    my $value  = shift;

    $self->validate_action_args([delete => $model] => $key => $value)
        if $self->strict_arguments;

    return $self->method(delete => ["model", $model, $key, $value]);
}

sub update {
    my $self   = shift;
    my $model  = shift;
    my $key    = shift;
    my $value  = shift;

    $self->validate_action_args([update => $model] => $key => $value, @_)
        if $self->strict_arguments;

    return $self->method(put => ["model", $model, $key, $value], @_);
}

sub read {
    my $self   = shift;
    my $model  = shift;
    my $key    = shift;
    my $value  = shift;

    return $self->get(["model", $model, $key, $value]);
}

sub search {
    my $self  = shift;
    my $model = shift;
    my @args;

    while (@_) {
        if (@_ == 1) {
            push @args, shift;
        }
        else {
            # id => [1,2,3] maps to id/1/id/2/id/3
            if (ref($_[1]) eq 'ARRAY') {
                push @args, map { $_[0] => $_ } @{ $_[1] };
                splice @_, 0, 2;
            }
            else {
                push @args, splice @_, 0, 2;
            }
        }
    }

    return $self->get(["search", $model, @args]);
}

sub validate_action_args {
    my $self   = shift;
    my $action = shift;
    my %args   = @_;

    my $name;
    if (ref($action) eq 'ARRAY') {
        my ($operation, $model) = @$action;

        # drop MyApp::Model::
        $model =~ s/.*:://;

        confess "Invalid model operation: $operation. Expected 'create', 'update', or 'delete'." unless $operation =~ m{^(?:create|update|delete)$}i;

        $name = ucfirst(lc $operation) . $model;
    }
    else {
        $name = $action;
    }

    my $action_spec = $self->get_action_spec($name);

    for my $arg (keys %$action_spec) {
        confess "Mandatory argument '$arg' not given for action $name."
            if $action_spec->{$arg}{mandatory} && !defined($args{$arg});
        delete $args{$arg};
    }

    if (keys %args) {
        confess "Unknown arguments given for action $name: "
              . join(', ', keys %args);
    }

    return 1;
}

sub get_action_spec {
    my $self = shift;
    my $name = shift;

    unless ($self->action_specs->{$name}) {
        $self->action_specs->{$name} = $self->get("action/$name");
    }

    return $self->action_specs->{$name};
}

sub get_model_spec {
    my $self = shift;
    my $name = shift;

    unless ($self->model_specs->{$name}) {
        $self->model_specs->{$name} = $self->get("model/$name");
    }

    return $self->model_specs->{$name};
}

sub get_sid {
    my $self = shift;
    my $cookie = $self->cookie_name;

    my $sid;
    $sid = $1
        if $self->ua->cookie_jar->as_string =~ /\Q$cookie\E=([^;]+)/;

    $self->sid($sid);
}

sub join_url {
    my $self = shift;

    return join '/', map { $self->escape($_) } grep { defined } @_
}

sub escape {
    my $self = shift;

    return map { s/([^a-zA-Z0-9_.!~*'()-])/uc sprintf("%%%02X", ord $1)/eg; $_ }
           map { Encode::encode_utf8($_) }
           @_
}

sub load_date {
    my $self = shift;
    my $ymd  = shift;

    my ($y, $m, $d) = $ymd =~ /^(\d\d\d\d)-(\d\d)-(\d\d)(?: 00:00:00)?$/
        or confess "Invalid date passed to load_date: $ymd. Expected yyyy-mm-dd.";

    require DateTime;
    return DateTime->new(
        time_zone => 'floating',
        year      => $y,
        month     => $m,
        day       => $d,
    );
}

sub email_eq {
    my $self = shift;
    my $a    = shift;
    my $b    = shift;

    # if one's defined and the other isn't, return 0
    return 0 unless (defined $a ? 1 : 0)
                 == (defined $b ? 1 : 0);

    return 1 if !defined($a) && !defined($b);

    # so, both are defined

    require Email::Address;

    for ($a, $b) {
        $_ = 'nobody@localhost' if $_ eq 'nobody' || /<nobody>/;
        my ($email) = Email::Address->parse($_);
        $_ = lc($email->address);
    }

    return $a eq $b;
}

sub is_me {
    my $self = shift;
    my $email = shift;

    return 0 if !defined($email);

    return $self->email_eq($self->email, $email);
}

sub load_config {
    my $self = shift;

    $self->config_permissions;
    $self->read_config_file;

    # allow config to override everything. this may need to be less free in
    # the future
    while (my ($key, $value) = each %{ $self->config }) {
        $self->$key($value)
            if $self->can($key);
    }

    $self->prompt_login_info
        unless $self->config->{email} || $self->config->{sid};

    # update config if we are logging in manually
    unless ($self->config->{sid}) {

        # if we have user/pass in the config then we still need to log in here
        unless ($self->sid) {
            $self->login;
        }

        # now write the new config
        $self->config->{sid} = $self->sid;
        $self->write_config_file;
    }

    return $self->config;
}

sub config_permissions {
    my $self = shift;
    my $file = $self->config_file;

    return if $^O eq 'MSWin32';
    return unless -e $file;
    my @stat = stat($file);
    my $mode = $stat[2];
    if ($mode & S_IRGRP || $mode & S_IROTH) {
        warn "Config file $file is readable by users other than you, fixing.";
        chmod 0600, $file;
    }
}

sub read_config_file {
    my $self = shift;
    my $file = $self->config_file;

    return unless -e $file;

    $self->config(YAML::LoadFile($self->config_file) || {});

    if ($self->config->{site}) {
        # Somehow, localhost gets normalized to localhost.localdomain,
        # and messes up HTTP::Cookies when we try to set cookies on
        # localhost, since it doesn't send them to
        # localhost.localdomain.
        $self->config->{site} =~ s/localhost/127.0.0.1/;
    }
}

sub write_config_file {
    my $self = shift;
    my $file = $self->config_file;

    YAML::DumpFile($file, $self->config);
    chmod 0600, $file;
}

sub prompt_login_info {
    my $self = shift;

    print << "END_WELCOME";
Before we get started, please enter your @{[ $self->site ]}
username and password.

This information will be stored in @{[ $self->config_file ]},
should you ever need to change it.

END_WELCOME

    local $| = 1; # Flush buffers immediately

    while (1) {
        print "First, what's your email address? ";
        $self->config->{email} = <STDIN>;
        chomp($self->config->{email});

        my $read_mode = eval {
            require Term::ReadKey;
            \&Term::ReadKey::ReadMode;
        } || sub {};

        print "And your password? ";
        $read_mode->('noecho');
        $self->config->{password} = <STDIN>;
        chomp($self->config->{password});
        $read_mode->('restore');

        print "\n";

        $self->email($self->config->{email});
        $self->password($self->config->{password});

        last if eval { $self->login };

        $self->email('');
        $self->password('');

        print "That combination doesn't seem to be correct. Try again?\n";
    }
}

sub filter_config {
    my $self = shift;

    return {} unless $self->use_filters;

    my $all_config = {};

    require Path::Class;
    require Cwd;
    my $dir = Path::Class::dir(shift || Cwd::getcwd());

    require Hash::Merge;
    my $old_behavior = Hash::Merge::get_behavior();
    Hash::Merge::set_behavior('RIGHT_PRECEDENT');

    while (1) {
        my $file = $dir->file( $self->filter_file )->stringify;

        if (-r $file) {
            my $this_config = YAML::LoadFile($file);
            $all_config = Hash::Merge::merge($this_config, $all_config);
        }

        my $parent = $dir->parent;
        last if $parent eq $dir;
        $dir = $parent;
    }

    Hash::Merge::set_behavior($old_behavior);

    return $all_config;
}

sub email_of {
    my $self = shift;
    my $id = shift;

    my $user = $self->read(User => id => $id);
    return $user->{email};
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__

=head1 NAME

Net::Jifty - interface to online Jifty applications

=head1 SYNOPSIS

    use Net::Jifty;
    my $j = Net::Jifty->new(
        site        => 'http://mushroom.mu/',
        cookie_name => 'MUSHROOM_KINGDOM_SID',
        email       => 'god@mushroom.mu',
        password    => 'melange',
    );

    # the story begins
    $j->create(Hero => name => 'Mario', job => 'Plumber');

    # find the hero whose job is Plumber and change his name to Luigi
    # and color to green
    $j->update(Hero => job => 'Plumber',
        name  => 'Luigi',
        color => 'Green',
    );

    # win!
    $j->delete(Enemy => name => 'Bowser');

=head1 DESCRIPTION

L<Jifty> is a full-stack web framework. It provides an optional REST interface
for applications. Using this module, you can interact with that REST
interface to write client-side utilities.

You can use this module directly, but you'll be better off subclassing it, such
as what we've done for L<Net::Hiveminder>.

This module also provides a number of convenient methods for writing short
scripts. For example, passing C<< use_config => 1 >> to C<new> will look at
the config file for the username and password (or SID) of the user. If neither
is available, it will prompt the user for them.

=head1 METHODS

=head2 CRUD - create, read, update and delete.

=head3 create MODEL, FIELDS

Create a new object of type C<MODEL> with the C<FIELDS> set.

=head3 read MODEL, KEY => VALUE

Find some C<MODEL> where C<KEY> is C<VALUE> and return it.

=head3 update MODEL, KEY => VALUE, FIELDS

Find some C<MODEL> where C<KEY> is C<VALUE> and set C<FIELDS> on it.

=head3 delete MODEL, KEY => VALUE

Find some C<MODEL> where C<KEY> is C<VALUE> and delete it.

=head2 Other actions

=head3 search MODEL, FIELDS[, OUTCOLUMN]

Searches for all objects of type C<MODEL> that satisfy C<FIELDS>. The optional
C<OUTCOLUMN> defines the output column, in case you don't want the entire
records.

=head3 act ACTION, ARGS

Perform any C<ACTION>, using C<ARGS>. This does use the REST interface.

=head2 Arguments of actions

Arguments are treated as arrays with (name, value) pairs so you can do the following:

    $jifty->create('Model', x => 1, x => 2, x => 3 );

Some actions may require file uploads then you can use hash reference as value with
content, filename and content_type fields. filename and content_type are optional.
content_type by default is 'application/octeat-stream'.

=head3 validate_action_args action => args

Validates the given action, to check to make sure that all mandatory arguments
are given and that no unknown arguments are given.

Arguments are checked CRUD and act methods if 'strict_arguments' is set to true.

You may give action as a string, which will be interpreted as the action name;
or as an array reference for CRUD - the first element will be the action
(create, update, or delete) and the second element will be the model name.

This will throw an error or if validation succeeds, will return 1.

=head2 Specifications of actions and models

=head3 get_action_spec NAME

Returns the action spec (which arguments it takes, and metadata about them).
The first request for a particular action will ask the server for the spec.
Subsequent requests will return it from the cache.

=head3 get_model_spec NAME

Returns the model spec (which columns it has).  The first request for a
particular model will ask the server for the spec.  Subsequent requests will
return it from the cache.

=head2 Subclassing

=head3 BUILD

Each L<Net::Jifty> object will do the following upon creation:

=over 4

=item Read config

..but only if you C<use_config> is set to true.

=item Log in

..unless a sid is available, in which case we're already logged in.

=back

=head3 login

This method is called automatically when each L<Net::Jifty> object is
constructed (unless a session ID is passed in).

This assumes your site is using L<Jifty::Plugin::Authentication::Password>.
If that's not the case, override this in your subclass.

=head3 prompt_login_info

This will ask the user for her email and password. It may do so repeatedly
until login is successful.

=head3 call ACTION, ARGS

This uses the Jifty "web services" API to perform C<ACTION>. This is I<not> the
REST interface, though it resembles it to some degree.

This module currently only uses this to log in.

=head2 Requests helpers

=head3 post URL, ARGS

This will post C<ARGS> to C<URL>. See the documentation for C<method> about
the format of C<URL>.

=head3 get URL, ARGS

This will get the specified C<URL> with C<ARGS> as query parameters. See the
documentation for C<method> about the format of C<URL>.

=head3 method METHOD, URL[, ARGS]

This will perform a C<METHOD> (GET, POST, PUT, DELETE, etc) using the internal
L<LWP::UserAgent> object.

C<URL> may be a string or an array reference (which will have its parts
properly escaped and joined with C</>). C<URL> already has
C<http://your.site/=/> prepended to it, and C<.yml> appended to it, so you only
need to pass something like C<model/YourApp.Model.Foo/name>, or
C<[qw/model YourApp.Model.Foo name]>.

This will return the data structure returned by the Jifty application, or throw
an error.

=head3 form_url_encoded_args ARGS

This will take an array containing (name, value) argument pairs and
convert those arguments into URL encoded form. I.e., (x => 1, y => 2, z => 3) becomes:

  x=1&y=2&z=3

These are then ready to be appened to the URL on a GET or placed into
the content of a PUT. However this method can not handle file uploads
as they must be sent using 'multipart/form-date'.

See also L</"form_form_data_args ARGS"|"form_form_data_args"> and
L</"Arguments of actions">.

=head3 form_form_data_args ARGS

This will take an array containing (name, value) argument pairs and
convert those arguments into L<HTTP::Message> objects ready for adding
to a 'mulitpart/form-data' L<HTTP::Request> as parts with something like:

    my $req = HTTP::Request->new( POST => $uri );
    $req->header('Content-type' => 'multipart/form-data');
    $req->add_part( $_ ) foreach $self->form_form_data_args( @args );

This method can handle file uploads, read more in L</"Arguments of actions">.

See also L</"form_form_data_args ARGS"|"form_form_data_args"> and
L</"Arguments of actions">.

=head3 join_url FRAGMENTS

Encodes C<FRAGMENTS> and joins them with C</>.

=head3 escape STRINGS

Returns C<STRINGS>, properly URI-escaped.

=head2 Various helpers

=head3 email_eq EMAIL, EMAIL

Compares the two email addresses. Returns true if they're equal, false if
they're not.

=head3 is_me EMAIL

Returns true if C<EMAIL> looks like it is the same as the current user's.

=head3 email_of ID

Retrieve user C<ID>'s email address.

=head3 load_date DATE

Loads C<DATE> (which must be of the form C<YYYY-MM-DD>) into a L<DateTime>
object.

=head3 get_sid

Retrieves the sid from the L<LWP::UserAgent> object.

=head2 Working with config

=head3 load_config

This will return a hash reference of the user's preferences. Because this
method is designed for use in small standalone scripts, it has a few
peculiarities.

=over 4

=item

It will C<warn> if the permissions are too liberal on the config file, and fix
them.

=item

It will prompt the user for an email and password if necessary. Given
the email and password, it will attempt to log in using them. If that fails,
then it will try again.

=item

Upon successful login, it will write a new config consisting of the options
already in the config plus session ID, email, and password.

=back

=head3 config_permissions

This will warn about (and fix) config files being readable by group or others.

=head3 read_config_file

This transforms the config file into a hashref. It also does any postprocessing
needed, such as transforming localhost to 127.0.0.1 (due to an obscure bug,
probably in HTTP::Cookies).

The config file is a L<YAML> document that looks like:

    ---
    email: you@example.com
    password: drowssap
    sid: 11111111111111111111111111111111

=head3 write_config_file

This will write the config to disk. This is usually only done when a sid is
discovered, but may happen any time.

=head3 filter_config [DIRECTORY] -> HASH

Looks at the (given or) current directory, and all parent directories, for
files named C<< $self->filter_file >>. Each file is YAML. The contents of the
files will be merged (such that child settings override parent settings), and
the merged hash will be returned.

What this is used for is up to the application or subclasses. L<Net::Jifty>
doesn't look at this at all, but it may in the future (such as for email and
password).

=head1 SEE ALSO

L<Jifty>, L<Net::Hiveminder>

=head1 AUTHORS

Shawn M Moore, C<< <sartak at bestpractical.com> >>

Ruslan Zakirov, C<< <ruz at bestpractical.com> >>

Jesse Vincent, C<< <jesse at bestpractical.com> >>

=head1 CONTRIBUTORS

Andrew Sterling Hanenkamp, C<< <hanenkamp@gmail.com> >>,

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-jifty at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Jifty>.

=head1 COPYRIGHT & LICENSE

Copyright 2007-2009 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

