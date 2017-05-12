# Palm::Progect.pm
#
# Perl class for dealing with Palm Progect databases.
#
# Author: Michael Graham
# Thanks to Andrew Arensburger's great Palm::* modules

use strict;
package Palm::Progect;
use Palm::StdAppInfo;
use Palm::PDB;
use Palm::Raw;

use Palm::Progect::Constants;
use Palm::Progect::Record;
use Palm::Progect::Prefs;
use Palm::Progect::Converter;

use vars '$VERSION';

$VERSION = '2.0.4';

=head1 NAME

Palm::Progect - Handler for Palm Progect databases.

=head1 SYNOPSIS

    use Palm::Progect;
    use Palm::Progect::Constants;

    my $progect = Palm::Progect->new('options' => { 'quiet' => 1 });

    $progect->load_db(
        file    => $some_file,
    );

    $progect->export_records(
        file    => $some_other_file,
        format  => 'text',
        options => {
            tabstop          => 4,
            fill_with_spaces => 1,
            date_format      => 'dd-mm-yyyy',
        },
    );

=head1 DESCRIPTION

Palm::Progect is a class for handling Progect Database files.

Progect is a hierarchical organizer for the Palm OS.  You can find it at:

L<http://sourceforge.net/projects/progect>

Palm::Progect allows you to load and save Progect databases (and to convert
between database versions), and to import and export records in various formats.

If all you are interested in doing is converting from one format to another,
you should probably look at the C<progconv> utility program which does just that.

These docs are for developers who want to manipulate Progect C<PDB> files
programatically.

=head1 OVERVIEW

You should be able to access all functions of the C<Palm::Progect> system
directly from the C<Palm::Progect> module.

Although the various database drivers and record converters all live in
their own Perl modules, C<Palm::Progect> is the interface to their
functionality.  It will transparently delegate to the appropriate module
behind the scenes necessary.

You can load a C<Palm::Progect> database from a Progect C<PDB> file (via
the C<load_db> method), or import records and/or preferences from
another format (such as Text or CSV) (via the C<import_records> and
C<import_prefs> methods).

After a Progect database has been loaded or imported, you will have
a list of records (in C<$progect-E<gt>records>), and a preferences object
(in C<$progect-E<gt>preferences>).

Each record in C<$progect-E<gt>records> is an object of type
L<Palm::Progect::Record>.

    for my $rec (@{ $progect->records }) {
        my $description = $rec->description;
        my $priority    = $rec->priority;
        print "[$priority] $description\n";
    }

See L<Palm::Progect::Record> for the format of these records.

Once you have loaded the records and preferences, you can save them
to a Progect C<PDB> file (via the C<save_db> method), or export
them to another format (such as Text or CSV), via the C<export_records>
and C<export_prefs> methods.

Currently the C<Preferences> interface is not well defined and is
mainly there to allow for future development.  See L<BUGS and CAVEATS>.

This module was largely written in support of the B<progconv> utility,
which is a conversion utility which imports and exports between
Progect PDB files and other formats.

=head2 Constructor

=over 4

=item new

Create a new C<Palm::Progect> object:

    my $progect = Palm::Progect->new(options => \%Options);

options takes an optional hashref containing arguments to the
system.  Currently this allows only a single option:

=over 4

=item quiet

Suppress informational messages when loading and saving databases.

=back

=back

=head2 Methods

=over 4

=item records

A reference to the list of records within the database.  Each record
is an object of type C<Palm::Progect::Record>.

=item prefs

A reference to the preferences object within the database.  It is an
object of type C<Palm::Progect::Prefs>.  For now the prefs object
doesn't do very much and is mostly a placeholder to allow for future
development.

=item options

Reference to the hash of user options passed to the C<new> constructor.
See the C<new> constructor for details.

=item version

The Progect database version currently in use.  This can come directly
from the source database (loaded with C<load_db>) or from the user (as
an argument to C<load_db> or C<save_db>).

=begin internal_use_only

=item _palm_pdb

The underlying C<Palm::Raw> database which C<Palm::Progect> uses
to access the database file.

=end internal_use_only

=cut

use CLASS;
use base qw(Class::Accessor Class::Constructor);

my @Accessors = qw(
    _palm_pdb
    records
    prefs
    options
    version
);

CLASS->mk_accessors(@Accessors);
CLASS->mk_constructor(
    Auto_Init    => \@Accessors,
    Init_Methods => '_init',
);

sub _init {
    my $self = shift;

    &Palm::PDB::RegisterPDBHandlers('Palm::Raw', [ "lbPG", "DATA" ], );
    $self->_palm_pdb(
        Palm::Raw->new
    );
}

=item load_db(file =E<gt> $filename, version =E<gt> $version)

Load the Progect database file specified by $filename.

The C<version> parameter is optional.  Normally you would
leave it out and let C<Palm::Progect> determine the version
from the database file itself.

If you specify a particular C<version>, then C<Palm::Progect> will attempt
to read the database as that version.  This would be useful for instance
in the case of a corrupt PDB that indicates an incorrect version, or a
PDB of a version that Palm::Progect does not support (but you want to
try and see if it can read it anyway).

Currently supported versions are C<18> (for Progect database version 0.18) and
C<23> (for Progect database version 0.23).

Progect database version 0.18 was used all the way up until Progect version
0.22, so if you saved a database with Progect 0.22, the database will be
a version 0.18 database.

=cut

sub load_db {
    my $self = shift;
    my %args = @_;

    my $file    = $args{'file'};

    print STDERR "Loading Progect database from $file\n" unless $self->options->{'quiet'};
    $self->_palm_pdb->Load($file);

    # Determine the version from the database
    # Lucky for us, the db version number is the first byte
    # of the appinfo block.

    my $appinfo = {};

    if ($self->_palm_pdb->{'appinfo'}) {
        &Palm::StdAppInfo::parse_StdAppInfo($appinfo, $self->_palm_pdb->{'appinfo'});
    }
    else {
        $appinfo = {
            'categories' => [],
            'other'      => pack('C', 23),
        };
    }

    my $version = unpack 'C', $appinfo->{'other'};
    print STDERR "Progect database is version $version\n" unless $self->options->{'quiet'};

    # Allow the user to manually override the version
    # (after all, the database prefs might be corrupt)
    if ($args{version} and $version != $args{version}) {
        $version = $args{version};
        print STDERR "Forcing version to $version\n" unless $self->options->{'quiet'};
    }

    my @raw_records = @{ $self->_palm_pdb->{'records'} };

    # Categories will always be a list of unique names
    my @categories  = @{$appinfo->{'categories'}};

    # Tell the Record class which categories we know about

    Palm::Progect::Record->set_categories(@categories);

    # Build @records from @raw_records:

    my @records;

    for my $raw_record (@raw_records) {
        my $record = Palm::Progect::Record->new(
            version    => $version,
            raw_record => $raw_record,
        );

        push @records, $record;
    }

    # This doesn't do much at present
    my $prefs  = Palm::Progect::Prefs->new(
        version    => $version,
        appinfo    => $appinfo,
        name       => _db_name_from_filename($file),
    );
    $prefs->categories(@categories);

    $self->records(@records);
    $self->prefs($prefs);
    $self->version($version);
}

=item save_db(file =E<gt> $filename, version =E<gt> $version)

Save the records and prefs as a Progect database of version C<$version>
to the filename C<$filename>.

If you do not specify a version then the latest available version is
assumed, unless you have set C<version> before, by a previous call
to C<load_db> or C<save_db>.

Currently supported versions are C<18> (for Progect database version 0.18) and
C<23> (for Progect database version 0.23).

Progect database version 0.18 was used all the way up until Progect version
0.22, so if you saved a database with Progect 0.22, the database will be
a version 0.18 database.

=cut

sub save_db {
    my $self = shift;
    my %args = @_;

    my $file           = $args{'file'};
    my $save_version   = $args{'version'} || 0;
    my $loaded_version = $self->version   || 0;

    # Repair the records tree
    $self->repair_tree;

    # Pack the raw records from our list of records

    my @records = @{ $self->records };

    my (@raw_records);

    for my $record (@records) {

        my $new_record = Palm::Progect::Record->new(
            version     => $save_version,
            from_record => $record,
        );

        push @raw_records, $new_record->raw_record;
    }

    # Use our prefs object, if it exists.
    # Otherwise, create a new one.

    my $prefs = $self->prefs;

    $prefs = Palm::Progect::Prefs->new(
        version    => $save_version,
        from_prefs => $self->prefs,
    );
    $self->prefs($prefs);

    # Fetch the final category list from the Record object
    my @categories = Palm::Progect::Record::get_categories();

    # Pack the categories into the prefs
    $prefs->categories(@categories);
    $prefs->name(_db_name_from_filename($file));

    # $version is now our preferred db version
    $self->version($save_version);

    # Save our records
    $self->records(\@raw_records);

    # put @raw_records, $raw_prefs, and some constant stuff into $self->_palm_pdb

    $self->_palm_pdb->{'records'}                = \@raw_records;
    $self->_palm_pdb->{'appinfo'}                = $prefs->packed_appinfo;

    $self->_palm_pdb->{'creator'}                = 'lbPG';
    $self->_palm_pdb->{'type'}                   = "DATA";
    $self->_palm_pdb->{'attributes'}{'resource'} = 0;

    # This may move to Palm::Progect::Prefs eventually...
    $self->_palm_pdb->{'name'}                   = $prefs->name;

    # Finally, write the pdb file
    print STDERR "Saving Progect database in version $save_version to $file\n" unless $self->options->{'quiet'};
    $self->_palm_pdb->Write($file);
}

=item import_records(%args)

Import records from a file.

The options passed in C<%args> are as follows:

=over 4

=item file

The file to import the records from.

=item format

The conversion format to use when importing the records.

Internally, this determines which module will do the actual conversion.

For instance, specifying a format of C<Text> will cause
C<Palm::Progect::Converter::Text> module to handle the import.

=item append

If true, then C<import_records> will B<append> the records imported from C<file>
to the internal records list.  If false, C<import_records> will B<replace>
the internal records list with the records imported from C<file>.

=back

You can pass other options to C<import_records>, and these will be passed
directly to the module that does the eventual conversion.  For instance:

    $progect->import_records(
        file        => 'somefile.csv',
        format      => 'CSV',
        date_format => 'dd-mm-yyyy',
    );

In this example, the value of C<date_format> will get passed directly
to the C<Palm::Progect::Converter::CSV> module.

=cut

sub import_records {
    my $self = shift;
    my %args = @_;

    my $file   = delete $args{'file'};
    my $append = delete $args{'append'};

    my $converter = Palm::Progect::Converter->new(
        %args,
    );

    $converter->load_records($file, $append);
    $self->records($converter->records);
    $self->prefs($converter->prefs);
}

=item export_records(%args)

Export records to a file.

The options passed in C<%args> are as follows:

=over 4

=item file

The file to export the records to.  If blank, then the
exported records will be written to STDOUT.

=item format

The conversion format to use when exporting the records.

Internally, this determines which module will do the actual conversion.

For instance, specifying a format of C<Text> will cause
C<Palm::Progect::Converter::Text> module to handle the export.

=item append

If true, then C<export_records> will B<append> the exported records to C<file>.
If false, C<export_records> will overwrite C<file> (if it exists)
before exporting the records.

=back

You can pass other options to C<export_records>, and these will be passed
directly to the module that does the eventual conversion.  For instance:

    $progect->export_records(
        file        => 'somefile.csv',
        format      => 'CSV',
        date_format => 'dd-mm-yyyy',
    );

In this example, the value of C<date_format> will get passed directly
to the C<Palm::Progect::Converter::CSV> module.

=cut

sub export_records {
    my $self = shift;
    my %args = @_;

    my $file   = delete $args{'file'};
    my $append = delete $args{'append'};

    my $converter = Palm::Progect::Converter->new(
        %args,
        records => $self->records,
        prefs   => $self->prefs,
    );

    $converter->save_records($file, $append);
}

=item import_prefs

Import preferences from a file.  Currently this is not supported.

=cut

sub import_prefs {
    my $self = shift;
    my %args = @_;
}

=item export_prefs

Export preferences to a file.  Currently this is not supported.

=cut

sub export_prefs {
    my $self = shift;
    my %args = @_;
}

=item repair_tree

Goes through the list of records and repairs the relationships between them:

    $progect->repair_tree;

C<Palm::Progect> calls this method internally just before it saves a Progect
database file.

That means:

=over 4

=item *

Insert the root record (no description, level 0) if necessary.

=item *

Fix the parent/child/sibling relationships (C<has_child>, C<has_next>,
C<has_prev>, etc.) if necessary.

=back

=cut

sub repair_tree {
    my $self = shift;

    my @records = @{ $self->records };

    # Insert the "root record" if necessary
    if ($records[0]->level or $records[0]->description) {
        my $root_record = new Palm::Progect::Record( version => $self->version );

        $root_record->has_child(1);
        $root_record->level(0);
        $root_record->is_opened(1);

        unshift @records, $root_record;
    }

    # Fix relations between records

    for (my $i = 0; $i < @records; $i++) {
        my $rec = $records[$i];

        $rec->has_child(0);
        $rec->has_next(0);
        $rec->has_prev(0);

        if ($i == 0 and @records > 0) {
            $rec->has_prev(0);

            my $next_rec = $records[$i+1];
            $rec->has_child(1) if $next_rec and $next_rec->level > $rec->level;

            # Look ahead to other records, see if we
            # can find one at the same level as us,
            # before we cross one at a previous level
            for (my $j = $i + 1; $j < @records; $j++) {

                my $other_record = $records[$j];

                last if $other_record->level < $rec->level;

                if ($other_record->level == $rec->level) {
                    $rec->has_next(1);
                    last;
                }
            }
        }
        else {
            my $prev_rec = $records[$i-1];
            if (@records > $i) {
                my $next_rec = $records[$i+1];
                $rec->has_child(1) if $next_rec and ($next_rec->level || 0) > ($rec->level || 0);
            }
            # Look ahead to other records, see if we
            # can find one at the same level as us,
            # before we cross one at a previous level
            if ($i < @records) {
                for (my $j = $i + 1; $j < @records; $j++) {

                    my $other_record = $records[$j];

                    last if $other_record->level < $rec->level;

                    if ($other_record->level == $rec->level) {
                        $rec->has_next(1);
                        last;
                    }
                }
            }
            # Same thing, working backwards
            for (my $j = $i - 1; $j > 0; $j--) {

                my $other_record = $records[$j];

                last if $other_record->level < $rec->level;

                if ($other_record->level == $rec->level) {
                    $rec->has_prev(1);
                    last;
                }
            }
        }
    }

    $self->records(@records);
}

=back

=begin internal_use_only

=head2 Utility Subroutines



=over 4

=item _db_name_from_filename

This is a subroutine, not a method.  Call it like:

    my $db_name = _db_name_from_filename($filename);

Given a filename, try to come up with a sensible name for the progect
database.  Remove the extension, the C<lbPG> prefix (if any), etc.

=back

=end internal_use_only

=cut

sub _db_name_from_filename {
    my $filename = shift;
    $filename =~ tr{\\}{/};
    $filename =~ tr{:}{/};
    $filename = (split m{/}, $filename)[-1];
    $filename =~ s/^lbPG-//;
    $filename =~ s/\..*?$//;
    return $filename;
}

1;

__END__

=head1 BUGS and CAVEATS

=head2 Categories

Palm::Progect reads and writes categories properly from and to Progect C<PDB>
files.  As of version 0.25, Progect itself can read these categories properly.

Versions of Progect earlier than 0.25 may have problems reading
the categories as saved by Palm::Progect.

This is due to the fact that Palm::Progect does not write the preferences
block correctly.

As a result, when you load into an older version of Progect a database
that you created with Palm::Progect, You will get a warning that "Your
preferences have been deleted".

Progect will then reset the category list.

However, all of the records will still keep their references to the deleted
categories.

So, if you select "Edit Categories..." and recreate the categories
B<in the exact same order> as they were before, the records will
magically return to their proper categories.

Again, these steps are only required when you are using a version of
Progect that is older than version 0.25.

=head2 Preferences

Preferences are not handled properly yet.  They cannot be imported or
exported, and they are not read from the Progect database file.

Additionally, in Progect version 0.23 and earlier, when you load a
database created by Palm::Progect into Progect, you will get a warning
that "Your preferences have been deleted".  The preferences for the
database will be reset to sensible defaults.

In Progect version 0.25, you will not get this warning.

=head2 Two-digit Dates

Using a two digit date format will fail for dates before 1950
or after 2049 :).

=head1 AUTHOR

Michael Graham E<lt>mag-perl@occamstoothbrush.comE<gt>

Copyright (C) 2002-2005 Michael Graham.  All rights reserved.
This program is free software.  You can use, modify,
and distribute it under the same terms as Perl itself.

The latest version of this module can be found on http://www.occamstoothbrush.com/perl/

=head1 SEE ALSO

C<progconv>

L<Palm::PDB(3)>

http://progect.sourceforge.net/

=cut


