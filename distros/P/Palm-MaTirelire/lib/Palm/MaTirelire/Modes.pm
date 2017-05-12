=encoding iso-8859-1

=cut

#
# Copyright (C) 2005, Maxime Soulé
# You may distribute this file under the terms of the Artistic
# License, as specified in the README file.
#

package Palm::MaTirelire::Modes;

use strict;

use Palm::BlockPack;

use Palm::MaTirelire::DBItemId;

use base qw(Palm::MaTirelire::DBItemId);

our $VERSION = '1.0';


# Each record
my $RECORD_BLOCK = Palm::BlockPack->new
    (UInt32	=> [
		    [ 'mode_id:5'	=> 0 ],
		    [ 'value_date:3'	=> 0 ],
		    [ 'first_val:6'	=> 0 ],
		    [ 'debit_date:5'	=> 0 ],
		    [ 'cheque_auto:1'	=> 0 ],
		    [ 'reserved:*'	=> 0 ],
		    ],

     'Z24'	=> [ 'only_in_account' => '' ],
     'Z*'	=> [ 'name' => '' ],
     );


sub import
{
    &Palm::PDB::RegisterPDBHandlers(__PACKAGE__, [ "MaT2", 'Mode' ]);
}


sub meta_infos ($)
{
    return { name	  => "MaTi-Modes",
	     type	  => "Mode",
	     record_block => $RECORD_BLOCK,
	     id_field	  => 'mode_id',
	     unfiled_name => 'Unknown',
	     num	  => (1 << 5),
	   };
}

1;
__END__

=head1 NAME

Palm::MaTirelire::Modes - Handler for Palm MT v2 modes database

=head1 SYNOPSIS

  use Palm::MaTirelire::Modes;

=head1 DESCRIPTION

The MaTirelire::Modes PDB handler is a helper class for the
Palm::PDB package.
It parses Palm Ma Tirelire v2 modes database.

To be done XXX...

=head1 SEE ALSO

Palm::MaTirelire(3)

Palm::MaTirelire::DBItemId(3)

Palm::MaTirelire::AccountsV2(3)

=head1 AUTHOR

Maxime Soulé, E<lt>max@Ma-Tirelire.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Maxime Soulé

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
