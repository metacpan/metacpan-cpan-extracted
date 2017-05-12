package Osgood::Server::Schema;
use strict;

use YAML::Dumper;
use YAML::Loader;

use base qw/DBIx::Class::Schema/;

__PACKAGE__->load_classes({
	'Osgood::Server::Model' => [
	qw/
		Action
		Event
		EventParameter
		Object
	/]
});

sub connect {
    my $self = shift;

    my $schema = $self->next::method(@_);

    if($schema && $schema->storage->can('connect_info')) {
        if(lc($schema->storage->connect_info->[0]) =~ /mysql/) {
            $schema->storage->dbh->do('SET @@SQL_AUTO_IS_NULL=0')
        }
    }

    return $schema;
}

sub inflate {
    my $self = shift;
    my $yaml = new YAML::Loader->new($self);

    return $yaml->load(@_);
}

sub deflate {
    my $self = shift;
    my $yaml = YAML::Dumper->new;

	return $yaml->dump(@_);
}

1;
