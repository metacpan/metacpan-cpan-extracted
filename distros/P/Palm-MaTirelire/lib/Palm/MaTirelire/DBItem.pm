=encoding iso-8859-1

=cut

#
# Copyright (C) 2005, Maxime Soulé
# You may distribute this file under the terms of the Artistic
# License, as specified in the README file.
#

package Palm::MaTirelire::DBItem;

use strict;

use Palm::BlockPack;

use Palm::MaTirelire;

use base qw(Palm::MaTirelire);

our $VERSION = '1.0';


sub meta_infos ($)
{
    return {};
}


sub new
{
    my $classname   = shift;
    my $self        = $classname->SUPER::new(@_);

    # Create a generic PDB. No need to rebless it,
    # though.

    my $ref_meta_infos = $self->meta_infos;

    $self->{name} = $ref_meta_infos->{name};
    $self->{type} = $ref_meta_infos->{type};

    if (defined $ref_meta_infos->{appinfo_block})
    {
	$ref_meta_infos->{appinfo_block}->init_block($self->{appinfo});
    }

    return $self;
}

sub new_Record
{
    my $self = shift;
    my $retval = $self->SUPER::new_Record(@_);

    if (defined(my $record_block = $self->meta_infos->{record_block}))
    {
	$record_block->init_block($retval);
    }

    return $retval;
}


sub ParseAppInfoBlock
{
    my $self = shift;

    if (defined(my $appinfo_block = $self->meta_infos->{appinfo_block}))
    {
	return $appinfo_block->unpack_block(shift);
    }

    $self->SUPER::ParseAppInfoBlock(@_);
}


sub PackAppInfoBlock
{
    my $self = shift;

    if (defined(my $appinfo_block = $self->meta_infos->{appinfo_block}))
    {
	return $appinfo_block->pack_block($self->{appinfo});
    }

    $self->SUPER::PackAppInfoBlock(@_);
}


sub ParseRecord
{
    my $self = shift;
    my %record = @_;

    delete $record{offset};	# This is useless

    if (defined(my $record_block = $self->meta_infos->{record_block}))
    {
	$record_block->unpack_block(delete $record{data}, \%record);
    }

    return \%record;
}


sub PackRecord
{
    my $self = shift;

    if (defined(my $record_block = $self->meta_infos->{record_block}))
    {
	return $record_block->pack_block(shift);
    }

    return '';
}

1;
__END__

=head1 NAME

Palm::MaTirelire::DBItem - Superclass handler for some Palm MT databases

=head1 SYNOPSIS

  use Palm::MaTirelire::DBItem;

=head1 DESCRIPTION

To be done XXX...

=head1 SEE ALSO

Palm::MaTirelire(3)

Palm::MaTirelire::DBItemId(3)

Palm::MaTirelire::Currencies(3)

Palm::MaTirelire::Descriptions(3)

Palm::MaTirelire::ExternalCurrencies(3)

Palm::MaTirelire::Modes(3)

Palm::MaTirelire::Types(3)

=head1 AUTHOR

Maxime Soulé, E<lt>max@Ma-Tirelire.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Maxime Soulé

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
