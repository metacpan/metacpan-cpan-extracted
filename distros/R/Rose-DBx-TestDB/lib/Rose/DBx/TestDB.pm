package Rose::DBx::TestDB;

use warnings;
use strict;
use File::Temp 'tempfile';
use Rose::DB;
use Carp;

# we want our END to run no matter what (even if ^C)
use sigtrap qw(die normal-signals error-signals);

our $VERSION = '0.05';

my @TMPFILES;

# check for sqlite version per Rose::DB tests
eval { require DBD::SQLite };

if ( $@ || $DBD::SQLite::VERSION < 1.08 || $ENV{'RDBO_NO_SQLITE'} ) {
    croak 'Missing DBD::SQLite 1.08+';
}
elsif ( $DBD::SQLite::VERSION == 1.13 ) {
    carp 'DBD::SQLite 1.13 is broken but we will try testing anyway';
}

sub new {
    my ( undef, $filename ) = tempfile();
    push @TMPFILES, $filename;

    Rose::DB->register_db(

        domain          => 'test',
        type            => 'sqlite',
        driver          => 'sqlite',
        database        => $filename,
        auto_create     => 0,
        connect_options => {
            AutoCommit => 1,
            ( ( rand() < 0.5 ) ? ( FetchHashKeyName => 'NAME_lc' ) : () ),
        },
        post_connect_sql =>
            [ 'PRAGMA synchronous = OFF', 'PRAGMA temp_store = MEMORY', ],
    );
    Rose::DB->default_domain('test');
    Rose::DB->default_type('sqlite');

    my $db = Rose::DB->new()
        or croak "could not create new Rose::DB instance: $!";

    return $db;
}

# in theory File::Temp should clean these up. In theory.
END {
    for my $file (@TMPFILES) {
        unlink $file unless -e $file;    # Sets $! correctly
        1 while unlink $file;
    }
}

=head1 NAME

Rose::DBx::TestDB - test Rose::DB::Object modules

=head1 SYNOPSIS

 use Rose::DBx::TestDB;
 my $db = Rose::DBx::TestDB->new;
 
 # do something with $db
 
 exit;
 
 # END block will automatically clean up all temp db files

=head1 METHODS

=head2 new

Returns a new Rose::DB object using a temp sqlite database.

=head1 AUTHOR

Peter Karman, C<< <perl at peknet.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-rose-dbx-testdb at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Rose-DBx-TestDB>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Rose::DBx::TestDB

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Rose-DBx-TestDB>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Rose-DBx-TestDB>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Rose-DBx-TestDB>

=item * Search CPAN

L<http://search.cpan.org/dist/Rose-DBx-TestDB>

=back

=head1 ACKNOWLEDGEMENTS

Inspired by DBICx::TestDatabase.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Peter Karman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
