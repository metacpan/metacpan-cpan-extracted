use strict;
use warnings;
use Test::More;
use Test::Exception;

BEGIN {
    eval "use Sledge::TestPages;use Apache::FakeRequest";
    plan $@ ? ( skip_all => 'needs Sledge::TestPages, Sledge::FakeRequest for testing' ) : ( tests => 1 );
}

package Mock::Authorizer;
use base qw(Sledge::Authorizer::BasicAuth);
require Sledge::Authorizer::BasicAuth;

__PACKAGE__->realm('SECRET');
__PACKAGE__->error_template('401.html');

sub authorize {
    my ( $self, $page ) = @_;

    my ( $user, $pass ) = $self->basic_auth($page) or return;
    if ( $user eq 'ok' and $pass eq 'pass' ) {
        return;
    }
    else {
        $self->show_error_page($page);
    }
}

package Mock::Pages;
use base qw(Sledge::TestPages);

use Apache::FakeRequest;

sub CGI::header_in { $ENV{HTTP_AUTHORIZATION} }

sub create_authorizer { Mock::Authorizer->new(shift) }

sub dispatch_ok_password {
    ::pass('ok_password');
    shift->redirect('/ok');
}

sub dispatch_empty_password {
    ::fail('empty_password');
    shift->redirect('/empty');
}

sub dispatch_invalid_password {
    ::fail('invalid_password');
    shift->redirect('/invalid');
}

package main;
my $d = $Mock::Pages::TMPL_PATH;
$Mock::Pages::TMPL_PATH = 't/';
my $c = $Mock::Pages::COOKIE_NAME;
$Mock::Pages::COOKIE_NAME = 'sid';
$ENV{HTTP_COOKIE}         = "sid=SIDSIDSIDSID";
$ENV{REQUEST_METHOD}      = 'GET';
$ENV{QUERY_STRING}        = 'aff_type=mock&s=ABCDEFG';

$ENV{HTTP_AUTHORIZATION} = "Basic b2s6cGFzcw==\n";
Mock::Pages->new->dispatch('ok_password');

$ENV{HTTP_AUTHORIZATION} = 'Basic Og==';
Mock::Pages->new->dispatch('empty_password');
$ENV{HTTP_AUTHORIZATION} = 'Basic aW46dmFsaWQ=';
Mock::Pages->new->dispatch('invalid_password');

