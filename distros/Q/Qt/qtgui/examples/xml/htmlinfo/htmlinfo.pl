#!/usr/bin/perl


use strict;
use warnings;
use QtCore4;
use QtGui4;


sub parseHtmlFile {
    my ($fileName) = @_;
    my $file = Qt::File($fileName);

    print 'Analysis of HTML file: ' . $fileName . "\n";

    if (!$file->open(Qt::IODevice::ReadOnly())) {
        print '  Couldn\'t open the file.' . "\n" . "\n" . "\n";
        return;
    }

# [0]
    my $reader = Qt::XmlStreamReader($file);
# [0]

# [1]
    my $paragraphCount = 0;
    my @links;
    my $title;
    while (!$reader->atEnd()) {
        $reader->readNext();
        if ($reader->isStartElement()) {
            if ($reader->name()->toString() eq 'title') {
                $title = $reader->readElementText();
            }
            elsif($reader->name()->toString() eq 'a') {
                push @links, $reader->attributes()->value('href')->toString();
            }
            elsif($reader->name()->toString() eq 'p') {
                ++$paragraphCount;
            }
        }
    }
# [1]

# [2]
    if ($reader->hasError()) {
        print '  The HTML file isn\'t well-formed: ' . $reader->errorString()
            . "\n" . "\n" . "\n";
        return;
    }
# [2]

    print '  Title: \'' . $title . '\'' . "\n"
        . '  Number of paragraphs: ' . $paragraphCount . "\n"
        . '  Number of links: ' . scalar @links . "\n"
        . '  Showing first few links:' . "\n";

    while( scalar @links > 5 ) {
        pop @links;
    }

    foreach my $link (@links) {
        print '    ' . $link . "\n";
    }
    print "\n" . "\n";
}

sub main
{
    # intialize QtCore application
    my $app = Qt::CoreApplication(\@ARGV);

    # get a list of all html files in the current directory
    my @filter = (
        '*.htm',
        '*.html',
    );
    my $htmlFiles = Qt::Dir::current()->entryList(\@filter, Qt::Dir::Files());

    if (ref $htmlFiles eq 'ARRAY' && !scalar @{$htmlFiles}) {
        print 'No html files available.';
        return 1;
    }

    # parse each html file and write the result to file/stream
    foreach my $file (@{$htmlFiles}) {
        parseHtmlFile($file);
    }

    return 0;
}

exit main();
