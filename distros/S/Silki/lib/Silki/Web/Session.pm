package Silki::Web::Session;
{
  $Silki::Web::Session::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use Silki::Types qw( ArrayRef HashRef NonEmptyStr ErrorForSession );

use Moose;
use MooseX::Params::Validate qw( pos_validated_list );
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

has form_data => (
    is      => 'rw',
    isa     => HashRef,
    lazy    => 1,
    default => sub { {} },
);

has _errors => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => ArrayRef [ NonEmptyStr | HashRef ],
    default  => sub { [] },
    init_arg => undef,
    handles  => {
        add_error => 'push',
        errors    => 'elements',
    },
);

has _messages => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => ArrayRef [NonEmptyStr],
    default  => sub { [] },
    init_arg => undef,
    handles  => {
        add_message => 'push',
        messages    => 'elements',
    },
);

around add_error => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig( map { $self->_error_text($_) } @_ );
};

sub _error_text {
    my $self = shift;
    my ($e) = pos_validated_list( \@_, { isa => ErrorForSession } );

    if ( eval { $e->can('messages') } && $e->messages() ) {
        return $e->messages();
    }
    elsif ( eval { $e->can('message') } ) {
        return $e->message();
    }
    elsif ( ref $e ) {
        return @{$e};
    }
    else {

        # force stringification
        return $e . q{};
    }
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: An object for session data

__END__
=pod

=head1 NAME

Silki::Web::Session - An object for session data

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

