package Spike::Site::Handler;

use strict;
use warnings;

use base qw(Spike::Object);

use feature 'state';

use FindBin;
use Carp;
use HTTP::Status qw(:constants);
use Scalar::Util qw(blessed);

use Spike::Error;
use Spike::Log;
use Spike::Site::Request;
use Spike::Config;

sub debug { state $debug //= $ENV{PLACK_ENV} =~ /devel/ }

sub run {
    my $proto = shift;
    my $class = ref $proto || $proto;

    state $self ||= $class->new(@_);

    return sub { $self->request(@_) };
}

sub _error_page {
    my ($self, $status) = @_;

    return '<html><head><title>'.
        HTTP::Status::status_message($status).
        '</title></head><body bgcolor="white"><center><h1>'.
        $status.' '.HTTP::Status::status_message($status).
        '</h1></center><hr><center>Spike-'.$Spike::VERSION.
        '</center></body></html>';
}

sub request {
    my ($self, $env) = @_;

    $Spike::Log::bind_values = [ $$, $env->{REMOTE_ADDR} ];

    my $req = Spike::Site::Request->new($env);
    my $res = $req->new_response(HTTP_OK);

    eval {
        $self->handler($req, $res);
    };
    if (my $error = $@) {
        if (blessed $error) {
            if ($error->isa('Spike::Error::HTTP_OK')) {
                # do nothing
            }
            elsif ($error->isa('Spike::Error::HTTP')) {
                carp "HTTP error: status=".$error->value.", text=\"".$error->text."\"";

                $res = $req->new_response($error->value, $error->headers,
                    $self->_error_page($error->value));
            }
            elsif ($error->isa('Spike::Error')) {
                carp "Error: class=".ref($error).", text=\"".$error->text."\"";

                $res = $req->new_response(HTTP_INTERNAL_SERVER_ERROR, undef,
                    $self->_error_page(HTTP_INTERNAL_SERVER_ERROR));
            }
            else {
                carp "Error: class=".ref($error).", text=\"".($error->can('text') ? $error->text : "$error")."\"";

                $res = $req->new_response(HTTP_INTERNAL_SERVER_ERROR, undef,
                    $self->_error_page(HTTP_INTERNAL_SERVER_ERROR));
            }
        }
        else {
            carp $error;

            $res = $req->new_response(HTTP_INTERNAL_SERVER_ERROR, undef,
                $self->_error_page(HTTP_INTERNAL_SERVER_ERROR));
        }
    }

    $self->clean;

    $Spike::Log::bind_values = undef;

    return $res->finalize;
}

sub handler {}
sub clean {}

1;
