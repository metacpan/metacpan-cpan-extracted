=encoding iso-8859-1

=cut

#
# Copyright (C) 2005, Maxime Soulé
# You may distribute this file under the terms of the Artistic
# License, as specified in the README file.
#

package Palm::MaTirelire::Descriptions;

use strict;

use Palm::BlockPack;

use Palm::MaTirelire::DBItem;

use base qw(Palm::MaTirelire::DBItem);

our $VERSION = '1.0';


# Each record
my $RECORD_BLOCK = Palm::BlockPack->new
    (UInt32	=> [
		    [ 'sign:2'		=> 0 ],
		    [ 'is_mode:1'	=> 0 ],
		    [ 'mode:5'		=> 0 ],
		    [ 'is_type:1'	=> 0 ],
		    [ 'type:8'		=> 0 ],
		    [ 'shortcut:8'	=> 0 ],
		    [ 'cheque_num:1'	=> 0 ],
		    [ 'auto_valid:1'	=> 0 ],
		    [ 'reserved:*'	=> 0 ],
		    ],
     'Z12'	=> [ 'amount'	=> '' ],
     'Z16'	=> [ 'account'	=> '' ],
     'Z16'	=> [ 'xfer'	=> '' ],
     'Z24'	=> [ 'only_in_account'	=> '' ],
     'Z*'	=> [ 'name'	=> '' ],
     );


sub import
{
    &Palm::PDB::RegisterPDBHandlers(__PACKAGE__, [ "MaT2", 'Desc' ]);
}


sub meta_infos ($)
{
    return { name => "MaTi-Descriptions",
	     type => "Desc",
	     record_block  => $RECORD_BLOCK,
	   };
}

1;
__END__

=head1 NAME

Palm::MaTirelire::Descriptions - Handler for Palm MT v2 descriptions database

=head1 SYNOPSIS

  use Palm::MaTirelire::Descriptions;

=head1 DESCRIPTION

The MaTirelire::Descriptions PDB handler is a helper class for the
Palm::PDB package.
It parses Palm Ma Tirelire v2 descriptions database.

To be done XXX...

=head1 SEE ALSO

Palm::MaTirelire(3)

Palm::MaTirelire::DBItem(3)

Palm::MaTirelire::AccountsV2(3)

=head1 AUTHOR

Maxime Soulé, E<lt>max@Ma-Tirelire.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Maxime Soulé

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
