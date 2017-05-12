package Net::NicoVideo::Response::MylistItem;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.28';

use base qw/Net::NicoVideo::Response/;
use Net::NicoVideo::Content::MylistItem;

sub parsed_content { # implement
    my $self = shift;
    Net::NicoVideo::Content::MylistItem->new($self->_component)->parse;
}


1;
__END__
