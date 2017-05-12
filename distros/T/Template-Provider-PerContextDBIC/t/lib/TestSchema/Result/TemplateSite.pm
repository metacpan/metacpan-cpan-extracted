package TestSchema::Result::TemplateSite;

use strict;
use warnings;
use parent 'DBIx::Class::Core';

__PACKAGE__->table('TemplateSite');
__PACKAGE__->add_columns(
    qw/id name/
);

__PACKAGE__->set_primary_key('id');

sub restrict_Template3_resultset {
	my $self = shift; #the TemplateSite object
	my $unrestricted_rs = shift; #the Template3 object
    my $me = $unrestricted_rs->current_source_alias;
	return $unrestricted_rs->search_rs( { "$me.site_id" => $self->id } );
}


1;
