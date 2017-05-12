package Net::NicoVideo::Response::MylistRSS;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.28';

use base qw(Net::NicoVideo::Response);
use Net::NicoVideo::Content::MylistRSS;

sub parsed_content { # implement
    my $self = shift;
    Net::NicoVideo::Content::MylistRSS->new($self->_component)->parse;
}


1;
__END__
