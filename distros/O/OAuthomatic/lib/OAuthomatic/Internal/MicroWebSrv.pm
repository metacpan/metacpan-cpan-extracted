package OAuthomatic::Internal::MicroWebSrv;
# ABSTRACT: temporary embedded web server used internally - request handling


use namespace::sweep;
use Moose;
use MooseX::AttributeShortcuts;
use MooseX::Types::Path::Tiny qw/AbsDir AbsPath/;
use Path::Tiny qw/path/;
use threads;
use Thread::Queue;
use HTTP::Server::Brick;
use HTTP::Status;
use IO::Null;
use Template;
use OAuthomatic::Internal::Util qw/parse_http_msg_form/;

has 'app_name' => (is=>'ro', isa=>'Str', required=>1);
has 'site_name' => (is=>'ro', isa=>'Str', required=>1);
has 'site_client_creation_page' => (is=>'ro', isa=>'Str', required=>1);
has 'site_client_creation_desc' => (is=>'ro', isa=>'Str', required=>1);
has 'site_client_creation_help' => (is=>'ro', isa=>'Str', required=>1);
has 'static_dir' => (is=>'ro', isa=>AbsDir, required=>1, coerce=>1);
has 'template_dir' => (is=>'ro', isa=>AbsDir, required=>1, coerce=>1);
has 'port' => (is=>'ro', isa=>'Int', required=>1);
has 'callback_path' => (is=>'ro', isa=>'Str', required=>1);
has 'client_key_path' => (is=>'ro', isa=>'Str', required=>1);
has 'debug' => (is=>'ro', isa=>'Bool', required=>1);
has 'verbose' => (is=>'ro', isa=>'Bool', required=>1);
has 'oauth_queue' => (is=>'ro', required=>1, clearer=>'_clear_oauth_queue');
has 'client_key_queue' => (is=>'ro', required=>1, clearer=>'_clear_client_key_queue');

has '_brick' => (is=>'lazy', clearer=>'_clear_brick');
has '_template' => (is=>'lazy', clearer=>'_clear_template');

sub run {
    my $self = shift;

    my $debug = $self->debug;

    $self->_template;  # Not needed but let's fail fast if there are problems
    my $brick = $self->_brick;

    $brick->mount($self->callback_path => {
        handler => sub {
            return $self->_handle_oauth_request(@_);
        },
        wildcard => 1,  # let's treat longer urls as erroneous replies
    });
    $brick->mount($self->client_key_path => {
        handler => sub {
            return $self->_handle_client_key_request(@_);
        },
    });
    $brick->mount("/favicon.ico" => {
        handler => sub {
            return RC_NOT_FOUND;
        },
    });
    $brick->mount("/static" => {
        path => $self->static_dir,
    });
    $brick->mount( '/' => {
        handler => sub {
            return $self->_handle_generic_request(@_);
        },
        wildcard => 1,
    });

    print "[OAuthomatic] Embedded web server listens to requests\n" if $debug;

    # Signalling we started. This queue is as good as any
    $self->oauth_queue->enqueue({"started" => 1});

    $brick->start();

    # Clear variables, just in case.
    $self->_clear_brick;
    $self->_clear_template;
    $self->_clear_oauth_queue;
    $self->_clear_client_key_queue;
    undef $brick;
    undef $self;

    print "[OAuthomatic] Embedded web server is shut down\n" if $debug;

    return;
}

sub _build__template {
    my $self = shift;

    my $tt_vars  = {
        app_name => $self->app_name,
        site_name => $self->site_name,
        site_client_creation_page => $self->site_client_creation_page,
        site_client_creation_desc => $self->site_client_creation_desc,
        site_client_creation_help => $self->site_client_creation_help,
        static_dir => $self->static_dir,
       };

    my $tt = Template->new({
        INCLUDE_PATH=>[$self->template_dir, $self->static_dir],
        VARIABLES=>$tt_vars,
        ($self->debug ? (CACHE_SIZE => 0) : ()),  # Disable caching during tests
        # STRICT=>1,
    }) or die "Failed to setup templates: $Template::ERROR\n";

    return $tt;
}

sub _build__brick {
    my $self = shift;
    my @args = (
        port => $self->port,
        daemon_args => [ Timeout => 1 ],   # To make shutdown faster, Brick's timeout does not work
       );
    unless($self->verbose) {
        my $null = IO::Null->new;
        push @args, (error_log => $null, access_log => $null);
    }
    my $brick = HTTP::Server::Brick->new(@args);
    # URLs are mounted in run
    return $brick;
}

sub _render_template {
    my ($self, $response, $template_name, $template_params) = @_;

    my $tt = $self->_template;
    unless( $tt->process($template_name,
                         $template_params,
                         sub { $response->add_content(@_); }) ) {
        my $err = $tt->error();
        # use Data::Dumper; print Dumper($err->info);
        OAuthomatic::Error::Generic->throw(
            ident => "Template error",
            extra => $err->as_string());
    }
    return;
}

sub _handle_oauth_request {
    my ($self, $req, $resp) = @_;

    my $params = $req->uri->query_form_hash();   # URI::QueryParam

    my $verifier = $params->{'oauth_verifier'};
    my $token = $params->{'oauth_token'};

    my $reply = {};
    my $template_name;

    if ($verifier && $token) {
        $reply = {
            verifier => $verifier,
            token => $token,
        };
        $template_name = "oauth_granted.thtml";
    } else {
        my $oauth_problem = $params->{'oauth_problem'} || '';
        $reply->{oauth_problem} = $oauth_problem if $oauth_problem;
        if($oauth_problem eq 'user_refused') {
            $template_name = "oauth_rejected.thtml";
        } else {
            $template_name = "oauth_bad_request.thtml";
        }
    }

    $self->_render_template($resp, $template_name, $reply);

    $self->oauth_queue->enqueue($reply);

    $resp->code(200);
    return RC_OK;
}

sub _handle_client_key_request {
    my ($self, $req, $resp) = @_;

    unless($req->method eq 'POST') {
        # Just show input form
        $self->_render_template($resp, "client_key_entry.thtml", {});
    } else {
        my $params = parse_http_msg_form($req) || {};

        my %values;
        my %errors;
        # Validation
        foreach my $pname (qw(client_key client_secret)) {
            my $value = $params->{$pname};
            # Strip leading and final spaces (possible copy&paste)
            $value =~ s/^[\s\r\n]+//x;
            $value =~ s/[\s\r\n]+$//x;
            unless($value) {
                $errors{$pname} = "Missing value.";
            } elsif ($value !~ /^\S{10,1000}$/x) {
                $errors{$pname} = "Invalid value (suspiciously short, too long, or contaning invalid characters)";
            }
            $values{$pname} = $value;
        }

        unless(%errors) {
            $self->_render_template($resp, "client_key_submitted.thtml", {});
            $self->client_key_queue->enqueue(\%values);
        } else {
            # Redisplay
            $self->_render_template($resp, "client_key_entry.thtml", {
                errors_found => 1,
                error => \%errors,
                value => \%values  });
        }
    }

    $resp->code(200);
    return RC_OK;
}

sub _handle_generic_request {
    my ($self, $req, $resp) = @_;

    print "[OAuthomatic] Ignoring as unsupported request to ", $req->uri, "\n" if $self->debug;

    $self->_render_template($resp, "default.thtml", {});

    $resp->code(200);
    return RC_NOT_FOUND;
}

1;

# FIXME: reuse single browser window (maybe frame and some long polling)
# FIXME: whole process in browser, without terminal snippets

__END__

=pod

=encoding UTF-8

=head1 NAME

OAuthomatic::Internal::MicroWebSrv - temporary embedded web server used internally - request handling

=head1 VERSION

version 0.0202

=head1 DESCRIPTION

This is actual code of MicroWeb.

This object is constructed in separate thread and runs there, rest of
the code manages it via L<OAuthomatic::Internal::MicroWeb>.

=head1 AUTHOR

Marcin Kasperski <Marcin.Kasperski@mekk.waw.pl>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Marcin Kasperski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
