package Test::Chado;
{
  $Test::Chado::VERSION = 'v4.1.1';
}
use feature qw/say/;
use Test::Chado::Factory::DBManager;
use Test::Chado::Factory::FixtureLoader;
use Test::Chado::Types qw/MaybeFixtureLoader MaybeDbManager/;
use Types::Standard qw/Str Bool/;
use Moo;
use DBI;
use MooX::ClassAttribute;
use Sub::Exporter -setup => {
    exports => [
        'chado_schema'                => \&_build_schema,
        'drop_schema'                 => \&_drop_schema,
        'reload_schema'               => \&_reload_schema,
        'set_fixture_loader_type'     => \&_set_fixture_loader_type,
        'get_fixture_loader_instance' => \&_get_fixture_loader_instance,
        'set_fixture_loader_instance' => \&_set_dbmanager_instance,
        'set_dbmanager_instance'      => \&_set_dbmanager_instance,
        'get_dbmanager_instance'      => \&_get_dbmanager_instance,
    ],
    groups => {
        'schema'  => [qw/chado_schema reload_schema drop_schema/],
        'manager' => [
            qw/get_fixture_loader_instance set_fixture_loader_instance
                get_dbmanager_instance set_dbmanager_instance/
        ]
    }
};

class_has 'ignore_tc_env' => (
    is => 'rw', isa => Bool, default => 0 , lazy => 1
);

class_has 'is_schema_loaded' =>
    ( is => 'rw', isa => Bool, default => 0, lazy => 1 );

class_has '_fixture_loader_instance' => (
    is      => 'rw',
    isa     => MaybeFixtureLoader,
    clearer => 1
);

class_has '_dbmanager_instance' => (
    is      => 'rw',
    isa     => MaybeDbManager,
    clearer => 1
);

class_has '_fixture_loader_type' =>
    ( is => 'rw', isa => Str, default => 'preset', lazy => 1 );

sub _set_fixture_loader_type {
    my ($class) = @_;
    return sub {
        my ($arg) = @_;
        if ($arg) {
            $class->_fixture_loader_type($arg);
        }
    };
}

sub _set_fixture_loader_instance {
    my ($class) = @_;
    return sub {
        my ($arg) = @_;
        if ($arg) {
            $class->_fixture_loader_instance($arg);
        }
    };
}

sub _get_fixture_loader_instance {
    my ($class) = @_;
    return sub {
        my $fixture_loader = $class->_fixture_loader_instance;
        die "fixture loader is not initiated !!!\n" if !$fixture_loader;
        return $fixture_loader;
    };
}

sub _set_dbmanager_instance {
    my ($class) = @_;
    return sub {
        my ($arg) = @_;
        if ($arg) {
            $class->_dbmanager_instance($arg);
        }
    };
}

sub _get_dbmanager_instance {
    my ($class) = @_;
    return sub {
        my $dbmanager = $class->_dbmanager_instance;
        die "dbmanager is not initiated !!!\n" if !$dbmanager;
        return $dbmanager;
    };
}

sub _reload_schema {
    my ($class) = @_;
    return sub {
        my $fixture_loader
            = $class->_fixture_loader_instance
            ? $class->_fixture_loader_instance
            : $class->_prepare_fixture_loader_instance;
        $fixture_loader->dbmanager->reset_schema;
        $class->is_schema_loaded(1);
    };
}

sub _drop_schema {
    my ($class) = @_;
    return sub {
        my $fixture_loader
            = $class->_fixture_loader_instance
            ? $class->_fixture_loader_instance
            : $class->_prepare_fixture_loader_instance;
        $fixture_loader->dbmanager->drop_schema;
        $class->is_schema_loaded(0);
        $class->_clear_fixture_loader_instance;
    };
}

sub _build_schema {
    my ($class) = @_;
    return sub {
        my (%arg) = @_;
        my $fixture_loader
            #= $class->_fixture_loader_instance
            #? $class->_fixture_loader_instance
            = $class->_prepare_fixture_loader_instance;

            #if ( !$class->is_schema_loaded ) {
            $fixture_loader->dbmanager->deploy_schema;
            #$class->is_schema_loaded(1);
            #}
        if ( defined $arg{'custom_fixture'} ) {
            die
                "only **preset** fixture loader can be used with custom_fixture\n"
                if $class->_fixture_loader_type ne 'preset';
            $fixture_loader->load_custom_fixtures( $arg{'custom_fixture'} );
            return $fixture_loader->dynamic_schema;
        }

        $fixture_loader->load_fixtures
            if defined $arg{'load_fixture'};
        return $fixture_loader->dynamic_schema;
    };
}

sub _prepare_fixture_loader_instance {
    my ($class) = @_;
    my ( $loader, $dbmanager );
    if ($class->ignore_tc_env) {
        $dbmanager
            = $class->_prepare_default_dbmanager;
    }
    elsif ( exists $ENV{TC_POSTGRESSION} ) {
        $dbmanager
            = Test::Chado::Factory::DBManager->get_instance('postgression');
    }
    elsif ( exists $ENV{TC_TESTPG} ) {
        $dbmanager = Test::Chado::Factory::DBManager->get_instance('testpg');
    }
    elsif ( defined $ENV{TC_DSN} ) {
        my ( $scheme, $driver, $attr_str, $attr_hash, $driver_dsn )
            = DBI->parse_dsn( $ENV{TC_DSN} );
        $dbmanager = Test::Chado::Factory::DBManager->get_instance($driver);
        $dbmanager->dsn( $ENV{TC_DSN} );
        $dbmanager->user( $ENV{TC_USER} )     if defined $ENV{TC_USER};
        $dbmanager->password( $ENV{TC_PASS} ) if defined $ENV{TC_PASS};
    }
    else {
        $dbmanager
            = $class->_prepare_default_dbmanager;
    }

    $loader = Test::Chado::Factory::FixtureLoader->get_instance(
        $class->_fixture_loader_type );
    $loader->dbmanager($dbmanager);
    $class->_dbmanager_instance($dbmanager);
    $class->_fixture_loader_instance($loader);
    return $loader;
}

sub _prepare_default_dbmanager {
    my ($class) = @_;
    return 
            #$class->_dbmanager_instance
            #? $class->_dbmanager_instance
             Test::Chado::Factory::DBManager->get_instance('sqlite');

}

1;

# ABSTRACT: Unit testing for chado database modules and applications

__END__

=pod

=head1 NAME

Test::Chado - Unit testing for chado database modules and applications

=head1 VERSION

version v4.1.1

=head1 SYNOPSIS

=head3 Start with a perl module

This means you have a module with namespace(with or without double colons), along with B<Makefile.PL> or B<Build.PL> or even B<dist.ini>. You have your libraries in
B<lib/> folder and going to write tests in B<t/> folder.
This could an existing or new module, anything would work.

=head3 Write tests 

It should be in your .t file(t/dbtest.t for example)

  use Test::More;
  use Test::Chado;
  use Test::Chado::Common;

  my $schema = chado_schema(load_fixtures => 1);

  has_cv($schema,'sequence', 'should have sequence ontology');
  has_cvterm($schema, 'part_of', 'should have term part_of');
  has_db($schema, 'SO', 'should have SO in db table');
  has_dbxref($schema, '0000010', 'should have 0000010 in dbxref');

  drop_schema();

=head3 Run any test commands to test it against chado sqlite

  prove -lv t/dbtest.t

  ./Build test 

  make test

=head3 Run against postgresql

  #Make sure you have a database with enough permissions
  
  prove -l --dsn "dbi:Pg:dbname=testchado;host=localhost"  --user tucker --password halo t/dbtest.t

  ./Build test --dsn "dbi:Pg:dbname=testchado;host=localhost"  --user tucker --password halo

  make test  --dsn "dbi:Pg:dbname=testchado;host=localhost"  --user tucker --password halo

=head3 Run against postgresql without setting any custom server

  prove -l --postgression t/dbtest.t

  ./Build test --postgression

  make test --postgression

=head1 DOCUMENTATION

Use the B<quick start> or pick any of the section below to start your testing. All the source code for this documentation is also available L<here|https://github.com/dictyBase/Test-Chado-Guides>.

=over

=item L<Quick start|Test::Chado::Manual::QuickStart.pod> 

=item L<Testing perl distribution|Test::Chado::Manual::TestingWithDistribution.pod> 

=item L<Testing web application|Test::Chado::Manual::TestingWithWebApp.pod> 

=item L<Testing with postgresql|Test::Chado::Manual::TestingWithPostgres> 

=item L<Loading custom schema(sql statements) for testing|Test::Chado::Manual::TestingWithCustomSchema> 

=item L<Loading custom fixtures(test data)|Test::Chado::Manual::TestingWithCustomFixtures> 

=back

=head1 API

=head3 Methods

All the methods are available as B<all> export group. There are two more export groups.

=over

=item schema

=over

=item chado_schema

=item reload_schema

=item drop_schema

=back

=item manager

=over

=item get_fixture_loader_instance

=item set_fixture_loader_instance

=item get_dbmanager_instance

=item set_dbmanager_instance

=back

=back

=over

=item B<chado_schema(%options)>

Return an instance of DBIx::Class::Schema for chado database.

However, because of the way the backends works, for Sqlite it returns a on the fly schema generated from L<DBIx::Class::Schema::Loader>, whereas for B<Pg> backend it returns L<Bio::Chado::Schema>

=over

=item B<options>

B<load_fixture> : Pass a true value(1) to load the default fixture, default is false.

B<custom_fixture>: Path to a custom fixture file made with L<DBIx::Class::Fixtures>. It
should be a compressed tarball. Currently it is recommended to use
B<tc-prepare-fixture> script to make custom fixutre so that it fits the expected layout.
Remember, only one fixture set could be loaded at one time and if both of them specified,
I<custom_fixture> will take precedence.

=back

=back

=over

=item B<drop_schema>

=item B<reload_schema>

Drops and then reloads the schema.

=item set_fixture_loader_type

Sets the type of fixture loader backend it should use, either of B<preset> or B<flatfile>.

=item get_dbmanager_instance

Returns an instance of B<backend> class that implements the
L<Test::Chado::Role::HasDBManager> Role. 

=item set_dbmanager_instance

Sets the dbmanager class that should implement L<Test::Chado::Role::HasDBManager> Role.

=item get_fixture_loader_instance

Returns an instance of B<fixture loader> class that implements the
L<Test::Chado::Role::Helper::WithBcs> Role.

=item set_fixture_loader_instance

Sets B<fixture loader> class that should implement the
L<Test::Chado::Role::Helper::WithBcs> Role.

=back

=head1 Build Status

=begin HTML

<a href='https://travis-ci.org/dictyBase/Test-Chado'>
  <img src='https://travis-ci.org/dictyBase/Test-Chado.png?branch=develop'
  alt='Travis CI status'/></a>

<a href='https://coveralls.io/r/dictyBase/Test-Chado'><img
src='https://coveralls.io/repos/dictyBase/Test-Chado/badge.png?branch=develop'
alt='Coverage Status' /></a>

=end HTML

=head1 AUTHOR

Siddhartha Basu <biosidd@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Siddhartha Basu.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
