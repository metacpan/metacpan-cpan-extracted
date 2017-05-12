# Copyright (c) 2002-2005 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Perl translation by Martin Busik <martin.busik@busik.de>

package Test::C2FIT::eg::ExampleTests;
use base 'Test::C2FIT::ColumnFixture';

use strict;

use Error qw( :try );
use Test::C2FIT::Fixture;
use IO::File;

sub new {
    my $pkg  = shift;
    my $self = $pkg->SUPER::new( basedir => undef );

    for my $adir qw(.) {
        $self->{basedir} = $adir
          if -d "$adir"
          && -d "$adir/input"
          && -d "$adir/output";
    }
    die "expecting input and output directories somewhere!"
      unless defined( $self->{basedir} );

    $self->{input}     = undef;
    $self->{tables}    = undef;
    $self->{fixture}   = undef;
    $self->{runCounts} = new Test::C2FIT::Counts();
    $self->{footnote}  = undef;
    $self->{fileCell}  = undef;

    return $self;
}

sub run {
    my $self  = shift;
    my $input = $self->read( $self->{file} );
    $self->{fixture} = new Test::C2FIT::Fixture();
    if ( defined( $self->{wiki} ) && $self->{wiki} eq "true" ) {
        $self->{tables} =
          new Test::C2FIT::Parse( $input, [ "wiki", "table", "tr", "td" ] );
        $self->{fixture}->doTables( $self->{tables}->{parts} );
    }
    else {
        $self->{tables} =
          new Test::C2FIT::Parse( $input, [ "table", "tr", "td" ] );
        $self->{fixture}->doTables( $self->{tables} );
    }
    $self->{runCounts}->tally( $self->{fixture}->{counts} );

    #
    # TBD: following line is not correct
    # $Test::C2FIT::Fixture::summary{"counts run"} = $self->{runCounts};
}

sub right() {
    my $self = shift;
    $self->run();
    return $self->{fixture}->{counts}->{right};
}

sub wrongCount() {
    my $self = shift;
    return $self->{fixture}->{counts}->{wrong};
}

sub ignores() {
    my $self = shift;
    return $self->{fixture}->{counts}->{ignores};
}

sub exceptions() {
    my $self = shift;
    return $self->{fixture}->{counts}->{exceptions};
}

sub read {
    my $self     = shift;
    my $filename = shift;
    my $fqfn     = $self->{basedir} . "/input/" . $filename;

    my $of = new IO::File "<$fqfn";
    die unless ref($of);

    my $cont = join( '', <$of> );
    $of = undef;
    $cont;
}

#
# nice perl trickery, since the java-fit-document uses a public int wrong() and
# the Fixture uses as void wrong(Parse cell)
#

sub wrong {
    my $self = shift;
    if ( scalar(@_) == 0 ) {

        #
        #  public int wrong()
        #
        return $self->wrongCount();
    }
    else {

        #
        #   wrong(Parse cell)
        #
        return $self->SUPER::wrong(@_);
    }
}

=pod

not supported yet...
    
sub doRow {
    my ($self, $row) = @_;
    $self->{fileCell} = $row->leaf();
    $self->SUPER::doRow($row);
}


sub wrong {
    my ($self,$cell) = @_;
    $self->SUPER::wrong($cell);
    if(!defined($self->{footnote})) {
        # Footnotes not supported yet...
        # $self->{footnote} = $self->{tables}->footnote();
        $self->{fileCell}->addToBody($self->{footnote});
    }
}

=cut

1;
