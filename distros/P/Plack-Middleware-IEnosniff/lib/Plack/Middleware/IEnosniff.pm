package Plack::Middleware::IEnosniff;
use strict;
use warnings;
use parent 'Plack::Middleware';
use Plack::Util;
use Plack::Util::Accessor qw/only_ie/;

our $VERSION = '0.02';

sub call {
    my ($self, $env) = @_;

    my $res = $self->app->($env);
    $self->response_cb($res, sub {
        my $res = shift;
        if ($res && $res->[0] == 200) {
            if ( !$self->only_ie
                    || ($env->{HTTP_USER_AGENT} && $env->{HTTP_USER_AGENT} =~ m!MSIE 8!) ) {
                my $h = Plack::Util::headers($res->[1]);
                $h->set('X-Content-Type-Options' => 'nosniff');
            }
        }
    });
}

1;

__END__

=head1 NAME

Plack::Middleware::IEnosniff - added HTTP Header 'X-Content-Type-Options: nosniff'


=head1 SYNOPSIS

    enable 'IEnosniff';

you can set 'only_ie' option, if you want to send 'X-Content-Type-Options: nosniff' for IE8 only.

    enable 'IEnosniff', only_ie => 1;


=head1 DESCRIPTION

Plack::Middleware::IEnosniff is middleware for Plack. This middleware adds HTTP Header 'X-Content-Type-Options: nosniff' for safe. Sending X-Content-Type-Options response header with the value nosniff will prevent Internet Explorer from MIME-sniffing a response away from the declared content-type.


=head1 METHOD

=over

=item call

=back


=head1 REPOSITORY

Plack::Middleware::IEnosniff is hosted on github
<http://github.com/bayashi/Plack-Middleware-IEnosniff>


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<Plack::Middleware>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
