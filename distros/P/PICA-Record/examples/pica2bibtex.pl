#!/usr/bin/perl

=head1 NAME

pica2bibtex.pl - Convert PICA+ records to BibTeX

=head1 DESCRIPTION

This example parses PICA+ records from given files
and creates a simple BibTeX mapping of it.

=cut

use strict;
use warnings;

use Text::BibTeX qw(:metatypes);
use Text::BibTeX::Entry;
use PICA::Parser;

# read filenames as command line parameters
while (@ARGV) {
    my $filename = pop @ARGV;
    PICA::Parser->new(
        Record => sub {
            my $bibtex = pica2bibtex( shift );
            print $bibtex->print_s();
        }
    )->parsefile( $filename );
}

=head2 pica2bibtex ( $record [, $key ] )

Converts a given L<PICA::Record> to a L<Text::BibTeX::Entry> object.
If no BibTeX key is specified (by the second argument), the key will
be set by the PPN in PICA+ field 003@$0.

=cut

sub pica2bibtex {
    my $record = shift;
    my $key = shift;

    croak('Missing PICA::Record object!')
        unless ref($record) eq 'PICA::Record';

    my $entry = Text::BibTeX::Entry->new();
    $entry->set_metatype(&BTE_REGULAR);
    $key = $record->sf('003@$0') unless defined $key;
    $entry->set_key($key);

    # Set a BibTeX field to a value only if the value is defined.
    # returns whether the value was defined.
    #
    my $setfield = sub { # $key, ( $value | \@array, $sep )
        my ($key, $value, $sep) = @_;
        if (ref($value) eq "ARRAY") {
            my @v = grep { defined $_ } @{ $value };
            return 0 unless scalar @v;
            $value = join( defined $sep ? $sep : "", @v );
        }
        return 0 unless defined $value;
        $entry->set($key, $value);
        return 1;
    };


    # record type
    if ($record->sf('021A$x1')) {
        $entry->set_type("inbook");
    } else {
        $entry->set_type("book");
    }

    # authors
    if ($record->sf('028A$a')) {
        my @names = ( $record->sf('028A$a') . ", " . $record->sf('028A$d') );
        if ($record->field('028B/01')) {
            push @names, $record->sf('028B/01$a') . ", " . $record->sf('028B/01$d');
        }
        if ($record->field('028B/02')) {
            push @names, $record->sf('028B/02$a') . ", " . $record->sf('028B/02$d');
        }
        &$setfield('author', \@names, ' and ');
    }

    # other persons
    if ($record->sf('028C$a')) {
        my @names = ( $record->sf('028C$a') . ", " . $record->sf('028C$d') );
        if ($record->field('028C/01')) {
            push @names, $record->sf('028C/01$a') . ", " . $record->sf('028C/01$d');
        }
        if ($record->field('028C/02')) {
            push @names, $record->sf('028C/02$a') . ", " . $record->sf('028C/02$d');
        }
        &$setfield('editor', \@names, ' and ');
    }

    my @comments;

    # crossref
    # multiple volumes detected place a crossref
    &$setfield('crossref', $record->sf('036D$9'));

    # comments
    if ($record->sf('039D$9')) {
        # Review of some book
        $entry->set('crossref', $record->sf('039D$9'));
        # how to do this canonically???
        push @comments, "Rezension";
    }
    if ($record->field('037A')) {
        push @comments, $record->sf('037A$a');
    }
    if ($record->field('037C')) {
        push @comments, $record->sf('037C$b') . " " . $record->sf('037C$a');
    }
    if ($record->sf('046M$a')) {
        push @comments, $record->sf('046M$a');
    }

    # title
    if ($record->sf('021A$a')) {
        # a normal book has this field set
        my $title = $record->sf('021A$a');
        $title =~ s/@//;
        # add the subtitle
        if ($record->sf('021A$d')) {
            $title .= ": " . $record->sf('021A$d');
        }
        $entry->set('title', $title);
    }
    if ($record->sf('021A$x1')) {
        # this is a j-record and stores the title in another field
        $entry->set('crossref', $record->sf('021A$9'));
        my $title = "";
        if ($record->sf('036C$a')) {
            $title .= $record->sf('036C$a') . ": ";
        }
        $title .= $record->sf('021B$a');
        $entry->set('title', $title);
    }

    # how published
    &$setfield('howpublished', $record->sf('004A$a'));

    # other simple fields
    &$setfield('address', $record->sf('033A$p'));
    &$setfield('publisher', $record->sf('033A$n'));
    &$setfield('edition', $record->sf('032@$a'));
    &$setfield('pages', $record->sf('034D$a'));
    &$setfield('series', $record->sf('036E$a'));
    &$setfield('number', $record->sf('036E$l'));
    &$setfield('language', $record->sf('010@$a'));
    &$setfield('year', $record->sf('011@$a'));

    # handling 10 and 13 digits ISBN, store both if available
    # Check also for additional ISBN-fields
    &$setfield('isbn', $record->sf('004A$A')) || &$setfield('isbn', $record->sf('004A$0'));
    &$setfield('sisbn', $record->sf('004A$0')) || &$setfield('sisbn', $record->sf('004B$0'));

    # classification codes
    &$setfield('loc', $record->sf('045A$a'));
    &$setfield('ddc', $record->sf('045F$a'));
    &$setfield('bk', [
        $record->sf('045Q/01$8'),
        $record->sf('045Q/02$8'),
        $record->sf('045Q/03$8'),
        $record->sf('045Q/04$8'),
        $record->sf('045Q/05$8')
    ], ", ");

    if ($record->sf('034M$a') || $record->sf('037A$a')) {
        my $c = $record->sf('034M$a') || "";
        $c .= $record->sf('037M$a') || "";
        push @comments, $c;
    }

    &$setfield('comment', \@comments, " / ");

    # keywords
    &$setfield('keywords', [
        $record->sf('044K$8'), # Keywords
        $record->sf('041A$8'), # Ger
        $record->sf('044F$a'), # DDB
        $record->sf('044A$a'), # LCC
        $record->sf('044G$a'), # BC
        $record->sf('044C$a')  # MeSH
    ], "; ");

    # price
    if ($record->sf('004A$f')) {
        &$setfield('price', "GVK: " . $record->sf('004A$f'));
    }

    my @rvkother = $record->sf('045M/90$a');
    &$setfield('RVKother', \@rvkother, ", ");

    # normally the TOC or something like that.
    &$setfield('url', $record->sf('009P/09$a'));

    # add a timestamp
    my ($second, $minute, $hour, $dayOfMonth, $month, $year) = localtime();
    $year += 1900;
    $month++;
    $month = "0$month" if ($month < 10);
    &$setfield('timestamp', "$year$month$dayOfMonth");

    return $entry;
}

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >> and
Alexander Wagner C<< <a.wagner@fz-juelich.de> >>


