package Net::NicoVideo::Response::Flv;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.28';

use base qw(Net::NicoVideo::Response);
use Net::NicoVideo::Content::Flv;

sub parsed_content { # implement
    my $self = shift;
    Net::NicoVideo::Content::Flv->new($self->_component)->parse;
}

1;
__END__
