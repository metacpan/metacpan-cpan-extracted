# Copyright (c) 2002 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
#
# Perl translation by Martin Busik <martin.busik@busik.de>
#

package Test::C2FIT::eg::AllFiles;
use base 'Test::C2FIT::Fixture';
use File::Spec::Functions;
use Test::C2FIT::Parse;
use Test::C2FIT::Fixture;
use IO::File;
use File::Basename;
use Error qw( :try );

## not used $Test::C2FIT::eg::AllFiles::runCount = 0;
%Test::C2FIT::eg::AllFiles::fileStack = ();

sub new {
    my $pkg = shift;
    return bless $pkg->SUPER::new(), $pkg;
}

sub doRow {
    my $self  = shift;
    my $row   = shift;
    my $cell  = $row->leaf;
    my @files = $self->expand( $cell->text );
    if ( 0 < @files ) {
        $self->doRow2( $row, \@files );
    }
    else {
        $self->ignore($cell);
        $self->info( $cell, " no match" );
    }
}

sub doRow2 {
    my ( $self, $row, $files ) = @_;
    $self->doFiles( $row, @$files );
}

sub expand {
    my $self   = shift;
    my $text   = shift;
    my @result = ();
    push( @result, grep { -f "$_" } glob($text) );
    return @result;
}

sub doFiles {
    my $self  = shift;
    my $row   = shift;
    my @files = @_;
    for my $path (@files) {
        my $cells = $self->td( basename($path), $self->td( "", undef ) );
        $row->{more} = $self->tr( $cells, $row->{more} );
        $row = $row->{more};
        my $fixture = new Test::C2FIT::Fixture();
        $self->run( $path, $fixture, $cells );
        $self->summarize( $fixture, $path );
    }
}

sub run {
    my ( $self, $path, $fixture, $cells ) = @_;
    if ( $self->pushAndCheck($path) ) {
        $self->ignore($cells);
        $self->info( $cells, "recursive" );
        return;
    }
    try {
        my $input = $self->read($path);
        my $tables;

        if ( index( $input, "<wiki>" ) >= 0 ) {
            $tables =
              new Test::C2FIT::Parse( $input, [ "wiki", "table", "tr", "td" ] );
            $fixture->doTables( $tables->parts );
        }
        else {
            $tables = new Test::C2FIT::Parse( $input, [ "table", "tr", "td" ] );
            $fixture->doTables($tables);
        }
        $self->info( $cells->{more}, $fixture->{counts}->toString() );
        if (   $fixture->{counts}->{wrong} == 0
            && $fixture->{counts}->{exceptions} == 0 )
        {
            $self->right( $cells->{more} );
        }
        else {
            $self->wrong( $cells->{more} );
            $cells->{more}->addToBody( $tables->footnote() );
        }
      }
      otherwise {
        my $e = shift;
        $self->exception( $cells, $e );
      };
    $self->pop($path);
}

sub pushAndCheck {
    my ( $self, $path ) = @_;
    my $abs_path = File::Spec::Functions::rel2abs($path);
    return 1 if exists $Test::C2FIT::eg::AllFiles::fileStack{$abs_path};
    $Test::C2FIT::eg::AllFiles::fileStack{$abs_path} = 1;
    return undef;
}

sub pop {
    my ( $self, $path ) = @_;
    my $abs_path = File::Spec::Functions::rel2abs($path);

    delete $Test::C2FIT::eg::AllFiles::fileStack{$abs_path};
}

sub summarize {
    my ( $self, $fixture, $path ) = @_;
    $fixture->{summary}->{"input file"} = File::Spec::Functions::rel2abs($path);
    my $fileStat = ( stat($path) )[9];
    $fixture->{summary}->{"input update"} = localtime($fileStat);
    $runCounts =
      ( exists $self->{summary}->{"counts run"} )
      ? $self->{summary}->{"counts run"}
      : new Test::C2FIT::Counts();
    $runCounts->tally( $fixture->{counts} );
    $self->{summary}->{"counts run"} = $runCounts;
}

sub read {
    my ( $self, $fqfn ) = @_;

    my $of = new IO::File "<$fqfn";
    die unless ref($of);

    my $cont = join( '', <$of> );
    $of = undef;
    $cont;
}

sub tr {
    my ( $self, $cells, $more ) = @_;
    return Test::C2FIT::Parse->from( "tr", undef, $cells, $more );
}

sub td {
    my ( $self, $text, $more ) = @_;
    return Test::C2FIT::Parse->from( "td", $self->info($text), undef, $more );
}

1;
