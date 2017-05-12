package Net::AppNotifications;

use strict;
use 5.008_001;
our $VERSION = '0.03';
use AnyEvent::HTTP;
use Carp;
use URI::Escape 'uri_escape_utf8';

use constant POST_URI =>
    q{https://www.appnotifications.com/account/notifications.xml};

use constant KEY_URI =>
    q{https://www.appnotifications.com/account/user_session.xml};

sub new {
    my $class = shift;
    my %param = @_;
    my $notifier = bless { %param }, ref $class || $class;
    unless ($param{key}) {
        $param{key} = $class->get_key( %param );
    }
    croak "Key (or valid email, pass to get it) is needed" unless $param{key};
    return $notifier;
}

sub send {
    my $notifier = shift;

    my %cbs;
    my $key    = $notifier->{key};
    my $finish = sub {};
    my %param;

    if (scalar @_ == 1) {
        my $message = shift;
        unless (defined $message && length $message) {
            croak "Please, give me a message to push";
        }
        $param{message} = $message;

        my $done = AnyEvent->condvar;

        $cbs{on_posted} = sub {
            my ($data, $hds) = @_;
            $done->send;
            croak "Something happend" unless defined $data;
        };

        $cbs{on_timeout} = sub {
            $done->send;
            croak "timeout";
        };
        $cbs{on_error} = sub {
            $done->send;
            croak "Error $_[0]";
        };

        $finish = sub {
            $done->recv;
        };
    }
    else {
        %param = @_;

        $cbs{$_} = $param{$_} for qw{on_error on_timeout};

        my $early_error = $cbs{on_error} || sub { croak "$_[0]" }; 

        my $on_success = $param{on_success};
        unless ($on_success) {
            $early_error->("On success must be passed");
            return;
        }

        ## callback definitions
        $cbs{on_posted} = sub {
            my $data = shift;
            unless (defined $data) {
                $cbs{on_error}->("Something happened");
                return;
            }
            $on_success->($data, @_);
        };

        $cbs{on_error} ||= sub {
            warn "Error: $_[0]";
        };

        $cbs{on_timeout} ||= sub {
            warn "Timeout: $_[0]";
        };
    } 
    my $notification_params = $notifier->normalize(%param);

    my $uri  = POST_URI;
    my $body = build_body(
        "user_credentials" => $key,
        %$notification_params,
    );
    $notifier->post_request($uri, $body, %cbs);

    ## wait here for synchronous calls
    $finish->();
    return;
}

sub normalize {
    my $notifier = shift;
    my %param    = @_;

    my %nparam;
    my $N = "notification";

    my @keys = qw/
        message message_level action_loc_key run_command
        title long_message long_message_preview
        icon_url subtitle
    /;
    for (@keys) {
        next unless exists $param{$_};
        $nparam{"${N}[$_]"} = $param{$_} || "";
    }

    my $silent = 0;
    my $sound  = $param{sound};
    if ($sound) {
        unless ($sound =~ /^[1..7]$/) {
            $sound = "1";
        }
        $sound .= ".caf";
    }

    if (my $s = $param{silent}) {
        $s = lc $s;
        unless ($s eq 'off' or $s eq 'no' or $s eq 'false') {
            $silent = 1;
            $sound  = undef;
        }
    }
    $nparam{"${N}[silent]"} = $silent;
    $nparam{"${N}[sound]"}  = $sound || "";

    return \%nparam;
}

sub post_request {
    my $notifier = shift;
    my ($uri, $body, %cbs) = @_;

    http_request
        POST      => $uri,
        body      => $body,
        headers   => {
            'Content-Type' => 'application/x-www-form-urlencoded',
            'User-Agent'   => q{yann's Net::AppNotifications},
        },
        on_header => sub {
            my ($hds) = @_;
            if ($hds->{Status} ne '200') {
                return $cbs{on_error}->("$hds->{Status}: $hds->{Reason}");
            }
            return 1;
        },
        $cbs{on_posted};
    return
}

sub get_key {
    my $class = shift;

    my $done = AnyEvent->condvar;
    my $key;
    my $got_key = sub { $key = shift; $done->send };

    $class->async_get_key( @_, got_key => $got_key );

    $done->recv;
    return $key;
}

sub async_get_key {
    my $class = shift;
    my %param = shift;

    my $email    = $param{email} or return;
    my $password = $param{password};
    my $uri      = KEY_URI;

    my $body     = build_body(
       'user_session[email]'    => $email,
       'user_session[password]' => $password,
    );
    my %cbs = (
        on_posted => sub {
            my $key = shift;
            $param{got_key}->($key);
        },
    );
    $class->post_request($uri, $body, %cbs);
    return;
}

sub build_body {
    my %param = @_;
    return
        join "&", map {
            join "=", $_, uri_escape_utf8($param{$_})
        }
        keys %param;
}


1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Net::AppNotifications - send notifications to your iPhone.

=head1 SYNOPSIS

  $notifier = Net::AppNotifications->new(
      email    => $registered_email,
      password => $password,
  );

  # - or, prefered -

  $notifier = Net::AppNotifications->new(
      key => $key,
  );

  ## Synchronous blocking notification
  if ($notifier->send("Hello, Mr Jobs")) {
      print "Notification delivered";
  }

  ## Asynchronous non-blocking notification
  my $sent = AnyEvent->condvar;
  my $handle = $notifier->send(
    message               => "Hello!",  # shows up in the notification
    long_message          => "<b>html allowed</b>",    # in the iPhone app
    long_message_preview  => "the notif preview",      # in the iPhone app
    title                 => "the notification title", # in the iPhone app
    sound                 => 2,       # override default audible bell
    silent                => 0,       # if true, make sure there is no bell
    message_level         => -2,      # priority ([-2, 2])
    action_loc_key        => "Approve me", # button on the notification

    # what happened when clicked
    run_command  => "http://maps.google.com/maps?q=cupertino",

    ## delivery callbacks
    on_error   => $error_cb,
    on_timeout => $timeout_cb,
    on_success => sub { $sent->send },
  );
  $sent->recv;

  ## returns undef in case of error
  $key = Net::AppNotifications->get_key(
    email => $registered_email,
    password => $password,
  );

=head1 DESCRIPTION

Net::AppNotifications is a wrapper around appnotifications.com. It allows
you to push notifications to your iPhone(s) registered with the service.

A visual and audible alert (like for SMS) will arrive on your device
in a limited timeframe.

appnotifications allows you to tweak different aspect of the notification
received:

=over 4

=item * the message

=item * the sound played, if any

=item * the title of the accept button of the notification

=item * what happens once accepted

=item * ... more, see the L<SYNOPSIS>

=back

If you already have an APNS key, I recommend using L<AnyEvent::APNS>,
directly. 

=head1 AUTHOR

Yann Kerherve E<lt>yannk@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<AnyEvent::APNS>, L<http://www.appnotifications.com>

=cut
