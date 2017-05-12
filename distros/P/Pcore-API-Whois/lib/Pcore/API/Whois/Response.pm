package Pcore::API::Whois::Response;

use Pcore -class, -const, -export => { CONST => [qw[$WHOIS_FOUND $WHOIS_NOT_FOUND $WHOIS_NETWORK_ERROR $WHOIS_NO_CONTENT $WHOIS_BANNED $WHOIS_UNKNOWN $WHOIS_NOT_SUPPORTED]] };

with qw[Pcore::Util::Result::Status];

has query => ( is => 'ro', isa => Str, required => 1 );

has server    => ( is => 'ro' );
has content   => ( is => 'ro', isa => ScalarRef );
has is_cached => ( is => 'ro', isa => Bool, default => 0 );

const our $WHOIS_FOUND         => 200;    # NOT available for registration
const our $WHOIS_NOT_FOUND     => 201;    # available for registration
const our $WHOIS_NETWORK_ERROR => 500;    # network error
const our $WHOIS_NO_CONTENT    => 501;    # no content
const our $WHOIS_BANNED        => 502;    # IP addr. is banned
const our $WHOIS_UNKNOWN       => 503;    # unknown response type
const our $WHOIS_NOT_SUPPORTED => 504;    # pub. suffix is not supported

const our $STATUS_REASON => {
    $WHOIS_FOUND         => 'Found',
    $WHOIS_NOT_FOUND     => 'Not found',
    $WHOIS_NETWORK_ERROR => 'Network error',
    $WHOIS_NO_CONTENT    => 'No content',
    $WHOIS_BANNED        => 'Banned',
    $WHOIS_UNKNOWN       => 'Unknown',
    $WHOIS_NOT_SUPPORTED => 'Not supported',
};

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Whois::Response

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
