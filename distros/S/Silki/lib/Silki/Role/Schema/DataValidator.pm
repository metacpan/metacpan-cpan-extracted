package Silki::Role::Schema::DataValidator;
{
  $Silki::Role::Schema::DataValidator::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use Lingua::EN::Inflect qw( A );
use Silki::Exceptions qw( data_validation_error );

use MooseX::Role::Parameterized;

parameter 'steps' => (
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
);

parameter 'validate_on_insert' => (
    isa     => 'Bool',
    default => 1,
);

parameter 'validate_on_update' => (
    isa     => 'Bool',
    default => 1,
);

sub _clean_and_validate_data {
    my $self      = shift;
    my $p         = shift;
    my $is_insert = shift;

    my @errors = $self->_validation_errors( $p, $is_insert );

    data_validation_error errors => \@errors
        if @errors;
}

sub _check_non_nullable_columns {
    my $self      = shift;
    my $p         = shift;
    my $is_insert = shift;

    my @errors;
    for my $name (
        map { $_->name() }
        grep {
            !(     $_->is_nullable()
                || defined $_->default()
                || $_->is_auto_increment() )
        } $self->Table()->columns()
        ) {
        if ($is_insert) {
            push @errors, $self->_needs_value_error($name)
                unless exists $p->{$name} && defined $p->{$name};
        }
        else {
            push @errors, $self->_needs_value_error($name)
                if exists $p->{$name} && !defined $p->{$name};
        }
    }

    return @errors;
}

sub _needs_value_error {
    my $self = shift;
    my $name = shift;

    ( my $friendly_name = $name ) =~ s/_/ /g;

    my $articled = A($friendly_name);

    return {
        field   => $name,
        message => "You must provide $articled."
    };
}

sub ValidateForInsert {
    my $class = shift;
    my %p     = @_;

    return $class->_validation_errors( \%p, 'is insert' );
}

sub validate_for_update {
    my $self = shift;
    my %p    = @_;

    return $self->_validation_errors( \%p );
}

role {
    my $params = shift;

    if ( $params->validate_on_insert() ) {
        around 'insert' => sub {
            my $orig  = shift;
            my $class = shift;
            my %p     = @_;

            $class->_clean_and_validate_data( \%p, 'is insert' );

            return $class->$orig(%p);
        };
    }

    if ( $params->validate_on_update() ) {
        around 'update' => sub {
            my $orig = shift;
            my $self = shift;
            my %p    = @_;

            $self->_clean_and_validate_data( \%p );

            return unless keys %p;

            return $self->$orig(%p);
        };
    }

    my @steps = @{ $params->steps() };

    if (@steps) {
        method _validation_errors => sub {
            my $self      = shift;
            my $p         = shift;
            my $is_insert = shift;

            return $self->_check_validation_steps( $p, $is_insert ),
                $self->_check_non_nullable_columns( $p, $is_insert );
        };

        method _check_validation_steps => sub {
            my $self      = shift;
            my $p         = shift;
            my $is_insert = shift;

            return map { $self->$_( $p, $is_insert ) } @steps;
        };
    }
    else {
        method _validation_errors => sub {
            my $self      = shift;
            my $p         = shift;
            my $is_insert = shift;

            return $self->_check_non_nullable_columns( $p, $is_insert );
        };
    }
};

1;

# ABSTRACT: Does data validation on inserts and updates

__END__
=pod

=head1 NAME

Silki::Role::Schema::DataValidator - Does data validation on inserts and updates

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

