package Pangloss::Segment::Decline::NoListTerms;

use base qw( OpenFrame::WebApp::Segment::Decline );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.1 $ '))[2];

sub should_decline {
    my $self    = shift;
    my $request = $self->store->get('OpenFrame::Request') || return;
    my $path    = $request->uri ? $request->uri->path : '';
    my $args    = $request->arguments;

    return 0 if (($path =~ /\/terms\.html$/i) or
		 ($args->{list_terms}));
    return 1;
}

1;
