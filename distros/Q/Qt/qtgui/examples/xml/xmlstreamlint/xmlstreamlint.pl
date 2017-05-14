#!/usr/bin/perl

package XmlStreamLint;

use strict;
use warnings;
use QtCore4;
use QtCore4::isa qw(Qt::Object);

=begin

 This class exists for the sole purpose of creating a translation context.

=cut

use strict;
use warnings;
use QtCore4;

use constant {
    Success => 0,
    ParseFailure => 1,
    ArgumentError => 2,
    WriteError => 3,
    FileFailure => 4,
};

sub main
{

    my $app = Qt::CoreApplication(\@ARGV);

    if (scalar @ARGV != 1)
    {
        print STDERR XmlStreamLint::tr(
                       "Usage: xmlstreamlint <path to XML file>\n");
        return ArgumentError;
    }

    my $inputFilePath = Qt::CoreApplication::arguments()->[1];
    my $inputFile = Qt::File($inputFilePath);

    if (!Qt::File::exists($inputFilePath))
    {
        printf STDERR XmlStreamLint::tr(
                       "File %s does not exist.\n"), $inputFilePath;
        return FileFailure;

    } elsif (!$inputFile->open(Qt::IODevice::ReadOnly())) {
        printf STDERR XmlStreamLint::tr(
                       "Failed to open file %s.\n"), $inputFilePath;
        return FileFailure;
    }

    my $outputFile = Qt::File();
    # Use the special file descriptor form of open()
    if (!$outputFile->open(1, Qt::IODevice::WriteOnly()))
    {
        print STDERR XmlStreamLint::tr('Failed to open stdout.');
        return WriteError;
    }

# [0]
    my $reader = Qt::XmlStreamReader($inputFile);
    my $writer = Qt::XmlStreamWriter($outputFile);
# [0]

# [1]
    while (!$reader->atEnd())
    {
        $reader->readNext();

        if ($reader->error() != Qt::XmlStreamReader::NoError())
        {
            printf STDERR XmlStreamLint::tr(
                           "Error: %s in file %s at line %d, column %d.\n"),
                               $reader->errorString(), $inputFilePath,
                               $reader->lineNumber(),
                               $reader->columnNumber();
            return ParseFailure;
# [1]

# [2]
        } else {
            $writer->writeCurrentToken($reader);
        }
    }
# [2]

    $outputFile->flush();
    return Success;
}

exit main();
