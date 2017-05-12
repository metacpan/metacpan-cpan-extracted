package pdftest;

use strict;
use English;
use CGI qw(:all);

my ($curr, $status, $message, $pdfrep);

sub pdftest
{
    # This call to CGI initialises all the required variables

    $curr = CGI->new();

    # This sets up the PDF REP Module

    $pdfrep = PDFREP->new();

    # This generates the HTML output for the test display page

    my $text1 = param("SUBMIT");

    print header();
    print start_html(-TITLE=>'Hello Trevor',-BGCOLOR=>'228b22',-TEXT=>'FFFFFF',-ALINK=>'FFFFFF',
                     -VLINK=>'FFFFFF');
    print center();
    print "\n\n";
    print h1($text1);
    print "\n\n";
    print br();

    # This call to PDFREP generates the first line of data for the pdf file
    # This should be called to generate the heading line once per output file
    # It will open the output file with the given name and the given directory.
    # It returns a status flag = 1 succesful and 0 failure and a message text.
    # The .pdf file extension is added automatically to the output file
    # It also opens the temporary file for page data which is the same name and directory
    # but the extension is .tmp. So make sure there is enough room in the area you are
    # working in. The tmp file is deleted at the end of run or in case of an error.

    # All sections of PDFREP return a status flag and error message this is so that the Package
    # will not fall over and leave the error coding to the individual programmer.
    # Nice open source let you do what you want huh.

    my $filenam = "pdftest1";
    my $filedir = "../";
    my $title   = "Test Document For JPG Files";
    my $author  = "Trevor Ward";

    ($status, $message) = $pdfrep->heading($filenam, $filedir, $title, $author);

    # This is the error checking if failed files have to be closed and deleted by the PDFREP Package.
    # This is done by calling the crashed part of the package with no parameters

    if (!$status)
    {
        print "<BR><BR><h4>PDF FILE CREATION FAILED </h4>- $message<BR><BR>\n";
        ($status, $message) = $pdfrep->crashed();
        print "$status - $message<BR>\n";
    }
    else
    {
        print "$status - $message<BR>\n";
    }

    # The next item to setup in generating the pdf file is the fonts used throughout the document.
    # This is done by calling FONTSET with two parameters.
    # 1 = The font reference name - this will be used when writing out the data
    # 2 = The font to be used i.e. Arial or Helvetica etc.
    #
    # For this example two fonts will be used as per the example above.

    ($status, $message) = $pdfrep->fontset('F1','Helvetica');

    if (!$status)
    {
        print "<BR><BR><h4>PDF FONT CREATION FAILED </h4>- $message<BR><BR>\n";
        ($status, $message) = $pdfrep->crashed();
        print "$status - $message<BR>\n";
    }
    else
    {
        print "$status - $message<BR>\n";
    }

    ($status, $message) = $pdfrep->fontset('F2','Helvetica-Bold');

    if (!$status)
    {
        print "<BR><BR><h4>PDF FONT CREATION FAILED </h4>- $message<BR><BR>\n";
        ($status, $message) = $pdfrep->crashed();
        print "$status - $message<BR>\n";
    }
    else
    {
        print "$status - $message<BR>\n";
    }

    # So now we have the PDF file opened and ready for input the fonts have been specified so now lets
    # start writing the data. OH Joy OH Rapture.
    # This is done by calling the Pagedata section of PDFREP. This section has various parameters
    # 1 The type of data passed
    # np = new page
    # nl = new line
    # nc = new column
    # Used to enable the columinsation of reports by using the offset field. Will only left
    # Justify so if require right justify user courier font and space pad front of data.
    # Allows the usage of different font and colours by column.
    # im = new image
    # You specify one of these as the first parameter passed to identify what your upto.
    # Data is written out one line at a time so try not to exceed the characters.
    # Always start with new page.

    # The other parameters passed are
    # 2  = The column offset . This is the amount of characters from the left hand column of the line.
    # 3  = The font size to be used with the font set later. It is the text point size standard is 12
    # 4  = The name of the font you want to use as previously set
    # 5  = The size of the font on the next data line to allow for correct data throws.
    # 6  = Italic 0 = No 1 = yes > 1 get some weird results.
    # 7  = Red colour
    # 8  = Green colour
    # 9  = Blue colour 0 0 0 = black 1 1 1 = white
    # 10 = The data. This is the textual data you require.
    # If image ten contains the name of the image width and hieght ie. I2 300 60

    # For a new page line there are two extra parameters required page size and orientation. The document
    # must have the same all the way through

    # 11 = Page Size LE = letter A4 = A4
    # 12 = Page Orientation PO = Portrait LA = Landscape

    # Leaving these blank defaults to Letter Portrait

    # Again it is a good idea to check the status after every line of data output just in case an error
    # occurs like run out of disc space. OK in this example its a bit of a pain but thats life normally
    # this would be a nice loop.

    ($status, $message) = $pdfrep->pagedata('np','0','12','F2','12','0','0','0','0','This is the first bit of text just to prove it to Mel','A4','PO');

    if (!$status)
    {
        print "<BR><BR><h4>PDF NEW PAGE CREATION FAILED </h4>- $message<BR><BR>\n";
        ($status, $message) = $pdfrep->crashed();
        print "$status - $message<BR>\n";
    }
    else
    {
        print "$status - $message<BR>\n";
    }

    ($status, $message) = $pdfrep->pagedata('nl','0','12','F1','12','0','0','0','0','This is the second bit of text');

    if (!$status)
    {
        print "<BR><BR><h4>PDF NEW DATA LINE CREATION FAILED </h4>- $message<BR><BR>\n";
        ($status, $message) = $pdfrep->crashed();
        print "$status - $message<BR>\n";
    }
    else
    {
        print "$status - $message<BR>\n";
    }

    ($status, $message) = $pdfrep->pagedata('nl','0','10','F1','10','0','0','0','0','This is the third bit of data');
    ($status, $message) = $pdfrep->pagedata('nc','150','10','F1','10','0','0','0','0','This is the four bit of text');
    ($status, $message) = $pdfrep->pagedata('nc','300','10','F1','10','0','0','0','0','This is the five bit of text');
    ($status, $message) = $pdfrep->pagedata('nc','450','10','F1','10','0','0','0','0','This is the five bit text 2');
    ($status, $message) = $pdfrep->pagedata('nl','0','10','F1','10','0','1','0','0','This is the third bit of data');
    ($status, $message) = $pdfrep->pagedata('nc','150','10','F2','10','0','0','0','0','This is the four bit of text');
    ($status, $message) = $pdfrep->pagedata('nc','300','10','F2','10','0','0','0','0','This is the five bit of text');
    ($status, $message) = $pdfrep->pagedata('nl','0','10','F1','10','0','0','0','0','This is the third bit of data');
    ($status, $message) = $pdfrep->pagedata('nc','150','10','F1','10','0','0','0','0','This is the four bit of text');
    ($status, $message) = $pdfrep->pagedata('nc','300','10','F1','10','0','0','1','0','This is the five bit of text');
    ($status, $message) = $pdfrep->pagedata('nl','0','10','F2','10','0','0','0','0','This is the third bit of data');
    ($status, $message) = $pdfrep->pagedata('nc','150','10','F2','10','0','0','0','0','This is the four bit of text');
#    ($status, $message) = $pdfrep->pagedata('nc','300','10','F2','10','0','0','0','0','Teo');
    ($status, $message) = $pdfrep->pagedata('nc','450','10','F1','10','0','1','0','0','FCUK');
#    ($status, $message) = $pdfrep->pagedata('nl','0','12','F1','12','0','0','0','0','This is the third bit of data');
#    ($status, $message) = $pdfrep->pagedata('nl','0','12','F1','12','0','0','0','0','This is the four bit of text');
#    ($status, $message) = $pdfrep->pagedata('nl','0','12','F2','12','0','0','0','0','This is the five bit of text');
    ($status, $message) = $pdfrep->pagedata('nl','0','10','F1','10','0','0','0','0','This is the six bit of text');
#    ($status, $message) = $pdfrep->pagedata('nl','0','12','F1','12','0','0','0','0','This is the seven bit of text');
#    ($status, $message) = $pdfrep->pagedata('nl','0','12','F1','12','0','0','0','0','This is the eight bit of text');
#    ($status, $message) = $pdfrep->pagedata('nl','0','12','F1','12','0','0','0','0','This is the ninth bit of text');
#    ($status, $message) = $pdfrep->pagedata('nl','0','12','F1','12','0','0','0','0','This is the tenth bit of text');
    ($status, $message) = $pdfrep->pagedata('np','0','12','F2','12','0','0','0','0','This is the first bit of text','A4','PO');

    # The following code uses the Chart module from CPAN to generate a PNG file which is a graph
    # of data. This is predomently why PDFREP was written.

    use Chart::Composite;
    my $obj = new Chart::Composite (600,350);

    my %hash=('transparent'     => 'true',
              'text_space'      => 5,
              'title'           => 'POWERTRAIN QUALITY STATUS Average over 9 CIPE Quality Tools',
              'x_label'         => 'Date',
              'y_label'         => '% Complete',
              'legend'          => 'bottom',
              'legend_labels'   => ['Target',
                                    'Cat A Systems',
                                    'Other Systems',
                                    'Recovery Plan',
                                    'Checkpoints'],
              'tick_len'        => 3,
              'y_ticks'         => 11,
              'max_val'         => 100,
              'min_val'         => 0,
              'pt_size'         => 18,
              'colors'          => {'x_grid_lines' => [255,255,255],
                                    'y_grid_lines' => [0,0,0]},
              'grey_background' => 'false',
              'grid_lines'      => 'false',
              'brush_size'      => 3,
              'pt_size'         => 20,
              'composite_info'  => [['LinesPoints',[1,3,5]],['LinesPoints',[2,4]]],
              'same_y_axes'     => 'true',
              'no_cache'        => 'true');

    my @xticks=(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34);
    my @data0=(68,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,80,undef,undef,undef,undef,undef,80,undef);#Target
    my @data1=(28,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,35,40,46,55,55,55,58,58);#Cat A Systems
    my @data2=(22,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,35,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,80);#Recovery Plan
    my @data3=(22,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,35,35,38,42,44,44,46,47);#Other Systems
    my @data4=(0,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,undef,0,undef,undef,undef,undef,undef,0,undef);#Checkpoints
    my @stuff=\(@xticks,@data0,@data1,@data2,@data3,@data4);

    $obj->set(%hash);
    $obj->png('../test1.png',\@stuff);

    # Using this PNG image now we can display it.

    # the include image includes the image into the PDF file. It uses the physical file
    # on disc and can then be used at any point on any page.

    $pdfrep->include_image('I1','test1.png','600','350', 'png', '../');

    # This is the im option for displaying page data

    ($status, $message) = $pdfrep->pagedata('im','0','12','F1','12','0','0','0','0','I1 600 350');

#    ($status, $message) = $pdfrep->include_image('I2','cipetitle.jpg','300','60', 'jpg', '../');
#    ($status, $message) = $pdfrep->pagedata('im','100','12','F1','12','0','0','0','0','I2 300 60');

    # OK so are all the data lines and pages written now. Hope so because it's time to write the
    # PDF file. This might take a minute because it's playing with reading the temporary file and
    # outputting this to the PDF File, It will also build the page cross reference list and all
    # the required trailer records just for fun or to make it easier for the programmer to remember what
    # is required when producing a PDF like the data haha.
    # So you think all the parameters are over well think again
    # 1 = Page size LE = Letter and A4 = A4 defaults to letter
    # 2 = Page orientation PO = Portrait and LA = Landscape

    ($status, $message) = $pdfrep->writepdf('A4','PO');

    my $fileout = $filedir . $filenam . ".pdf";

    print br();
    print "\n\n";
    print ("<A href=$fileout>");
    print ("<FONT COLOR='000000'><B>");
    print ("PDF file is ", $filenam);
    print ("</B></FONT>");
    print ("</A>");
    print "\n\n";

    print end_html();  
    print "\n\n";
}
1;