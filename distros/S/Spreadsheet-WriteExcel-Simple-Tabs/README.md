# NAME

Spreadsheet::WriteExcel::Simple::Tabs - Simple Interface to the Spreadsheet::WriteExcel Package

# SYNOPSIS

    use Spreadsheet::WriteExcel::Simple::Tabs;
    my $ss=Spreadsheet::WriteExcel::Simple::Tabs->new;
    my @data=(
              ["Heading1", "Heading2"],
              ["data1",    "data2"   ],
              ["data3",    "data4"   ],
             );
    $ss->add(Tab1=>\@data, Tab2=>\@data);
    print $ss->header(filename=>"filename.xls"), $ss->content;

# DESCRIPTION

This is a simple wrapper around Spreadsheet::WriteExcel that creates tabs for data.  It is meant to be simple not full featured.  I use this package to export data from the [DBIx::Array](https://metacpan.org/pod/DBIx::Array) sqlarrayarrayname method which is an array of array references where the first array is the column headings.

# CONSTRUCTOR

## new

## initialize

## book

Returns the workbook object

## add

    $ss->add("Tab Name", \@data);
    $ss->add(Tab1=>\@data, Tab2=>\@data);

## header

Returns a header appropriate for a web application

    Content-type: application/vnd.ms-excel
    Content-Disposition: attachment; filename=filename.xls

    $ss->header                                           #embedded in browser
    $ss->header(filename=>"filename.xls")                 #download prompt
    $ss->header(content_type=>"application/vnd.ms-excel") #default content type

## content

This returns the binary content of the spreadsheet.

    print $ss->content;

    print $ss->header, $ss->content; #CGI Application

    binmod($fh);
    print $fh, $ss->content;

# PROPERTIES

## first

Returns a hash of additional settings for the first row

    $ss->first({setting=>"value"}); #settings from L<Spreadsheet::WriteExcel>

## default

Returns a hash of default settings for the body

    $ss->default({setting=>"value"}); #settings from L<Spreadsheet::WriteExcel>

# AUTHOR

    Michael R. Davis

# COPYRIGHT

Copyright (c) 2009 Michael R. Davis
Copyright (c) 2001-2005 Tony Bowden (IO::Scalar portion used here "under the same terms as Perl itself")

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

# SEE ALSO

[Spreadsheet::WriteExcel::Simple](https://metacpan.org/pod/Spreadsheet::WriteExcel::Simple), [DBIx::Array](https://metacpan.org/pod/DBIx::Array) sqlarrayarrayname method, [IO::Scalar](https://metacpan.org/pod/IO::Scalar), [Spreadsheet::WriteExcel](https://metacpan.org/pod/Spreadsheet::WriteExcel)
