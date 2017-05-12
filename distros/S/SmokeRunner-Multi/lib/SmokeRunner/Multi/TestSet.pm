package SmokeRunner::Multi::TestSet;
our $AUTHORITY = 'cpan:YANICK';
#ABSTRACT: Represents a set of tests
$SmokeRunner::Multi::TestSet::VERSION = '0.21';
use strict;
use warnings;

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_ro_accessors( qw( name set_dir test_dir last_run_time is_prioritized ) );

use Class::Factory::Util;
use File::Basename qw( basename );
use File::Find::Rule;
use File::Path qw( rmtree );
use File::Spec;
use List::Util qw( max );
use SmokeRunner::Multi::DBI;
use SmokeRunner::Multi::Validate qw( validate DIR_TYPE );


BEGIN
{
    for my $subclass ( map { __PACKAGE__ . '::' . $_ } __PACKAGE__->subclasses() )
    {
        eval "require $subclass" or die $@;
    }
}

{
    my $spec = { set_dir => DIR_TYPE };
    sub new
    {
        my $class = shift;
        my %p     = validate( @_, $spec );

        my $test_dir = File::Spec->catdir( $p{set_dir}, 't' );
        die "A test set's directory must have a 't' subdirectory"
            unless -d $test_dir;

        my %subclass_p = ( %p,
                           name     => basename( $p{set_dir} ),
                           test_dir => $test_dir,
                           dbh      => SmokeRunner::Multi::DBI::handle(),
                         );

        my $self;
        for my $subclass ( map { __PACKAGE__ . '::' . $_ } $class->subclasses() )
        {
            $self = $subclass->_new(%subclass_p);
        }

        $self ||= __PACKAGE__->_new(%subclass_p);

        $self->_instantiate_in_db();
        $self->_get_db_data();

        return $self;
    }
}

sub _new
{
    my $class = shift;

    return bless { @_ }, $class;
}

sub _instantiate_in_db
{
    my $self = shift;

    my $insert_sql = 'INSERT OR IGNORE INTO TestSet (name) VALUES (?)';

    $self->{dbh}->do( $insert_sql, {}, $self->name() );
}

sub _get_db_data
{
    my $self = shift;

    my $select_sql = 'SELECT last_run_time, is_prioritized FROM TestSet WHERE name = ?';

    @{ $self }{ qw( last_run_time is_prioritized ) } =
        $self->{dbh}->selectrow_array( $select_sql, {}, $self->name() );
}

sub test_files
{
    my $self = shift;

    return sort File::Find::Rule->file()->name( '*.t' )->in( $self->test_dir() );
}

sub last_mod_time
{
    my $self = shift;

    return $self->{last_mod_time} if exists $self->{last_mod_time};

    $self->{last_mod_time} = $self->_last_mod_time() || 0;

    return $self->{last_mod_time};
}

sub _last_mod_time
{
    my $self = shift;

    return max map { ( stat $_ )[9] } $self->test_files();
}

sub is_out_of_date
{
    my $self = shift;

    return $self->seconds_out_of_date() > 0 ? 1 : 0;
}

sub seconds_out_of_date
{
    my $self = shift;

    return $self->last_mod_time() - $self->last_run_time();
}

sub update_last_run_time
{
    my $self = shift;
    my $time = shift;

    my $update_sql = 'UPDATE TestSet SET last_run_time = ? WHERE name = ?';

    $self->{dbh}->do( $update_sql, {}, $time, $self->name() );

    $self->_get_db_data();
}

sub prioritize
{
    my $self = shift;

    my $update_sql = 'UPDATE TestSet SET is_prioritized = ? WHERE name = ?';

    $self->{dbh}->do( $update_sql, {}, 1, $self->name() );

    $self->_get_db_data();
}

sub unprioritize
{
    my $self = shift;

    my $update_sql = 'UPDATE TestSet SET is_prioritized = ? WHERE name = ?';

    $self->{dbh}->do( $update_sql, {}, 0, $self->name() );

    $self->_get_db_data();
}

sub update_files
{
    return;
}

sub remove
{
    my $self = shift;

    my $delete_sql = 'DELETE FROM TestSet WHERE name = ?';

    $self->{dbh}->do( $delete_sql, {}, $self->name() );

    rmtree( $self->set_dir(), 0, 0 )
        or die "Cannot rmtree " . $self->set_dir() . "\n";
}

sub All
{
    my $class = shift;

    my $root_dir = SmokeRunner::Multi::Config->instance()->root_dir();

    opendir my $dh, $root_dir
        or die "Cannot read $root_dir: $!";

    return
        ( sort _sort_sets
          map { eval { $class->new( set_dir => $_ ) } || () }
          grep { -d }
          map { File::Spec->catdir( $root_dir, $_ ) }
          File::Spec->no_upwards( readdir $dh )
        );
}

sub _sort_sets
{
    return
        ( $b->is_prioritized() <=> $a->is_prioritized()
          or
          $b->seconds_out_of_date() <=> $a->seconds_out_of_date()
          or
          # This last clause simply ensures that the sort order is
          # unique and repeatable.
          $a->name() cmp $b->name()
        );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SmokeRunner::Multi::TestSet - Represents a set of tests

=head1 VERSION

version 0.21

=head1 SYNOPSIS

  my $set = SmokeRunner::Multi::TestSet->new( set_dir => 'path/to/set' );

=head1 DESCRIPTION

This class provides methods for getting information about a test set.

A test set is simple any directory that contains a subdirectory named
"t", which in turn should contain one or more test files ending in
".t". It can also contain various other directories or files. In
typical usage, this would be a checkout of an application or module.

=head1 METHODS

This class provides the following methods:

=head2 SmokeRunner::Multi::Reporter->new(...)

This method creates a new test set object. It requires one parameter:

=over 4

=item * set_dir

This should be a directory containing a subdirectory named "t".

=back

Instead of simply returning an object of this class, the constructor
looks at each test set subclass and tries to construct an object of
the subclass's class. Subclasses will simply return if they cannot
create an object. If no subclasses return an object, then the
constructor will simply use this class
(C<SmokeRunner::Multi::TestSet>) as the object's class.

=head2 $set->name()

This is the name of the directory containing the test set, without the
full path. So if you create a set with the path
F</home/checkouts/branches/trunk>, the name of the set would be
"trunk".

=head2 $set->set_dir()

This returns the path to the set directory, as passed to the
constructor.

=head2 $set->test_dir()

This returns the path to the "t" subdirectory in the set directory.

=head2 $set->last_run_time()

Returns the time of the last test run for this set. If it has never
been run, the time will be 0.

=head2 $set->is_prioritized()

Returns a boolean indicating whether the set has been prioritized.

=head2 $set->test_files()

Returns a sorted list of all the files in the set's C<test_dir()>.

=head2 $set->last_mod_time()

Returns the last modification time for the set. By default, this is
simply the most recent last mod time for one of the test files, but
subclasses may override this.

=head2 $set->is_out_of_date()

A convenience method which returns true if the last mod time of the
set is greater than its last run time.

=head2 $set->seconds_out_of_date()

This returns the number of seconds by which the set is out of
date. This number can be zero negative, in which case the set is not
out of date, as the last run time is equal to or greater than the last
mod time.

=head2 $set->update_last_run_time()

Updates the last run time of the set in the database.

=head2 $set->prioritize()

=head2 $set->unprioritize()

This methods flip the C<is_prioritized()> flag for the set in the
database.

=head2 $set->update_files()

By default, this method is a no-op, but subclasses can override it.

=head2 $set->remove()

This method deletes the set from the database and from the filesystem.

=head2 SmokeRunner::Multi::TestSet->All()

This returns a sorted list of all the test sets under the root
directory specified in the config file.

Sets are sorted first by whether or not they are prioritized, then by
how out of date they are, and finally by name.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-smokerunner-multi@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 LiveText, Inc., All Rights Reserved.

This program is free software; you can redistribute it and /or modify
it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=head1 AUTHORS

=over 4

=item *

Dave Rolsky <autarch@urth.org>

=item *

Yanick Champoux <yanick@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by LiveText, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
