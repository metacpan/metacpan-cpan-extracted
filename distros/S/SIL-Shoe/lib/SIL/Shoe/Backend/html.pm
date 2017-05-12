package SIL::Shoe::Backend::html;

sub new
{
    # perhaps need to open an output file here?
    # also may need configuration for css
    my ($class, $outfile, $css, $props) = @_;
    my ($self) = {};
    my ($ofh);

    if ($outfile)
    { $ofh = IO::File->new($outfile, ">:utf8") || die "Can't create $outfile"; }
    else
    { $ofh = IO::File->new(">&STDOUT") || die "Can't dup stdout"; }

    $self->{'ofh'} = $ofh;
    
$ofh->print(<<"EOT");
<html xmlns:v="urn:schemas-microsoft-com:vml"
xmlns:o="urn:schemas-microsoft-com:office:office"
xmlns:w="urn:schemas-microsoft-com:office:word"
xmlns="http://www.w3.org/TR/REC-html40">
<head>
<meta http-equiv='Content-Type' content="text/html; charset=utf-8"/>
<meta name='ProgId' content='Word.Document'/>
<meta name='Generator' content="Microsoft Word 10"/>
<meta name='Originator' content="Microsoft Word 10"/>
EOT

if ($css)
{ $ofh->print("<link rel='stylesheet' href='$css' type='text/css' media='all'/>\n"); }

$ofh->print(<<"EOT");
</head>
<body lang=EN-US>
EOT

    return bless $self, $class;
}

sub start_section
{
    my ($self, $type, $name) = @_;
}

sub end_section
{
    my ($self, $type, $name) = @_;
}

sub start_letter
{
    my ($self) = @_;
    my ($ofh) = $self->{'ofh'};
    
    if ($self->{'curr_para'})
    { 
        $ofh->print("  </p>\n");
        $self->{'curr_para'} = 0;
    }
    
    if ($self->{'curr_sect'})
    { $ofh->print("</div>\n"); }
    
    $ofh->print("<div class='SectionHead' style='page:single'>\n");
    $self->{"curr_sect"} = 1;
}

sub end_letter
{
    my ($self) = @_;

    my ($ofh) = $self->{'ofh'};
    
    if ($self->{'curr_para'})
    { 
        $ofh->print("  </p>\n");
        $self->{'curr_para'} = 0;
    }
    
    if ($self->{'curr_sect'})
    { $ofh->print("</div>\n"); }

    $ofh->print("<br clear='all' style='page-break-before:auto;mso-break-type:section-break'/>\n");
    $ofh->print("<div style='page:double'>\n");
    $self->{'curr_sect'} = 1;
}

sub new_para
{
    my ($self, $type) = @_;
    my ($ofh) = $self->{'ofh'};
    
    if ($self->{'curr_para'})
    { $ofh->print("  </p>\n"); }
    $ofh->print("   <p class='$type'>");
    $self->{'curr_para'} = 1;
    $self->{'start_para'} = 1;
}

sub output_tab
{
    my ($self) = @_;
    
    $self->{'ofh'}->print("<span style='mso-tab-count: 1'>&#xa0;</span>") unless ($self->{'start_para'});
}

sub output_space
{    
    my ($self) = @_;
    
    $self->{'ofh'}->print("&#xa0;") unless ($self->{'start_para'});
}

sub output_newline
{
    my ($self) = @_;

    $self->{'ofh'}->print("<br/>\n") unless ($self->{'start_para'});
}

sub output
{
    my ($self, $text) = @_;
    
    $self->{'ofh'}->print($text);
    $self->{'start_para'} = 0;
}

sub char_style
{
    my ($self, $style, $text) = @_;
    
    $self->{'ofh'}->print("<span class='$style'>$text</span>");
    $self->{'start_para'} = 0;
}

sub picture
{
    my ($self, $style, $fname) = @_;
}

sub finish
{
    my ($self) = @_;
    my ($ofh) = $self->{'ofh'};

    if ($self->{'curr_para'})
    {
        $ofh->print("  </p>\n");
        $self->{'curr_para'} = 0;
    }
    if ($self->{'curr_sect'})
    {
        $ofh->print("</div>\n");
        $self->{'curr_sect'} = '';
    }
    $ofh->print("</body></html>\n");
    $ofh->close;
}

1;
