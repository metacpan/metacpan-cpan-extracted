# $Id: FileRunner.pm,v 1.10 2006/06/16 15:20:56 tonyb Exp $
#
# Copyright (c) 2002-2005 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Perl translation by Dave W. Smith <dws@postcognitive.com>
# Modified by Tony Byrne <fit4perl@byrnehq.com>

package Test::C2FIT::FileRunner;

use strict;
use IO::File;
use Test::C2FIT::Parse;
use Test::C2FIT::Fixture;
use Error qw( :try );

sub new {
    my $pkg = shift;
    return bless {
        input   => undef,
        tables  => undef,
        output  => undef,
        fixture => Test::C2FIT::Fixture->new(),
        @_
    }, $pkg;
}

sub run {
    my $self = shift;
    my (@argv) = @_;
    $self->argv(@argv);
    $self->process();
    $self->_exit();
}

sub argv {
    my $self = shift;
    my (@argv) = @_;

    die "usage: FileRunner.pl input-file output-file\n"
      unless 2 == @argv;

    $Test::C2FIT::Fixture::summary{'input file'}  = $argv[0];
    $Test::C2FIT::Fixture::summary{'output file'} = $argv[1];

    my $in = IO::File->new( $argv[0], "r" ) or die "$argv[0]: $!\n";
    $self->{'input'} = join( "", <$in> );
    my $out = IO::File->new( $argv[1], "w" ) or die "$argv[1]: $!\n";
    $self->{'output'} = $out;

    my @inputFileStat   = stat( $argv[0] );
    my $inputUpdateTime = localtime( $inputFileStat[9] );
    $Test::C2FIT::Fixture::summary{'input update'} = $inputUpdateTime;

}

sub process {
    my $self = shift;

    use Benchmark;
    try {
        if ( $self->{'input'} =~ /<wiki>/ ) {
            $self->{'tables'} =
              Test::C2FIT::Parse->new( $self->{'input'},
                [ 'wiki', 'table', 'tr', 'td' ] );
            $self->{'fixture'}->doTables( $self->{'tables'}->parts() );
        }
        else {
            $self->{'tables'} =
              Test::C2FIT::Parse->new( $self->{'input'},
                [ 'table', 'tr', 'td' ] );
            $self->{'fixture'}->doTables( $self->{'tables'} );
        }
      }
      otherwise {
        my $e = shift;
        $self->exception($e);
      };

    $self->{'output'}->print( $self->{'tables'}->asString() );
}

sub exception {
    my $self = shift;
    my ($exception) = @_;

# $self->{'tables'} = new Parse("Unable to parse input. Input ignored.", undef);
# $self->{'fixture'}->exception($self->{'tables'}, $exception);

    print $exception;
    exit(-1);
}

sub _exit {
    my ($self) = @_;
    $self->{'output'}->close();
    my $counts = $self->{fixture}->{counts};
    print STDERR $counts->toString(), "\n";
    exit( $counts->{wrong} + $counts->{exceptions} );
}

1;

__END__

=head1 NAME

Test::C2FIT::FileRunner - a runner class operating on (plain) html files. 

=head1 SYNOPSIS

	$runner = new Test::C2FIT::FileRunner();
	$runner->run($infile,$outfile);


=head1 DESCRIPTION

Either you use this class as a starting point for your tests or your test documents refer to other test
documents which shall be processed recursively.

To run your tests, it might be even simplier to use C<FileRunner.pl> or C<perl -MTest::C2FIT -e file_runner>.

=head1 SEE ALSO

Extensive and up-to-date documentation on FIT can be found at:
http://fit.c2.com/

=cut
