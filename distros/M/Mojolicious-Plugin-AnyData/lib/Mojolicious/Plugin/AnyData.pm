################################################################################
#
#  Mojolicious::Plugin::AnyData 1.20
#
#    uses perl data in the memory like a database source.
#    author: Alexander Ponomarev <shootnix@cpan.org>
#
################################################################################

package Mojolicious::Plugin::AnyData;

BEGIN {
    $Mojolicious::Plugin::AnyData::VERSION = '1.20';
}

use Mojo::Base 'Mojolicious::Plugin';
use DBI;
use v5.10;

has 'dbh';
has 'app';

# Run on startup
sub register {
    my ($self, $app, $param) = @_;
    
    return if $app->mode && $app->mode eq 'production';

    my ($data, $data_file);
    my $func   = $param->{func};
    my $helper = $param->{helper};
    $helper ||= 'db';
    my $dbh  = DBI->connect('dbi:AnyData:(RaiseError=>1)');
    
    $self->dbh($dbh);
    $self->app($app);
    
    if ( $param->{load_data} ) {
	$self->load_data( $param->{load_data} );
    }
    
    if ( $func && ref $func eq 'ARRAY' && scalar @$func > 0 ) {
	#$dbh->func(@$func);
	$self->func(@$func);
    }
    
    $app->helper( $param->{helper} => sub { return $dbh } );
    $app->helper( any_data => sub { return $self } );
}

# Load data into the memory using different ways
# in: arrayref (data structure) or scalar (filename)
sub load_data {
    my ($self, $data) = @_;
    
    return unless $self->dbh && $self->app;
    
    if ( ref $data ) {
    	$self->ad_import($data);
    }
    else {
    	my $data_file = $data;
    	$data = $self->app->plugin(config => {
    	    file => $data_file,
    	    stash_key => 'any_data',
    	});
    	$self->ad_import($data);
    }
}

# Provide the wrapper method for DBD::AnyData::func method
sub func {
    my ($self, $table_name, $table_type, $table_data, $table_method) = @_;
    
    return unless $self->dbh;
    
    $self->dbh->func($table_name, 'ad_clear');
    $self->dbh->func( $table_name, $table_type, $table_data, $table_method );
}

# Execute DBD::AnyData::func method in order to load data into the memory
sub ad_import {
    my ($self, $data) = @_;
    
    return unless $self->dbh;
    
    if ( $data && ref $data eq 'HASH' && keys %$data > 0 ) {
    	TABLE:
	for my $table_name ( keys %$data ) {
	    next TABLE unless ref $data->{$table_name} eq 'ARRAY';
	    
	    $self->dbh->func($table_name, 'ad_clear');
    	    $self->dbh->func($table_name, 'ARRAY', $data->{$table_name}, 'ad_import');
        }
    }
}

sub version {
    my ($self) = @_;
    
    return $Mojolicious::Plugin::AnyData::VERSION;
}

1;
__END__

=head1 NAME

Mojolicious::Plugin::AnyData

=head1 VERSION

version 1.20

=head1 DESCRIPTION

Mojolicious::Plugin::AnyData uses perl data in the memory like a database source.

=head1 SYNOPSIS

    use Mojolicious::Plugin::AnyData
    
    sub startup {
	my $self = shift;
	
	$self->plugin(any_data => {
	    load_data => {
                cars => [
		    ['id', 'model'],
		    [ 1, 'Honda'], ],
		},
	    },
	    helper => 'db',
	});
	
	# ... or
	$self->plugin(any_data => {
	    func => ['cars', 'XML', 'cars.xml', 'ad_import'],
	});
	
	# ... or
	$self->plugin(any_data => {
	    load_data => 'my_test_data.conf'
	});
    }

=head1 CONFIGURATION

This plugin doesn't require any options at startup, so you
may load your data in your program at any time. 
The helper returns the default value 'db' if they haven't been 
specified before.

You can switch from DBD::AnyData instance to your production database
handler by change development mode to production in your project:

    app->mode('production');

=head1 HELPERS

Mojolicious::Plugin::AnyData provides all methods inherited from DBD::AnyData
and DBI.

=head3 db (or something else)

This helper will be created with your specified name or 'db', by default,
in order to access a database handler.

=head3 any_data

This helper gives access to a plugin instance and provides the
following methods:

=head1 METHODS

=head3 load_data

It loads data from perl struct (hashref) into the memory. 
Also, it can support several tables at the same time. You can use this method
on startup, like a simple config option:

    $self->plugin(any_data => {
	load_data => {
	    artists => [
		['id_artist', 'artist_name'],
		[          1, 'Metallica'],
		[          2, 'Dire Staits'],
	    ],
	    releases => [
		['id_release', 'release_name',  'id_artist'],
		[           1, 'Death Magnetic',          1],
		[           2, 'Load',                    1],
	    ],
	},
    });

Or, like a real plugin method in your program:

    app->any_data->load_data({
	artists => [
	    ['id_artist', 'artist_name'],
	    [          1, 'Metallica'],
	    [          2, 'Dire Staits'],
	],
	releases => [
	    ['id_release', 'release_name',  'id_artist'],
	    [           1, 'Death Magnetic',          1],
	    [           2, 'Load',                    1],
	],
    });
    
You can also load data stuctures from a separate config, using
Mojolicious::Plugin::Config:
  
    $self->plugin(any_data => {
	load_data => 'test_data.conf',
	helper    => 'db'
    });
    
    # or:
    
    app->any_data->load_data('test_data.conf');

The plugin automatically checks the data type (hashref or simple scalar) and 
in case if it's a scalar, treats it as the file name containing data.
They will be loaded automagically using Mojolicious::Plugin::Config.

=head3 func

It provides a wrapper for the common DBD::AnyData::func method with one change:
before loading new data, it will remove the table with the same name from the memory
if it already exists.

    $self->plugin(any_data => {
	func => ['cars', 'XML', 'cars.xml', 'ad_import'],
    });
    
    # or, of course
    
    app->any_data->func('cars', 'XML', 'cars.xml', 'ad_import');

=head1 SEE ALSO

Mojolicious, DBI, DBD::AnyData

=head1 AUTHOR

Alexander Ponomarev, C<< <shootnix@cpan.org> >>

=head1 BUGS/CONTRIBUTING

Please report any bugs and feature requests via the Web interface
at L<https://github.com/shootnix/Mojolicious-Plugin-AnyData/issues>.
If you want to contribute, feel free to fork our Git repository
L<https://github.com/shootnix/Mojolicious-Plugin-AnyData/>.
