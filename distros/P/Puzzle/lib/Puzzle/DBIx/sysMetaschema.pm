package Puzzle::DBIx::sysMetaschema;

our $VERSION = '0.02';

use base qw(Puzzle::DBI);

__PACKAGE__->table('sysMetaschema');

__PACKAGE__->columns(All => qw/	
																cod_columnname txt_label
															/);

*label = \&txt_label;

1;
