package MooseX::Types::Authen::Passphrase;
BEGIN {
  $MooseX::Types::Authen::Passphrase::AUTHORITY = 'cpan:NUFFIN';
}
# git description: v0.03-2-gbdb4541
$MooseX::Types::Authen::Passphrase::VERSION = '0.04';
# ABSTRACT: L<Authen::Passphrase> type constraint and coercions

use strict;
use warnings;

use Authen::Passphrase;
use Authen::Passphrase::RejectAll;

use MooseX::Types::Moose qw(Str Undef);

use MooseX::Types -declare => [qw(Passphrase)];

use namespace::clean;

class_type "Authen::Passphrase";
class_type Passphrase, { class => "Authen::Passphrase" };

foreach my $type ( "Authen::Passphrase", Passphrase ) {
    coerce( $type,
        from Undef, via { Authen::Passphrase::RejectAll->new },
        from Str, via {
            if ( /^\{/ ) {
                return Authen::Passphrase->from_rfc2307($_);
            } else {
                return Authen::Passphrase->from_crypt($_);
                #my ( $p, $e ) = do { local $@; my $p = eval { Authen::Passphrase->from_crypt($_) }; ( $p, $@ ) };

                #if ( ref $p and $p->isa("Authen::Passphrase::RejectAll") and length($_) ) {
                #    warn "e: $e";
                #    return Authen::Passphrase::Clear->new($_);
                #} elsif ( $e ) {
                #    die $e;
                #} else {
                #    return $p;
                #}
            }
        },
    );
}

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Types::Authen::Passphrase - L<Authen::Passphrase> type constraint and coercions

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    package User;
    use Moose;

    use MooseX::Types::Authen::Passphrase qw(Passphrase);

    has pass => (
        isa => Passphrase,
        coerce => 1,
        handles => { check_password => "match" },
    );

    User->new( pass => undef ); # Authen::Passphrase::RejectAll

    my $u = User->new( pass => "{SSHA}ixZcpJbwT507Ch1IRB0KjajkjGZUMzX8gA==" );

    $u->check_password("foo"); # great success

    User->new( pass => Authen::Passphrase::Clear->new("foo") ); # clear text is not coerced by default

=head1 DESCRIPTION

This L<MooseX::Types> library provides string coercions for the
L<Authen::Passphrase> family of classes.

=head1 TYPES

=head2 C<Authen::Passphrase>, C<Passphrase>

These are defined a class types.

The following coercions are defined:

=over 4

=item from C<Undef>

Returns L<Authen::Passphrase::RejectAll>

=item from C<Str>

Parses using C<from_rfc2307> if the string begins with a C<{>, or using
C<from_crypt> otherwise.

=back

=head1 AUTHOR

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Yuval Kogman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 CONTRIBUTORS

=for stopwords Brian Fraser Karen Etheridge Yuval Kogman

=over 4

=item *

Brian Fraser <fraserbn@gmail.com>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Yuval Kogman <nothingmuch@woobling.org>

=back

=cut
