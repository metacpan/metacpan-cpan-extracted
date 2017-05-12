#
# This file is part of Module-Packaged-Generator
#
# This software is copyright (c) 2010 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.010;
use strict;
use warnings;

package Module::Packaged::Generator;
BEGIN {
  $Module::Packaged::Generator::VERSION = '1.111930';
}
# ABSTRACT: build list of modules packaged by a linux distribution

use DBI;
use Devel::Platform::Info::Linux;
use Moose;
use MooseX::Has::Sugar;

use Module::Packaged::Generator::CPAN;
use Module::Packaged::Generator::DB;

with 'Module::Packaged::Generator::Role::Logging';


# -- public attributes
{


    has file => ( ro, isa=>'Str', lazy_build );
    sub _build_file {
        my $self = shift;
        my $dist = $self->drivername;
        return "cpan_$dist.db";
    }



    has drivername => ( ro, isa=>'Str', lazy_build );
    sub _build_drivername {
        my $self = shift;
        my $dist = Devel::Platform::Info::Linux->new->get_info->{oslabel};
        return $dist;
    }

}


# -- private attributes
{
    # the mpg::db object
    has _db => ( ro, isa=>'Module::Packaged::Generator::DB', lazy_build );
    sub _build__db {
        my $self = shift;
        return Module::Packaged::Generator::DB->new( file => $self->file );
    }

    # the driver object
    has _driver => ( ro, isa=>'Module::Packaged::Generator::Driver', lazy_build );
    sub _build__driver {
        my $self = shift;

        my $flavour = $self->drivername;
        my $driver  = "Module::Packaged::Generator::Driver::$flavour";

        $self->log_debug( "trying to use driver $driver" );
        eval "use $driver";
        $self->log_fatal( $@ ) if $@ =~ /Compilation failed/;
        $self->log_fatal( "driver $driver not found" ) if $@;

        return $driver->new;
    }
}


# -- public methods



sub run {
    my $self = shift;

    # initialize stuff
    $self->log_step( "initialization" );
    $self->log_debug( "driver name: " . $self->drivername );
    # force attribute creation
    $self->_driver;
    Module::Packaged::Generator::CPAN->new->module2dist( "Foo::Bar::Baz");

    # fetch the list of available perl modules
    my @modules = $self->_driver->list;
    $self->log( "found " . scalar(@modules) . " perl modules" );

    # insert the modules in the database
    my $db = $self->_db;
    $db->create;
    $self->log_step( "populating database" );
    my $prefix = "inserting modules in db";
    my $progress = $self->progress_bar( {
        count     => scalar(@modules),
        bar_width => 50,
        remove    => 1,
        name      => $prefix,
    } );
    $progress->minor(0);  # we're so fast now that we don't need minor scale
    my $next_update = 0;
    foreach my $i ( 0 .. $#modules ) {
        my $m = $modules[$i];
        $db->insert_module($m);
        $next_update = $progress->update($_)
            if $i >= $next_update;
    }
    $progress->update( scalar(@modules) );
    $self->log( "${prefix}: done" );

    $db->create_indices;
    $db->close;

    $self->log_step( "database is ready" );
}


1;


=pod

=head1 NAME

Module::Packaged::Generator - build list of modules packaged by a linux distribution

=head1 VERSION

version 1.111930

=head1 DESCRIPTION

This module alows to fetch modules available as native Linux (or BSD)
distribution packages, and wraps them in a sqlite database. This allows
people to do analysis, draw CPANTS metrics from it or whatever.

Of course, running the utility shipped in this dist will only create the
database for the current distribution. But that's not our job to do
crazy manipulation with this data, we just provide the data :-)

=head1 ATTRIBUTES

=head2 file

The path to the database file to be created (a string). Defaults to
C<cpan_$dist.db>, where C<$dist> is the distribution name.

=head2 drivername

The name of the driver to use (eg, C<Mageia>). Defaults to the actual
distribution name.

=head1 METHODS

=head2 run

    $generator->run;

Create the database and populate it according to the driver's list of
modules.

=head1 SEE ALSO

You can find more information on this module at:

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/Module-Packaged-Generator>

=item * See open / report bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Module-Packaged-Generator>

=item * Git repository

L<http://github.com/jquelin/module-packaged-generator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Module-Packaged-Generator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Module-Packaged-Generator>

=back

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

