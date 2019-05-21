package Net::Flotum::Object::Customer;
use strict;
use warnings;
use utf8;
use Carp qw/croak/;
use Moo;
our $AUTOLOAD;

use namespace::clean;
use Net::Flotum::Object::CreditCard;
use URI::Escape;

has 'flotum' => ( is => 'ro',  weak_ref => 1, required => 1);
has 'id'     => ( is => 'rwp', required => 1 );
has 'loaded' => ( is => 'rwp', default  => 0 );

has '_data' => ( is => 'rwp' );

sub AUTOLOAD {
    my $self = shift;
    my ($call) = $AUTOLOAD =~ /([^:]+)$/;

    $self->_load_from_id() unless $self->loaded();

    my $data = $self->_data;

    return $data->{$call} if exists $data->{$call};

    croak "Object type: ", ( ref $self ), ", illegal method call: $call\n";

}

sub _load_from_id {
    my ($self) = @_;
    my $mydata = $self->flotum->_get_customer_data( id => $self->id );
    $self->_set__data($mydata);
    $self->_set_loaded(1);
    return 1;
}

sub _load_from_remote_id {
    my ( $self, $remote_id ) = @_;
    my $mydata = $self->flotum->_get_customer_data( remote_id => $remote_id );
    $self->_set_loaded(1);
    $self->_set_id( $mydata->{id} );
    $self->_set__data($mydata);
    return 1;
}

sub add_credit_card {
    my ( $self, %opts ) = @_;

    my $callback = delete $opts{callback};

    my $session = $self->flotum->_get_customer_session_key( id => $self->id );

    return {
        method => 'POST',
        href   => (
            join '/', $self->flotum->requester->flotum_api,
            'customers', $self->id, 'credit-cards',
            '?api_key=' . uri_escape($session) . ( $callback ? '&callback=' . uri_escape($callback) : '' )
        ),
        valid_until => time + 900,
        fields      => {
            (
                map { $_ => '?Str' }
                  qw/address_name
                  address_zip
                  address_street
                  address_number
                  address_observation
                  address_neighbourhood
                  address_city
                  address_state/
            ),
            ( map { $_ => '*Str' } qw/name_on_card legal_document/ ),
            number             => '*CreditCard',
            csc                => '*CSC',
            brand              => '*Brand',
            validity           => '*YYYYDD',
            address_inputed_at => '?GmtDateTime',
        },
        accept => 'application/json'
    };
}

sub list_credit_cards {
    my ($self) = @_;

    my @credit_cards = $self->flotum->_get_list_customer_credit_cards( id => $self->id );

    my @objs;
    foreach my $cc_data (@credit_cards) {
        push @objs,
          Net::Flotum::Object::CreditCard->new(
            flotum               => $self->flotum,
            merchant_customer_id => $self->id,
            %$cc_data,
          );
    }

    return wantarray ? @objs : \@objs;

}

sub new_charge {
    my $self = shift;

    return $self->flotum->_new_charge( @_, customer => $self );
}

sub update {
    my $self = shift;

    $self->_set_loaded(0);
    return $self->flotum->_update_customer( @_, customer => $self );
}

# suppress warning on cleanup
sub DESTROY {}

1;

__END__

=encoding utf-8

=head1 NAME

Net::Flotum::Object::Customer - Flotum customer object represetation

=head1 SYNOPSIS

Please read L<Net::Flotum>

=head1 AUTHOR

Renato CRON E<lt>rentocron@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2015-2016 Renato CRON

Owing to http://eokoe.com

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
