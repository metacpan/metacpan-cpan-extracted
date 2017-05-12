use strict;
use warnings;

package Net::FreshBooks::API::Role::Common;
$Net::FreshBooks::API::Role::Common::VERSION = '0.24';
use Moose::Role;
use Carp qw( carp croak );
use Data::Dump qw( dump );

has 'die_on_server_error' => ( is => 'rw', isa => 'Bool', lazy_build => 1, );
has 'last_server_error'   => ( is => 'rw' );
has 'verbose'             => ( is => 'rw', isa => 'Bool', lazy_build => 1 );

has '_return_xml'  => ( is => 'rw', isa => 'Str' );
has '_request_xml' => ( is => 'rw', isa => 'Str' );

sub _build_die_on_server_error { return 1; }

sub _build_verbose {
    return 1 if $ENV{VERBOSE} || $ENV{DEBUG};
    return 0;
}

sub _handle_server_error {

    my $self = shift;
    my $msg  = shift;

    if ( $self->die_on_server_error ) {
        croak $msg;
    }

    $self->last_server_error( $msg );

    return;

}

sub _log {    ## no critic

    my $self = shift;
    return if !$self->verbose;

    my ( $level, $message ) = @_;
    $message .= "\n" if $message !~ m{\n/z}x;
    carp "$level: $message";

    return;

}

1;

# ABSTRACT: Roles common to both Base.pm and API.pm

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::FreshBooks::API::Role::Common - Roles common to both Base.pm and API.pm

=head1 VERSION

version 0.24

=head1 SYNOPSIS

These roles are generally for debugging and error handling.

=head2 verbose( 0|1 )

Enable this to direct a lot of extra info the STDOUT

=head1 AUTHORS

=over 4

=item *

Edmund von der Burg <evdb@ecclestoad.co.uk>

=item *

Olaf Alders <olaf@wundercounter.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Edmund von der Burg & Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
