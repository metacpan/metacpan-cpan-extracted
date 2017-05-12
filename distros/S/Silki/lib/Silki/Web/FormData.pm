package Silki::Web::FormData;
{
  $Silki::Web::FormData::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use Moose;
use MooseX::StrictConstructor;

has 'sources' => (
    is       => 'ro',
    isa      => 'ArrayRef[HashRef|Object]',
    required => 1,
);

has 'suffix' => (
    is      => 'ro',
    isa     => 'Str',
    default => q{},
);

sub has_sources {
    return scalar @{ $_[0]->sources() };
}

sub param {
    my $self  = shift;
    my $param = shift;

    if ( my $s = $self->suffix() ) {
        $param =~ s/\Q$s\E$//;
    }

    foreach my $s ( @{ $self->sources() } ) {
        if ( blessed $s ) {
            return $s->$param() if $s->can($param);
        }
        else {
            return $s->{$param} if exists $s->{$param};
        }
    }

    return;
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Represents data for filling in forms


__END__
=pod

=head1 NAME

Silki::Web::FormData - Represents data for filling in forms

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

