package Nephia::Plugin::CSRFDefender;
use 5.008005;
use strict;
use warnings;
use parent 'Nephia::Plugin';

our $VERSION = "0.81";

our $ERROR_HTML = <<'...';
<!doctype html>
<html>
  <head>
    <title>403 Forbidden</title>
  </head>
  <body>
    <h1>403 Forbidden</h1>
    <p>
      Session validation failed.
    </p>
  </body>
</html>
...

sub new {
    my ($class, %opts) = @_;
    my $self = $class->SUPER::new(%opts);
    my $app = $self->app;
    $app->action_chain->prepend(CSRFDefender_Before => $self->can('_before_action'));
    $app->action_chain->append(CSRFDefender_After => $self->can('_process_content'));
    return $self;
}

sub exports {
    qw/ get_csrf_defender_token validate_csrf /;
}

sub get_csrf_defender_token {
    my ($self, $context) = @_;
    return sub {
        _get_csrf_defender_token($self->app);
    };
}

sub validate_csrf {
    my ($self, $context) = @_;
    return sub {
        _validate_csrf($self->app);
    };
}

sub _get_csrf_defender_token {
    my ($app) = @_;
    
    my $session = $app->dsl('session')->();

    if ( my $token = $session->get('csrf_token') ) {
        $token;
    } else {
        $token = generate_token();
        $session->set('csrf_token' => $token);
        $token;
    }
}

sub _validate_csrf {
    my ($app) = @_;
    
    my $session = $app->dsl('session')->();
    my $req     = $app->dsl('req')->();
    
    if ( $req->{env}->{REQUEST_METHOD} eq 'POST' ) {
        my $r_token = $req->param('csrf_token');
        my $session_token = $session->get('csrf_token');
        if ( !$r_token || !$session_token || ( $r_token ne $session_token ) ) {
            return 0;
        }
    }
    return 1;
}

sub generate_token {
    my @chars = ('A'..'Z', 'a'..'z', 0..9);
    my $ret;
    for (1..32) {
        $ret .= $chars[int rand @chars];
    }
    return $ret;
}

sub _before_action {
    my ($app, $context) = @_;
    my $obj = $app->loaded_plugins->fetch('Nephia::Plugin::CSRFDefender');

    unless ($obj->{no_validate_hook}) {
        if (!_validate_csrf($app)) {
            return ($context, Nephia::Response->new(
                403,
                [
                    'Content-Type'   => 'text/html',
                    'Content-Length' => length($ERROR_HTML)
                ],
                [ $ERROR_HTML ],
            ));
        }
    }

    return $context;
}

sub _process_content {
    my ($app, $context) = @_;

    my $res  = $context->get('res');
    my $body = $res->{body}->[0]; 
    my $obj  = $app->loaded_plugins->fetch('Nephia::Plugin::CSRFDefender');

    my $form_regexp = $obj->{post_only} ? qr{<form\s*.*?\s*method=['"]?post['"]?\s*.*?>}is : qr{<form\s*.*?>}is;
   
    if (defined $body) {
        $body =~ s!($form_regexp)!qq{$1\n<input type="hidden" name="csrf_token" value="}._get_csrf_defender_token($app).qq{" />}!ge;
    }

    $res->{body}->[0] = $body;
    $context->set('res' => $res);

    return $context;
}

1;

__END__

=encoding utf8

=head1 NAME

Nephia::Plugin::CSRFDefender - CSRF Defender Plugin for Nephia

=head1 SYNOPSIS

    package MyApp;
    use strict;
    use warnings;
    use Nephia plugins => [
        'PlackSession',
        'CSRFDefender'
    ];

=head1 DESCRIPTION

Nephia::Plugin::CSRFDefender denies CSRF request.

=head1 METHODS

=over 4

=item get_csrf_defender_token()

Get a CSRF defender token.

=item validate_csrf()

Validate CSRF token manually.

=back

=head1 SEE ALSO

L<Nephia>

L<Amon2::Plugin::Web::CSRFDefender>

=head1 LICENSE

Copyright (C) papix.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

papix E<lt>mail@papix.netE<gt>

=cut
