package RPM::Search;

use strict;
use warnings;

use File::Find;
use DBI;
use Try::Tiny;

our $VERSION = '0.01';

=head1 NAME

RPM::Search - Search all available RPMs

=head1 SYNOPSIS

  # On (recent) RPM based systems
  my $db = RPM::Search->new();

  my @names = $db->search(qr/perl-Mo.se/);
  # or
  @names = $db->search('perl-CGI-*');
  # or
  @names = $db->search('cpanminus');

  if ( @names ) {
    my $pkgs = join ", ", @names;
    `/usr/bin/yum -y install $pkgs`;
  }
  else {
      print "No matching packages\n";
  }

=head1 PURPOSE

This module allows one to search the entire collection of RPMs available for 
a given installed Linux distribution that uses RPMs, not just listing the RPMs 
already installed on a system.

And frankly, have you tried using C<yum search>? 

Eventually, I plan to use this functionality to make a plugin for 
C<cpanminus> to suggest vendor-supplied packages instead of building 
them "from scratch."

=head1 ATTRIBUTES

These are standard Perlish accessors: pass an argument to set it, pass no 
argument to get the current value.

=over

=item cache_base 

Base location of the yum data (default: none)

=back

=cut

sub cache_base {
    my $self = shift;
    my $param = shift;

    if ( $param ) {
        return unless -d $param;
        $self->{'cache_base'} = $param;
    }

    return $self->{'cache_base'};
}

=over 

=item yum_primary_db 

Fully qualified path to the primary SQLite database (default: none)

=back

=cut 

sub yum_primary_db {
    my $self = shift;
    my $param = shift;

    if ( $param ) {
        return unless -e $param;
        $self->{'yum_primary_db'} = $param;
    }

    return $self->{'yum_primary_db'};
}

=over

=item dbh 

DBI handle to the yum SQLite database

=back

=cut

sub dbh {
    my $self = shift;
    my $param = shift;

    if ( $param ) {
        return unless ref($param) =~ /DBI/i;
        $self->{'dbh'} = $param;
    }

    return $self->{'dbh'};
}

=head1 METHODS

=over

=item new()

Make a new L<RPM::Search|RPM::Search> object.  Will automatically search 
for an appropriate yum database and open a handle to the data set 
unless you pass valid arguments to the F<dbh> and/or F<yum_primary_db>
attributes at construction time.

Returns a new L<RPM::Search|RPM::Search> object.

=back

=cut

sub new {

    try {
        require DBD::SQLite;
    }
    catch {
        die "This module requires DBD::SQLite. Try:\n\tsudo yum -y install perl-DBD-SQLite\n";
    };

    my $class = shift;
    my $proto = ref $class || $class;
    
    my $self = bless { @_ }, $proto;

    $self->find_yum_db unless $self->yum_primary_db; 
    $self->open_db unless $self->dbh;

    return $self;
}




=over

=item find_yum_db()

This method searches for an appropriate yum database starting at the 
location passed as a parameter. If no parameter is given, the method
will use F<cache_base>. If F<cache_base> is not set, the method will 
use F</var/cache/yum>.

This call populates F<yum_primary_db>.

The return value is boolean: true for success, false for failure.

=back

=cut

sub find_yum_db {
    my $self = shift;
    my $base = shift || $self->cache_base() || "/var/cache/yum";


    my $path;
    find( { wanted => 
            sub {
                $path = $File::Find::name if /primary.*\.sqlite\z/ &&
                $File::Find::dir !~ /update/ &&
                $File::Find::dir !~ /extra/ 
            }, 
            untaint => 1, 
    },
    $base);

    if ( $path ) {
        $self->yum_primary_db($path);
        return 1;
    }
    else {
        warn "Couldn't find any yum primary SQLite databases in $base\n";
        return 0;
    }
}

=over

=item open_db()

This method opens a connection to the yum SQLite database.  The DSN
is constructed from the passed in parameter.  If no parameter is
passed in, the method will use F<yum_primary_db>.

This method populates F<dbh>.

This method causes a fatal error on any failure.

=back

=cut

sub open_db {
    my $self = shift;
    my $dbname = shift || $self->yum_primary_db;

    try {
        my $dbh = DBI->connect("dbi:SQLite:dbname=$dbname", undef, undef, {
                        RaiseError => 1,
                    sqlite_unicode => 1, 
                } ) or die $DBI::err;
        $self->dbh($dbh);
    }
    catch {
        die "Couldn't open db $dbname: $_\n";
    };
}

=over

=item search()

This method searches the RPM database using an optional pattern parameter.
If no pattern is given, the method returns all available package names. 
(B<Note>: This will be thousands of packages.)

The format of the pattern can be one of the following:

=over

=item *

A regular expression using the C<qr//> construct.

=item *

A SQL-ish wildcard expression using % and _

=item *

A filesystem like glob expression using ? and *

=item *

A scalar which must be a literal match for a package name in 
the database to return any results

=back

The method returns an array of all matching package names
(which may be zero results.)  Undef is returned on errors.

=back

=cut

sub search {
    my $self = shift;
    my $pattern = shift;

    my $sql = "SELECT name FROM packages";
    my @bind_params;

    if ( $pattern ) {
        $sql .= " WHERE name ";

        if ( ref($pattern) =~ /regexp/i ) {
            $sql .= "REGEXP ?";
        }
        elsif ( $pattern =~ /[%_]/ ) {
            $sql .= "LIKE ?";
        }
        elsif ( $pattern =~ /[\?\*]/ ) {
            $sql .= "GLOB ?";
        }
        else {
            $sql .= "=?";
        }
        push @bind_params, $pattern;
    }

    try {
        return @{ $self->dbh->selectcol_arrayref($sql, undef, @bind_params) } or die $DBI::err;
    }
    catch {
        warn "Couldn't execute query $sql: $_\n";
        return undef;
    }
}

=head1 AUTHOR

Mark Allen, C<mrallen1 at yahoo dot com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rpm-search at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RPM-Search>. 

I will be notified, and then you'll automatically be notified of progress on your 
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc RPM::Search

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=RPM-Search>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/RPM-Search>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/RPM-Search>

=item * MetaCPAN

L<https://metacpan.org/module/RPM::Search/>

=item * Github

L<https://github.com/mrallen1/RPM-Search.git>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Mark Allen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
