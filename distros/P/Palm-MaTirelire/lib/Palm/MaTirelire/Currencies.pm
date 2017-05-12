=encoding iso-8859-1

=cut

#
# Copyright (C) 2005, Maxime Soulé
# You may distribute this file under the terms of the Artistic
# License, as specified in the README file.
#

package Palm::MaTirelire::Currencies;

use strict;

use Palm::BlockPack;

use Palm::MaTirelire::DBItemId;

use base qw(Palm::MaTirelire::DBItemId);

our $VERSION = '1.0';


# AppInfoBlock
my $APPINFO_BLOCK = Palm::BlockPack->new
    (N => [ 'last_ext_creation_date' => 0 ]);

# Each record
my $RECORD_BLOCK = Palm::BlockPack->new
    (UInt32	=> [
		    [ 'curr_id:8'	=> 0 ],
		    [ 'reference:1'	=> 0 ],
		    [ 'reserved:*'	=> 0 ],
		    ],
     'double'	=> [ 'reference_amount' => 1 ],
     'double'	=> [ 'currency_amount'  => 1 ],

     'Z4'	=> [ 'iso4217' => '' ],

     'Z*'	=> [ 'name' => '' ],
     );


sub import
{
    &Palm::PDB::RegisterPDBHandlers(__PACKAGE__, [ "MaT2", 'Curr' ]);
}


sub meta_infos ($)
{
    return { name	   => "MaTi-Currencies",
	     type	   => "Curr",
	     appinfo_block => $APPINFO_BLOCK,
	     record_block  => $RECORD_BLOCK,
	     id_field	   => 'curr_id',
	     num	   => (1 << 8),
	   };
}


sub reference ($)
{
    my $self = shift;

    foreach my $rec (@{$self->{records}})
    {
	return $rec if $rec->{reference};
    }
}


sub convert_amount ($$$$)
{
    my($self, $amount, $rec_old, $rec_new) = @_;

    return $amount if not defined $rec_old or not defined $rec_new;

    return sprintf('%.2f', ($amount * $rec_new->{currency_amount}
			    * $rec_old->{reference_amount})
		   / ($rec_new->{reference_amount}
		      * $rec_old->{currency_amount}));
}

1;
__END__

=head1 NAME

Palm::MaTirelire::Currencies - Handler for Palm MT v2 currencies database

=head1 SYNOPSIS

  use Palm::MaTirelire::Currencies;

=head1 DESCRIPTION

The MaTirelire::Currencies PDB handler is a helper class for the
Palm::PDB package.
It parses Palm Ma Tirelire v2 currencies database.

To be done XXX...

=head1 SEE ALSO

Palm::MaTirelire(3)

Palm::MaTirelire::DBItemId(3)

Palm::MaTirelire::ExternalCurrencies(3)

Palm::MaTirelire::AccountsV2(3)

=head1 AUTHOR

Maxime Soulé, E<lt>max@Ma-Tirelire.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Maxime Soulé

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
