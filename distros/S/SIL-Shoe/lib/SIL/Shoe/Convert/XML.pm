package SIL::Shoe::Convert::XML;

use IO::File;

sub optlist
{ "a:d:fix:"; }

sub new
{
    my ($class, $opts, $settings, $type, $sh, $outfname) = @_;
    my ($fh) = IO::File($outfname, "<:utf8") || die "Can't create $outfname";

    $opts->{'a'} ||= ($opt_m ? '_' : 'value');
    my ($self) = {
        'settings' => $settings,
        'type' => $type,
        'outf' => $fh,
        'opts' => $opts
    };
    $fh->print '<?xml version="1.0" encoding="UTF-8"' . ($opts->{'i'} ? ' standalone="yes"' : '') . ' ?>' . "\n";
    $fh->print '<?xml-stylesheet type="text/xsl" href="' . $opts->{'x'} . "\"?>\n" if ($opts->{'x'});
    return bless $self, ref $class || $class;
}

sub init_dtd
{
    my ($self, $root) = @_;
    my ($fh);
    
    if (defined $self->{'opts'}{'d'})
    {
        $self->{'dtdfh'} = IO::File($self->{'opts'}{'d'}, ">:utf8") || die "Can't create $self->{'opts'}{'d'}";
        $self->{'dtdfh'}->print('<?xml version="1.0" encoding="UTF-8" ?>' . "\n");
    }
    elsif (defined $self->{'opts'}{'i'})
    { $self->{'dtdfh'} = $self->{'outfh'}; }
    else
    { return undef; }

    $fh = $self->{'dtdfh'};

    $fh->print("<!DOCTYPE shoebox [\n");
    if ($self->{'opts'}{'f'})
    {
        $fh->print("<!ELEMENT shoebox (shoebox-format, ($root)*)>\n");
        $fh->print(<<'EOT');
<!ELEMENT shoebox-format (marker)*>
<!ELEMENT marker (language, font, interlinear?, original-marker?)>
<!ATTLIST marker 
    name CDATA #REQUIRED
    style (char | par) #REQUIRED>

<!ELEMENT language (#PCDATA)>

<!ELEMENT font (#PCDATA)>
<!ATTLIST font 
        size CDATA #REQUIRED
        style CDATA #IMPLIED
        color CDATA #IMPLIED>
        
<!ELEMENT interlinear EMPTY>
<!ATTLIST interlinear level CDATA #IMPLIED>

<!ELEMENT original-marker (#PCDATA)>

EOT
    }
    else
    { $fh->print("<!ELEMENT shoebox ($root)*>\n"); }

    $fh->print("<!ATTLIST shoebox type CDATA #IMPLIED>\n\n");
}

sub out_dtd
{
    my ($self, $mult, $mark, @list) = @_;

    return unless ($self->{'dtdfh'});
    push(@list, $self->{'opts'}{'a'}) if ($mult);
    if (@list)
    {
        $self->{'dtdfh'}->print("<!ELEMENT $mark (" . join("|", @list). ")*>\n");
        $self->{'dtdfh'}->print("<!ATTLIST $mark $self->{'opts'}{'a'} CDATA #IMPLIED>\n") unless ($mult);
    }
    else
    { $self->{'dtdfh'}->print("<!ELEMENT $mark (#PCDATA)>\n");
}

sub end_dtd
{
    my ($self) = @_;

    return unless ($self->{'dtdfh'});
    $self->{'dtdfh'}->print("]>\n\n");
    $self->{'dtdfh'}->close unless ($self->{'dtdfh'} eq $self->{'outfh'});
    $self->{'dtdfh'} = undef;
}



sub init_format
{
    my ($self) = @_;
    $self->{'outf'}->print("<shoebox-format>\n");
}

sub end_format
{
    my ($self) = @_;
    $self->{'outf'}->print("</shoebox-format>\n");
}

sub output_format
{
    my ($self, $sfm, $marker, $lang, $font, $charpar, $interlin) = @_;
    my ($fh) = $self->{'outf'};

    $fh->print("  <marker name=\"$marker\" style=\"$charpar\">\n";
    $fh->print("    <language>$lang</language>\n";
    $fh->print("    <font size='$font->{'size'}'");
    $fh->print(" style='$font->{'bold'}$font->{'italic'}'") if ($font->{'bold'} || $font->{'italic'});
    $fh->print(" color='$font->{'color'}'") if ($font->{'color'});
    $fh->print(">$font->{'name'}</font>\n");
    $fh->print("    <interlinear level='$interlin'/>\n") if ($interlin);
    $fh->print("    <original-marker>" . protect($sfm) . "</original-marker>\n") if ($sfm ne $marker);
    $fh->print("  </marker>\n");
}

sub init_interlin
{
    my ($self) = @_;
    $self->{'outf'}->print((" " x $self->{'indent'}) . "<interlinear-block>\n");
    $self->{'indent'} += 2;
}

sub end_interlin
{
    my ($self) = @_;
    $self->{'indent'} -= 2;
    $self->{'outf'}->print((" " x $self->{'indent'}) . "</interlinear-block>\n");
}

sub init_marker
{
    my ($self, $mult, $marker, $dat, $children, $noinline) = @_;
    my ($fh) = $self->{'outfh'};

    if ($mult)
    {
        $fh->print(" " x $self->{'indent'});
        $fh->print("<$marker>\n");
        $self->{'indent'} += 2;
        $fh->print(" " x $self->{'indent'});
        $fh->print("<$self->{'opts'}{'a'}>" . protect($dat)) if ($dat || !$noinline);
        if ($noinline)
        {
            $fh->print("</$self->{'opts'}{'a'}\n");
            unless ($children)
            {
                $self->{'indent'} -= 2;
                $fh->print(" " x $self->{'indent'});
                $fh->print("</$marker>\n");
            }
        }
        else
        {
            $self->{'inline'} = 1;
            unshift(@{$self->{'stack'}, $self->{'opts'}{'a'});
            unshift(@{$self->{'stack'}, $marker);
        }
    }
    elsif ($children)
    {
        $fh->print(" " x $self->{'indent'});
        $self->{'indent'} += 2;
        $fh->print("<$marker $self->{'opts'}{'a'}=\"". protect($dat) . "\">\n";
        unshift (@{$self->{'stack'}, $marker);
    }
    elsif (!$dat)
    {
        $fh->print(" " x $self->{'indent'});
        $fh->print("<$marker/>\n");
    }
    else
    {
        $fh->print(" " x $self->{'indent'});
        $fh->print("<$marker>" . protect($dat) . "</$marker>\n");
    }
}

sub end_marker
{
    my ($self) = @_;
    my ($fh) = $self->{'outf'};

    return unless (scalar @{$self->{'stack'}});
    if ($self->{'inline'})
    { $self->{'inline'} = 0; }
    else
    {
        $self->{'indent'} -= 2;
        $fh->print(" " x $self->{'indent'});
    }
    $fh->print("</" . shift(@{$self->{'stack'}}) . ">\n");
}

sub start_inline
{
    my ($self, $marker) = @_;
    $self->{'outf'}->print("<$marker>");
}

sub out_inline
{
    my ($self, $dat) = @_;
    $self->{'outf'}->print(protect($dat));
}

sub end_inline
{
    my ($self, $marker) = @_;
    $self->{'outf'}->print("</$marker>\n");
}
