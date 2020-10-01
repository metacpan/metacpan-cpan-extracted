package Net::Cisco::FMC::v1::Role::REST::Client;
$Net::Cisco::FMC::v1::Role::REST::Client::VERSION = '0.005001';
# ABSTRACT: Cisco Firepower Management Center (FMC) REST client

use 5.024;
use feature 'signatures';
use Syntax::Keyword::Try;
use Time::HiRes qw( sleep );
use Sub::Retry;
use Moo::Role; # last for cleanup

no warnings "experimental::signatures";

with 'Role::REST::Client';
with 'Role::REST::Client::Auth::Basic';

# has be be after with 'Role::REST::Client::Auth::Basic'; to be called before
# its method modifier
before '_call' => sub {
    # disable http basic auth by default because only the generatetoken call
    # needs it
    $_[4]->{authentication} = 'none'
        unless defined $_[4]->{authentication};
};

around '_call' => sub($orig, $self, @params) {
    my $try_count = 20;
    my $try_timeout = 3;

    return retry $try_count, $try_timeout,
        sub {
            my $n = shift;
            warn "api call retry #$n\n"
                if $n > 1;
            return $orig->($self, @params);
        }, sub {
            my $res = shift;
            # retry on error 429
            if ($res->code == 429) {
                warn "got error 429 too many requests, retrying in $try_timeout seconds\n";
                return 1;
            }
            # pseudo-code from HTTP::Tiny
            elsif ($res->code == 599
                && $res->data =~ /Timed out while waiting for socket to become ready for reading/) {
                warn "timeout, retrying in $try_timeout seconds\n";
                return 1;
            }
            #elsif ($res->response->is_error ) {
            #    warn 'code ' . $res->code . ': ' . $res->data;
            #}
            return 0;
        };
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Cisco::FMC::v1::Role::REST::Client - Cisco Firepower Management Center (FMC) REST client

=head1 VERSION

version 0.005001

=head1 AUTHOR

Alexander Hartmaier <abraxxa@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 - 2020 by Alexander Hartmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
