package PGObject::Util::DBChange;

use 5.010; # double forward slash requires 5.10
use strict;
use warnings;

use strict;
use warnings;
use PGObject::Util::DBChange::History;
use Digest::SHA;
use Cwd;
use Moo;

=head1 NAME

PGObject::Util::DBChange - Track applied change files in the database

=head1 VERSION

Version 0.050.2

=cut

our $VERSION = '0.050.2';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use PGObject::Util::DBChange;

    my $foo = PGObject::Util::DBChange->new();
    ...

=head1 PROPERTIES

=head2 path

Path to load content from -- Must be defined and '' or a string

=cut

has path => (is => 'ro',
             isa => sub { die 'path undefined' unless defined $_[0]; 
                          die 'references not allowed' if ref $_[0]; } );

=head2 no_transactions

If true, we assume success even if transaction fails

Future versions may add additional checking possibilies instead

=cut

has no_transactions =>(is => 'ro');

=head2 content

Content of the file.  Can be specified at load, or is built by reading from the
file.

=cut

has content => (is => 'lazy');

sub _build_content {
    my ($self) = @_;
    my $file;
    local $!;
    open(FILE, '<', $self->path) or
        die 'FileError: ' . Cwd::abs_path($self->path) . ": $!";
    binmode FILE, ':utf8';
    my $content = join '', <FILE>;
    close FILE;
    return $content;
}

=head2 succeeded (rwp)

Undefined until run.  After run, 1 if success, 0 if failure.

=cut

has succeeded => (is => 'rwp');

=head2 dependencies

A list of other changes to apply first.  If strings are provided, these are
turned into path objects.

Currently these must be explicitly provided. Future bersions may read these from
comments in the files themselves.

=cut

has dependencies => (is => 'ro',
                     default => sub { [] },
                     isa => sub {  die 'dependencies must be an arrayref' 
                                           if ref $_[0] !~ /ARRAY/
                                              and defined $_[0];
                                   for (@{$_[0]}) {
                                       die 'dependency must be a PGObject::Util::Change object'
                                           unless eval { $_->isa(__PACKAGE__) };
                                   }
                           }
                    );
                                           

=head2 sha

The sha hash of the normalized content (comments and whitespace lines stripped)
of the file.

=cut

has sha => (is => 'lazy');

sub _build_sha {
    my ($self) = @_;
    my $content = $self->content; 
    my $normalized = join "\n",
                     grep { /\S/ }
                     map { my $string = $_; $string =~ s/--.*//; $string }
                     split("\n", $content);
    return Digest::SHA::sha512_base64($normalized);
}

=head2 begin_txn

Code to begin transaction, defaults to 'BEGIN;'

=cut

has begin_txn => (is => 'ro', default => 'BEGIN;');

=head2 commit_txn

Code to commit transaction, defaults to 'COMMIT;'

Useful if one needs to do two phase commit or similar

=cut

has commit_txn => (is => 'ro', default => 'COMMIT;');

=head1 METHODS

=head2 content_wrapped($before, $after)

Returns content wrapped with before and after.

=cut

sub content_wrapped {
    my ($self, $before, $after) = @_;
    $before //= "";
    $after //= "";
    return $self->_wrap_transaction(
        _wrap($self->content, $before, $after)
    );
}

sub _wrap_transaction {
    my ($self, $content) = @_;
    $content = _wrap($content, $self->begin_txn, $self->commit_txn)
       unless $self->no_transactions;
    return $content;
}

sub _wrap {
    my ($content, $before, $after) = @_;
    return "$before\n$content\n$after";
}

=head2 is_applied($dbh)

returns 1 if has already been applied, false if not

=cut

sub is_applied {
    my ($self, $dbh) = @_;
    my $sha = $self->sha;
    my $sth = $dbh->prepare(
        "SELECT * FROM db_patches WHERE sha = ?"
    );
    $sth->execute($sha);
    my $retval = int $sth->rows;
    $sth->finish;
    return $retval;
}

=head2 run($dbh)

Runs against the current dbh without tracking.

=cut

sub run {
    my ($self, $dbh) = @_;
    $dbh->do($self->content); # not raw
}

=head2 apply($dbh)

Applies the current file to the db in the current dbh.

=cut

sub apply {
    my ($self, $dbh, $log) = @_;
    my $need_commit = $self->_need_commit($dbh);
    my $before = "";
    my $after;
    my $sha = $dbh->quote($self->sha);
    my $path = $dbh->quote($self->path);
    my $no_transactions = $self->no_transactions;
    if ($self->is_applied($dbh)){
        $after = "
              UPDATE db_patches
                     SET last_updated = now()
               WHERE sha = $sha;
        ";
    } else {
        $after = "
           INSERT INTO db_patches (sha, path, last_updated)
           VALUES ($sha, $path, now());
        ";
    }
    if ($no_transactions){
        $dbh->do($after);
        $after = "";
        $dbh->commit if $need_commit;
    }
    my $success = eval {
         $dbh->do($self->content_wrapped($before, $after));
    };
    $dbh->commit if $need_commit;
    die "$DBI::state: $DBI::errstr" unless $success or $no_transactions;
    $self->log(dbh => $dbh, state => $DBI::state, errstr => $DBI::errstr) 
       if $log;
    return 1;
}

sub log {
    my ($self, %args) = @_;
    my $dbh = $args{dbh};
    $dbh->prepare("
            INSERT INTO db_patch_log(when_applied, path, sha, sqlstate, error)
            VALUES(now(), ?, ?, ?, ?)
    ")->execute($self->path, $self->sha, $args{state}, $args{errstr});
    $dbh->commit if $self->_need_commit($dbh);
}

our $commit = 1;

sub _need_commit{
    my ($self, $dbh) = @_;
    return $commit;
}

=head1 Functions (package-level)

=head2 needs_init($dbh)

Checks to see whether the schema has been initialized

=cut

sub needs_init {
    my $dbh = pop @_;
    my $count = $dbh->prepare("
        select relname from pg_class
         where relname = 'db_patches'
               and pg_table_is_visible(oid)
    ")->execute();
    return !int($count);
}

=head2 init($dbh);

Initializes the system.  Modifications are maintained through the History
module.  Returns 0 if was up to date, 1 if was initialized.

=cut

sub init {
    my $dbh = pop @_;
    return update($dbh) unless needs_init($dbh);
    my $success = $dbh->prepare("
    CREATE TABLE db_patch_log (
       when_applied timestamp primary key,
       path text NOT NULL,
       sha text NOT NULL,
       sqlstate text not null,
       error text
    );
    CREATE TABLE db_patches (
       sha text primary key,
       path text not null,
       last_updated timestamp not null
    );
    ")->execute();
    die "$DBI::state: $DBI::errstr" unless $success;

    return update($dbh) || 1;
}

=head2 update($dbh)

Updates the current schema to the most recent.

=cut

sub update {
    my $dbh = pop @_;
    my $applied_num = 0;
    #my @changes = __PACKAGE__::History::get_changes();
    #$applied_num += $_->apply($dbh) for @changes;
    return $applied_num;
}

=head1 AUTHOR

Chris Travers, C<< <chris.travers at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pgobject-util-dbchange at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PGObject-Util-DBChange>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PGObject::Util::DBChange


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PGObject-Util-DBChange>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PGObject-Util-DBChange>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PGObject-Util-DBChange>

=item * Search CPAN

L<http://search.cpan.org/dist/PGObject-Util-DBChange/>

=back


=head1 ACKNOWLEDGEMENTS

Portions of this code were developed for LedgerSMB 1.5 and copied from
appropriate sources there.

Many thanks to Sedex Global for their sponsorship of portions of the module.

=head1 LICENSE AND COPYRIGHT

Copyright 2016, 2017 Chris Travers.

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

* Neither the name of LedgerSMB
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

1; # End of PGObject::Util::DBChange
