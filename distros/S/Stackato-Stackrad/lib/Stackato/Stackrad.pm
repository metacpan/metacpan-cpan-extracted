use strict; use warnings;
package Stackato::Stackrad;
our $VERSION;
BEGIN {
    $VERSION = '0.13';
}

use Mo qw'build builder default';
use Curses::UI;
use LWP::UserAgent;
use LWP::Protocol::https;
use HTTP::Request;
use URI::Escape;
use JSON::XS;
use YAML::XS;

our $SELF;
sub PPP {
    my $self = $SELF;
    my $text = YAML::XS::Dump(@_);
    $self->error($text);
    wantarray ? @_ : $_[0]
}

use constant app_name => 'Stackrad';
use constant target_key_hint => ' (set target with Ctrl+t)';
use constant default_title => app_name . target_key_hint;
use constant new_target_prompt =>
    "New target? (e.g., api.stackato.example.com)";
use constant username_prompt => "Username:";
use constant password_prompt => "Password:";
use constant user_agent_string =>
    app_name . "/$VERSION lwp/$LWP::UserAgent::VERSION";
use constant main_color => 'cyan';
use constant secondary_color => 'cyan';
use constant accent_color => 'red';
use constant banner => <<EOT;
        _____                   _              _          _
       / ____|                 | |            | |        | |
  ____| O_________          ___| |_  __ _  ___| | __ __ _| |_  ___
 /     \\___ \\     \\        / __| __|/ _` |/ __| |/ // _` | __|/ _ \\ TM
|     .____O |     |       \\__ \\ |_| (_| | (__|   <| (_| | |_| (_) |
 \\_...|_____...___/        |___/\\__|\\__,_|\\___|_|\\_\\\\__,_|\\__|\\___/
                                                by ActiveState





EOT

has targets => (default => sub{[]});
# has targets => (default => sub{[{hostname=>'api.stacka.to'}]});

has target_index => ();
has cui => ();
has win1 => ();
has tabs => ();
has ui => (default => sub { [
    {
        name => 'Targets',
        on_activate => sub { },
        contents => undef,
    },
    {
        name => 'Overview',
        on_activate => sub { },
        contents => <<'EOT'
Memory: [ 128 MB of 256 MB ]
[----------------                  ]

1 / 2 Applications
0 / 2 Services

Applications:
[ ] tty-js [STARTED]
    Framework: node, Services: 0, Owner: as@sharpsaw.org
    [Restart] [Stop] [Launch] [Logs] [All Files] [More Info]

[ ] pairup [STARTED]
    Framework: generic, Services: 0, Owner: ingy@ingy.net
    [Restart] [Stop] [Launch] [Logs] [All Files] [More Info]

...

Provisioned Services:
[ ] filesystem  Provisioned Name: home   Bindings: 1
    [(Cannot Delete Bound Service)]
EOT
    },
    {
        name => 'Users',
        on_activate => sub { $SELF->update_users },
        contents => <<'EOT'
You need to login to a valid target Stackato VM.
EOT
    },
    {
        name => 'Groups',
        on_activate => sub { },
        contents => <<'EOT'
    Group   Users   Apps
[ ] pair    5       1
EOT
    },
    {
        name => 'App Store',
        on_activate => sub { },
        contents => <<'EOT'
[ ] Bugzilla - perl / mysql
    A bug tracking system for individuals or groups of developers
    256MB Required - License: MPL
    (Third Party Apps for Stackato)

[ ] Currency Converter - python / redis
    Currency converter using Python bottle framework
    128MB Required - License: Unknown
    (ActiveState Stackato Sample Applications)

[ ] Drupal - php / filesystem / mysql
    A popular PHP content management system which uses mysql and
    the persistent file system
    128MB Required - License: GPLv2
    (Third Party Apps for Stackato)

[ ] ...
EOT
    },
    {
        name => 'Local Apps',
        on_activate => sub { },
        contents => <<'EOT'
[ ] Node Env - node
    /home/ingy/src/node-env/

[ ] Foozle - ruby / postgresql
    /home/ingy/src/foozle/
EOT
    },
]});


sub run {
    my $class = shift;
    my $self = $class->new();
    $SELF = $self; # XXX, PPP
    $self->setup_cui;
    $self->cui->mainloop();
}

sub setup_cui {
    my $self = shift;
    $self->target_index($#{$self->targets}) if @{$self->targets};    # XXX
    my $cui = $self->{cui} = $self->cui(
        Curses::UI->new(
            -color_support => 1,
            # -debug => 1,
        )
    );

    $cui->set_binding(sub { exit 0 }, "\cC");
    $cui->set_binding(sub { $self->prompt_for_target }, "\cT");
    $cui->set_binding(sub { $self->delete_current_target }, "\cX");
    $cui->set_binding(sub { $self->login_logout }, "\cL");
    for my $index (1 .. 9) {
        $cui->set_binding(sub { $self->set_target($index) }, $index);
    }

    my $win1 = $self->{win1} =
        $cui->add('win1', 'Window',
            -title  => default_title,
            -bfg    => main_color,
            -border => 1,
        );
    $win1->add('help_text', 'Label',
        -y     => $win1->height - 3,
        -width => $win1->width - 2,
        -text  => 'Ctrl+n/PgUp / Ctrl+p/PgDn to switch tabs; Ctrl+C to exit',
        -textalignment => 'middle',
        -bold  => 1,
    );
    my $notebook = $win1->add('notebook', 'Notebook',
        -height => $win1->height - 3,
        -border => 1,
    );
    for my $tab (@{$self->ui}) {
        my $name = $tab->{name};
        my $id = 'tab_'.$name;
        my $page = $tab->{page} = $notebook->add_page($name,
            -on_activate => $tab->{on_activate}
        );
        $tab->{tv} = $page->add(
            $id, 'TextViewer',
            -x    => 1,
            -y    => 1,
            -text => $tab->{contents},
        );
    }
    $self->update_targets_screen;
    $notebook->focus;
}

sub tab_named {
    my ($self, $name) = @_;
    for (@{$self->ui}) {
        return $_ if $name eq $_->{name};
    }
}

sub current_target {
    my $self = shift;
    return unless defined $self->target_index;
    $self->targets->[$self->target_index]
}

sub set_target {
    my ($self, $new_index) = @_;
    $self->target_index($new_index);
    $self->update_users;
}

sub prompt_for_target {
    my $self = shift;
    my $answer = $self->cui->question(new_target_prompt); # TODO: "api."
    return unless $answer;

    return $self->error($answer . " does not appear to be a valid Stackato VM")
        unless $self->validate_target($answer);
    push @{$self->targets}, {hostname => $answer};
    $self->target_index($#{$self->targets});
    $self->update_targets_screen;
    $self->set_title
}

sub delete_current_target {
    my $self = shift;
    my $i = $self->target_index;
    return unless defined $i;
    splice @{$self->targets}, $i, 1;
    $i = undef if --$i < 0;
    $self->target_index($i);
    $self->set_title;
    $self->update_targets_screen;
}

sub update_targets_screen {
    my $self = shift;
    my $tab = $self->tab_named('Targets');
    my $out = '';
    for (0 .. $#{$self->targets}) {
        my $target = $self->targets->[$_];
        $out .= $_ == $self->target_index ? ' * ' : '   ';
        $out .= $target->{hostname};
        $out .= $target->{user}
            ? " (${\$target->{user}}) "
            : " (not logged in) ";
        $out .= "\n";
    }
    $out .= "\n\n";
    if (@{$self->targets}) {
        $out .= 'Ctrl+L to log' . ($self->logged_in ? 'out' : 'in')."\n";
        $out .= "Ctrl+x to delete current target.\n"
    } else {
        $out .= banner;
    }
    $out .= "Ctrl+t to add a target.\n";
#     $out .= "\n\nPress 'Ctrl+<target #>' to set current target."
#         if @{$self->targets} > 1;
    $tab->{tv}{-text} = $out;
    $self->redraw;
}

sub update_users {
    my $self = shift;
    my $out = '';
    if (not $self->current_target) {
        $out = 'You have no Stackato VM as a current target.';
    }
    else {
        my $response = $self->get(path => '/users');
        my $status = $response->code;
        if ($status == 403) {
            $out = "Unauthorized. Maybe you need to login as an admin user?";
        } else {
            my $data = decode_json($response->content);
            for (0 .. $#{$data}) {
                my $user = $data->[$_];
                $out .= $_+1 . '. ' . $user->{email} . "\n";
            }
        }
    }
    $self->tab_named('Users')->{tv}{-text} = $out;
}

sub login_logout {
    my $self = shift;
    return $self->logout if $self->logged_in;
    my $username = $self->cui->question(username_prompt); # TODO: <prev-user>
    return unless $username;
    my $password = $self->cui->question(password_prompt);
    return unless $password;
    my $path = '/users/' . uri_escape($username) . '/tokens';
    $password = quotemeta($password);
    my $response = $self->post(
        path => $path,
        content => qq({"password":"$password"})
    );
    unless ($response->is_success) {
        $self->error("Couldn't login.");
        return $self->logout;
    }
    my $token = decode_json($response->content)->{token};
    $self->current_target->{user} = $username;
    $self->current_target->{token} = $token;
    $self->update_targets_screen;
}

sub logout {
    my $self = shift;
    my $cur = $self->current_target;
    delete $cur->{user};
    delete $cur->{token};
    $self->update_targets_screen;
}

sub logged_in {
    my $self = shift;
    $self->current_target->{user}
}

sub set_title {
    my $self = shift;
    my $title = app_name;
    $title .= ' - target: ' . (
        $self->current_target &&
        $self->current_target->{hostname} ||
        'No Target'
    );
    $self->win1->{-title} = $title;
    $self->redraw;
}

sub validate_target {
    my ($self, $target) = @_;
    my $response = $self->get_from_target(
        target => { hostname => $target },
        path => '/info/'
    );
    return unless $response->is_success;
    decode_json($response->content)
}

sub post_to_target {
    my ($self, %args) = @_;
    $self->ua->simple_request(
        $self->http_req('POST',
            host => $args{target}{hostname},
            path => $args{path},
            headers => {
                $args{target}{token}
                ? ('AUTHORIZATION' => $args{target}{token}) : ()
            },
            content => $args{content},
        )
    )
}

sub post {
    my ($self, %args) = @_;
    $self->post_to_target(
        target => $self->current_target,
        path => $args{path},
        content => $args{content},
    )
}

sub get_from_target {
    my ($self, %args) = @_;
    $self->ua->simple_request(
        $self->http_req('GET',
            host => $args{target}{hostname},
            path => $args{path},
            headers => {
                $args{target}{token}
                ? ('AUTHORIZATION' => $args{target}{token}) : ()
            },
            content => $args{content},
        )
    )
}

sub get {
    my ($self, %args) = @_;
    $self->get_from_target(
        target => $self->current_target,
        path => $args{path},
        content => $args{content},
    )
}

sub ua {
    my $self = shift;
    my $ua = LWP::UserAgent->new(agent => user_agent_string);
    # XXX
    # warn "Stackrad being lazy and disabling SSL cert verification!";
    $ua->ssl_opts(
        verify_hostname => 0,
        #? SSL_ca_path => '/app/fs/pair/certcert/stackato.ddns.us.pem',
    );
    $ua
}

sub http_req {
    my ($self, $method, %args) = @_;
    my $url = "https://$args{host}$args{path}";
    my $request = HTTP::Request->new($method, $url);
    $request->header('Accept' => 'application/json', %{$args{headers}});
    $request->content($args{content}) if $args{content};
    $request
}

sub error {
    my $self = shift;
    $self->cui->error(@_);
}

sub redraw {
    my $self = shift;
    $self->win1->draw(1);
}

1;
