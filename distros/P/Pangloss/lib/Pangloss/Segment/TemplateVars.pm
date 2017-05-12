package Pangloss::Segment::TemplateVars;

use URI;

use base qw( OpenFrame::WebApp::Segment::User
	     OpenFrame::WebApp::Segment::Session
	     OpenFrame::WebApp::Segment::Template );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.8 $ '))[2];

sub dispatch {
    my $self     = shift;
    my $request  = $self->store->get('OpenFrame::Request') || return;
    my $tmpl     = $self->get_template_from_store || return;

    my $session  = $self->get_session_from_store;
    my $user     = $self->get_user_from_store;
    my $view     = $self->store->get( 'Pangloss::Application::View' );

    $tmpl->template_vars->{uri}     = $self->get_original_uri;
    $tmpl->template_vars->{pager_uri} = $self->get_pager_uri;
    $tmpl->template_vars->{request} = $request;
    $tmpl->template_vars->{user}    = $user    if $user;
    $tmpl->template_vars->{view}    = $view    if $view;
    $tmpl->template_vars->{session} = $session if $session;

    $self->emit( "template vars contain:\n\t" . join("\n\t",keys %{ $tmpl->template_vars }) );
    $self->emit( "view contains:\n\t" . join("\n\t",keys %{ $view }) ) if $view;

#    use Data::Dumper;
#    $self->emit( Dumper( $tmpl->template_vars ) );

    return 1;
}

sub get_original_uri {
    my $uri = shift->store->get( 'OriginalURI' );
    return $$uri;
}

sub get_pager_uri {
    my $self    = shift;
    my $request = ${ $self->store->get( 'OriginalRequest' ) } || return;
    my $uri     = $request->uri || return;
    my $clone   = $uri->clone;
    my %args    = %{ $request->arguments };
    delete $args{page};
    $clone->query_form( %args );
    return $clone;
}

1;

__END__


    view	# current application view
    uri		# origianl uri
    pager_uri	# search pager
    request
        arguments
    session
        id
        user	# current user
    user	# currently seleted user

