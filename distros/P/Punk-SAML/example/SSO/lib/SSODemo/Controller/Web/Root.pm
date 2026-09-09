package SSODemo::Controller::Web::Root;

use Punk::Controller;

our $VERSION = '0.01';

# Controller methods are plain subs receiving the context - no instance, no
# dispatch overhead. The coderef is resolved once at to_app and called
# directly per request.

sub index {
    my ($c) = @_;
    return $c->render('welcome', {
        title   => 'SSODemo',
        app     => 'SSODemo',
        version => $Punk::VERSION,
        routes  => [
            { method => 'GET',  path => '/',              target => 'Web::Root#index' },
            { method => 'GET',  path => '/me',            target => 'Web::Root#me'    },
            { method => 'GET',  path => '/saml/metadata', target => 'Punk::Plugin::SAML' },
            { method => 'GET',  path => '/saml/login',    target => 'Punk::Plugin::SAML' },
            { method => 'POST', path => '/saml/acs',      target => 'Punk::Plugin::SAML' },
        ],
        idps    => [ $c->saml_idps ],
    });
}

# What a signed-in user looks like. Everything shown here came out of a
# verified assertion: nothing on this page was read before the signature
# over it was checked.
sub me {
    my ($c) = @_;
    # auth_id is the signed-in id straight off the session, with no
    # database behind it. A real application declares `auth model` and
    # uses $c->user instead.
    my $id   = $c->auth_id or return $c->redirect($c->url_for('home'), 303);
    my $user = $SSODemo::USERS{$id}
        or return $c->redirect($c->url_for('home'), 303);
    return $c->render('me', {
        title  => 'Signed in',
        app    => 'SSODemo',
        email  => $user->{email},
        nameid => $user->{name_id},
        groups => $user->{groups},
    });
}

1;

__END__

=head1 NAME

SSODemo::Controller::Web::Root - the front page

=head1 METHODS

=head2 index

Renders the welcome page, with a sign-in link per configured provider.

=head2 me

Renders the identity of the signed-in user, or redirects home when there
is none.

=cut
