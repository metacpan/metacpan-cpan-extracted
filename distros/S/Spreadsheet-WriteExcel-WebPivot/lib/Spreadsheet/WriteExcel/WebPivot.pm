package Spreadsheet::WriteExcel::WebPivot;

use 5.006;
use strict;
use warnings;
use DBI;
use FileHandle;
use Switch;
use POSIX 'strftime';

our(@ISA, @EXPORT);
sub makewebpivot;

use Exporter 'import';
@EXPORT = qw(makewebpivot);

our $VERSION = '0.01';

#-----------------------------------------------------------------------
# not needed or even that useful anymore now that we are exporting the
# main function
#
sub new {
    my $class = shift;
    $class = ref($class) if (ref($class));

    my $self = {};
    bless($self, $class);
    return $self;
}


# these four variables are for storing large amounts of text for
# a home-brew template system. The Template Toolkit is much better
# but I wanted to reduce module dependencies

my ($pivotcachetext, $pivotcachefooter,$pivothdrtext,$filelisttmpl);

#-----------------------------------------------------------------------
# this function is an internal function that does the proper xml 
# escaping for hash references containing
# data that needs to be output as xml

sub cleanhash4xml {
    my $self = shift; # get class thingy
    my $rhsh = shift;

    return 	unless(defined($rhsh));
    my @keys = keys %$rhsh;
    # the line below takes care of uninitialized data errors
    map {(!exists($rhsh->{$_}) or !defined($rhsh->{$_})) ? $rhsh->{$_} = ' ': 1} @keys;
    map ($rhsh->{$_} =~ s/\&/\&amp;/g, @keys);
    map ($rhsh->{$_} =~ s/"/\&quot;/g, @keys);
    map ($rhsh->{$_} =~ s/</\&lt;/g, @keys);
    map ($rhsh->{$_} =~ s/>/\&gt;/g, @keys);
    map ($rhsh->{$_} =~ s/[^[:alnum:][:punct:] ]//g, @keys);
    if (defined($self->{types})) {
        foreach my $key (@keys) {
            #die "dead #".$rhsh->{$key} . "#\n"	if( 'Tier' eq $key and !($rhsh->{$key} =~ /\w/));
            if (!defined($rhsh->{$key}) or !($rhsh->{$key} =~ /\w/)) {
                if ( $self->{types}->{$key} eq 'text' ) {
                    $rhsh->{$key} = 'none';
                }
                else {
                    $rhsh->{$key} = "0";
                }
            }
        }
    }
}


#-----------------------------------------------------------------------
sub cleanArray4xml {
    shift; # get class thingy
    my $rarr = shift;
    # the line below takes care of uninitialized data errors
    map {defined($_) ? $_ : ''} @$rarr;
    map (s/\&/\&amp;/g, @$rarr);
    map (s/"/\&quot;/g, @$rarr);
    map (s/</\&lt;/g, @$rarr);
    map (s/>/\&gt;/g, @$rarr);
    map (s/[^[:alnum:][:punct:] ]//g, @$rarr);
}



#-----------------------------------------------------------------------
sub getDataTypes {
    my $self = shift;
    my $href = shift;
    my $rkeys = shift;
    my @keys = @$rkeys;
    my $type; my $typename;
    my @pivotfields;
    my $i = 1;
    my @dkeys = keys %$href;
    my %keysh; @keysh{@keys} = @keys;
    map { push @keys, $_ unless(exists $keysh{$_}) }  @dkeys;
    foreach my $key (@keys) {
        die "$key not defined\n" unless(defined $href->{$key});
        switch ($href->{$key}) {
            case /^\d+$/ {
                $type = q(type="int"); 
                $typename = 'int';
            }
            case /^\d+\.\d+$/ {
                $type = q(type="float");
                $typename = 'float';
            }
            case qr/^\d{4}\-\d{2}\-\d{2}/ {
                $type = q(type="dateTime");
                $typename = 'dateTime';
            }
            else {
                $type = q(maxLength="255"); 
                $typename = 'text';
            }
        }
        push @pivotfields, {FIELDNAME=>$key, COLNUM=>$i++, DATATYPE=>$type};
        $self->{types}->{$key} = $typename;
    }
    return @pivotfields;
}

#-----------------------------------------------------------------------
# this function sets up the subdirectory required by Excel's web object
#
sub makepivotdir {
    my $file = shift;
    my $title = shift;
    my $rkeys = shift;
    my $summarytype = shift;

    mkdir $file . "_files"	unless( -d $file . "_files" );
    # if the summary flag was not set or the directory does not exist
    # generate table main page ( as opposed to the data page )
    # based on pivotfields
    my $fh = FileHandle->new(">$file".".htm")
        or die "Unable to open $file\n";

    printPivotHdr($fh, $title, $file, $rkeys, $summarytype);

    $fh->close;
    $fh->open(">$file".'_files/filelist.xml') or
            die "Unable to open $file _files/filelist.xml\n";
    $filelisttmpl =~ s/CACHENAME/$file/g;
    print $fh $filelisttmpl;
    $fh->close;
}

#-----------------------------------------------------------------------
# this is an internal function that takes each successive row of data 
# and puts it in the required format
#
sub addPivotData {
    my $self = shift;
    my $fh = shift;
    my $href = shift;
    my $datarows = shift;
    my $rkeys = shift;
    my $i;

    $self->cleanhash4xml($href); # takes care of escaping characters.
    my @keys = @$rkeys;
    my $key1 = $keys[0];
    my $keyN = $keys[$#keys];
    my @dkeys = keys %$href;
    my %keysh; @keysh{@keys} = @keys;
    map { push @keys, $_ unless(exists $keysh{$_}) }  @dkeys;
    #print "keys: @keys\n";
    my @datacolumns;
    for ($i=1; my $key = shift @keys; $i++) {
        push @datacolumns, qq(Col$i="$href->{$key}");
    }
    print $fh "   <z:row ",join(" ",@datacolumns),"/>\n";
    return $i; # return the column count
}


#-----------------------------------------------------------------------
# this is the top level function. The only one called directly by the
# user.
#
sub makewebpivot {
    #my $self = shift;
    my $self = bless({},'Spreadsheet::WriteExcel::WebPivot');
    my $dbh = shift; my $query = shift;
    my $rquerykeys = shift;
    my $summarytype = shift;
    my $file = shift;
    my $title = shift;

    # the line below allows us to pass in a reference to 
    # an array of hash refs and the code will pretend it is a
    # DBI object and fetch each hashref in the array.
    $dbh = Spreadsheet::WriteExcel::WebPivot::FakeDBI->new($dbh) if( ref($dbh) eq 'ARRAY' );

    $self->{SummaryType} = $summarytype;

    my @datarows; my @queries = ();
    if( 'ARRAY' eq ref($query) ) {
        @queries = @$query;
        $query = shift @queries;
    }
    my $sth = $dbh->prepare($query);
    $sth->execute;

    makepivotdir($file,$title,$rquerykeys,$summarytype);

    my $fh = FileHandle->new(">$file"."_files/$file".'_1234_cachedata001.xml');
    die "Unable to open cache\n" unless($fh);

    my $href = $sth->fetchrow_hashref;
    my @pivotfields = $self->getDataTypes($href,$rquerykeys);
    {
        local $/ = undef;  # INPUT SEPARATOR
        local $" = "\n";   # OUTPUT SEPARATOR
        my @ncolumns = (map { qq(    <s:attribute type="Col$_"/>) } 
                    (1..scalar(@pivotfields)) 
                );
        my @columns;
        map { push @columns,  
        qq(   <s:AttributeType name="Col$_->{COLNUM}" rs:name="$_->{FIELDNAME}">),
        qq(    <s:datatype dt:$_->{DATATYPE}/>),
        qq(   </s:AttributeType>); } @pivotfields; 
        my $outtext = eval $pivotcachetext;
        print $fh $outtext;
    }
    my $colcount = $self->addPivotData($fh,$href,\@datarows, $rquerykeys);

    # a bit of code gymnastics here to handle an array of query strings
    # if there are multiple query strings we run execute each new query
    # and run the loop again.
    do {
        while( $href = $sth->fetchrow_hashref ) {
            $colcount = $self->addPivotData($fh,$href, \@datarows, $rquerykeys);
        }
        $sth->finish;
    } while( ($query = shift @queries) && ($sth = $dbh->prepare($query)) && $sth->execute );

    print $fh $pivotcachefooter;
    $fh->close;

    #$sth->finish;

} # end makewebpivot


#-----------------------------------------------------------------------
# internal variable initialization
#

$pivotcachetext = q(qq(<xml xmlns:x="urn:schemas-microsoft-com:office:excel"
 xmlns:dt="uuid:C2F41010-65B3-11d1-A29F-00AA00C14882"
 xmlns:s="uuid:BDC6E3F0-6DA3-11d1-A2A3-00AA00C14882"
 xmlns:rs="urn:schemas-microsoft-com:rowset" xmlns:z="#RowsetSchema">
 <x:PivotCache>
  <x:CacheIndex>1</x:CacheIndex>
  <s:Schema id="RowsetSchema">
   <s:ElementType name="row" content="eltOnly">
@ncolumns
    <s:extends type="rs:rowbase"/>
   </s:ElementType>
@columns
  </s:Schema>
  <rs:data>
));

$pivotcachefooter = q(
  </rs:data>
 </x:PivotCache>
</xml>
);

$filelisttmpl = q(
<xml xmlns:o="urn:schemas-microsoft-com:office:office">
 <o:MainFile HRef="../CACHENAME.htm"/>
 <o:File HRef="CACHENAME_1234_cachedata001.xml"
  PublicationID="CACHENAME"/>
 <o:File HRef="filelist.xml"/>
</xml>
);

# another "role your own template" function
# printPivotHdr creates the file that serves as the header file for Excel XML
# web objects

sub printPivotHdr {
    my ($fh,$TITLE,$CACHENAME,$rkeys,$SUMMARYTYPE,$NOSUBTOTAL) = @_;
    #print "Summary Type = $SUMMARYTYPE\n";
    if($NOSUBTOTAL) {
        $NOSUBTOTAL = q(&lt;Subtotal&gt;None&lt;/Subtotal&gt;&#13;&#10;);
    } else { $NOSUBTOTAL = ''; }

    my @pivotfields = @$rkeys;
    my $DATAFIELD = $pivotfields[$#pivotfields];
    my @pivotfieldsloop;
    my ($POS,$FIELDNAME);

    map { $POS++; $FIELDNAME = $_;
    push @pivotfieldsloop, qq(
     &lt;PivotField&gt;&#13;&#10;
     &lt;Name&gt;$FIELDNAME&lt;/Name&gt;&#13;&#10;
     &lt;Orientation&gt;Row&lt;/Orientation&gt;&#13;&#10;
     $NOSUBTOTAL
     &lt;Position&gt;$POS&lt;/Position&gt;&#13;&#10;
     &lt;PivotItem&gt;&#13;&#10;    &lt;Name&gt;&lt;/Name&gt;&#13;&#10;
     &lt;Hidden/&gt;&#13;&#10;    &lt;HideDetail/&gt;&#13;&#10;
     &lt;/PivotItem&gt;&#13;&#10;  &lt;/PivotField&gt;&#13;&#10;
    ); } @pivotfields[0..$#pivotfields-1];

    my $TODAY = strftime '%Y-%m-%d %H:%M:%S', localtime;
    $TODAY =~ s/ /T/;
    $pivothdrtext =~ s/CACHENAME/$CACHENAME/gm;
    $pivothdrtext =~ s/TITLE/$TITLE/gm;
    $pivothdrtext =~ s/TODAY/$TODAY/gm;
    $pivothdrtext =~ s/DATAFIELD/$DATAFIELD/gm;
    $pivothdrtext =~ s/SUMMARYTYPE/$SUMMARYTYPE/gm;
    $pivothdrtext =~ s/PIVOTFIELDSLOOP/@pivotfieldsloop/m;
    print $fh $pivothdrtext;
    #print $fh "@pivotfieldsloop\n";
}

# I appologize in advance for the big, ugly inlined document that follows
# I would have prefered to store this text after the END marker and use
# the <DATA> handle to access it but that doesn't work in this module file.

$pivothdrtext = q(<html xmlns:o="urn:schemas-microsoft-com:office:office"
xmlns:x="urn:schemas-microsoft-com:office:excel"
xmlns="http://www.w3.org/TR/REC-html40">
<head>
<title>TITLE</title>
<meta http-equiv=Content-Type content="text/html; charset=windows-1252">
<meta name=ProgId content=FrontPage.Editor.Document>
<meta name=Generator content="Perl instead of Excel 10">
<link rel=File-List href="CACHENAME_files/filelist.xml">
</head>
<body>
<!--[if !excel]>&nbsp;&nbsp;<![endif]-->
<!--The following information wasn't generated by Microsoft Excel's Publish as Web
Page wizard.-->
<!--If the same item is republished from Excel, all information between the DIV
tags will be replaced.-->
<!----------------------------->
<!--START OF OUTPUT FROM EXCEL PUBLISH AS WEB PAGE WIZARD -->
<!----------------------------->
<div id="CACHENAME_1234" align=left x:publishsource="Excel"><object
 id="CACHENAME_1234_PivotTable"
 classid="CLSID:0002E552-0000-0000-C000-000000000046">
 <param name=XMLData value="&lt;!--[if gte mso 9]&gt;&lt;xml
 xmlns:o=&quot;urn:schemas-microsoft-com:office:office&quot;&#13;&#10;
 xmlns:x=&quot;urn:schemas-microsoft-com:office:excel&quot;&#13;&#10;
 xmlns:html=&quot;http://www.w3.org/TR/REC-html40&quot;&gt;&#13;&#10;
 &lt;WorksheetOptions
 xmlns=&quot;urn:schemas-microsoft-com:office:excel&quot;&gt;&#13;&#10;
 &lt;Zoom&gt;0&lt;/Zoom&gt;&#13;&#10;  &lt;Selected/&gt;&#13;&#10;
 &lt;TopRowVisible&gt;2&lt;/TopRowVisible&gt;&#13;&#10;
 &lt;Panes&gt;&#13;&#10;   &lt;Pane&gt;&#13;&#10;
 &lt;Number&gt;3&lt;/Number&gt;&#13;&#10;
 &lt;RangeSelection&gt;$D:$D&lt;/RangeSelection&gt;&#13;&#10;
 &lt;/Pane&gt;&#13;&#10;  &lt;/Panes&gt;&#13;&#10;
 &lt;ProtectContents&gt;False&lt;/ProtectContents&gt;&#13;&#10;
 &lt;ProtectObjects&gt;False&lt;/ProtectObjects&gt;&#13;&#10;
 &lt;ProtectScenarios&gt;False&lt;/ProtectScenarios&gt;&#13;&#10;
 &lt;/WorksheetOptions&gt;&#13;&#10; &lt;PivotTable
 xmlns=&quot;urn:schemas-microsoft-com:office:excel&quot;&gt;&#13;&#10;
 &lt;PTSource&gt;&#13;&#10;
 &lt;DataMember&gt;XLDataSource&lt;/DataMember&gt;&#13;&#10;
 &lt;CacheIndex&gt;1&lt;/CacheIndex&gt;&#13;&#10;
 &lt;VersionLastRefresh&gt;1&lt;/VersionLastRefresh&gt;&#13;&#10;
 &lt;RefreshName&gt;perlpivot&lt;/RefreshName&gt;&#13;&#10;
 &lt;CacheFile HRef=&quot;CACHENAME_files/CACHENAME_1234_cachedata001.xml&quot;/&gt;&#13;&#10;
 &lt;RefreshDate&gt;TODAY&lt;/RefreshDate&gt;&#13;&#10;
 &lt;RefreshDateCopy&gt;TODAY&lt;/RefreshDateCopy&gt;&#13;&#10;
 &lt;/PTSource&gt;&#13;&#10;  
 &lt;Name&gt; TITLE &lt;/Name&gt;&#13;&#10;
 &lt;DataMember&gt;XLDataSource&lt;/DataMember&gt;&#13;&#10;
 &lt;ImmediateItemsOnDrop/&gt;&#13;&#10;
 &lt;ShowPageMultipleItemLabel/&gt;&#13;&#10;
 &lt;Location&gt;$A$1:$D$5&lt;/Location&gt;&#13;&#10;
 &lt;VersionLastUpdate&gt;1&lt;/VersionLastUpdate&gt;&#13;&#10;
 &lt;DefaultVersion&gt;1&lt;/DefaultVersion&gt;&#13;&#10;
 &lt;PivotField&gt;&#13;&#10;   
 &lt;Name&gt;DATAFIELD&lt;/Name&gt;&#13;&#10;
 &lt;/PivotField&gt;&#13;&#10;  
PIVOTFIELDSLOOP
&lt;PivotField&gt;&#13;&#10;   &lt;DataField/&gt;&#13;&#10;
 &lt;Name&gt;Data&lt;/Name&gt;&#13;&#10;
 &lt;Orientation&gt;Row&lt;/Orientation&gt;&#13;&#10;
 &lt;Position&gt;-1&lt;/Position&gt;&#13;&#10;
 &lt;/PivotField&gt;&#13;&#10;  
&lt;PivotField&gt;&#13;&#10;
 &lt;Name&gt;SUMMARYTYPE of DATAFIELD&lt;/Name&gt;&#13;&#10;
 &lt;ParentField&gt;DATAFIELD&lt;/ParentField&gt;&#13;&#10;
 &lt;NumberFormat&gt;#,##0&lt;/NumberFormat&gt;&#13;&#10;
 &lt;Orientation&gt;Data&lt;/Orientation&gt;&#13;&#10;
 &lt;Function&gt;SUMMARYTYPE&lt;/Function&gt;&#13;&#10;
 &lt;Position&gt;1&lt;/Position&gt;&#13;&#10;
 &lt;/PivotField&gt;&#13;&#10;  &lt;PTFormat
 Style='mso-number-format:&quot;\#\,\#\#0&quot;'&gt;&#13;&#10;
 &lt;PTRule&gt;&#13;&#10;
 &lt;RuleType&gt;DataOnly&lt;/RuleType&gt;&#13;&#10;
 &lt;/PTRule&gt;&#13;&#10;  &lt;/PTFormat&gt;&#13;&#10;  &lt;PTFormat
 Style='mso-number-format:&quot;\#\,\#\#0&quot;'&gt;&#13;&#10;
 &lt;PTRule&gt;&#13;&#10;
 &lt;RuleType&gt;Blanks&lt;/RuleType&gt;&#13;&#10;
 &lt;/PTRule&gt;&#13;&#10;  &lt;/PTFormat&gt;&#13;&#10;
 &lt;/PivotTable&gt;&#13;&#10;&lt;/xml&gt;&lt;![endif]--&gt;"><p
 style='margin-top:100;font-family:Arial;font-size:8.0pt'>To use this Web
 page interactively, you must have Microsoft Internet Explorer 4.01 Service
 Pack 1 (SP1) or later and the Microsoft Office XP Web Components.</p>
 <p style='margin-top:100;font-family:Arial;font-size:8.0pt'>See the <a
 href="http://office.microsoft.com/office/redirect/10/MSOWCPub.asp?HelpLCID=1033">Microsoft
 Office Web site</a> for more information.</p>
</object></div>
<!----------------------------->
<!--END OF OUTPUT FROM EXCEL PUBLISH AS WEB PAGE WIZARD-->
<!----------------------------->
<br>
</body>
</html>
); 

package Spreadsheet::WriteExcel::WebPivot::FakeDBI;

# the constructor
sub new {
    my $class = shift;
    my $arg = shift;
    if( defined($arg) and ref($arg) eq 'ARRAY' ) {
        bless($arg); # I don't expect anyone to ever inherit from this
    } else { 
        $arg = [];
        bless($arg);
    }
    return $arg;
}

sub prepare {
    my $self = shift;
    return $self;
}

sub execute {
}

sub finish {
}

sub fetchrow_hashref {
    my $self = shift;
    return shift @$self;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;

__END__

=head1 NAME

Spreadsheet::WriteExcel::WebPivot - generates an MS Excel Web Pivot table for IE

=head2 makewebpivot

=head1 SYNPOSIS

use Spreadsheet::WriteExcel::WebPivot;

makewebpivot(db handle,query,query keys, summary type, file name, title);

=head1 DESCRIPTION

this method creates an MS Excel Web Pivot which when viewed on a Windows 
machine with MS Office XP and IE gives you a fully functional embedded 
spreadsheet object in the browser. This should be able to run and produce
output anywhere perl is installed but the output will only be useful to those
running Windows and IE.
The pivot table gives a high level summary of the numbers that can be
rearranged in different ways.

=head1 PARAMETERS

The parameters it takes are a database handle, a query string or array ref (see below), the query
keys which is a reference to an array of the names of fields in the query 
listed in the
order you want them diplayed in the web pivot, the summary type which is
the type of summary to be used in the pivot, the file name to save the
generated web pivot under and the last parameter is the title of the pivot table

Note the query parameter can also be a reference to an array of query strings.
makewebpivot will detect whether query is a string or array of strings. If it
is an array of strings it execute each query in order and add their results to
the pivot. Note that if you use multiple queries, all queries must return the
same results in the same format as the first query. This restriction is 
inherent in MS Excel pivot tables.

This module can also be used in the absense of a database connection by
passing in a reference to an array of hash references. When called this
way whatever query you pass in will be ignored and the module will instead 
present the data in the data structure you passed in. For a trivial example:

use Spreadsheet::WriteExcel::WebPivot;

my @array;

for(my $i=0; $i < 20; $i++) {
    push @array, { Name => "a$i", Number => $i };
}

my @fields = qw(Name Number);

makewebpivot(\@array, '', \@fields, 'Count', 'exceltest', 'Test Pivot');

=head2 The above example uses the module without a database. Below is a trivial example using a database.

use Spreadsheet::WriteExcel::WebPivot;
use DBI;

my $dbh = DBI->connect('dbi:your:database');

my @fields = qw(field1 field2 field3);

my $query = "select * from table";

makewebpivot($dbh,$query,\@fields,'Count', 'exceltest2','Test Pivot2');

=head3 Note: you will likely need to adjust the security settings of your IE browser to view the generated pages as pivot tables. Please inspect the generated pages if you are concerned about this.

=head1 AUTHOR

Nathan Lewis, E<lt>nathanlewis42@yahoo.co.ukE<gt>

Nathan is no longer maintaining this module.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Nathan Lewis

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
