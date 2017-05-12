package Plack::Handler::AnyEvent::ReverseHTTP;
use strict;
use 5.008_001;
our $VERSION = '0.04';

use AnyEvent::ReverseHTTP;
use HTTP::Message::PSGI;
use HTTP::Response;
use Plack::Util;

sub new {
    my($class, %args) = @_;
    bless \%args, $class;
}

sub register_service {
    my($self, $app) = @_;
    $self->{guard} = reverse_http $self->{host}, $self->{token}, sub {
        my $req = shift;
        my $env = $req->to_psgi;

        if (my $client = delete $env->{HTTP_REQUESTING_CLIENT}) {
            @{$env}{qw( REMOTE_ADDR REMOTE_PORT )} = split /:/, $client, 2;
        }

        $env->{'psgi.nonblocking'}  = Plack::Util::TRUE;
        $env->{'psgi.streaming'}    = Plack::Util::TRUE;
        $env->{'psgi.multithread'}  = Plack::Util::FALSE;
        $env->{'psgi.multiprocess'} = Plack::Util::FALSE;
        $env->{'psgi.run_once'}     = Plack::Util::FALSE;

        my $r = $app->($env);
        if (ref $r eq 'ARRAY') {
            return HTTP::Response->from_psgi($r);
        } elsif (ref $r eq 'CODE') {
            my $cv = AE::cv;
            $r->(sub {
                my $r = shift;

                if (defined $r->[2]) {
                    my $res = HTTP::Response->from_psgi($r);
                    $cv->send($res);
                } else {
                    my $res = HTTP::Response->from_psgi([ $r->[0], $r->[1], [] ]); # dummy
                    my @body;
                    return Plack::Util::inline_object
                        write => sub { push @body, $_[0] },
                        close => sub { $res->content(join '', @body); $cv->send($res) };
                }
            });
            return $cv;
        } else {
            die "Bad response: $r";
        }
    };
}

sub run {
    my $self = shift;
    $self->register_service(@_);
    AE::cv->recv;
}

1;

__END__

=head1 NAME

Plack::Handler::AnyEvent::ReverseHTTP - reversehttp gateway for PSGI application

=head1 SYNOPSIS

  > plackup --server AnyEvent::ReverseHTTP --host rhttplabel --token your-token

=head1 DESCRIPTION

Plack::Handler::AnyEvent::ReverseHTTP is Plack handler that runs your
PSGI application on L<AnyEvent::ReverseHTTP>. It uses ReverseHTTP
gateway to access your PSGI application on your desktop or behind the
firewall from the internet. Just like Ruby's hookout does with Rack
applications.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This module is licensed under the same terms as Perl itself.

=head1 SEE ALSO

L<AnyEvent::ReverseHTTP> L<http://github.com/paulj/hookout/tree/master> L<http://www.reversehttp.net/>

=cut
