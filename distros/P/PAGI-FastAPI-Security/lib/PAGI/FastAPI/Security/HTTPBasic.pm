package PAGI::FastAPI::Security::HTTPBasic;

use v5.36;
use version;
use MIME::Base64 qw(decode_base64);
use parent 'PAGI::FastAPI::Security::Base';

our $VERSION   = qv('v0.0.4');
our $AUTHORITY = 'cpan:MANWAR';

=encoding utf-8

=head1 NAME

PAGI::FastAPI::Security::HTTPBasic - HTTP Basic authentication scheme for PAGI::FastAPI

=head1 VERSION

Version v0.0.4

=head1 SYNOPSIS

    use PAGI::FastAPI::Security::HTTPBasic;

    my $basic = PAGI::FastAPI::Security::HTTPBasic->new(realm => 'my-api');

    $app->get('/admin',
        dependencies => [ $basic->depends(key => 'creds') ],
        handler      => async sub ($c) {
            my ($user, $pass) = @{ $c->stash->{creds} }{qw(username password)};
            # ... verify $user/$pass yourself ...
            return { ok => 1 };
        },
    );

=head1 DESCRIPTION

Grabs C<username>/C<password> information from an C<Authorization: Basic E<lt>base64(user:pass)E<gt>>
request header. This class just extracts the information, verification of the
information is the user’s responsibility (user should verify the information
against the database comparing it to password hashed with some hashing algorithm,
an example could be L<Crypt::Bcrypt>/L<Crypt::Argon2>.

Upon success, a dependency resolves to a HashRef:

    C<< { username => $user, password => $pass } >>.

=head1 CONSTRUCTOR OPTIONS

=over 4

=item * C<realm> - (Optional) Realm string sent in the C<WWW-Authenticate>
challenge header on failure. Default: C<'Restricted'>.

=item * C<auto_error> - (Optional) See L<PAGI::FastAPI::Security::Base>.
Default: true.

=back

=cut

sub new ($class, %opts) {
    $opts{realm} //= 'Restricted';
    return $class->SUPER::new(%opts);
}

sub _extract ($self, $c) {
    my $auth = $c->header('Authorization') // return undef;
    return undef unless $auth =~ /^Basic\s+(\S+)$/i;

    my $decoded = eval { decode_base64($1) };
    return undef unless defined $decoded && $decoded =~ /^([^:]*):(.*)$/s;

    return { username => $1, password => $2 };
}

sub _failure ($self) {
    my $realm = $self->{realm};
    $realm =~ s/"/\\"/g;
    return (401, 'Not authenticated', ['WWW-Authenticate' => qq{Basic realm="$realm"}]);
}

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/PAGI-FastAPI-Security>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/PAGI-FastAPI-Security/issues>.
I will be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PAGI::FastAPI::Security::HTTPBasic

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/PAGI-FastAPI-Security/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PAGI-FastAPI-Security>

=item * Search MetaCPAN

L<https://metacpan.org/dist/PAGI-FastAPI-Security/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License (2.0). You may obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1; # End of PAGI::FastAPI::Security::HTTPBasic
