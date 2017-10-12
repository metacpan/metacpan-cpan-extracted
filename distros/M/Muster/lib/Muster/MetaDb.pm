package Muster::MetaDb;
$Muster::MetaDb::VERSION = '0.62';
#ABSTRACT: Muster::MetaDb - keeping meta-data about pages
=head1 NAME

Muster::MetaDb - keeping meta-data about pages

=head1 VERSION

version 0.62

=head1 SYNOPSIS

    use Muster::MetaDb;;

=head1 DESCRIPTION

Content Management System
keeping meta-data about pages.

=cut

use Mojo::Base -base;
use Carp;
use DBI;
use Search::Query;
use Sort::Naturally;
use Text::NeatTemplate;
use YAML::Any;
use POSIX qw(ceil);
use Mojo::URL;

=head1 METHODS

=head2 init

Set the defaults for the object if they are not defined already.

=cut
sub init {
    my $self = shift;

    $self->{primary_fields} = [qw(title name date filetype is_page pagelink extension filename parent_page)];
    if (!defined $self->{metadb_db})
    {
        # give a default name
        $self->{metadb_db} = 'muster.sqlite';
    }
    if (!defined $self->{route_prefix})
    {
        $self->{route_prefix} = '/'; # for absolute links
    }

    return $self;

} # init

=head2 update_one_page

Update the meta information for one page

    $self->update_one_page($page, %meta);

=cut

sub update_one_page {
    my $self = shift;
    my $pagename = shift;
    my %args = @_;

    if (!$self->_connect())
    {
        return undef;
    }

    $self->_add_page_data($pagename, %args);

} # update_one_page

=head2 update_all_pages

Update the meta information for all pages.

=cut

sub update_all_pages {
    my $self = shift;
    my %args = @_;

    if (!$self->_connect())
    {
        return undef;
    }

    $self->_update_all_entries(%args);

} # update_all_pages

=head2 delete_one_page

Delete the meta information for one page

    $self->delete_one_page($page);

=cut

sub delete_one_page {
    my $self = shift;
    my $pagename = shift;
    my %args = @_;

    if (!$self->_connect())
    {
        return undef;
    }

    if ($self->page_exists($pagename))
    {
        return $self->_delete_page_from_db($pagename);
    }

    return 0;
} # delete_one_page

=head2 update_derived_tables

Update the derived tables for all pages.

=cut

sub update_derived_tables {
    my $self = shift;
    my %args = @_;

    if (!$self->_connect())
    {
        return undef;
    }

    $self->_generate_derived_tables();

} # update_derived_tables

=head2 page_or_file_info

Get the info about one page. Returns undef if the page isn't there.

    my $meta = $self->page_or_file_info($pagename);

=cut

sub page_or_file_info {
    my $self = shift;
    my $pagename = shift;

    if (!$self->_connect())
    {
        return undef;
    }

    return $self->_get_page_meta($pagename);
} # page_or_file_info

=head2 query

Do a freeform query. This returns a reference to the first column of results.

    my $results = $self->query($query);

=cut

sub query {
    my $self = shift;
    my $query = shift;

    if (!$self->_connect())
    {
        return undef;
    }

    return $self->_do_one_col_query($query);
} # query

=head2 pagespec_translate

Attempt to translate an IkiWiki-style pagespec into an SQL condition.

=cut
sub pagespec_translate {
    my $self = shift;
    my $spec=shift;

    # Convert spec to SQL.
    my $sql="";
    while ($spec=~m{
            \s*		# ignore whitespace
            (		# 1: match a single word
                \!		# !
                |
                \(		# (
                        |
                        \)		# )
                |
                \w+\([^\)]*\)	# command(params)
            |
            [^\s()]+	# any other text
        )
        \s*		# ignore whitespace
    }gx)
    {
        my $word=$1;
        if (lc $word eq 'and')
        {
            $sql.=' AND';
        }
        elsif (lc $word eq 'or')
        {
            $sql.=' OR';
        }
        elsif ($word eq '!')
        {
            $sql.=' NOT';
        }
        elsif ($word eq "(" || $word eq ")")
        {
            $sql.=' '.$word;
        }
        elsif ($word =~ /^(\w+)\((.*)\)$/)
        {
            # can't deal with functions, skip it
        }
        else
        {
            $sql.=" page GLOB '$word'";
        }
    } # while

    return $sql;
} # pagespec_translate

=head2 query_pagespec

Do a query using an IkiWiki-style pagespec.

    my $results = $self->query($spec);

=cut

sub query_pagespec {
    my $self = shift;
    my $spec = shift;

    if (!$self->_connect())
    {
        return undef;
    }
    my $where = $self->pagespec_translate($spec);
    my $query = "SELECT page FROM pagefiles WHERE ($where);";

    return $self->_do_one_col_query($query);
} # query_pagespec

=head2 pagelist

Query the database, return a list of pages

=cut

sub pagelist {
    my $self = shift;
    my %args = @_;

    if (!$self->_connect())
    {
        return undef;
    }

    return $self->_get_all_pagenames();
} # pagelist

=head2 allpagelinks

Query the database, return a list of all pages' pagelinks.
This does not include _Header or _Footer pages.

=cut

sub allpagelinks {
    my $self = shift;
    my %args = @_;

    if (!$self->_connect())
    {
        return undef;
    }

    my $pagelinks = $self->_do_one_col_query("SELECT pagelink FROM pagefiles WHERE is_page IS NOT NULL AND NAME NOT GLOB '_*' ORDER BY page;");
    return @{$pagelinks};
} # allpagelinks

=head2 total_pages

Query the database, return the total number of records.

=cut

sub total_pages {
    my $self = shift;
    my %args = @_;

    if (!$self->_connect())
    {
        return undef;
    }

    return $self->_total_pages(%args);
} # total_pages

=head2 page_exists

Does this page/file exist in the database?

=cut

sub page_exists {
    my $self = shift;
    my $page = shift;

    if (!$self->_connect())
    {
        return undef;
    }
    my $dbh = $self->{dbh};

    my $q = "SELECT COUNT(*) FROM pagefiles WHERE page = ?;";
    my $sth = $self->_prepare($q);

    my $ret = $sth->execute($page);
    if (!$ret)
    {
        croak "FAILED to execute '$q' $DBI::errstr";
    }
    my $total = 0;
    my @row;
    while (@row = $sth->fetchrow_array)
    {
        $total = $row[0];
    }
    return $total > 0;
} # page_exists

=head2 bestlink

Which page does the given link match, when linked from the given page?

my $linkedpage = $self->bestlink($page,$link);

=cut

sub bestlink {
    my $self = shift;
    my $page = shift;
    my $link = shift;

    if (!$self->_connect())
    {
        return undef;
    }
    my $dbh = $self->{dbh};

    # code based on IkiWiki
    my $cwd=$page;
    if ($link=~s/^\/+//)
    {
        # absolute links
        $cwd="";
    }
    $link=~s/\/$//;

    do {
        my $l=$cwd;
        $l.="/" if length $l;
        $l.=$link;

        my $page_exists = $self->page_exists($l);
        if ($page_exists)
        {
            return $l;
        }
        else
        {
            my $realpage = $self->_find_pagename($l);
            return $realpage if $realpage;
        }
    } while $cwd=~s{/?[^/]+$}{};

    # broken link
    return "";
} # bestlink

=head1 Helper Functions

These are functions which are NOT exported by this plugin.

=cut

=head2 _connect

Connect to the database
If we've already connected, do nothing.

=cut

sub _connect {
    my $self = shift;

    my $old_dbh = $self->{dbh};
    if ($old_dbh)
    {
        return 1;
    }

    # The database is expected to be an SQLite file
    # and will be created if it doesn't exist
    my $database = $self->{metadb_db};
    if ($database)
    {
        my $creating_db = 0;
        if (!-r $database)
        {
            $creating_db = 1;
        }
        my $dbh = DBI->connect("dbi:SQLite:dbname=$database", "", "");
        if (!$dbh)
        {
            croak "Can't connect to $database $DBI::errstr";
        }
        $dbh->{sqlite_unicode} = 1;
        $self->{dbh} = $dbh;

        # Create the tables if they don't exist
        $self->_create_tables();

        # cache for prepared statements
        $self->{prepared} = {};
    }
    else
    {
	croak "No Database given." . Dump($self);
    }

    return 1;
} # _connect

=head2 _prepare

Retrieve or create prepared statement handles.

    my $sth = $self->_prepare($q);

=cut
sub _prepare {
    my $self = shift;
    my $q = shift;

    my $sth;
    if (exists $self->{prepared}->{$q}
            and defined $self->{prepared}->{$q})
    {
        $sth = $self->{prepared}->{$q};
    }
    else
    {
        $sth = $self->{dbh}->prepare($q);
        if (!$sth)
        {
            croak "FAILED to prepare '$q' $DBI::errstr";
        }
        $self->{prepared}->{$q} = $sth;
    }
    return $sth;
} # _prepare

=head2 _create_tables

Create the initial tables in the database:

pagefiles: (page, title, name, filetype, is_page, filename, parent_page)
links: (page, links_to)
deepfields: (page, field, value)

=cut

sub _create_tables {
    my $self = shift;

    return unless $self->{dbh};

    my $dbh = $self->{dbh};

    my $q = "CREATE TABLE IF NOT EXISTS pagefiles (page PRIMARY KEY, " . join(',', @{$self->{primary_fields}}) . ");";
    my $ret = $dbh->do($q);
    if (!$ret)
    {
        croak __PACKAGE__ . " failed '$q' : $DBI::errstr";
    }
    $q = "CREATE TABLE IF NOT EXISTS links (page, links_to, UNIQUE(page, links_to));";
    $ret = $dbh->do($q);
    if (!$ret)
    {
        croak __PACKAGE__ . " failed '$q' : $DBI::errstr";
    }
    $q = "CREATE TABLE IF NOT EXISTS deepfields (page, field, value, UNIQUE(page, field));";
    $ret = $dbh->do($q);
    if (!$ret)
    {
        croak __PACKAGE__ . " failed '$q' : $DBI::errstr";
    }
    $q = "CREATE UNIQUE INDEX IF NOT EXISTS deepfields_index ON deepfields (page, field)";
    $ret = $dbh->do($q);
    if (!$ret)
    {
        croak __PACKAGE__ . " failed '$q' : $DBI::errstr";
    }

    return 1;
} # _create_tables

=head2 _generate_derived_tables

Create and populate the flatfields table using the data from the deepfields table.
Expects the deepfields table to be up to date, so this needs to be called
at the end of the scanning pass.

    $self->_generate_derived_tables();

=cut

sub _generate_derived_tables {
    my $self = shift;

    return unless $self->{dbh};

    my $dbh = $self->{dbh};

    # ---------------------------------------------------
    # TABLE: flatfields
    # ---------------------------------------------------
    print STDERR "Generating flatfields table\n";
    
    # Drop the table, as it is going to be re-defined.
    my $q = "DROP TABLE IF EXISTS flatfields;";
    my $ret = $dbh->do($q);
    if (!$ret)
    {
        croak __PACKAGE__ . " failed '$q' : $DBI::errstr";
    }
    my @fieldnames = $self->_get_all_nonhidden_fieldnames();

    # need to define some fields as numeric
    my @field_defs = ();
    foreach my $field (@fieldnames)
    {
        if (exists $self->{field_types}->{$field})
        {
            push @field_defs, $field . ' ' . $self->{field_types}->{$field};
        }
        else
        {
            push @field_defs, $field;
        }
    }
    $q = "CREATE TABLE IF NOT EXISTS flatfields (page PRIMARY KEY, "
    . join(", ", @field_defs) .");";
    $ret = $dbh->do($q);
    if (!$ret)
    {
        croak __PACKAGE__ . " failed '$q' : $DBI::errstr";
    }

    # prepare the insert query
    my $placeholders = join ", ", ('?') x @fieldnames;
    my $iq = 'INSERT INTO flatfields (page, '
    . join(", ", @fieldnames) . ') VALUES (?, ' . $placeholders . ');';
    my $isth = $self->_prepare($iq);
    if (!$isth)
    {
        croak __PACKAGE__ . " failed to prepare '$iq' : $DBI::errstr";
    }

    # Insert values for all the pages
    my $transaction_on = 0;
    my $num_trans = 0;
    my @pagefiles = $self->_get_all_pagefiles();
    foreach my $page (@pagefiles)
    {
        if (!$transaction_on)
        {
            my $ret = $dbh->do("BEGIN TRANSACTION;");
            if (!$ret)
            {
                croak __PACKAGE__ . " failed 'BEGIN TRANSACTION' : $DBI::errstr";
            }
            $transaction_on = 1;
            $num_trans = 0;
        }
        my $meta = $self->_get_fields_for_page($page);

        my @values = ();
        foreach my $fn (@fieldnames)
        {
            my $val = $meta->{$fn};
            if (!defined $val)
            {
                push @values, undef;
            }
            elsif (ref $val)
            {
                $val = join("|", @{$val});
                push @values, $val;
            }
            else
            {
                push @values, $val;
            }
        }
        # we now have values to insert
        $ret = $isth->execute($page, @values);
        if (!$ret)
        {
            croak __PACKAGE__ . " failed '$iq' (" . join(',', ($page, @values)) . "): $DBI::errstr";
        }
        # do the commits in bursts
        $num_trans++;
        if ($transaction_on and $num_trans > 100)
        {
            $self->_commit();
            $transaction_on = 0;
            $num_trans = 0;
        }

    } # for each page
    if ($transaction_on)
    {
        $self->_commit();
    }

    print STDERR "Generated flatfields table\n";
    return 1;
} # _generate_derived_tables

=head2 _drop_main_tables

Drop all the tables in the database except the flatfields table (which will be done
just before it is recreated)
If one is doing a scan-all-pages pass, dropping and re-creating may be quicker than updating.

=cut

sub _drop_main_tables {
    my $self = shift;

    return unless $self->{dbh};

    my $dbh = $self->{dbh};

    foreach my $table (qw(pagefiles links deepfields))
    {
        my $q = "DROP TABLE IF EXISTS $table;";
        my $ret = $dbh->do($q);
        if (!$ret)
        {
            croak __PACKAGE__ . " failed '$q' : $DBI::errstr";
        }
    }

    return 1;
} # _drop_main_tables

=head2 _update_all_entries

Update all pages, adding new ones and deleting non-existent ones.
This expects that the pages passed in are the DEFINITIVE list of pages,
and if a page isn't in this list, it no longer exists.

    $self->_update_all_entries($page=>{...},$page2=>{}...);

=cut
sub _update_all_entries {
    my $self = shift;
    my %pages = @_;

    my $dbh = $self->{dbh};

    # it may save time to drop all the tables and create them again
    $self->_drop_main_tables();
    $self->_create_tables();

    # update/add pages
    my $transaction_on = 0;
    my $num_trans = 0;
    foreach my $pn (sort keys %pages)
    {
        print STDERR "UPDATING $pn\n";
        if (!$transaction_on)
        {
            my $ret = $dbh->do("BEGIN TRANSACTION;");
            if (!$ret)
            {
                croak __PACKAGE__ . " failed 'BEGIN TRANSACTION' : $DBI::errstr";
            }
            $transaction_on = 1;
            $num_trans = 0;
        }
        $self->_add_page_data($pn, %{$pages{$pn}});
        # do the commits in bursts
        $num_trans++;
        if ($transaction_on and $num_trans > 100)
        {
            $self->_commit();
            $transaction_on = 0;
            $num_trans = 0;
        }
    }
    if ($transaction_on)
    {
        $self->_commit();
    }

    print STDERR "UPDATING DONE\n";
} # _update_all_entries

=head2 _commit

Commit a pending transaction.

    $self->_commit();

=cut
sub _commit ($%) {
    my $self = shift;
    my %args = @_;
    my $meta = $args{meta};

    return unless $self->{dbh};

    my $ret = $self->{dbh}->do("COMMIT;");
    if (!$ret)
    {
        croak __PACKAGE__ . " failed 'COMMIT' : $DBI::errstr";
    }
} # _commit

=head2 _get_all_pagefiles

List of all pagefiles

$dbtable->_get_all_pagefiles(%args);

=cut

sub _get_all_pagefiles {
    my $self = shift;
    my %args = @_;

    my $dbh = $self->{dbh};
    my $pages = $self->_do_one_col_query("SELECT page FROM pagefiles ORDER BY page;");

    return @{$pages};
} # _get_all_pagefiles

=head2 _get_all_pagenames

List of all pagenames

$dbtable->_get_all_pagenames();

=cut

sub _get_all_pagenames {
    my $self = shift;

    my $dbh = $self->{dbh};
    my $pages = $self->_do_one_col_query("SELECT page FROM pagefiles WHERE is_page IS NOT NULL ORDER BY page;");

    return @{$pages};
} # _get_all_pagenames

=head2 _get_all_nonhidden_fieldnames

List of the unique non-hidden field-names from the deepfields table.
Hidden field names start with '_' and are not supposed to be put into the flatfields table,
though they can be queried from the deepfields table.

    @fieldnames = $self->_get_all_nonhidden_fieldnames();

=cut

sub _get_all_nonhidden_fieldnames {
    my $self = shift;

    my $dbh = $self->{dbh};
    my $fields = $self->_do_one_col_query("SELECT DISTINCT field FROM deepfields WHERE field NOT GLOB '_*' ORDER BY field;");

    return @{$fields};
} # _get_all_nonhidden_fieldnames

=head2 _get_fields_for_page

Get the field-value pairs for a single page from the deepfields table.

    $meta = $self->_get_fields_for_page($page);

=cut

sub _get_fields_for_page {
    my $self = shift;
    my $pagename = shift;

    return unless $self->{dbh};
    my $dbh = $self->{dbh};
    my $q = "SELECT field, value FROM deepfields WHERE page = ?;";

    my $sth = $self->_prepare($q);
    if (!$sth)
    {
        croak "FAILED to prepare '$q' $DBI::errstr";
    }
    my $ret = $sth->execute($pagename);
    if (!$ret)
    {
        croak "FAILED to execute '$q' $DBI::errstr";
    }
    my %meta = ();
    my @row;
    while (@row = $sth->fetchrow_array)
    {
        my $field = $row[0];
        my $value = $row[1];
        $meta{$field} = $value;
    }

    return \%meta;
} # _get_fields_for_page

=head2 _get_children_for_page

Get the "child" pages for this page from the pagefiles table.

    $meta = $self->_get_children_for_page($page);

=cut

sub _get_children_for_page {
    my $self = shift;
    my $pagename = shift;

    return unless $self->{dbh};
    my $dbh = $self->{dbh};
    my $children = $self->_do_one_col_query("SELECT page FROM pagefiles WHERE parent_page = '$pagename' AND is_page IS NOT NULL;");

    return $children;
} # _get_children_for_page

=head2 _get_attachments_for_page

Get the "attachments" non-pages for this page from the pagefiles table.

    $meta = $self->_get_attachments_for_page($page);

=cut

sub _get_attachments_for_page {
    my $self = shift;
    my $pagename = shift;

    return unless $self->{dbh};
    my $dbh = $self->{dbh};
    my $attachments = $self->_do_one_col_query("SELECT page FROM pagefiles WHERE parent_page = '$pagename' AND is_page IS NULL;");

    return $attachments;
} # _get_attachments_for_page

=head2 _get_links_for_page

Get the "links" pages for this page from the links table.

    $meta = $self->_get_links_for_page($page);

=cut

sub _get_links_for_page {
    my $self = shift;
    my $pagename = shift;

    return unless $self->{dbh};
    my $dbh = $self->{dbh};
    my $links = $self->_do_one_col_query("SELECT links_to FROM links WHERE page = '$pagename'");

    return $links;
} # _get_links_for_page

=head2 _get_page_meta

Get the meta-data for a single page.

    $meta = $self->_get_page_meta($page);

=cut

sub _get_page_meta {
    my $self = shift;
    my $pagename = shift;

    return unless $self->{dbh};
    my $dbh = $self->{dbh};

    my $q = "SELECT * FROM pagefiles WHERE page = ?;";

    my $sth = $self->_prepare($q);
    if (!$sth)
    {
        croak "FAILED to prepare '$q' $DBI::errstr";
    }
    my $ret = $sth->execute($pagename);
    if (!$ret)
    {
        croak "FAILED to execute '$q' $DBI::errstr";
    }
    # return the first matching row because there should be only one row
    my $meta = $sth->fetchrow_hashref;
    if (!$meta)
    {
        return undef;
    }
    # Note that there are three different kinds of files we have data on:
    # files: just the basic info in the pagefiles table
    # files-with-filetypes: which have additional meta-data (for example, image file meta-data)
    # pages: which have additional meta-data, and also children, attachments, and links
    if ($meta->{filetype})
    {
        # Now the rest of the meta, if this has meta
        # Get this from the deepfields table rather than the flatfields table
        # because the deepfields table includes "hidden" fields.
        my $more_meta = $self->_get_fields_for_page($pagename);

        foreach my $key (keys %{$more_meta})
        {
            if (!exists $meta->{$key})
            {
                $meta->{$key} = $more_meta->{$key};
            }
        }

        # non-pages don't have links, children, or attachments
        if ($meta->{is_page})
        {
            # get multi-valued fields from other tables
            $meta->{children} = $self->_get_children_for_page($pagename);
            $meta->{attachments} = $self->_get_attachments_for_page($pagename);
            $meta->{links} = $self->_get_links_for_page($pagename);
        }
    }

    return $meta;
} # _get_page_meta

=head2 _do_one_col_query

Do a SELECT query, and return the first column of results.
This is a freeform query, so the caller must be careful to formulate it correctly.

my $results = $self->_do_one_col_query($query);

=cut

sub _do_one_col_query {
    my $self = shift;
    my $q = shift;

    if ($q !~ /^SELECT /)
    {
        # bad boy! Not a SELECT.
        return undef;
    }
    my $dbh = $self->{dbh};

    my $sth = $self->_prepare($q);
    if (!$sth)
    {
        croak "FAILED to prepare '$q' $DBI::errstr";
    }
    my $ret = $sth->execute();
    if (!$ret)
    {
        croak "FAILED to execute '$q' $DBI::errstr";
    }
    my @results = ();
    my @row;
    while (@row = $sth->fetchrow_array)
    {
        push @results, $row[0];
    }
    return \@results;
} # _do_one_col_query

=head2 _total_pagefiles

Find the total records in the database.

$dbtable->_total_pagefiles();

=cut

sub _total_pagefiles {
    my $self = shift;

    my $dbh = $self->{dbh};

    my $q = "SELECT COUNT(*) FROM pagefiles;";

    my $sth = $self->_prepare($q);
    if (!$sth)
    {
        croak "FAILED to prepare '$q' $DBI::errstr";
    }
    my $ret = $sth->execute();
    if (!$ret)
    {
        croak "FAILED to execute '$q' $DBI::errstr";
    }
    my $total = 0;
    my @row;
    while (@row = $sth->fetchrow_array)
    {
        $total = $row[0];
    }
    return $total;
} # _total_pagefiles

=head2 _total_pages

Find the total number of pages.

$dbtable->_total_pages();

=cut

sub _total_pages {
    my $self = shift;

    my $dbh = $self->{dbh};

    my $q = "SELECT COUNT(*) FROM pagefiles WHERE is_page IS NOT NULL;";

    my $sth = $self->_prepare($q);
    if (!$sth)
    {
        croak "FAILED to prepare '$q' $DBI::errstr";
    }
    my $ret = $sth->execute();
    if (!$ret)
    {
        croak "FAILED to execute '$q' $DBI::errstr";
    }
    my $total = 0;
    my @row;
    while (@row = $sth->fetchrow_array)
    {
        $total = $row[0];
    }
    return $total;
} # _total_pages

=head2 _find_pagename

Does this page exist in the database?
This does a case-insensitive check if there isn't an exact match.
Returns the real pagename if it is found, otherwise empty string.

=cut

sub _find_pagename {
    my $self = shift;
    my $page = shift;

    if (!$self->_connect())
    {
        return undef;
    }
    if ($self->page_exists($page))
    {
        return $page;
    }

    return unless $self->{dbh};
    my $dbh = $self->{dbh};

    # set both the column and the query to uppercase
    my $q = "SELECT page FROM pagefiles WHERE UPPER(page) = ?;";
    my $upper_page = uc($page);

    my $sth = $self->_prepare($q);
    if (!$sth)
    {
        croak "FAILED to prepare '$q' $DBI::errstr";
    }
    my $ret = $sth->execute($upper_page);
    if (!$ret)
    {
        croak "FAILED to execute '$q' $DBI::errstr";
    }
    my $realpage = '';
    my @row;
    while (@row = $sth->fetchrow_array)
    {
        $realpage = $row[0];
    }
    return $realpage;
} # _find_pagename

=head2 _pagelink

The page as if it were a html link.
This does things like add a route-prefix or trailing slash if it is needed.

It's okay to hardcode the route-prefix into the database, because it isn't
as if one is going to be mounting the same config multiple times with different
route-prefixes. If you have a different config, you're going to need a
different database.

=cut
sub _pagelink {
    my $self = shift;
    my $link = shift;
    my $info = shift;

    if (!defined $info)
    {
        return $link;
    }
    # if this is an absolute link, needs a prefix in front of it
    if ($link eq $info->{pagename})
    {
        $link = $self->{route_prefix} . $link;
    }
    # if this is a page, it needs a slash added to it
    if ($info->{is_page})
    {
        $link .= '/';
    }
    return $link;
} # _pagelink

=head2 _add_page_data

Add metadata to db for one page.

    $self->_add_page_data($page, %meta);

=cut
sub _add_page_data {
    my $self = shift;
    my $pagename = shift;
    my %meta = @_;

    return unless $self->{dbh};
    my $dbh = $self->{dbh};

    # ------------------------------------------------
    # Derive derivable data
    # ------------------------------------------------
    if (!$meta{pagelink})
    {
        $meta{pagelink} = $self->_pagelink($meta{pagename}, \%meta);
    }
    
    # ------------------------------------------------
    # TABLE: pagefiles
    # ------------------------------------------------
    my @values = ();
    foreach my $fn (@{$self->{primary_fields}})
    {
	my $val = $meta{$fn};
	if (!defined $val)
	{
	    push @values, undef;
	}
	elsif (ref $val)
	{
	    $val = join("|", @{$val});
	    push @values, $val;
	}
	else
	{
	    push @values, $val;
	}
    }

    # Check if the page exists in the table
    # and do an INSERT or UPDATE depending on whether it does.
    # This is faster than REPLACE because it doesn't need
    # to rebuild indexes.
    my $page_exists = $self->page_exists($pagename);
    my $q;
    my $ret;
    if ($page_exists)
    {
        $q = "UPDATE pagefiles SET ";
        for (my $i=0; $i < @values; $i++)
        {
            $q .= sprintf('%s = ?', $self->{primary_fields}->[$i]);
            if ($i + 1 < @values)
            {
                $q .= ", ";
            }
        }
        $q .= " WHERE page = '$pagename';";
        my $sth = $self->_prepare($q);
        if (!$sth)
        {
            croak __PACKAGE__ . " failed to prepare '$q' : $DBI::errstr";
        }
        $ret = $sth->execute(@values);
        if (!$ret)
        {
            croak __PACKAGE__ . " failed '$q' : $DBI::errstr";
        }
    }
    else
    {
        my $placeholders = join ", ", ('?') x @{$self->{primary_fields}};
        $q = 'INSERT INTO pagefiles (page, '
        . join(", ", @{$self->{primary_fields}}) . ') VALUES (?, ' . $placeholders . ');';
        my $sth = $self->_prepare($q);
        if (!$sth)
        {
            croak __PACKAGE__ . " failed to prepare '$q' : $DBI::errstr";
        }
        $ret = $sth->execute($pagename, @values);
        if (!$ret)
        {
            croak __PACKAGE__ . " failed '$q' : $DBI::errstr";
        }
    }

    # ------------------------------------------------
    # TABLE: links
    # ------------------------------------------------
    if (exists $meta{links} and defined $meta{links})
    {
        my @links = ();
        if (ref $meta{links})
        {
            @links = @{$meta{links}};
        }
        else # one scalar link
        {
            push @links, $meta{links};
        }
        foreach my $link (@links)
        {
            # the "OR IGNORE" allows duplicates to be silently discarded
            $q = "INSERT OR IGNORE INTO links(page, links_to) VALUES(?, ?);";
            my $sth = $self->_prepare($q);
            if (!$sth)
            {
                croak __PACKAGE__ . " failed to prepare '$q' : $DBI::errstr";
            }
            $ret = $sth->execute($pagename, $link);
            if (!$ret)
            {
                croak __PACKAGE__ . " failed '$q' : $DBI::errstr";
            }
        }
    }
    # ------------------------------------------------
    # TABLE: deepfields
    #
    # This is for all the meta-data about a page
    # apart from multi-valued things like links
    # Add both pages and non-pages, because non-pages like images
    # can also have extra meta-data.
    # ------------------------------------------------

    # Need to delete the fields that are no longer there
    my $oldmeta = $self->_get_fields_for_page($pagename);
    foreach my $field (sort keys %{$oldmeta})
    {
        if (!exists $meta{$field})
        {
            $q = "DELETE FROM deepfields WHERE page = ? AND field = ?;";
            my $sth = $self->_prepare($q);
            if (!$sth)
            {
                croak __PACKAGE__ . " failed to prepare '$q' : $DBI::errstr";
            }
            $ret = $sth->execute($pagename, $field);
            if (!$ret)
            {
                croak __PACKAGE__ . " failed '$q' : $DBI::errstr";
            }
        }
    }
    # Now update with the new values
    foreach my $field (sort keys %meta)
    {
        if ($field ne 'links')
        {
            my $value = $meta{$field};
            # force all field-names to be lower-case
            my $fieldname = lc($field);

            next unless defined $value;
            if (ref $value eq 'ARRAY')
            {
                $value = join("|", @{$value});
            }
            elsif (ref $value)
            {
                $value = Dump($value);
            }

            $q = "INSERT OR REPLACE INTO deepfields(page, field, value) VALUES(?, ?, ?);";
            my $sth = $self->_prepare($q);
            if (!$sth)
            {
                croak __PACKAGE__ . " failed to prepare '$q' : $DBI::errstr";
            }
            $ret = $sth->execute($pagename, $fieldname, $value);
            if (!$ret)
            {
                croak __PACKAGE__ . " failed '$q' : $DBI::errstr";
            }
        }
    }

    return 1;
} # _add_page_data

sub _delete_page_from_db {
    my $self = shift;
    my $page = shift;

    my $dbh = $self->{dbh};

    foreach my $table (qw(pagefiles links deepfields flatfields))
    {
        my $q = "DELETE FROM $table WHERE page = ?;";
        my $sth = $self->_prepare($q);
        my $ret = $sth->execute($page);
        if (!$ret)
        {
            croak __PACKAGE__, "FAILED query '$q' $DBI::errstr";
        }
    }

    return 1;
} # _delete_page_from_db

sub DESTROY {
    my $self = shift;

    if (exists $self->{dbh}
            and defined $self->{dbh}
            and ref $self->{dbh})
    {
        if (exists $self->{prepared})
        {
            foreach my $q (keys %{$self->{prepared}})
            {
                delete $self->{prepared}->{$q};
            }
        }
        $self->{dbh}->disconnect();
    }
} # DESTROY

1; # End of Muster::MetaDb
__END__
