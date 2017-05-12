package Silki::Request;
{
  $Silki::Request::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use Silki::Util qw( string_is_empty );

use Moose::Role;

with 'Catalyst::TraitFor::Request::REST::ForBrowsers';

sub user_params {
    my $self = shift;

    my $params = $self->params();

    my %p = $self->_params_for_classes('Silki::Schema::User');
    $p{password2} = $params->{password2}
        unless string_is_empty( $params->{password2} );

    for my $field (qw( is_admin is_system_user is_disabled )) {
        delete $p{$field}
            unless exists $params->{$field};
    }

    return %p;
}

sub wiki_params {
    my $self = shift;

    return $self->_params_for_classes('Silki::Schema::Wiki');
}

sub domain_params {
    my $self = shift;

    return $self->_params_for_classes('Silki::Schema::Domain');
}

sub account_params {
    my $self = shift;

    return $self->_params_for_classes('Silki::Schema::Account');
}

sub _params_for_classes {
    my $self    = shift;
    my $classes = shift;
    my $suffix  = shift || '';

    my $params = $self->params();

    my %found;

    for my $class ( @{ ref $classes ? $classes : [$classes] } ) {
        my $table = $class->Table();

        my %pk = map { $_->name() => 1 } @{ $table->primary_key() };

        for my $col ( $table->columns() ) {
            my $name = $col->name();

            next if $pk{$name};

            my $key = $name;
            $key .= q{-} . $suffix
                if $suffix;

            if ( $col->generic_type() eq 'boolean' ) {
                $found{$name} = $params->{$key} ? 1 : 0;
                next;
            }

            if ( string_is_empty( $params->{$key} ) ) {
                if ( $col->is_nullable() ) {
                    $found{$name} = undef;
                }

                next;
            }

            $found{$name} = $params->{$key};
        }
    }

    return %found;
}

1;

# ABSTRACT: A Catalyst::Request subclass which knows how to get user-provided data for specific classes


__END__
=pod

=head1 NAME

Silki::Request - A Catalyst::Request subclass which knows how to get user-provided data for specific classes

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

