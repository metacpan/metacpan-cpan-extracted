package ObjectDB::InflateColumn;
use strict;
use warnings;

our $VERSION = '0.01';

BEGIN {
    use Carp;
    use Module::Util qw();
    unless (Module::Util::module_is_loaded('ObjectDB')) {
        croak __PACKAGE__." can't be loaded before ObjectDB"
    }
    # ok, lets go
}

use Sub::Install;

my $imported = 0;
sub import {
	my $class = shift;
	return if $imported;
	
	# extend ObjectDB::Schema
	Sub::Install::install_sub({
	    code => sub {
	        my $self = shift;
	        my $field = shift;
	        unless ($field) {
	            return $self->{_inflate_columns_info} ||= {};
	        }; 
	        my $param = ref $_[0] eq 'HASH' ? $_[0] : {@_};
	        $param->{inflate} ||= sub {$_[0]};
	        $param->{deflate} ||= sub {$_[0]};
	        
	        $self->{_inflate_columns_info}->{$field} = $param;
	        
	        return 1;
	    },
	    into => 'ObjectDB::Schema',
	    as   => 'inflate_column'
	});
	# method 'inflate_column' has been added
	
	Sub::Install::install_sub({
	    code => sub {$_[0]->{_inflate_columns_info} ||= {}},
	    into => 'ObjectDB::Schema',
	    as   => '_inflate_columns_info'
	});
	# method '_inflate_columns_info' has been added (access to field {_inflate_columns_info})
	
	# extend ObjectDB
	Sub::Install::install_sub({
	    code => sub {
	        my $self = shift;
	        my $inflate_info = $self->schema->_inflate_columns_info;
	        if (exists $inflate_info->{$_[0]}) {
	            if (@_==1) {
	                return $inflate_info->{$_[0]}->{deflate}->($self->column($_[0]));
	            } elsif (@_==2) {
	                return $self->column($_[0], $inflate_info->{$_[0]}->{inflate}->($_[1]));
	            };
	        };
	        return $self->column(@_);
	    },
	    into => 'ObjectDB',
	    as   => 'inflate_column'
	});
	# method 'inflate_column' has been added
	$imported++;
};

1;
__END__
=head1 NAME

ObjectDB::InflateColumn - automatically create references from column data

=head1 SYNOPSIS

    package MyApp::ObjectDB;		
	use base qw(ObjectDB);	
	use ObjectDB::InflateColumn;
    
    .....
    
    1;    
    
    # in your table classes
    package MyApp::ORM::SomeTokenAction;    
    use base 'MyApp::ObjectDB';
    
    # some schema description
    __PACKAGE__->schema(
        table          => 'some_token_action',
        columns        => [qw/id token .... data/],
        primary_keys   => ['id'],
        auto_increment => 'id',
    );
    
    use JSON;
    my $json = JSON->new;
    
    # describe infalte
    __PACKAGE__->schema->inflate_column(
        'data', 
        {
            inflate => sub { $json->allow_nonref->encode($_[0]) },
            deflate => sub { $json->utf8(1)->decode($_[0]) },
        }
    );
    
    # =============================================================
    
    # in main code
    package main;
    use MyApp::ORM::SomeTokenAction;
    
    # create entity
    my $token_entity = MyApp::ORM::SomeTokenAction->new(token => ...);    
    $token_entity->inflate_column('data', {some_key => 'some_value'});
    $token_entity->column('data');            # string '{"some_key":"some_value"}'
    $token_entity->inflate_column('data');    # real hash {"some_key":"some_value"}
    $token_entity->create;
    
    # or load
    my $token_entitys = MyApp::ORM::SomeTokenAction->find(where => [token => ...]);
    $token_entitys->[0]->column('data');            # string '{"some_key":"some_value"}'
    $token_entitys->[0]->inflate_column('data');    # real hash {"some_key":"some_value"}
    
    # or something else from ObjectDB
    
=head1 DESCRIPTION

There's similar L<DBIx::Class::InflateColumn>, but created for L<ObjectDB>.

This module make export some methods to L<ObjectDB::Schema> and L<ObjectDB>.

=head1 METHODS

=head2 new for ObjectDB::Schema

=head3 inflate_column($col_name, {inflate => sub {}, deflate => sub{}})

By default 'inflate' and 'deflate' will be set to B<sub{ $_[0] }>.

=head2 new for ObjectDB

=head3 inflate_column($col_name[, $new_val])

Accessor for inflate column.

=head1 SOURSE

    git@github.com:mrRico/p5-ObjectDB-InflateColumn.git

=head1 SEE ALSO

L<ObjectDB>

=head1 AUTHOR

mr.Rico <catamoose at yandex.ru>

=cut
