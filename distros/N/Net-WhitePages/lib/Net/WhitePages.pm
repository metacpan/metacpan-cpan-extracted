package Net::WhitePages;

use strict;
use vars qw($VERSION);

$VERSION = '1.05';

use LWP::Simple qw($ua get);
use Params::Validate qw(validate);
use URI;

use constant API_BASE => 'http://api.whitepages.com';

# Constructor -- simply stores everything given to it
sub new {
    my $class = shift;
    my $args = @_ && ref($_[0]) eq 'HASH' ? shift : { @_ };

    $ua->agent("$class/$VERSION (" . $ua->agent . ")");

    bless {
        DEBUG       => 0,
        TOKEN       => $ENV{'WHITEPAGES_TOKEN'},
        API_VERSION => '1.0',
        %$args,
    } => $class;
}

# ----------------------------------------------------------------------
# find_person()
#
# http://developer.whitepages.com/docs/Methods/find_person
# ----------------------------------------------------------------------
sub find_person {
    my $self = shift;
    return $self->_request(
        validate(@_, {
            'firstname' => 0,
            'lastname'  => 1,
            'house'     => 0,
            'street'    => 0,
            'city'      => 0,
            'state'     => 0,
            'zip'       => 0,
            'areacode'  => 0,
            'metro'     => 0,
        })
    );
}

# ----------------------------------------------------------------------
# reverse_phone
# 
# http://developer.whitepages.com/docs/Methods/reverse_phone
# ----------------------------------------------------------------------
sub reverse_phone {
    my $self = shift;
    return $self->_request(
        validate(@_, {
            'phone' => 1,
            'state' => 0,
        }),
    );
}

# ----------------------------------------------------------------------
# reverse_address
# 
# http://developer.whitepages.com/docs/Methods/reverse_address
# ----------------------------------------------------------------------
sub reverse_address {
    my $self = shift;
    return $self->_request(
        validate(@_, {
            'house'     => 0,
            'apt'       => 0,
            'street'    => 1,
            'city'      => 0,
            'state'     => 0,
            'zip'       => 0,
            'areacode'  => 0,
        }),
    );
}

# Make the URI
# Takes API_BASE, $self->{ API_VERSION }, and caller
sub _uri {
    my $self = shift;
    my $meth = shift;
    my %p = @_;
    my $uri = URI->new(API_BASE . '/' . $meth . '/' . $self->{ API_VERSION });

    my $t = $self->{ TOKEN } ||
        die "No token defined; can't make a request without a token!\n";

    $p{'api_key'} = $t;
    $p{'outputtype'} = 'Perl';
    $uri->query_form(%p);

    return $uri;
}

# Do the actual request against the whitepages.com server
sub _request {
    my $self = shift;
    my @meth = caller(1);
   (my $meth = $meth[3]) =~ s/.*:://;
    my $uri = $self->_uri($meth, @_);

    if ($self->{ DEBUG }) {
        warn "[DEBUG] Calling `", $uri->canonical, "'\n";
    }

    my $data = get($uri->canonical);

    return eval($data);
}

1;

__END__

=head1 NAME

Net::WhitePages - A Perl interface to the WhitePages.com API v1.0

=head1 SYNOPSIS

    use Net::WhitePages;

    my $wp = Net::WhitePages->new(TOKEN => "12345");
    my $res = $wp->find_person(lastname => "Wall", firstname => "Larry");

=head1 DESCRIPTION

C<Net::WhitePages> provides a simple perl wrapper for the whitepages.com
API (see http://developer.whitepages.com/ for details).  The interface
matches the API exactly; see http://developer.whitepages.com/docs for a
description of it.

You'll need to have a whitepages.com API token to function; see
http://developer.whitepages.com/ for a sign-up link and terms of service.

WhitePages.com places strict usage limitations, which this module does
not attempt to enforce.

Note that this currently only works for version 1.0 of the WhitePages.com API.

=head1 METHODS

=over 4

=item find_person

Search by a person's name and location to find the person's complete
address and phone number.  See
http://developer.whitepages.com/docs/Methods/find_person for more
details.

=item reverse_phone

Search by phone number to find the related name and address. See
http://developer.whitepages.com/docs/Methods/reverse_phone for
details.

=item reverse_address

Search by street address to find the related name and phone number.
See http://developer.whitepages.com/docs/Methods/reverse_address for
details.

=back

Each method returns a serialized version of the results data; see
http://developer.whitepages.com/docs/docs/Responses/Results_Response
for details on it looks like.

=head1 BUGS

Please report bugs via the RT queue at https://rt.cpan.org/.

=head1 VERSION

1.05

=head1 AUTHOR

Darren Chamberlain <darren@cpan.org>
