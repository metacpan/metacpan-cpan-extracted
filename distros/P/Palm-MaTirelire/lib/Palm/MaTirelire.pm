=encoding iso-8859-1

=cut

#
# Copyright (C) 2005, Maxime Soulé
# You may distribute this file under the terms of the Artistic
# License, as specified in the README file.
#

package Palm::MaTirelire;
use Palm::Raw();

use base qw(Palm::Raw);

our $VERSION = '1.14';

sub new
{
    my $classname   = shift;
    my $self        = $classname->SUPER::new(@_);
    # Create a generic PDB. No need to rebless it,
    # though.

    $self->{creator} = "MaT2";
    $self->{attributes}{resource} = 0;
                                # The PDB is not a resource database by
                                # default, but it's worth emphasizing,
                                # since MemoDB is explicitly not a PRC.
    $self->{attributes}{Backup} = 1; # Always set the backup bit...

    # Have to define type and name in subclasses...

    # Give the PDB a blank AppInfo block
    $self->{appinfo} = {};

    # Give the PDB a blank sort block
    $self->{sort} = undef;

    # Give the PDB an empty list of records
    $self->{records} = [];

    return $self;
}

1;
__END__

=head1 NAME

Palm::MaTirelire - Superclass handler for Palm MaTirelire databases.

=head1 SYNOPSIS

  use Palm::MaTirelire;

=head1 DESCRIPTION

Superclass for handlers Palm::MaTirelire::*.

To be done XXX...

=head1 SEE ALSO

Palm::MaTirelire::AccountsV1(3)

Palm::MaTirelire::AccountsV2(3)

Palm::MaTirelire::Currencies(3)

Palm::MaTirelire::DBItem(3)

Palm::MaTirelire::DBItemId(3)

Palm::MaTirelire::Descriptions(3)

Palm::MaTirelire::ExternalCurrencies(3)

Palm::MaTirelire::Modes(3)

Palm::MaTirelire::SavedPreferences(3)

Palm::MaTirelire::Types(3)

=head1 AUTHOR

Maxime Soulé, E<lt>max@Ma-Tirelire.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Maxime Soulé

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
