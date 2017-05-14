package Plack::ResponseHelper::Text;
use strict;
use warnings;

use Encode qw/encode/;
use Plack::Response;

sub helper {
    my $init = shift;
    my $content_type = $init && $init->{content_type} || 'text/plain';
    my $encoding = $init && $init->{encoding} || 'utf-8';

    return sub {
        my $r = shift;
        my $response = Plack::Response->new(200);
        $response->content_type($content_type);
        $response->body(ref $r eq 'ARRAY' ? [map {encode $encoding, $_} @$r] : encode $encoding, $r);
        return $response;
    };
}

1;

__END__

=head1 NAME

Plack::ResponseHelper::Text

=head1 SYNOPSIS

    use Plack::ResponseHelper 'text' => 'Text';
    respond text => 'line';
    respond text => ['line1', 'line2'];

=head1 SEE ALSO

Plack::ResponseHelper

=cut
