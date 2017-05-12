#line 1
package Plack::Builder;
use strict;
use parent qw( Exporter );
our @EXPORT = qw( builder add enable enable_if mount );

use Carp ();
use Plack::App::URLMap;
use Plack::Middleware::Conditional; # TODO delayed load?
use Scalar::Util ();

sub new {
    my $class = shift;
    bless { middlewares => [ ] }, $class;
}

sub add_middleware {
    my($self, $mw, @args) = @_;

    if (ref $mw ne 'CODE') {
        my $mw_class = Plack::Util::load_class($mw, 'Plack::Middleware');
        $mw = sub { $mw_class->wrap($_[0], @args) };
    }

    push @{$self->{middlewares}}, $mw;
}

sub add_middleware_if {
    my($self, $cond, $mw, @args) = @_;

    if (ref $mw ne 'CODE') {
        my $mw_class = Plack::Util::load_class($mw, 'Plack::Middleware');
        $mw = sub { $mw_class->wrap($_[0], @args) };
    }

    push @{$self->{middlewares}}, sub {
        Plack::Middleware::Conditional->wrap($_[0], condition => $cond, builder => $mw);
    };
}

# do you want remove_middleware() etc.?

sub _mount {
    my ($self, $location, $app) = @_;

    if (!$self->{_urlmap}) {
        $self->{_urlmap} = Plack::App::URLMap->new;
    }

    $self->{_urlmap}->map($location => $app);
    $self->{_urlmap}; # for backward compat.
}

sub to_app {
    my($self, $app) = @_;

    if ($app) {
        $self->wrap($app);
    } elsif ($self->{_urlmap}) {
        $self->{_urlmap} = $self->{_urlmap}->to_app
            if Scalar::Util::blessed($self->{_urlmap});
        $self->wrap($self->{_urlmap});
    } else {
        Carp::croak("to_app() is called without mount(). No application to build.");
    }
}

sub wrap {
    my($self, $app) = @_;

    if ($self->{_urlmap} && $app ne $self->{_urlmap}) {
        Carp::carp("WARNING: wrap() and mount() can't be used altogether in Plack::Builder.\n" .
                   "WARNING: This causes all previous mount() mappings to be ignored.");
    }

    for my $mw (reverse @{$self->{middlewares}}) {
        $app = $mw->($app);
    }

    $app;
}

# DSL goes here
our $_add = our $_add_if = our $_mount = sub {
    Carp::croak("enable/mount should be called inside builder {} block");
};

sub enable         { $_add->(@_) }
sub enable_if(&$@) { $_add_if->(@_) }

sub mount {
    my $self = shift;
    if (Scalar::Util::blessed($self)) {
        $self->_mount(@_);
    }else{
        $_mount->($self, @_);
    }
}

sub builder(&) {
    my $block = shift;

    my $self = __PACKAGE__->new;

    my $mount_is_called;
    my $urlmap = Plack::App::URLMap->new;
    local $_mount = sub {
        $mount_is_called++;
        $urlmap->map(@_);
        $urlmap;
    };
    local $_add = sub {
        $self->add_middleware(@_);
    };
    local $_add_if = sub {
        $self->add_middleware_if(@_);
    };

    my $app = $block->();

    if ($mount_is_called) {
        if ($app ne $urlmap) {
            Carp::carp("WARNING: You used mount() in a builder block, but the last line (app) isn't using mount().\n" .
                       "WARNING: This causes all mount() mappings to be ignored.\n");
        } else {
            $app = $app->to_app;
        }
    }

    $app = $app->to_app if $app and Scalar::Util::blessed($app) and $app->can('to_app');

    $self->to_app($app);
}

1;

__END__

#line 346



