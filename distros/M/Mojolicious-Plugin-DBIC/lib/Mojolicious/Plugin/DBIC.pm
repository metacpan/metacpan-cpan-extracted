package Mojolicious::Plugin::DBIC;
our $VERSION = '0.001';
# ABSTRACT: Mojolicious ♥ DBIx::Class

#pod =head1 SYNOPSIS
#pod
#pod     use Mojolicious::Lite;
#pod     plugin DBIC => {
#pod         schema => { 'Local::Schema' => 'dbi:SQLite::memory:' },
#pod     };
#pod     get '/model', {
#pod         controller => 'DBIC',
#pod         action => 'list',
#pod         resultset => 'Model',
#pod         template => 'model/list.html.ep',
#pod     };
#pod     app->start;
#pod     __DATA__
#pod     @@ model/list.html.ep
#pod     % for my $row ( $resultset->all ) {
#pod         <p><%= $row->id %></p>
#pod     % }
#pod
#pod =head1 DESCRIPTION
#pod
#pod This plugin makes working with L<DBIx::Class> easier in Mojolicious.
#pod
#pod =head2 Configuration
#pod
#pod Configure your schema in multiple ways:
#pod
#pod     # Just DSN
#pod     plugin DBIC => {
#pod         schema => {
#pod             'MySchema' => 'DSN',
#pod         },
#pod     };
#pod
#pod     # Arguments to connect()
#pod     plugin DBIC => {
#pod         schema => {
#pod             'MySchema' => [ 'DSN', 'user', 'password', { RaiseError => 1 } ],
#pod         },
#pod     };
#pod
#pod     # Connected schema object
#pod     my $schema = MySchema->connect( ... );
#pod     plugin DBIC => {
#pod         schema => $schema,
#pod     };
#pod
#pod This plugin can also be configured from the application configuration
#pod file:
#pod
#pod     # myapp.conf
#pod     {
#pod         dbic => {
#pod             schema => {
#pod                 'MySchema' => 'dbi:SQLite:data.db',
#pod             },
#pod         },
#pod     }
#pod
#pod     # myapp.pl
#pod     use Mojolicious::Lite;
#pod     plugin 'Config';
#pod     plugin 'DBIC';
#pod
#pod =head2 Controller
#pod
#pod This plugin contains a controller to reduce the code needed for simple
#pod database operations. See L<Mojolicious::Plugin::DBIC::Controller::DBIC>.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Mojolicious>, L<DBIx::Class>, L<Yancy>
#pod
#pod =cut

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Loader qw( load_class );
use Scalar::Util qw( blessed );

sub register {
    my ( $self, $app, $conf ) = @_;
    # XXX Allow multiple schemas?
    my $schema_conf = $conf->{schema};
    if ( !$schema_conf && $app->can( 'config' ) ) {
        $schema_conf = $app->config->{dbic}{schema};
    }
    $app->helper( schema => sub {
        state $schema = _load_schema( $schema_conf );
        return $schema;
    } );
    push @{ $app->routes->namespaces }, 'Mojolicious::Plugin::DBIC::Controller';
}

sub _load_schema {
    my ( $conf ) = @_;
    if ( blessed $conf && $conf->isa( 'DBIx::Class::Schema' ) ) {
        return $conf;
    }
    elsif ( ref $conf eq 'HASH' ) {
        my ( $class, $args ) = %{ $conf };
        if ( my $e = load_class( $class ) ) {
            die sprintf 'Unable to load schema class %s: %s',
                $class, $e;
        }
        return $class->connect( ref $args eq 'ARRAY' ? @$args : $args );
    }
    die sprintf "Unknown DBIC schema config. Must be schema object or HASH, not %s",
        ref $conf;
}

1;

__END__

=pod

=head1 NAME

Mojolicious::Plugin::DBIC - Mojolicious ♥ DBIx::Class

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Mojolicious::Lite;
    plugin DBIC => {
        schema => { 'Local::Schema' => 'dbi:SQLite::memory:' },
    };
    get '/model', {
        controller => 'DBIC',
        action => 'list',
        resultset => 'Model',
        template => 'model/list.html.ep',
    };
    app->start;
    __DATA__
    @@ model/list.html.ep
    % for my $row ( $resultset->all ) {
        <p><%= $row->id %></p>
    % }

=head1 DESCRIPTION

This plugin makes working with L<DBIx::Class> easier in Mojolicious.

=head2 Configuration

Configure your schema in multiple ways:

    # Just DSN
    plugin DBIC => {
        schema => {
            'MySchema' => 'DSN',
        },
    };

    # Arguments to connect()
    plugin DBIC => {
        schema => {
            'MySchema' => [ 'DSN', 'user', 'password', { RaiseError => 1 } ],
        },
    };

    # Connected schema object
    my $schema = MySchema->connect( ... );
    plugin DBIC => {
        schema => $schema,
    };

This plugin can also be configured from the application configuration
file:

    # myapp.conf
    {
        dbic => {
            schema => {
                'MySchema' => 'dbi:SQLite:data.db',
            },
        },
    }

    # myapp.pl
    use Mojolicious::Lite;
    plugin 'Config';
    plugin 'DBIC';

=head2 Controller

This plugin contains a controller to reduce the code needed for simple
database operations. See L<Mojolicious::Plugin::DBIC::Controller::DBIC>.

=head1 SEE ALSO

L<Mojolicious>, L<DBIx::Class>, L<Yancy>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
