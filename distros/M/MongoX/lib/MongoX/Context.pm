package MongoX::Context;
# ABSTRACT: Implements DSL interface,context container.
use strict;
use warnings;

use Carp 'croak';
use MongoDB;
use Data::Dumper;
my %registry = ();
my %connection_pool = ();

# context
our ($_context_connection,$_context_db,$_context_collection);

sub get_connection {
    my ($id) = @_;
    $id ||= 'default';
    if (exists $connection_pool{$id}) {
        return $connection_pool{$id};
    }
    croak "connection_id:$id not exists in registry,forgot to add it?(add_connection)" unless exists $registry{$id};
    my $new_con = MongoDB::Connection->new(%{ $registry{$id} });
    $connection_pool{$id} = $new_con;
}

sub get_db {
    my ($dbname,$connection_id) = @_;
    if ($connection_id) {
        return get_connection($connection_id)->get_database($dbname);
    }
    return $_context_connection->get_database($dbname);
}

sub use_db {
    $_context_db = $_context_connection->get_database(shift);
}

sub add_connection {
   my (%opts) = @_;
   my $id = $opts{id} || 'default';
   $registry{$id} = { @_ };
}

sub use_connection {
    my ($id) = @_;
    $id ||= 'default';
    $_context_connection = get_connection($id);
}

sub use_collection {
    my ($collection_name) = @_;
    $_context_collection = $_context_db->get_collection($collection_name);
}

sub get_collection {
    my ($collection_name) = @_;
    $_context_db->get_collection($collection_name);
}


sub context_db { $_context_db }

sub context_connection { $_context_connection }

sub context_collection { $_context_collection }

sub boot {
    my (%opts) = @_;
    return unless %opts;
    $MongoDB::BSON::utf8_flag_on = $opts{utf8} ? 1 : 0 if exists $opts{utf8};
    add_connection(%opts);
    use_connection;
    use_db($opts{db}) if exists $opts{db};
}

sub reset {
    ($_context_connection,$_context_collection,$_context_db) = undef;
    %registry = ();
    %connection_pool = ();
}

sub with_context {
    local ($_context_connection,$_context_db,$_context_collection) = ($_context_connection,$_context_db,$_context_collection);
    if (@_ == 1) {
        return $_[0]->();
    }
    my $code = shift;
    my %new_context = @_;
    if ($new_context{connection}) {
        if (ref $new_context{connection} eq 'MongoDB::Connection') {
            $_context_db = $new_context{connection};
        }
        else {
            use_connection $new_context{connection};
        }
    }
    if ($new_context{db}) {
        if (ref $new_context{db} eq 'MongoDB::Database') {
            $_context_db = $new_context{db};
        }
        else {
            use_db $new_context{db};
        }
    }
    if ($new_context{collection}) {
        if (ref $new_context{collection} eq 'MongoDB::Collection') {
            $_context_collection = $new_context{collection};
        }
        else {
            use_collection $new_context{collection};
        }
    }
    $code->();
}

sub for_collections {
    my ($code,@cols) = @_;
    for my $col (@cols){
        local ($_context_connection,$_context_db,$_context_collection) = ($_context_connection,$_context_db,$_context_collection);
        use_collection $col;
        $code->($_context_collection);
    }
}

sub for_dbs {
    my ($code,@dbs) = @_;
    for my $db (@dbs) {
        local ($_context_connection,$_context_db,$_context_collection) = ($_context_connection,$_context_db,$_context_collection);
        use_db $db;
        $code->($_context_db);
    }
}

sub for_connections {
    my ($code,@connections) = @_;
    for my $con_id (@connections){
        local ($_context_connection,$_context_db,$_context_collection) = ($_context_connection,$_context_db,$_context_collection);
        use_connection $con_id;
        $code->($_context_collection);
    }
}

1;


=pod

=head1 NAME

MongoX::Context - Implements DSL interface,context container.

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    use MongoX::Context;
    
    MongoX::Context::add_connection host => 'mongodb:://127.0.0.1';
    
    MongoX::Context::use_connection;
    
    MongoX::Context::use_db 'test';
    
    MongoX::Context::reset;
    
    MongoX::Context::boot host => 'mongodb://127.0.0.1',db => 'test2';
    
    my $col2 = MongoX::Context::context_db->get_collection('foo2');

=head1 DESCRIPTION

MongoX::Context implements the DSL syntax, track and hold internal MongoDB related objects.

=head1 AUTHOR

Pan Fan(nightsailer) <nightsailer at gmail dot com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Pan Fan(nightsailer).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


