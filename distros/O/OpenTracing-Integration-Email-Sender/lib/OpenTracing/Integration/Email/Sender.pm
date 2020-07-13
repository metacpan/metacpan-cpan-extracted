package OpenTracing::Integration::Email::Sender;
# ABSTRACT: OpenTracing APM support for email sent via Email::Sender

use strict;
use warnings;

our $VERSION = '0.001';
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

no indirect;
use utf8;

=encoding utf8

=head1 NAME

OpenTracing::Integration::Email::Sender - support L<Email::Sender> tracing

=head1 SYNOPSIS

 use OpenTracing::Integration qw(Email::Sender);
 HTTP::Tiny->new->get('https://metacpan.org');

=head1 DESCRIPTION

See L<OpenTracing::Integration> for more details.

=cut

use Syntax::Keyword::Try;
use Role::Tiny::With;
use Class::Method::Modifiers qw(install_modifier);

use OpenTracing::DSL qw(:v1);

with qw(OpenTracing::Integration);

my $loaded;

sub load {
    my ($class, $load_deps) = @_;
    return unless $load_deps or Email::Sender::Simple->can('send');

    unless($loaded++) {
        require Email::Sender::Simple;
        require Email::Simple::Header;
        require Email::Address::XS;
        install_modifier q{Email::Sender::Simple}, around => send => sub {
            my ($code, $self, $message, $env, @rest) = @_;
            my $hdr = $message->header_obj;
            my $subject = $hdr->header_raw('Subject');
            my @to = map { $_->address } map { Email::Address::XS->parse($_) } $hdr->header_raw('To');
            my @from = map { $_->address } map { Email::Address::XS->parse($_) } $hdr->header_raw('From');
            my @cc = map { $_->address } map { Email::Address::XS->parse($_) } $hdr->header_raw('Cc');
            return trace {
                my ($span) = @_;
                try {
                    $span->tag(
                        'component'       => 'Email::Sender::Simple',
                        'email.to'        => join(',', @to),
                        'email.from'      => join(',', @from),
                        (@cc ? ('email.cc'        => join(',', @cc)) : ()),
                        'email.subject'   => $subject,
                        'email.body_size' => length($message->body),
                        'span.kind'       => 'client',
                    );
                    return $self->$code($message, $env, @rest);
                } catch {
                    my $err = $@;
                    $span->tag(
                        error => 1,
                    );
                    die $@;
                }
            } operation_name => 'email: ' . $subject;
        };
    }
}

1;

__END__

=head1 AUTHOR

Tom Molesworth C<< TEAM@cpan.org >>

=head1 LICENSE

Copyright Tom Molesworth 2020. Licensed under the same terms as Perl itself.

