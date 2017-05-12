package Pangloss::Segment::TemplateMapper;

use base qw( OpenFrame::WebApp::Segment::Template );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.5 $ '))[2];

sub dispatch {
    my $self     = shift;
    my $request  = $self->store->get('OpenFrame::Request') || return;
    my $tfactory = $self->store->get('OpenFrame::WebApp::Template::Factory') || return;

    return if $self->get_template_from_store;

    my $file = $request->uri->path || return;

    $file .= 'index.html' if ($file =~ /\/$/);

    # only accept .html files:
    return unless ($file =~ /^.+\.html$/i);

    $self->emit( "mapped $uri --> $file" );

    return $tfactory->new_template( $file ) if ($file);
}

1;
