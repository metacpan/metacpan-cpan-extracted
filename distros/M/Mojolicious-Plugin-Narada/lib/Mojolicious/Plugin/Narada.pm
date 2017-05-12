package Mojolicious::Plugin::Narada;

use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = 'v1.0.0';

use MojoX::Log::Fast;
use Narada::Config qw( get_config get_config_line );
use Narada::Lock qw( unlock );
use Scalar::Util qw( weaken );

my ($Log, $Ident);
our $IN_CB = 0;


sub register {
    my ($self, $app, $conf) = @_;

    $Log = MojoX::Log::Fast->new($conf->{log});
    $Ident = $Log->ident();

    # Replace default logger with Log::Fast.
    $app->log($Log);

    # Load Mojo-specific config files.
    if ($app->can('secrets')) {
        $app->secrets([split /\n/ms, get_config('cookie.secret')]);
    } else {
        $app->secret(get_config_line('cookie.secret'));
    }
    $app->config(hypnotoad => {
        listen      => [split /\n/ms, get_config('hypnotoad/listen')],
        proxy       => get_config_line('hypnotoad/proxy'),
        accepts     => get_config_line('hypnotoad/accepts'),
        workers     => get_config_line('hypnotoad/workers'),
        pid_file    => 'var/hypnotoad.pid',
    });

    # * Fix url->path and url->base->path.
    # * Set correct ident while handler runs.
    # * unlock() if handler died.
    my $realbase = Mojo::Path->new( get_config_line('basepath') )
        ->trailing_slash(0)
        ->leading_slash(1)
        ->to_string;
    $app->hook(around_dispatch => sub {
        my ($next, $c) = @_;
        my $url = $c->req->url;
        my $base = $url->base->path;
        my $path = $url->path;
        if ($base eq q{} && $path =~ m{\A\Q$realbase\E(.*)\z}mso) {
            $path->parse($1);
        }
        $base->parse($realbase);
        $path->leading_slash(1);
        $Log->ident($url->path);
        my $err = eval { $next->(); 1 } ? undef : $@;
        unlock();
        die $err if defined $err;   ## no critic(RequireCarping)
    });

    $app->helper(proxy      => sub { return _proxy(0, @_) });
    $app->helper(weak_proxy => sub { return _proxy(1, @_) });

    return;
}

sub _proxy {
    my ($is_weak, $this, $cb, @p) = @_;
    if ($is_weak) {
        weaken($this);
    }
    my $is_global_cb= ref $this eq 'Mojolicious::Controller';
    my $ident       = $is_global_cb ? $Ident : $Log->ident;
    my $__warn__    = $SIG{__WARN__};
    return sub {
        return if !$this;
        my $cur_ident = $Log->ident($ident);
        local $SIG{__WARN__} = $__warn__;
        my $err = eval { local $IN_CB=1; $cb->($this, @p, @_); 1 } ? undef : $@;
        if (defined $err) {
            $Log->ident($ident);
            if (!$IN_CB) {
                unlock()
            }
            if ($is_global_cb || $is_weak) {
                die $err;   ## no critic(RequireCarping)
            }
            else {
                $this->reply->exception($err);
            }
        }
        $Log->ident($cur_ident);
    };
}


1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Narada - Narada configuration plugin


=head1 VERSION

This document describes Mojolicious::Plugin::Narada version v1.0.0


=head1 SYNOPSIS

    # Mojolicious
    $self->plugin('Narada');
    $self->plugin(Narada => (log => Log::Fast->global));

    # Mojolicious::Lite
    plugin 'Narada';
    plugin Narada => (log => Log::Fast->global);

    # Global timer
    package MyApp;
    sub startup {
        my $app = shift;
        Mojo::IOLoop->timer(0 => $app->proxy(sub { say 'Next tick.' }));
    }

    # Request-related timer
    package MyApp::MyController;
    sub myaction {
        my $c = shift;
        $c->render_later;
        Mojo::IOLoop->timer(1 => $c->weak_proxy(sub { say 'Alive' }));
        Mojo::IOLoop->timer(2 => $c->proxy(sub {
              $c->render(text => 'Delayed by 2 seconds!');
        }));
        Mojo::IOLoop->timer(3 => $c->weak_proxy(sub { say 'Dead' }));
    }

=head1 DESCRIPTION

L<Mojolicious::Plugin::Narada> is a plugin that configure L<Mojolicious>
to work in L<Narada> project management environment.

Also this plugin add helpers C<proxy> and C<weak_proxy>, and you B<MUST>
use them to wrap all callbacks you setup for handling delayed events like
timers or I/O (both global in your app and related to requests in your
actions).

There is also one feature unrelated to Narada - if callback started by any
action throw unhandled exception it will be sent to browser using same
C<< $c->reply->exception >> as it already works for actions without
delayed response.

=over

=item Logging

L<Mojolicious> default L<Mojo::Log> replaced with L<MojoX::Log::Fast> to
support logging to project-local syslog daemon in addition to files.
In most cases it works as drop-in replacement and doesn't require any
modifications in user code.

Also it set C<< $app->log->ident() >> to C<< $c->req->url->path >> to
ease log file analyse.

=item Configuration

You should manually add these lines to C<./you_app> starting script before
call to C<< Mojolicious::Commands->start_app() >>:

    use Narada::Config qw( get_config_line );
    # mode should be set here because it's used before executing MyApp::startup()
    local $ENV{MOJO_MODE} = get_config_line('mode');

Config file C<config/cookie.secret> automatically loaded and used to
initialize C<< $app->secrets() >> (each line of file became separate
param).

Config file C<config/basepath> automatically loaded and used to fix
C<< $c->req->url->base->path >> and C<< $c->req->url->path >> to
guarantee their consistency in any environment:

=over

=item * url->path doesn't contain base->path

=item * url->path does have leading slash

=item * url->base->path set to content of config/basepath

=back


These config files automatically loaded from C<config/hypnotoad/*>
and used to initialize C<< $app->config(hypnotoad) >>:

    listen
    proxy
    accepts
    workers

Also hypnotoad configured to keep it lock/pid files in C<var/>.

=item Locking

C<unlock()> will be automatically called after all actions and callbacks,
even if they throw unhandled exception.

=back


=head1 OPTIONS

L<Mojolicious::Plugin::Narada> supports the following options.

=head2 log

  plugin Narada => (log => Log::Fast->global);

Value for L<MojoX::Log::Fast>->new().


=head1 METHODS

L<Mojolicious::Plugin::Narada> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);
  $plugin->register(Mojolicious->new, {log => Log::Fast->global});

Register hooks in L<Mojolicious> application.


=head1 SEE ALSO

L<Narada>, L<MojoX::Log::Fast>, L<Mojolicious>.


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/powerman/perl-Mojolicious-Plugin-Narada/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

L<https://github.com/powerman/perl-Mojolicious-Plugin-Narada>

    git clone https://github.com/powerman/perl-Mojolicious-Plugin-Narada.git

=head2 Resources

=over

=item * MetaCPAN Search

L<https://metacpan.org/search?q=Mojolicious-Plugin-Narada>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/Mojolicious-Plugin-Narada>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mojolicious-Plugin-Narada>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Mojolicious-Plugin-Narada>

=item * CPANTS: A CPAN Testing Service (Kwalitee)

L<http://cpants.cpanauthors.org/dist/Mojolicious-Plugin-Narada>

=back


=head1 AUTHOR

Alex Efros E<lt>powerman@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013-2015 by Alex Efros E<lt>powerman@cpan.orgE<gt>.

This is free software, licensed under:

  The MIT (X11) License


=cut
