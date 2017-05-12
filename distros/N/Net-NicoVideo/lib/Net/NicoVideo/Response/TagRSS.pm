package Net::NicoVideo::Response::TagRSS;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.28';

use base qw(Net::NicoVideo::Response);
use Net::NicoVideo::Content::TagRSS;

sub parsed_content { # implement
    my $self = shift;
    Net::NicoVideo::Content::TagRSS->new($self->_component)->parse;
}


1;
__END__
