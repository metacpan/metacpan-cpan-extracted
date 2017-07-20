package PGObject::Util::PGConfig;

use 5.006;
use strict;
use warnings;
use Carp;

=head1 NAME

PGObject::Util::PGConfig - Postgres Configuration Management

=head1 VERSION

Version 0.01

=cut

our $VERSION = 'v0.01';


=head1 SYNOPSIS

    use PGObject::Util::PGConfig;

    my $config = PGObject::Util::PGConfig->new();
    # setting values in the internal store
    $config->set('statement_timeout', 3600); # set the desired state
    $config->set('datestyle', 'ISO');

    # session configuration management
    $config->list($dbh);
    $config->fetch($dbh, 'statement_timeout'); # get the session statement timeout
    # We can now sync with Pg for the dbh session
    $config->sync_session($dbh, qw(statement_timeout datestyle));

    # or we can get from a file
    $config->fromfile('path/to/file');
    # or from file contents
    $config->fromcontents($string);
    # and can return current state as file contents
    $config->filecontents();
    # or write to a file
    $config->tofile('path/to/new.conf');

=head1 DESCRIPTION

The current config module provides an abstraction around the PostgreSQL GUC
(configuration system).  This includes parsing config files (postgresql.conf,
recovery.conf) and retrieve current settings from a database configuration.

The module does not depend on a database configuration so it can be used to 
aggregate configuration data from different sources.

Session update guarantees that only appropriate session variables are
updated.

=head1 Methods

=head2 Constructor

=head3 new

The constructor takes no arguments and initializes an empty store.  The store
is implemented as a hashref similar to what you would expect from a Moo/Moose
object but it is recommended that you do not inspect directly because this
behavior is not guaranteed for subclasses.

If a subclass overwrites the storage approach, it MUST override this method
as well.

=cut

sub new {
    my ($pkg) = @_;
    my $self = {};
    bless $self, $pkg;
}

=head2 Internal store

There are several things which are not the responsibility of the internal
store.  These include checking validity of variable names as these could
vary between major versions of PostgreSQL.  Subclasses MAY override these
methods safely and provide a different storage mechanism.

=head3 set($key, $value)

Sets a current GUC variable to a particular value.

=cut

sub set {
    my ($self, $key, $value) = @_;
    croak 'References unsupported' if ref $value;
    $self->{$key} = $value;
}

=head3 forget($key)

Deletes a key from the store

=cut

sub forget {
    my ($self, $key) = @_;
    delete $self->{$key};
}

=head3 known_keys()

Returns a list of keys from the store.

=cut

sub known_keys {
    my ($self) = @_;
    return keys %$self;
}

=head3 get_value($key)

Returns a value from the key in the store.

=cut

sub get_value {
    my ($self, $key) = @_;
    return $self->{$key};
}

=head2 DB Session

The methods in this session integrate with a database session and pull
data from these.  The module itself does not depend on the database
session for general use.

=head3 fetch($dbh, $key)

Retrieves a setting from the session and saves it to the store.

Returns the stored value.

=cut

sub fetch {
    my ($self, $dbh, $key) = @_;
    my $sth = $dbh->prepare("SELECT current_setting(?)");
    $sth->execute($key);
    $self->set($key, $sth->fetchrow_array);
    return $self->get_value($key); 
}

=head3 list($dbh)

Returns a list of all GUC variables set for the database session at $dbh

Does not affect store.

=cut

sub list {
    my ($self, $dbh) = @_;
    my $sth = $dbh->prepare('SELECT name FROM pg_settings ORDER BY name');
    $sth->execute;
    my @keys;
    while (my ($key) = $sth->fetchrow_array){
       push @keys, $key;
    }
    return @keys;
}

=head3 sync_session($dbh)

Synchronizes all stored variables into the current session if applicable.

=cut

sub sync_session{
    my ($self, $dbh) = @_;
    my $query = "
       SELECT s.name FROM pg_setting s
         JOIN pg_roles r ON rolname = session_user
        WHERE name = any(?) 
              AND (s.context = 'user'
                    OR s.context = 'superuser' AND r.rolsuper)
    ";
    my $sth = $dbh->prepare($query);
    $sth->execute([$self->list_keys]);
    my $setsth = $dbh->prepare(
       "SELECT set_config(?, ?, false)");
    while (my ($setname) = $sth->fetchrow_array){
       $setsth->execute($setname, $self->get_value($setname));
    }
}

=head2 File and Contents

This module is also capable of reading to and writing to files
and generating file content in the format expected.  This means that the
general whitespace rules and escaping approach PostgreSQL expects are met.

=head3 fromfile($path)

Reads the contents from a file. Loads the whole file into memory.

=cut

sub fromfile {
    my ($self, $file) = @_;
    my $fh;
    open $fh, '<', $file;
    $self->fromcontents(join("", <$fh>));
    close $fh;
}

=head3 fromcontents($contents)

Parses file content and sets the internal store accordingly.

=cut

sub _unescape {
    my ($val) = @_;
    return unless defined $val;
    $val =~ s/''/'/g;
    $val =~ s/(^'|'$)//g;
    return $val;
}

sub _escape {
    my ($val) = @_;
    $val =~ s/'/''/g;
    return $val;
}

sub fromcontents {
    my ($self, $contents) = @_;
    for my $line (split(/(\r|\n)/, $contents)){
        $line =~ s/\#.*//;
        $line =~ s/(^\s*|\s*$)//g;
        next unless $line;

        my ($key, $value);
        if ($line =~ /=/){
            ($key, $value) = split(/\s*=\s*/, $line, 2);
        } else {
            ($key, $value) = split(/\s/, $line, 2);
        }
 
        $self->set($key, _unescape($value));
    }
}

=head3 filecontents()

Returns file contents.  Variables are set in alphabetical order

=cut

sub filecontents{
    my ($self) = @_;
    return join "\n",
           (map {"$_ = '" . _escape($self->get_value($_)) . "'" }
           sort $self->known_keys);
}

=head3 tofile($path)

Writes the contents, per filecontents above, to $path

=cut

sub tofile {
    my ($self, $path) = @_;
    my $fh;
    open $fh, '>', $path;
    print $fh $self->filecontents;
    close $fh;
}

=head2 Future Versions

=head3 sync_system($dbh)

This command will use ALTER SYSTEM statements to set defaults to be used on 
next PostgreSQL restart or reload.  Not yet supported.

=head1 AUTHOR

Chris Travers, C<< <chris.travers at adjust.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pgobject-util-pgconfig at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PGObject-Util-PGConfig>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PGObject::Util::PGConfig


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PGObject-Util-PGConfig>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PGObject-Util-PGConfig>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PGObject-Util-PGConfig>

=item * Search CPAN

L<http://search.cpan.org/dist/PGObject-Util-PGConfig/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Adjust.com

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

* Neither the name of Adjust.com
nor the names of its contributors may be used to endorse or promote
products derived from this software without specific prior written
permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of PGObject::Util::PGConfig
