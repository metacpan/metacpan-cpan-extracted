use warnings;
use strict;
package Mojolicious::Plugin::Mongodb;
$Mojolicious::Plugin::Mongodb::VERSION = '1.16';
use Mojo::Base 'Mojolicious::Plugin';
use MongoDB;
use MongoDB::Collection;

sub register {
    my $self = shift;
    my $app  = shift;
    my $conf = shift || {}; 

    $conf->{helper} ||= 'db';

    $app->attr('_mongodb' => sub { 
        my $m = Mojolicious::Plugin::Mongodb::Connection->new(mongo_conf => $conf);
        $m->init();
        return $m;
    });

    $app->helper('mongodb_connection' => sub { return shift->app->_mongodb->_conn });


    $app->helper($conf->{helper} => sub {
        my $self = shift;
        return $self->app->_mongodb->db(@_);
    }) unless(defined($conf->{no_db}));

    $app->helper('model' => sub {
        my $c = shift;
        my $m = shift;

        if($m =~ /^(.*?)\.(.*)/) {
            # first bit has to be the db 
            return $c->app->_mongodb->db($1)->get_collection($2);
        } else {
            # act like coll
            return $c->app->_mongodb->coll($m);
        }
    }) unless(defined($conf->{no_model}));

    $app->helper('coll' => sub { return shift->app->_mongodb->coll(@_) }) unless(defined($conf->{no_coll}));

    for my $helpername (qw/find_and_modify map_reduce group/) {
        next if(defined($conf->{'no_' . $helpername}));
        $app->helper($helpername => sub { return shift->app->_mongodb->$helpername(@_) });
    }
}

package Mojolicious::Plugin::Mongodb::Connection;
$Mojolicious::Plugin::Mongodb::Connection::VERSION = '1.16';
use Mojo::Base -base;
use Tie::IxHash;

has 'mongo_conf' => sub { {} };
has 'current_db';
has '_conn';

sub init {
    my $self = shift;
    
    $self->_conn(MongoDB::Connection->new($self->mongo_conf));
}

sub db {
    my $self = shift;
    my $db   = shift;

    $self->current_db($db) if($db);
    return $self->_conn->get_database($self->current_db) if($self->current_db);
    return undef;
}

sub coll {
    my $self = shift;
    my $coll = shift;

    return $self->db->get_collection($coll);
}

sub find_and_modify {
    my $self = shift;
    my $coll = shift;
    my $opts = shift;

    my $cmd = Tie::IxHash->new(
        "findAndModify" => $coll,
        %$opts,
        );

    return $self->db->run_command($cmd);
}

sub map_reduce {
    my $self = shift;
    my $collection = shift;
    my $opts = shift;
    my $as_cursor = delete($opts->{'as_cursor'});

    my $cmd = Tie::IxHash->new( 
        "mapreduce" => $collection,
        %$opts
    );

    my $res = $self->db->run_command($cmd);
    if($res->{ok} == 1) {
        my $coll = $res->{result};
        return ($as_cursor) ? $self->coll($coll)->find() : $res;
    } else {
        return undef;
    }
}

sub group {
    my $self = shift;
    my $collection = shift;
    my $opts = shift;

    # fix the shit up
    $opts->{'ns'} = $self->name,
    $opts->{'$reduce'} = delete($opts->{'reduce'}) if($opts->{'reduce'});
    $opts->{'$keyf'} = delete($opts->{'keyf'}) if($opts->{'keyf'});

    return $self->find_one({ group => $opts });
}

1; 
__END__
=head1 NAME

Mojolicious::Plugin::Mongodb - Use MongoDB in Mojolicious

=head1 VERSION

version 1.16

=head1 SYNOPSIS

Provides a few helpers to ease the use of MongoDB in your Mojolicious application.

    use Mojolicious::Plugin::Mongodb

    sub startup {
        my $self = shift;
        $self->plugin('mongodb', { 
            host => 'localhost',
            port => 27017,
            helper => 'db',
            });
    }

=head1 CONFIGURATION OPTIONS

    helper          (optional)  The name to give to the easy-access helper if you want 
                                to change it's name from the default 'db' 

    no_db               (optional)  Don't install the 'db' helper
    no_model            (optional)  Don't install the 'model' helper
    no_coll             (optional)  Don't install the 'coll' helper
    no_find_and_modify  (optional)  Don't install the 'find_and_modify' helper
    no_map_reduce       (optional)  Don't install the 'map_reduce' helper
    no_group            (optional)  Don't install the 'group' helper

All other options passed to the plugin are used to connect to MongoDB.

=head1 HELPERS/ATTRIBUTES

=head2 mongodb_connection

This plugin helper will return the MongoDB::Connection object, use this if you need to access it for some reason. 

=head2 db([$dbname])

This is the name of the default easy-access helper. The default name for it is 'db', unless you have changed it using the 'helper' configuration option. This helper will return either the database you specify, or the last database you specified. You must use this in order to set the database you wish to operate on for those helpers that specify you should.

    sub someaction {
        my $self = shift;

        # select a database 
        $self->db('my_snazzy_database')->get_collection('foo')->insert({ bar => 'baz' });

        # do an insert on the same database
        $self->db->get_collection('foo')->insert({ bar => 'baz' });
    }

=head2 coll($collname)

This helper allows easy access to a collection. It requires that you have previously selected a database using the 'db' helper. It will return undef if you have not specified a database first.

    sub someaction {
        my $self = shift;

        # get the 'foo' collection in the 'bar' database
        $self->db('bar');
        my $collection = $self->coll('foo');

        # get the 'bar' collection in the 'baz' database
        $self->db('baz');
        my $collection = $self->coll('bar');
    }

=head2 model($db_and_collection) 

This helper functions as a combination of the above, or if you just want to use a different notation. An example usage would be:

    # get the number of items in collection 'bar' in database 'foo'
    my $count = $self->model('foo.bar')->count();

    # if you use dotted collection names, no problem!
    my $system_js_count = $self->model('foo.system.js')->count();

    # if you pass it a regular string without dots, this helper will act like C<coll>.
    my $bar_collection = $self->model('bar');

This helper will set the last selected db to whatever was passed as the database part of the argument, so try not to mix and match C<model> with C<coll> and C<db>. 

=head2 find_and_modify($collname, \%options)

This helper executes a 'findAndModify' operation on the given collection. You must have selected a database using the 'db' helper. See L<http://www.mongodb.org/display/DOCS/findAndModify+Command> for supported options. It will return the raw result from the MongoDB driver. 

=head2 map_reduce($collname, \%options)

This helper executes a 'mapReduce' operation on the given collection. You must have selected a database using the 'db' helper. All options from L<http://www.mongodb.org/display/DOCS/MapReduce> are supported. It will return undef on failure. On success, it will return the raw result from the MongoDB driver, or if you have passed the 'as_cursor' option, it will return a MongoDB::Cursor object for your result collection.

=head1 AUTHOR

Ben van Staveren, C<< <madcat at cpan.org> >>

=head1 BUGS/CONTRIBUTING

Please report any bugs through the web interface at L<http://github.com/benvanstaveren/mojolicious-plugin-mongodb/issues>  
If you want to contribute changes or otherwise involve yourself in development, feel free to fork the Git repository from
L<https://github.com/benvanstaveren/mojolicious-plugin-mongodb/>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mojolicious::Plugin::Mongodb


You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mojolicious-Plugin-Mongodb>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mojolicious-Plugin-Mongodb>

=item * Search CPAN

L<http://search.cpan.org/dist/Mojolicious-Plugin-Mongodb/>

=back


=head1 ACKNOWLEDGEMENTS

Based on L<Mojolicious::Plugin::Database> because I don't want to leave the MongoDB crowd in the cold.

Thanks to Henk van Oers for pointing out a few errors in the documentation, and letting me know I should really fix the MANIFEST

=head1 LICENSE AND COPYRIGHT

Copyright 2011, 2012, 2013 Ben van Staveren.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
