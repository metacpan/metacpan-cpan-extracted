package PAGI::FastAPI::Depends;

use v5.36;
use version;

our $VERSION   = qv('v0.0.5');
our $AUTHORITY = 'cpan:MANWAR';

use Exporter 'import';

our @EXPORT_OK = qw(Depends);

=encoding utf-8

=head1 NAME

PAGI::FastAPI::Depends - Dependency Injection Wrapper for PAGI::FastAPI

=head1 VERSION

Version v0.0.5

=head1 SYNOPSIS

    use PAGI::FastAPI::Depends qw(Depends);

    my $get_db = async sub ($c) {
        return My::DB->connect;
    };

    my $auth_check = async sub ($c) {
        my $token = $c->header('Authorization');
        unless ($token) {
            $c->status(401);
            return { detail => 'Unauthorized' };
        }
    };

    $app->get('/items',
        dependencies => [
            Depends($get_db, key => 'db'), # Store result in $c->stash->{db}
            Depends($auth_check),          # Execution guard dependency
        ],
        handler => async sub ($c) {
            my $db = $c->stash->{db};
            return { status => 'ok' };
        }
    );

=head1 DESCRIPTION

C<PAGI::FastAPI::Depends> provides a lightweight container object for wrapping
async dependency subroutines in L<PAGI::FastAPI>.

When registered on a route, dependencies execute asynchronously before the
primary route handler. If a C<key> option is specified, the return value of
the dependency is automatically injected into the request context's stash
(C<< $c->stash->{$key} >>).

=head1 FUNCTIONS

=head2 C<Depends($code_ref, [%options])>

Exportable helper function that constructs a new C<PAGI::FastAPI::Depends> instance.

    my $dep = Depends($code_ref, key => 'user');

Options:

C<key> - Optional scalar string key under which the dependency's return
value will be stored in C<< $c->stash >>.

=cut

sub Depends ($code, %opts) {
    return __PACKAGE__->new($code, %opts);
}

=head1 METHODS

=head2 C<new($code_ref, [%options])>

Constructs a new C<PAGI::FastAPI::Depends> object instance. Dies if
C<$code_ref> is not a C<CODE> reference.

=cut

sub new ($class, $code, %opts) {
    die "Depends requires a CODE reference"
        unless ref $code eq 'CODE';

    return bless {
        code        => $code,
        key         => $opts{key},
        _is_depends => 1,
    }, $class;
}

=head2 C<code()>

Returns the underlying code reference for the dependency subroutine.

=cut

sub code ($self) { $self->{code} }

=head2 C<key()>

Returns the stash key string associated with the dependency, or C<undef>
if none was defined.

=cut

sub key  ($self) { $self->{key} }

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/PAGI-FastAPI>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/PAGI-FastAPI/issues>.
I will be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PAGI::FastAPI::Depends

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/PAGI-FastAPI/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PAGI-FastAPI>

=item * Search MetaCPAN

L<https://metacpan.org/dist/PAGI-FastAPI/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License (2.0). You may obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1; # End of PAGI::FastAPI::Depends
