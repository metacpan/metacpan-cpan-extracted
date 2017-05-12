package Net::ACME::Challenge;

=encoding utf-8

=head1 NAME

Net::ACME::Challenge - a resolved/handled challenge

=head1 SYNOPSIS

    use Net::ACME::Challenge ();

    #This is minimal for now.
    my $challenge = Net::ACME::Challenge->new(
        status => 'invalid',        #or 'valid'
        error => $error_object,     #likely undef if status == “valid”
    );

=head1 DESCRIPTION

This module abstracts details of a handled/resolved challenge, whether
that challenge was met successfully or not.

To work with unhandled/unresolved challenges, see
(subclasses of) C<Net::ACME::Challenge::Pending>.

=cut

use strict;
use warnings;

use parent qw( Net::ACME::AccessorBase );

use constant _ACCESSORS => qw( error status );

use Net::ACME::Utils ();
use Net::ACME::X ();

my $ERROR_CLASS;

BEGIN {
    $ERROR_CLASS = 'Net::ACME::Error';
}

sub new {
    my ( $class, %opts ) = @_;

    if ( $opts{'error'} && !Net::ACME::Utils::thing_isa($opts{'error'}, $ERROR_CLASS) ) {
        die Net::ACME::X::create( 'InvalidParameter', "“error” must be an instance of “$ERROR_CLASS”, not “$opts{'error'}”!" );
    }

    return $class->SUPER::new( %opts );
}

sub status {
    my ($self) = @_;
    return $self->SUPER::status() || 'pending';
}

1;
