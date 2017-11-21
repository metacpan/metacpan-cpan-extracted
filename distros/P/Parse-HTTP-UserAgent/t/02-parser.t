#!/usr/bin/env perl -w
use strict;
use warnings;
use vars qw( $VERSION $SILENT );

BEGIN {
    $ENV{PARSE_HTTP_USERAGENT_TEST_SUITE} = 1;
}

use Carp qw( croak );
use Data::Dumper;
use File::Spec;
use Getopt::Long;
use Parse::HTTP::UserAgent;
use Test::More qw( no_plan );

$SILENT = 1 if ! $ENV{HARNESS_IS_VERBOSE};

GetOptions(\my %opt, qw(
    ids=i@
    dump
));

# Work-around for the removal of "." from @INC in Perl 5.26
if (! grep { $_ eq '.' } @INC) {
    require FindBin;
    no warnings 'once';
    push @INC, $FindBin::Bin . '/..';
}

require_ok( File::Spec->catfile( t => 'db.pl' ) );

my %wanted = $opt{ids} ? map { ( $_, $_ ) } @{ $opt{ids} } : ();

sub ok_to_test {
    my $id = shift;
    return 1 if ! %wanted;
    return $wanted{ $id };
}

my %seen;
foreach my $test ( database({ thaw => 1 }) ) {
    next if ! ok_to_test( $test->{id} );

    die "No user-agent string defined?\n"     if ! $test->{string};
    die "Already tested '$test->{string}'!\n" if   $seen{ $test->{string} }++;

    my $parsed = Parse::HTTP::UserAgent->new( $test->{string} );
    my %got    = $parsed->as_hash;

    if ( ! $test->{struct} ) {
        fail 'No data in the test result set? Expected something matching '
            . "with these:\n$test->{string}\n\n"
            . dump_struct( \%got );
        next;
    }

    is(
        delete $got{string},
        $test->{string},
        "Ok got the string back for $got{name}"
    );

    ok(
        delete $got{string_original},
        "Ok got the original string back for $got{name}"
    );

    # remove undefs, so that we can extend the test data with less headache
    %got =  map  { $_ => $got{ $_ } }
            grep { defined $got{$_} }
            keys %got;

    # also get rid of empty lists
    my @empty = grep {
                    ref $got{$_} eq 'ARRAY' && @{ $got{$_} } == 0
                } keys %got;
    delete @got{ @empty };

    my $is_eq = is_deeply(
        \%got,
        $test->{struct},
        sprintf q{Frozen data matches parse result for '%s' -> %s -> %s},
                    $test->{string},
                    $got{parser} || '???',
                    $test->{id}
    );

    if ( ! $is_eq || $opt{dump} ) {
        diag sprintf "GOT: %s\nEXPECTED: %s\n",
                        Dumper( \%got ),
                        Dumper( $test->{struct} );
    }
}

sub dump_struct {
    my $got = shift;
    delete $got->{string};

    my %ok = map { $_ => $got->{$_} }
            grep { defined $got->{$_} }
            keys %{ $got };

    my($width) = map { $_        }
                sort { $b <=> $a }
                map  { length $_ }
                keys %ok;

    return join q{},
            map {
                sprintf "% -${width}s => %s,\n",
                        $_,
                        dump_field( $ok{ $_ } )
            }
            sort keys %ok;
}

sub dump_field {
    my $thing = shift;
    my $rv    = trim( Dumper $thing );
    $rv =~ s{ \n \s+            }{ }xmsg;
    $rv =~ s{ \A \$VAR1 \s = \s }{}xms;
    $rv =~ s{              ; \z }{}xms;
    return $rv;
}

__END__
