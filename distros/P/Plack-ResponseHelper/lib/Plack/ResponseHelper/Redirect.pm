package Plack::ResponseHelper::Redirect;
use strict;
use warnings;

use Carp;
use Plack::Response;

sub helper {
    my $init = shift;
    my $default_location = $init && $init->{default_location};
    my $status = $init && $init->{default_status} || 302;

    return sub {
        my $r = shift;
        $r = $default_location unless defined $r;
        croak "No location specified" unless length $r;
        my $response = Plack::Response->new();
        $response->redirect($r, $status);
        return $response;
    };
}

1;

__END__

=head1 NAME

Plack::ResponseHelper::Redirect

=head1 SYNOPSIS

    use Plack::ResponseHelper redirect => 'Redirect',
                              page404  => [
                                  'Redirect',
                                  {default_status => 404, default_location => '/404.html'}
                              ];
    respond redirect => $location;
    respond page404 => undef;

=head1 SEE ALSO

Plack::ResponseHelper

=cut
