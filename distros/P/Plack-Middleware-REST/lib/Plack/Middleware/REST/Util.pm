package Plack::Middleware::REST::Util;

our $VERSION = '0.03';

use Plack::Request;

use parent 'Exporter';

our @EXPORT = qw(request_id request_content request_uri);

sub request_id {
    substr($_[0]->{PATH_INFO} || '/',1)
}

sub request_content {
    return unless defined $_[0]->{CONTENT_LENGTH};
    return (Plack::Request->new($_[0])->content => $_[0]->{CONTENT_TYPE});
}

sub request_uri {
    my $env = shift;
    my $id  = @_ ? shift : request_id($env);
    my $uri = Plack::Request->new($env)->base;
    $uri .= '/' unless $uri =~ qr{/$};
    return $uri . $id;
}

1;
__END__

=head1 NAME

Plack::Middleware::REST::Util - Utility methods to create RESTful PSGI applications

=head1 SYNOPSIS

    use Plack::Middleware::REST::Util;

    $id  = request_id($env)      # empty string or local resource identifier
    $uri = request_uri($env)     # resource identifier of current request
    $uri = request_uri($env,$id) # resource identifier of modified request
    ($content => $type) = request_content($env); # send content and MIME type

=cut
