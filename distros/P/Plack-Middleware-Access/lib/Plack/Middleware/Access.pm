package Plack::Middleware::Access;
#ABSTRACT: Restrict access depending on remote ip or other parameters
$Plack::Middleware::Access::VERSION = '0.4';
use strict;
use warnings;

use parent qw(Plack::Middleware);

use Plack::Util::Accessor qw(rules deny_page);

use Carp qw(croak);
use Net::IP;

sub prepare_app {
    my $self = shift;

    if (!ref $self->deny_page) {
        my $msg = defined $self->deny_page ?
                          $self->deny_page : 'Forbidden';
        $self->deny_page(sub {
            [403, [ 'Content-Type'   =>'text/plain',
                    'Content-Length' => length $msg ], [ $msg ] ];
        });
    } elsif (ref $self->deny_page ne 'CODE') {
        croak "deny_page must be a CODEREF";
    }

    if (!defined($self->rules)) {
        $self->rules([]);
    } elsif( ref($self->rules) ne 'ARRAY' ) {
        croak "rules must be an ARRAYREF";
    } elsif (@{ $self->rules } % 2 != 0) {
        croak "rules must contain an even number of params";
    }

    my @rules = ();

    foreach (my $i = 0; $i < @{ $self->rules }; $i += 2) {
        my $allowing = $self->rules->[$i];
        my $rule = $self->rules->[$i + 1];

        if ($allowing !~ /^(allow|deny)$/) {
            croak "first argument of each rule must be 'allow' or 'deny'";
        }

        if (!defined($rule)) {
            croak "rule argument must be defined";
        }

        $allowing = ($allowing eq 'allow') ? 1 : 0;
        my $check = $rule;

        if ($rule eq 'all') {
            $check = sub { 1 };
        } elsif ($rule =~ /[A-Z]$/i) {
            $check = sub { 
                my $host = $_[0]->{REMOTE_HOST};
                return unless defined $host; # skip rule
                return $host =~ qr/^(.*\.)?\Q${rule}\E$/;
            };
        } elsif ( ref($rule) ne 'CODE' ) {
            my $netip = Net::IP->new($rule) or
                die "not supported type of rule argument [$rule] or bad ip: " . Net::IP::Error();
            $check = sub {
                my $addr = $_[0]->{REMOTE_ADDR};
                my $ip;
                if (defined($addr) && ($ip = Net::IP->new($addr))) {
                    my $overlaps = $netip->overlaps($ip);
                    return $overlaps == $IP_B_IN_A_OVERLAP || $overlaps == $IP_IDENTICAL;
                } else {
                    return undef;
                }
            };
        }

        push @rules, [ $check => $allowing ];
    }

    $self->rules(\@rules);
}

sub allow {
    my ($self, $env) = @_;

    foreach my $rule (@{ $self->rules }) {
        my ($check, $allow) = @{$rule};
        my $result = $check->($env);
        if (defined $result && $result) {
            return $allow;
        }
    }

    return 1;
}

sub call {
    my ($self, $env) = @_;

    return $self->allow($env)
         ? $self->app->($env) : $self->deny_page->($env);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::Access - Restrict access depending on remote ip or other parameters

=head1 VERSION

version 0.4

=head1 SYNOPSIS

  # in your app.psgi
  use Plack::Builder;

  builder {
    enable "Access", rules => [
        allow => "goodhost.com",
        allow => sub { <some code that returns true, false, or undef> },
        allow => "192.168.1.5",
        deny  => "192.168.1/24",
        allow => "192.0.0.10",
        deny  => "all"
    ];
    $app;
  };

=head1 DESCRIPTION

This middleware is intended for restricting access to your app by some users.
It is very similar with allow/deny directives in web-servers.

=head1 CONFIGURATION

=over 4

=item rules

A reference to an array of rules. Each rule consists of directive C<allow> or
C<deny> and their argument. Rules are checked in the order of their record to
the first match. Code rules always match if they return a defined non-zero value. Access
is granted if no rule matched.

Argument for the rule is a one of four possibilites:

=over 4

=item "all"

Always matched. Typical use-case is a deny => "all" in the end of rules.

=item remote_host

Matches on domain or subdomain of remote_host if it can be resolved. If
C<$env{REMOTE_HOST}> is not set, the rule is skipped.

=item ip

Matches on one ip or ip range. See L<Net::IP> for detailed description of
possible variants.

=item code

An arbitrary code reference for checking arbitrary properties of the request.
This function takes C<$env> as parameter. The rule is skipped if the code
returns undef.

=back

=item deny_page

Either an error message which is returned with HTTP status code 403
("Forbidden" by default), or a code reference with a PSGI app to return a
PSGI-compliant response if access was denied.

=back

=head1 METHODS

=head2 allow( $env )

You can also the allow method of use this module just to check PSGI requests
whether they match some rules:

    my $check = Plack::Middleware::Access->new( rules => [ ... ] );

    if ( $check->allow( $env ) ) {
        ...
    }

=head1 SEE ALSO

If your app runs behind a reverse proxy, you should wrap it with
L<Plack::Middleware::ReverseProxy> to get the original request IP. There are
several modules in the L<Plack::Middleware::Auth::|http://search.cpan.org/search?query=Plack%3A%3AMiddleware%3A%3AAuth>
namespace to enable authentification for access restriction.

=head1 ACKNOWLEDGEMENTS

Jakob Voss

Jesper Dalberg

Sawyer X

=head1 AUTHOR

Yury Zavarin <yury.zavarin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Yury Zavarin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
