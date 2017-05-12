package POE::Component::IRC::Plugin::ImageMirror;
BEGIN {
  $POE::Component::IRC::Plugin::ImageMirror::AUTHORITY = 'cpan:HINRIK';
}
BEGIN {
  $POE::Component::IRC::Plugin::ImageMirror::VERSION = '0.15';
}

use strict;
use warnings FATAL => 'all';
use HTTP::Cookies;
use HTTP::Headers;
use Encode qw(is_utf8);
use List::Util qw(first);
use POE;
use POE::Component::IRC::Common qw(irc_to_utf8);
use POE::Component::IRC::Plugin qw(PCI_EAT_NONE PCI_EAT_PLUGIN);
use POE::Component::IRC::Plugin::URI::Find;
use POE::Quickie;
use URI::Title qw(title);
use Image::ImageShack;
use Try::Tiny;

sub new {
    my ($package, %args) = @_;
    my $self = bless \%args, $package;

    # defaults
    $self->{useragent} =
      'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9b3pre) Gecko/2008020108'
      if !defined $self->{useragent};

    $self->_text_to_regex();
    $self->{URI_match} = [qr/(?i:jpe?g|gif|png)$/] if !$self->{URI_match};
    $self->{URI_title} = 1 if !defined $self->{URI_title};
    $self->{Method} = 'notice' if !defined $self->{Method};
    $self->{req} = [];

    return $self;
}

sub _text_to_regex {
    my ($self) = @_;

    no re 'eval';
    if ($self->{URI_match}) {
        for my $elem (@{ $self->{URI_match} }) {
            $elem = qr/$elem/ if !ref $elem;
        }
    }

    while (my ($key, $value) = each %{ $self->{URI_subst} }) {
        if (!ref $key) {
            delete $self->{URI_subst}{$key};
            $self->{URI_subst}{qr/$key/} = $value;
        }
    }

    return;
}

sub PCI_register {
    my ($self, $irc) = @_;

    if ( !grep { $_->isa('POE::Component::IRC::Plugin::URI::Find') } values %{ $irc->plugin_list() } ) {
        $irc->plugin_add('URIFind', POE::Component::IRC::Plugin::URI::Find->new());
    }

    $self->{irc} = $irc;
    POE::Session->create(
        object_states => [
            $self => [qw(
                _start
                _sig_DIE
                _process_uri
                _mirror_imgur
                _mirror_imgshack
                _mirrored
                _post_uri
            )],
        ],
    );

    $irc->plugin_register($self, 'SERVER', qw(urifind_uri));
    return 1;
}

sub PCI_unregister {
    my ($self, $irc) = @_;
    $poe_kernel->refcount_decrement($self->{session_id}, __PACKAGE__);
    return 1;
}

sub _start {
    my ($kernel, $self, $session) = @_[KERNEL, OBJECT, SESSION];
    $self->{session_id} = $session->ID();
    $kernel->sig(DIE => '_sig_DIE');
    $kernel->refcount_increment($self->{session_id}, __PACKAGE__);
    return;
}

sub _sig_DIE {
    my ($kernel, $self, $ex) = @_[KERNEL, OBJECT, ARG1];
    chomp $ex->{error_str};
    warn "Error: Event $ex->{event} in $ex->{dest_session} raised exception:\n";
    warn "  $ex->{error_str}\n";
    $kernel->sig_handled();
    return;
}

sub S_urifind_uri {
    my ($self, $irc) = splice @_, 0, 2;
    my $where = ${ $_[1] };
    my $uri   = ${ $_[2] };

    return PCI_EAT_NONE if $self->_ignoring_channel($where);

    my $matched;
    for my $match (@{ $self->{URI_match} }) {
        $matched = 1 if $uri =~ $match;
        last if $matched;
    }
    return PCI_EAT_NONE if !$matched;

    if ($self->{URI_subst}) {
        while (my ($regex, $subst) = each %{ $self->{URI_subst} }) {
            $uri =~ s/$regex/$subst/;
        }
    }

    $poe_kernel->call($self->{session_id}, '_process_uri', $where, $uri);

    return $self->{Eat}
        ? PCI_EAT_PLUGIN
        : PCI_EAT_NONE;
}

sub _ignoring_channel {
    my ($self, $chan) = @_;

    if ($self->{Channels}) {
        return 1 if !first {
            my $c = $chan;
            $c = irc_to_utf8($c) if is_utf8($_);
            $_ eq $c
        } @{ $self->{Channels} };
    }
    return;
}

sub _process_uri {
    my ($kernel, $self, $sender, $where, $uri) =
        @_[KERNEL, OBJECT, SENDER, ARG0, ARG1];

    $kernel->refcount_increment($sender->ID, __PACKAGE__);

    my $req = {
        sender   => $sender->ID,
        where    => $where,
        orig_uri => $uri,
    };
    push @{ $self->{req} }, $req;


    if ($self->{URI_title}) {
        my $title;
        for (1..3) {
            ($title) = quickie(sub { print title($uri), "\n" });
            chomp $title;
            last if length $title;
        }
        $req->{title} = $title;
    }

    POE::Quickie->run(
        Program     => sub {
            _mirror_imgur($self->{Imgur_user}, $self->{Imgur_pass}, $uri);
        },
        Context     => [$req, '0_imgur'],
        StdoutEvent => '_mirrored',
    );

    POE::Quickie->run(
        Program     => sub { _mirror_imgshack($self->{useragent}, $uri) },
        Context     => [$req, '1_imgshack'],
        StdoutEvent => '_mirrored',
    );

    return;
}

sub _mirror_imgur {
    my ($imgur_user, $imgur_pass, $orig_uri) = @_;

    my $ua = LWP::UserAgent->new(
        cookie_jar            => HTTP::Cookies->new,
        requests_redirectable => [qw(GET HEAD POST)],
    );

    $ua->post(
        'http://imgur.com/signin',
        {
            username => $imgur_user,
            password => $imgur_pass,
            submit   => '',
        },
    );

    my $imgur = '';

    TRY: for (1..3) {
        my $res = $ua->get("http://imgur.com/api/upload/?url=$orig_uri");

        if ($res->is_success) {
            if (my ($uri) = $res->content =~ m{id="direct"\s+value="(.*?)"}) {
                $imgur = $uri;
                last TRY;
            }
        }
    }

    print $imgur, "\n";
    return;

}

sub _mirror_imgshack {
    my ($useragent, $orig_uri) = @_;

    my $ua = LWP::UserAgent->new(
        cookie_jar            => HTTP::Cookies->new,
        requests_redirectable => [qw(GET HEAD POST)],
        ua                    => $useragent,
        default_header        => HTTP::Headers->new(
            Referer => 'http://imageshack.us/',
        ),
    );
    my $ishack = Image::ImageShack->new;

    my $imgshack = '';

    TRY: for (1..3) {
        try {
            my $url = $ishack->host($orig_uri);

            # Try to get the big version
            my $res = $ua->get($url);
            if ($res->is_success) {
                if (my ($big_url) = $res->content =~ m{<meta property="og:image" content="(.*?)"}) {
                    $imgshack = $big_url;
                    last TRY;
                }
            }
        };
    }

    print $imgshack, "\n";
    return;
}

sub _mirrored {
    my ($kernel, $self, $uri, $context) = @_[KERNEL, OBJECT, ARG0, ARG2];

    my ($req, $mirror) = @$context;
    $req->{mirrored}{$mirror} = $uri;

    while (@{ $self->{req} }
        && $self->{req}[0]{mirrored}
        && keys %{ $self->{req}[0]{mirrored} } == 2) {
        my $request = shift @{ $self->{req} };
        $kernel->yield(_post_uri => $request);
    }
    return;
}

sub _post_uri {
    my ($kernel, $self, $req) = @_[KERNEL, OBJECT, ARG0];

    my $title = $self->{URI_title} ? "$req->{title} - " : '';
    my $mirrors = join ' / ',
                  map { $req->{mirrored}{$_} }
                  sort keys %{ $req->{mirrored} };

    $self->{irc}->yield($self->{Method}, $req->{where}, "$title$mirrors");

    $kernel->refcount_decrement($req->{sender}, __PACKAGE__);
    return;
}

1;

=encoding utf8

=head1 NAME

POE::Component::IRC::Plugin::ImageMirror - A PoCo-IRC plugin which uploads select images to a mirror service

=head1 SYNOPSIS

To quickly get an IRC bot with this plugin up and running, you can use
L<App::Pocoirc|App::Pocoirc>:

 $ pocoirc -s irc.perl.org -j '#bots' -a ImageMirror

Or use it in your code:

 use POE::Component::IRC::Plugin::ImageMirror;

 # mirror all images from 4chan.org
 $irc->plugin_add(ImageMirror => POE::Component::IRC::Plugin::ImageMirror->new(
     URI_match => [
         qr{4chan\.org/\w+/src/.*(?i:jpe?g|gif|png)$},
     ],
 ));

=head1 DESCRIPTION

POE::Component::IRC::Plugin::ImageMirror is a
L<POE::Component::IRC|POE::Component::IRC> plugin. It looks for image URLs in
the channel log and uploads the images to Imageshack and Imgur, then prints a
short description of the image along with the new URLs.

 <avar> http://images.4chan.org/b/src/1267339589262.gif
 -MyBot:#channel- gif (318 x 241) - http://imgur.com/RWcSE.gif - http://img535.imageshack.us/img535/9685/1267339589262.gif

This plugin makes use of
L<POE::Component::IRC::Plugin::URI::Find|POE::Component::IRC::URI::Find>. An
instance will be added to the plugin pipeline if it is not already present.

=head1 METHODS

=head2 C<new>

Takes the following optional arguments:

B<'Channels'>, an array reference of channels names. If you don't supply
this, images will be mirrored in all channels.

B<'URI_match'>, an array reference of regex objects. Any url found must match
at least one of these regexes if it is to be uploaded. If you don't supply
this parameter, a default regex of C<qr/(?i:jpe?g|gif|png)$/> is used.

B<'URI_subst'>, an hash reference of regex/string pairs. These
substitutions will be done on the accepted URIs before they are processed
further.

Example:

 # always fetch 7chan images via http, not https
 URI_subst => [
     qr{(?<=^)https(?=://(?:www\.)?7chan\.org)} => 'http',
 ]

B<'URI_title'>, whether or not to include a title produced by
L<URI::Title|URI::Title>. Defaults to true.

B<'Imgur_user'>, an Imgur username. If provided, the images uploaded to Imgur
will be under this account rather than anonymous.

B<'Imgur_pass'>, an Imgur account password to go with B<'ImgurUser'>.

B<'Method'>, how you want messages to be delivered. Valid options are
'notice' (the default) and 'privmsg'.

B<'Eat'>, when enabled, will prevent further processing of C<irc_urifind_uri>
events by other plugins for URIs which this plugin mirrors. False by default.

Returns a plugin object suitable for feeding to
L<POE::Component::IRC|POE::Component::IRC>'s C<plugin_add> method.

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson, hinrik.sig@gmail.com

Imageshack-related code provided by E<AElig>var ArnfjE<ouml>rE<eth>
Bjarmason <avar@cpan.org>.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Hinrik E<Ouml>rn SigurE<eth>sson

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
