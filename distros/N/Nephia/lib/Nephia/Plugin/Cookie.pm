package Nephia::Plugin::Cookie;
use strict;
use warnings;
use parent 'Nephia::Plugin';
use Scalar::Util ();
use Nephia::Response;

sub exports {
    qw/cookie/;
}

sub new {
    my ($class, %opts) = @_;
    my $self = $class->SUPER::new(%opts);
    my $app = $self->app;
    $app->action_chain->prepend(CookieEater => $self->can('_eat_cookie'));
    $app->action_chain->append(CookieImprinter => $self->can('_imprint_cookie'));
    return $self;
}

sub cookie {
    my ($self, $context) = @_;
    return sub (;$$) {
        my $cookies = $context->get('cookies');
        $cookies ||= {};
        if ($_[0] && $_[1]) {
            $cookies->{$_[0]} = $_[1];
            $context->set(cookies => $cookies);
        }
        my $rtn = $_[0] ? $cookies->{$_[0]} : $cookies;
        return $rtn;
    };
}

sub _eat_cookie {
    my ($app, $context) = @_;
    my $req = $context->get('req');
    my $cookies = $req->cookies || {};
    $context->set(cookies => $cookies);
    return $context;
}

sub _imprint_cookie {
    my ($app, $context) = @_;
    my $res = $context->get('res');
    $res = Scalar::Util::blessed($res) ? $res : Nephia::Response->new(@$res);
    my $cookies = $context->get('cookies');
    if ($cookies) {
        $res->cookies->{$_} = $cookies->{$_} for keys %$cookies;
        $context->set(res => $res);
    }
    return $context;
}

1;

__END__

=encoding utf-8

=head1 NAME

Nephia::Plugin::Cookie - Cookie manipulation for Nephia

=head1 DESCRIPTION

This plugin provides cookie manipulation feature.

=head1 SYNOPSIS

    package YourApp::Web;
    use Nephia plugins => ['Cookie'];
    app {
        my $count = cookie('count') || 0;
        $count++;
        cookie(count => $count);
        [200, [], "count = $count"];
    };

=head1 DSL

=head2 cookie

    # set cookie
    cookie($name => $value);
    
    # get cookie
    my $value = cookie($name);

Set or get specified cookie.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut

