package ORDB::Unihan;
{
    $ORDB::Unihan::VERSION = '0.03';
}

# ABSTRACT: An ORM for the published Unihan database

use strict;
use warnings;
use Carp ();
use File::Spec 0.80    ();
use File::Path 2.04    ();
use File::Remove 1.42  ();
use File::HomeDir 0.69 ();
use LWP::Online ();
use Params::Util 0.33 qw{ _STRING _NONNEGINT _HASH };
use DBI;
use ORLite 1.22 ();
use vars qw{@ISA};

BEGIN {
    @ISA = 'ORLite';
}

my $url = 'http://www.unicode.org/Public/UNIDATA/Unihan.zip';

sub dir {
    File::Spec->catdir( File::HomeDir->my_data,
        ( $^O eq 'MSWin32' ? 'Perl' : '.perl' ),
        'ORDB-Unihan', );
}
sub sqlite_path { File::Spec->catfile( dir(), 'Unihan.sqlite' ) }

sub import {
    my $self = shift;
    my $class = ref $self || $self;

    # Check for debug mode
    my $DEBUG = 0;
    if ( scalar @_ and defined _STRING( $_[-1] ) and $_[-1] eq '-DEBUG' ) {
        $DEBUG = 1;
        pop @_;
    }
    my %params;
    if ( _HASH( $_[0] ) ) {
        %params = %{ $_[0] };
    }
    else {
        %params = @_;
    }

    # where we save .sqlite to?
    # Determine the database directory
    my $dir = dir();

    # Create it if needed
    unless ( -e $dir ) {
        File::Path::mkpath( $dir, { verbose => 0 } );
    }

    # Determine the mirror database file
    my $db = sqlite_path();
    my $zip_path = File::Spec->catfile( $dir, 'Unihan.zip' );

    # Create the default useragent
    my $show_progress = $DEBUG;
    my $useragent     = delete $params{useragent};
    unless ($useragent) {
        $useragent = LWP::UserAgent->new(
            timeout       => 30,
            show_progress => $show_progress,
        );
    }

    # Do we need refecth?
    my $need_refetch = 1;
    {
        my $last_mod_file = File::Spec->catfile( $dir, 'last_mod.txt' );
        my $last_mod_local = 'N/A';
        if ( open( my $fh, '<', $last_mod_file ) ) {
            flock( $fh, 1 );
            $last_mod_local = <$fh>;
            chomp($last_mod_local);
            $last_mod_local ||= 0;
            close($fh);
        }

        my $res      = $useragent->head($url);
        my $last_mod = $res->header('last-modified');
        if ( $last_mod_local eq $last_mod ) {
            $need_refetch = 0;
        }
        else {
            print STDERR
              "Unihan.zip last-modified $last_mod, we have $last_mod_local\n"
              if $DEBUG;
            open( my $fh, '>', $last_mod_file );
            flock( $fh, 2 );
            print $fh $last_mod;
            close($fh);
        }
    }

    my $online = LWP::Online::online();
    unless ( $online or -f $db ) {

        # Don't have the file and can't get it
        Carp::croak("Cannot fetch database without an internet connection");
    }

    # refetch the .zip
    my $regenerated_sqlite = 0;
    if ( $need_refetch or !-e $zip_path ) {
        print STDERR "Mirror $url to $zip_path\n" if $DEBUG;

        # Fetch the archive
        my $response = $useragent->mirror( $url => $zip_path );
        unless ( $response->is_success or $response->code == 304 ) {
            Carp::croak("Error: Failed to fetch $url");
        }
        $regenerated_sqlite = 1;
    }

    # Extract .txt file
    my $old_txt_file = File::Spec->catfile( $dir, 'Unihan.txt' );
    unlink($old_txt_file) if -e $old_txt_file;
    my $txt_path = File::Spec->catfile( $dir, 'Unihan_Readings.txt' );
    if ( $regenerated_sqlite or !-e $txt_path ) {
        print STDERR "Extract $zip_path to $dir\n" if $DEBUG;
        require Archive::Extract;
        my $ae = Archive::Extract->new( archive => $zip_path );
        my $ok = $ae->extract( to => $dir );
        unless ($ok) {
            Carp::croak("Error: Failed to read .zip");
        }
        unless ( -e $txt_path ) {
            Carp::croak("Error: Failed to extract .zip");
        }
    }

    # regenerate the .sqlite
    if ( $regenerated_sqlite or !-e $db ) {
        unlink($db);
        my $dbh = DBI->connect(
            "DBI:SQLite:$db",
            undef, undef,
            {
                RaiseError => 1,
                PrintError => 1,
            }
        );
        $dbh->do('PRAGMA synchronous=OFF');
        $dbh->do('PRAGMA count_changes=OFF');
        $dbh->do('PRAGMA journal_mode=MEMORY');
        $dbh->do('PRAGMA temp_store=MEMORY');
        $dbh->do(<<'SQL');
  CREATE TABLE unihan (
    "hex" CHAR(5) NOT NULL,
    "type" VARCHAR(18) NOT NULL,
    "val" VARCHAR(255),
    PRIMARY KEY ("hex", "type")
  )
SQL
        my $sql =
          'INSERT INTO "unihan" ("hex", "type", "val") VALUES (?, ?, ?)';
        my $sth = $dbh->prepare($sql);

        opendir( my $fdir, $dir );
        my @files = grep { /.txt$/ } readdir($fdir);
        closedir($fdir);
        foreach my $file (@files) {
            next if $file eq 'last_mod.txt';
            print STDERR "Populate $dir/$file\n" if $DEBUG;
            open( my $fh, '<:utf8', "$dir/$file" );
            flock( $fh, 1 );
            while ( my $line = <$fh> ) {
                next if ( $line =~ /^\#/ );      # comment line
                next if ( $line =~ /^\s+$/ );    # blank line
                chomp($line);
                my ( $hex, $type, $val ) = split( /\t/, $line, 3 );
                $hex =~ s/^U\+//;
                $type =~ s/^k//;
                $val =~ s/(^\s|\s+)//g;
                $sth->execute( $hex, $type, $val )
                  or die "$dbh:errstr $type, $hex, $val";
            }
            close($fh);
        }
    }

    $params{file}     = $db;
    $params{readonly} = 1;

    # Hand off to the main ORLite class.
    $class->SUPER::import( \%params, $DEBUG ? '-DEBUG' : () );

}

1;

__END__

=pod

=head1 NAME

ORDB::Unihan - An ORM for the published Unihan database

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use ORDB::Unihan;

    # dbh way
    my $dbh = ORDB::Unihan->dbh;
    my $sql = 'SELECT val FROM unihan WHERE hex = 3402 AND type="RSUnicode"';
    my $sth = $dbh->prepare($sql);

    # simple way
    ORDB::Unihan->selectrow_array($statement);

    # or ORLite way
    my $vals = ORDB::Unihan::Unihan->select(
        'where hex = ?', '3402'
    );

=head1 DESCRIPTION

TO BE COMPLETED

=head2 METHODS

perldoc L<ORLite>, plus

=over 4

=item * sqlite_path

    my $sqlite_path = ORDB::Unihan->sqlite_path();

where the Unihan.sqlite is

=back

=head2 TABLE

  CREATE TABLE unihan (
    "hex" CHAR(5) NOT NULL,
    "type" VARCHAR(18) NOT NULL,
    "val" VARCHAR(255),
    PRIMARY KEY ("hex", "type")
  )

=over 4

=item B<hex>

the Unicode scalar value as U+[x]xxxx. 'hex' is [x]xxxx without U+

=item B<type>

one of Cangjie, Cantonese, CihaiT, Cowles, Definition, HanYu, IRGHanyuDaZidian, IRGKangXi, IRG_GSource, IRG_JSource, IRG_TSource, Mandarin, Matthews, OtherNumeric, Phonetic, RSAdobe_Japan1_6, RSUnicode, SemanticVariant, Matthews, TotalStrokes

=item B<val>

the value for C<hex> and C<type>

=head1 AUTHOR

Fayland Lam <fayland@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
