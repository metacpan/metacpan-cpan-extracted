package OpenTracing::Integration::HTTP::Tiny;

use strict;
use warnings;

our $VERSION = '1.005'; # VERSION
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

no indirect;
use utf8;

=encoding utf8

=head1 NAME

OpenTracing::Integration::HTTP::Tiny - support L<HTTP::Tiny> tracing

=head1 SYNOPSIS

 use OpenTracing::Integration qw(HTTP::Tiny);
 HTTP::Tiny->new->get('https://metacpan.org');

=head1 DESCRIPTION

See L<OpenTracing::Integration> for more details.

Since this is a core module, it's included in the L<OpenTracing> core distribution as well.

=cut

use Syntax::Keyword::Try;
use Role::Tiny::With;
use Class::Method::Modifiers qw(install_modifier);

use OpenTracing::DSL qw(:v1);

with qw(OpenTracing::Integration);

my $loaded;

sub load {
    my ($class, $load_deps) = @_;
    return unless $load_deps or HTTP::Tiny->can('new');

    unless($loaded++) {
        require HTTP::Tiny;
        require URI;
        install_modifier q{HTTP::Tiny}, around => request => sub {
            my ($code, $self, $method, $url, $args) = @_;
            my $uri = URI->new("$url");
            my $path = $uri->path;
            $path = '/' unless length $path;
            return trace {
                my ($span) = @_;
                try {
                    $span->tag(
                        'component' => 'HTTP::Tiny',
                        'http.method' => $method,
                        'http.url' => "$url",
                        'span.kind' => 'client',
                    );
                    my $res = $self->$code($method, $url, $args);
                    $span->tag(
                        'http.status_code' => $res->{status}
                    );
                    return $res;
                } catch {
                    my $err = $@;
                    $span->tag(
                        error => 1,
                    );
                    die $@;
                }
            } operation_name => $path;
        };
    }
}

1;

__END__

=head1 AUTHOR

Tom Molesworth C<< TEAM@cpan.org >>

=head1 LICENSE

Copyright Tom Molesworth 2018-2021. Licensed under the same terms as Perl itself.

