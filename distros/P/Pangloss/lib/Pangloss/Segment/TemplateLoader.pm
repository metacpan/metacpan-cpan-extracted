package Pangloss::Segment::TemplateLoader;

use base qw( OpenFrame::WebApp::Segment::Template::Loader );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.1 $ '))[2];

sub dispatch {
    my $self     = shift;
    my $response = $self->SUPER::dispatch || return;
    #if (Encode::is_utf8( $self->message )) {
    $response->mimetype( 'text/html; charset=UTF-8' );
}

1;
