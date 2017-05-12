package Net::NicoVideo::Response::NicoAPI;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.28';

use base qw(Net::NicoVideo::Response);

use Net::NicoVideo::Content::NicoAPI;

sub parsed_content { # implement
    my $self = shift;
    Net::NicoVideo::Content::NicoAPI->new($self->_component)->parse;
}


1;
__END__
