package Rubberband;
use 5.006;
use strict;
no strict 'refs';
use warnings;
use Carp;
use UNIVERSAL::require;
our $VERSION = '0.01';

sub import {
    my ($self, %args) = @_;
    $args{package}       ||= caller;
    $args{maypole}       ||= "Apache::MVC";
    $args{maypole_model} ||= "Maypole::Model::CDBI::Plain";
    $args{cdbi}          ||= "Class::DBI::BaseDSN";
    # Set up M::P::O in caller
    require Module::Pluggable::Ordered;
    Module::Pluggable::Ordered->import(%args);
    $args{classes} ||= [ $args{package}->plugins ];

    $self->setup_dbi_class(%args);
    $self->setup_maypole(%args);
    *{$args{package}."::create_database_tables"} = sub {
        my ($self, $debug) = @_;
        for my $class (@{$args{classes}}) {
            $class->require or next;
            if ($class->can("run_data_sql")) {
                warn "Setting up database in $class\n" if $debug;
                eval { $class->run_data_sql };
                warn $@ if $@ and $debug;
            }
        }
    }
}

sub setup_dbi_class {
    my ($self, %args) = @_;
    my $dbi = $args{package}."::DBI";
    $args{cdbi}->require or croak "Can't require DBI class $args{cdbi}: $@";
    @{${dbi}."::ISA"} = ($args{cdbi});
    croak "No DSN given! Can't connect!" unless $args{dsn};
    $dbi->set_db(Main => $args{dsn});
    my $schema_args = "";
    if ($args{translate_sql_from}) {
        my %map = ( mysql => "MySQL", Pg    => "PostgresQL");
        my ($from, $to) = ($args{translate_sql_from}, $dbi->__driver);
        $from = exists $map{$from} ? $map{$from} : $from;
        $to   = exists $map{$to}   ? $map{$to}   : $to;
        $schema_args = "(translate => [qw($from $to )])"
            if $from ne $to;
    }
    eval <<EOF
package $dbi;
use Class::DBI::DATA::Schema $schema_args;
1;
EOF
    or die "Something went very wrong: $@";
    push @{$_."::ISA"}, $dbi for @{$args{classes}};
}   

sub setup_maypole {
    my ($self, %args) = @_;

    # Set up Maypole in caller
    my $caller = $args{package};
    $args{maypole}->require 
        or croak "Can't require Maypole class $args{maypole}: $@";
    push @{$caller."::ISA"}, $args{maypole};
    $caller->config->{model} = $args{maypole_model};
    $args{maypole_model}->require
        or croak "Can't require Maypole class $args{maypole_model}: $@";

    # Require classes
    for my $class (@{$args{classes}}) { 
        push @{$class."::ISA"}, $args{maypole_model};
        $class->require or die $@ 
    }
    $caller->setup( $args{classes} );
}

1;
__END__

=head1 NAME

Rubberband - (Even more!) Extensible framework around Maypole

=head1 SYNOPSIS

In Foo.pm:

    package Foo;
    use Rubberband (
        search_path => [ "Foo", "Foo::Plugin" ],
        dsn => "dbi:SQLite:foo.db",
        translate_sql_from => "MySQL",
    );
    Foo->config->{uri_base} = "http://localhost/";
    # Other Maypole configuration parameters

From the command line:

    perl -MFoo -e 'Foo->setup_database_tables'

Or when adding a new plugin:

    perl -MFoo -e 'Foo::Plugin::Magic->run_data_sql'

In F<Foo/Plugin/Magic.pm>:

    package Foo::Plugin::Magic;
    Foo::Plugin::Magic->table("magic");
    Foo::Plugin::Magic->columns(...);

    sub conjure :Exported {
        my ($self, $r) = @_;
        $r->{objects} = [ Foo->call_plugins("collate_magic") ];
    }
    __DATA__
    CREATE TABLE magic (
        id integer auto_increment NOT NULL PRIMARY KEY,
        name varchar(255),
        spell text
    );

=head1 DESCRIPTION

Maypole as a web application framework is easy to extend "vertically" by
adding new C<Exported> methods, but not so easy to extend "horizontally"
by adding new "concepts" (that is, classes and tables). 

Rubberband, as its name implies, is designed to be stretched in both
directions. It uses C<Module::Pluggable::Ordered> to locate the classes
which encapsulate the tables, and also to provide a callback
functionality to allow extensions to "talk" to each other; it also uses
C<Class::DBI::DATA::Schema> to allow extension classes to declare the
SQL to set up their tables. Further, it helps to set up your classes
by creating a backend C<Foo::DBI> class (given an application called C<Foo>,
of course...) which handles the connection
information, and from which your plugin modules automatically inherit.

=head1 OPTIONS

The interface to the module is through options passed on the C<use>
line. The following options are available:

=head2 dsn

This is required - it is the DBI data source you will be using.

=head2 package

The package to set up. You almost never want to set this to anything
other than the default, which is the calling package.

=head2 maypole

The Maypole front-end class in use; this defaults to C<Apache::MVC>.

=head2 maypole_model

The Maypole back-end class; this defaults to C<Maypole::Model::CDBI::Plain>.

=head2 cdbi

The C<Class::DBI> base class; this defaults to C<Class::DBI::BaseDSN>.

=head2 search_path

This, and other C<Module::Pluggable::Ordered> options, are passed on to
that module.

=head2 translate_sql_from

When your DATA section contains the SQL to create your table, and someone
uses the module with a different database from yours, they're going to need
the SQL translated into the SQL variety spoken by their database. This can be
done if you declare what SQL variety B<your> SQL is in, by passing in a 
C<translate_sql_from> option.

=head1 SEE ALSO

L<Maypole>, L<Module::Pluggable::Ordered>, L<Class::DBI::DATA::Schema>.

=head1 AUTHOR

Simon Cozens, E<lt>simon@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Simon Cozens

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
