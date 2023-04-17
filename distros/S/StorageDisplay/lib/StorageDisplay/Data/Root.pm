#
# This file is part of StorageDisplay
#
# This software is copyright (c) 2014-2023 by Vincent Danjean.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package StorageDisplay::Data::Root;
# ABSTRACT: Handle machine data for StorageDisplay

our $VERSION = '2.04'; # VERSION

use Moose;
use namespace::sweep;
extends 'StorageDisplay::Data::Elem';

with (
    'StorageDisplay::Role::Style::IsSubGraph',
    'StorageDisplay::Role::Style::Machine',
    'StorageDisplay::Role::Elem::Kind'
    => { kind => "machine" }
);

has 'host' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    );

sub dotSubGraph {
    my $self = shift;
    my $t = shift // "\t";

    my @text;
    my @subnodes=$self->dotSubNodes($t);
    $self->pushDotText(\@text, $t,
                       $self->dotSubNodes($t));

    my $it = $self->iterator(recurse => 1);
    while (defined(my $e=$it->next)) {
        my @links = $e->dotLinks($t, @_);
        if (scalar(@links)>0) {
            $self->pushDotText(
                \@text, $t,
                '// Links from '.$e->dname,
                @links,
                );
        }
    }
    $it = $self->iterator(recurse => 1);
    while (defined(my $e=$it->next)) {
        my @blocks = grep {
            $_->provided
        } $e->consumedBlocks;

        if (scalar(@blocks)>0) {
            $self->pushDotText(
                \@text, $t,
                '// Links for '.$e->dname,
                (map { $_->elem->linkname.' -> '.$e->linkname } @blocks),
                );
        }
	{
	    # No consumed block. Perhaps, we come from a VM provisionning
	    my @blocks = grep {
		(!$_->provided)
		    && $_->isa('StorageDisplay::Block::System')
	    } $e->consumedBlocks;
	    if ($e->isa('StorageDisplay::Data::Partition::None')) {
		push @blocks, $e->allProvidedBlocks;
	    }
	    $self->pushDotText(
                \@text, $t,
                '// Links for '.$e->dname,
		(map {
		    "// TARGET LINK: ".$self->host." ".
			$_->size." ".
			$_->kname." ".$e->linkname} @blocks));

	}
    }
    return @text;
}

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $host = shift // 'machine';

    return $class->$orig(
        'name' => $host,
        'host' => $host,
        @_
        );
};

sub label {
    my $self = shift;
    return "COUCOU1".$self->host;
}

sub dotLabel {
    my $self = shift;
    return $self->host;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

StorageDisplay::Data::Root - Handle machine data for StorageDisplay

=head1 VERSION

version 2.04

=head1 AUTHOR

Vincent Danjean <Vincent.Danjean@ens-lyon.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2023 by Vincent Danjean.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
