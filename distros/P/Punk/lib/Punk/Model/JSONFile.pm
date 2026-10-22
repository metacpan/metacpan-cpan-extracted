package Punk::Model::JSONFile;

use 5.010;
use strict;
use warnings;
use Punk ();
use File::Raw::JSON ();

our $VERSION = '0.64';

1;

__END__

=head1 NAME

Punk::Model::JSONFile - a Punk::Model backend over a JSON file

=head1 SYNOPSIS

    # the app
    database data => { backend => 'Punk::Model::JSONFile', file => 'share/data.json' };
    model;

    # share/data.json
    { "modules": [ { "slug": "punk", "name": "Punk", "position": 1 }, ... ] }

    # the model
    package MyApp::Model::Module;
    use Punk::Model;
    database 'data';
    table    'modules';             # the "modules" array in the file
    field slug     => { type => 'string', primary => 1 };
    field name     => { type => 'string' };
    field position => { type => 'integer' };

    # anywhere
    my $page = $c->model('Module')->search({ name => { starts_with => 'P' } },
                                           { order_by => 'position' });
    $c->model('Module')->create({ slug => 'hamt', name => 'HAMT', position => 2 });

=head1 DESCRIPTION

The whole L<Punk::Model> contract over one JSON file: the file is an object,
and each model's C<table> names an array of rows in it, so one file can hold
several tables, and values beside them that L</document> hands back. It is for
data that is small, edited by hand or written rarely, and wants to live in the
repository rather than a database: a list of featured items, a site's
settings, a snapshot of an upstream API.

=head2 Reading

The file is read through L<File::Raw::JSON> and kept, per process, until it
changes. "Changes" means its inode, its size or its mtime: a write here, or
any tool that writes atomically, renames a new file into place, which can land
within the second of the last read, so the mtime alone would miss it. A
missing file has no rows. A file that is not a JSON object has no rows and
warns once for each version of it, rather than on every read.

Filters, C<order_by>, C<limit> and the C<after> token are those of
L<Punk::Model>, checked by the same code as L<Punk::Model::DBI>, with the same
croaks and the same token, evaluated with SQL's three-valued logic:
C<undef> (JSON C<null>) never equals, compares or is C<in> anything; C<!=>
leaves nulls out; C<not_in> over a list holding a null matches nothing.
Values compare as numbers when both look like numbers, otherwise as strings;
null sorts first. C<like> takes C<%> and C<_> and is case-sensitive.

Every row handed out is a deep copy.

=head2 Writing

C<create>, C<update> and C<delete> each rewrite the whole file. They hold an
exclusive C<flock> on F<< <file>.lock >> while they do (where the platform has
C<flock>), so two workers cannot lose each other's change; they read the file
afresh rather than from the cache; and they write a temporary file and rename
it over the old one, so a reader never sees half of it. The file is written
pretty-printed with sorted keys, so it diffs well under version control.

C<create> keeps the declared columns with defined values (validation, when the
model has any, has already run in L<Punk::Model>). Without a primary key value
it takes the next integer after the largest one, and croaks when the existing
keys are not all integers; an existing key croaks. C<update> needs the primary
key, sets the declared columns given, and returns the row, or C<undef> when
there is none. C<delete(%key)> returns how many rows it removed.

A broken file is never written over: a write croaks instead.

=head1 THE CONTRACT

=head2 get(%key)

The first row whose key columns equal the values, copied, or C<undef>.

=head2 search(\%filter, \%opts)

A page, C<< { rows, has_more_data, next } >>, as on L<Punk::Model::DBI>; see
L</Reading>.

=head2 count(\%filter)

How many rows match.

=head2 all()

C<< search({}, {}) >>.

=head2 create(\%data)

Appends the row and returns it; see L</Writing>.

=head2 update(\%key_and_changes)

Changes the row the primary key names and returns it, or C<undef>.

=head2 delete(%key)

Removes the matching rows and returns how many.

=head1 METHODS

=head2 file

The path, as the C<database> gave it.

=head2 document

The whole file, decoded and copied, or C<undef>: for values kept beside the
tables, such as a count or a timestamp.

=head2 new

Called by L<Punk::Model> with the C<database> options (which must include a
C<file>), the table, the primary key and the columns.

=head1 SEE ALSO

L<Punk::Model>, L<Punk::Model::DBI>, L<Punk::Model::Markdown>.

=cut
