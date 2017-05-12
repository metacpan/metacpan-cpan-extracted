package RT::Atom;
$RT::Atom::VERSION = '0.03';

use strict;

use URI;
use XML::Simple;
use Digest::MD5;
use Digest::SHA1;
use MIME::Base64;

*RT::Date::W3CDTF = sub {
    my $self = shift;
    my $date = $self->ISO . 'Z';
    $date =~ s/ /T/;
    return $date;
} unless defined &RT::Date::W3CDTF;

1;
