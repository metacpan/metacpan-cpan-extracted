
# Download source from http://tidy.sourceforge.net/docs/Overview.html#Download
# http://tidy.sourceforge.net/
### XML TOOLS !
# http://www.garshol.priv.no/download/xmltools/cat_ix.html#SC_GNConv

# http://www.chami.com/html-kit/
# --output-xml yes --output-xhtml yes --add-xml-decl yes



package WWW::Scraper::TidyXML;
$VERSION = sprintf("%d.%02d", q$Revision: 1.05 $ =~ /(\d+)\.(\d+)/);

use strict;
my $DaveRaggettVersion = 0; # Different versions of tidy.exe require different processing.

{ package WWW::Scraper::TidyXML::_struct_;
use Class::Struct;
    struct ( 
                 'm_asXML'   => '$'
                ,'m_asString'  => '$'
                ,'m_isTidyd' => '$'        # indicates this string has been "Tidy.exe"-d.
                ,'m_xmlParser' => '$'
                ,'m_TRACE' => '$'
                ,'m_context' => '$'
                ,'m_found_context' => '$'
                ,'artifactFolder' => '$'
                ,'parentScraper' => '$'
                ,'frameType' => '$'
           );
}
use base qw(WWW::Scraper::TidyXML::_struct_);

sub new {
    my $self = new WWW::Scraper::TidyXML::_struct_;
    bless $self, shift;
    
    my $scraper;
    my $string = '';
    for my $parm ( @_ ) {
        if ( $parm and not ref $parm ) {
            open TMP, "<$parm" or die "Can't open '$parm': $!\n";
            my $tmp = join '', <TMP>; close TMP;
            $string = \$tmp;
        } else {
            if ( ref($parm) eq 'HASH' ) {
                map { $self->$_($$parm{$_}) } keys %$parm;
            } elsif ( ref($parm) =~ m/WWW::Scraper/ ) {
                $self->parentScraper($parm);
            } elsif ( ref($parm) eq 'SCALAR' ) {
                $string = $parm;
            } else {
                $string = \$parm;
            }
        }
    }

    # Stash the original HTML into the artifacts folder.
    if ( $string && $self->artifactFolder && (my $scraper = $self->parentScraper) ) {
        my $artName = $self->artifactFolder().'/'.$scraper->{'scraperName'}.'_pg_'.$scraper->pageNumber.'.htm';
        open TMP, ">$artName" || warn "Can't open '$artName' to write: $!";
        print TMP $$string;
        close TMP;
    }

    if ( ($self->frameType eq 'TidyXML') and $string and not ($$string =~ m-<meta name="generator" content="HTML Tidy, see www.w3.org" />-s) ) {
        open TMP, ">temp.html" or die "Can't open 'temp.html': $!";
        print TMP fixupHtmlForTidy($string);
        close TMP;
        
        my $rslt;
        if ( $self->getTidyVersion() == 1 ) {
            $rslt = `tidy -upper -asxml -numeric -clean temp.html 2>temp.err`;
            unless ( $rslt ) {
                open TMP, "<temp.err"; my $err = join '',<TMP>; close TMP;
                unless ( $err =~ m/Parsing "temp\.html"/s ) {
                    warn "$err";
                    die "This Scraper engine requires 'Tidy' to scrub HTML before parsing.\nGet this program from 'http://tidy.sourceforge.net/docs/Overview.html#Download'\n";
                }
#                warn "$err";
            }
            unlink 'temp.html';
            $string = \$rslt;
        } elsif ( $WWW::Scraper::TidyXML::DaveRaggettVersion == 2 ) {
            $rslt = `tidy -upper -asxml -numeric --show-warnings no --write-back yes --clean yes --force-output yes --error-file temp.err temp.html >tidy.stdout 2>tidy.stderr`;
            if ( $? ) {
                open TMP, "<temp.err"; my $err = join '',<TMP>; close TMP;
                unless ( $err =~ m/Parsing "temp\.html"/s ) {
                    warn "$err";
                    die "This Scraper engine requires 'Tidy' to scrub HTML before parsing.\nGet this program from 'http://tidy.sourceforge.net/docs/Overview.html#Download'\n";
                }
#                warn "$err";
            }
            open TMP, "<temp.html" or die "Can't reopen 'temp.html': $!";
            my $xml = join '',<TMP>;
            $string = \$xml;
            close TMP;
            unlink 'temp.html';
        }
        else {
            die "This Scraper engine requires 'Tidy' to scrub HTML before parsing.\nGet this program from 'http://tidy.sourceforge.net/docs/Overview.html#Download'\n";
        }
        # Stash the tidied XML into the artifacts folder.
        if ( $self->artifactFolder && (my $scraper = $self->parentScraper) ) {
            my $artName = $self->artifactFolder().'/'.$scraper->{'scraperName'}.'_pg_'.$scraper->pageNumber.'.xml';
            open TMP, ">$artName" || warn "Can't open '$artName' to write: $!";
            print TMP $$string;
            close TMP;
        }
    }

    $self->m_asString($string);
    $self->m_isTidyd($WWW::Scraper::TidyXML::DaveRaggettVersion);
    return $self;
}

# Here are some common rewrites that should be done before handing the string to tidy.exe.
sub fixupHtmlForTidy {
    my ($string) = @_;
    $$string =~ s-<noframe>.*?</noframe>--gsi;
    return $$string;
}


# Extract the given xml path from the given TidyXML. Return reference to the string version.
sub asString {
    my ($self, $xmlPath) = @_;

    unless ( defined $xmlPath ) {
        my $result;
        if ( $self->m_context() ) {
            my $xml;
            $xml = $self->m_context()->toString();
            $result = \$xml;
        } else {
            $result = $self->m_asString();
        }
        return $result;
    }
    
    my $node;
    
    ####
    #### XML::XPath-wise parsing . . .
    ####
    # <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
    #return \undef unless $parsedXML = $elements->item($count-1);
    my $parsedXML = $self->m_asXML();
    unless ( $parsedXML ) {
        # Just-in-time parsing of the TidyXML string.
        my $xml = $self->m_asString();
        return \undef unless $$xml;
        $$xml =~ s-<!DOCTYPE.*?>--s;
        eval { 
            use XML::XPath;
            $parsedXML = XML::XPath->new('xml' => $$xml);
            $self->m_asXML($parsedXML);
            $self->m_context('');
        };
        die "Can't XML parse : $@" if $@;
        $self->m_asXML($parsedXML);
    }

    my $context = $self->m_context();
    $context = undef unless $context;
    my $nodeset = $parsedXML->find($xmlPath, $context); # find all paragraphs
    my @node = $nodeset->get_nodelist();
    $node = $node[0];
    
    unless ( $parsedXML = $node ) {
        $self->m_found_context('');
        return \undef;
    }

    $self->m_found_context($node);

    my $result = $parsedXML->toString();
    return \$result;
}

# Extract the given xml path from the given TidyXML. Return the xml version.
sub asXML { 
    my ($self, $xmlPath) = @_;

    return $self->m_asXML() unless defined $xmlPath;
    
    die "TidyXML::asXML(path) is not implemented.";
}



# Returns the marked up text from the referenced string, as designated by the given tag.
# This algorithm extracts the contents of the first <$tag> element it encounters,
#   taking into consideration that it may contain <$tag> elements within it.
# It removes the marked text from the original string, strips off the markup tags,
#   and returns that result.
# (if wantarray, will return result and first tag, with brackets removed)
#
sub getMarkedText {
    my ($self, $tag, $withContent) = @_;

    my ($sub_string, $theRest) = WWW::Scraper::getMarkedText(undef, $tag, $self->asString(), $withContent);

    $self->m_asXML(''); # By calling getMarkedText(), we lost any pre-parsing XPath may have set up.
    $self->m_context('');
    $self->m_found_context('');

    return ($sub_string, $theRest) if wantarray;
    return $sub_string;
}

my $AttributeGrabber = qr/(?:\s*\w[\w\d]*=(?:(?:"(?:(?:\\")|(?:[^"]))*")|(?:'(?:(?:\\')|(?:[^']))*')|(?:[^'"][^ >]*)))/;
sub Attributes {
    my ($self, $attrs) = @_;
    
    my $attributes = {};
    my (@attrs) = ($attrs =~ m{($AttributeGrabber)}gs);
    for ( @attrs ) {
        my ($name, $attr) = (m{\s*(\w[\w\d]*)=(.*)$});
        $attr = '' if !defined $attr;
        $attr =~ s{^'(.*)'$}{$1} unless $attr =~ s{^"(.*)"$}{$1};
        $attributes->{lc $name} = $attr;
    }
    return $attributes;
}

sub getMarkedTextAndAttributes {
    my ($self, $tag, $withContent) = @_;
    
    my ($sub_string, $attrs) = $self->getMarkedText($tag, $withContent);
    return undef unless $sub_string;

    my $attributes = $self->Attributes($attrs);    
    return ($sub_string, $attributes) if wantarray;
    return $attributes;
}

sub isNotTestable {
   my ($self, $scraperEngine) = @_;
    my $rslt = `tidy -version 2>tidy.stderr`;
    if ( $? ) {
        return ($scraperEngine?$scraperEngine:"This Scraper engine")." requires 'HTML Tidy' to scrub HTML before parsing.\nGet this program from 'http://tidy.sourceforge.net/docs/Overview.html#Download'\nMake sure it is in your execution search path.\n";
    }
    return '';
}

sub getTidyVersion {

    unless ( $WWW::Scraper::TidyXML::DaveRaggettVersion ) {
        my $rslt = `tidy -version 2>tidy.version`;
        if ( $? ) {
            $WWW::Scraper::TidyXML::DaveRaggettVersion = -1;
        } else {
            open TMP, "<tidy.version"; $rslt = join "\n",<TMP>; close TMP;
            # Dave Raggett
            #HTML Tidy release date: 30th April 2000
            #See http://www.w3.org/People/Raggett for details
            if ( $rslt =~ m{HTML Tidy release date: 30th April 2000} ) {
                $WWW::Scraper::TidyXML::DaveRaggettVersion = 1;
            } else {
                $WWW::Scraper::TidyXML::DaveRaggettVersion = 2;
            }
        }
    }
    return $WWW::Scraper::TidyXML::DaveRaggettVersion;
}

# Pick an input parameter according to the version of tidy.exe.
sub accordingToTidyVersion {
    WWW::Scraper::TidyXML::getTidyVersion();
    if ( $WWW::Scraper::TidyXML::DaveRaggettVersion > 0 ) {
        return $_[$WWW::Scraper::TidyXML::DaveRaggettVersion-1];
    } else {
        return undef;
    }
}
1;



__END__
=pod

=head1 NAME

WWW::Scraper::TidyXML - TidyXML and XPath support for Scraper.

=head1 SYNOPSIS

    Use WWW::Scraper::TidyXML 

in your Scraper module.

Use 'TidyXML' and 'XPath' options in the scraperFrame to locate relevant regions of the results and details pages.

=head1 DESCRIPTION

One of the easiest ways to implement a Scraper engine for a new search engine is to use the "TidyXML" method.

The basic idea behind TidyXML is to convert the search engine's results page into XML.
Then it is *much* easier to locate regions in the results page that contain the relevant data.

Here is how it works:

1. Process the results page through the Tidy program (available at tidy.sourceforge.com).

2. Convert the search engine's results page to XML with Tidy (via 'TidyXML' option in the scraperFrame).

3. Select relevant data via the 'XPath' scraperFrame operation (see XPath definition at http://www.w3.org/TR/xpath).

Most search engines generate remarkably ill-structured HTML. The Tidy program fixes that up,
converts it to well-formed XML, making it accessible to Scraper's XML parsing operations.
As XML, it is much easier to identify the relevant regions.

To initially develop a TidyXML-based Scraper module, you, as an implementor,
manually process a results page through Tidy (using the -asxml option).
This produces an XML file that can be viewed with any XML viewer. 
Internet Explorer or Netscape Navigator work well for this
(my personal favorite is XMLSpy. Try toolbar 'Table'.'Display as Table' option for revealing views
 - get a 30-day free trial at www.xmlspy.com).

Browse the XML to visually identify the relevant regions.
Then code these regions into your new engine implementation via XPath notation.
E.G., the first <TABLE> of the converted HTML would be selected by

	/html/body/table

Skipping the first <TABLE> to select the second table would be selected

	/html/body/table[2]

You would then pass this <TABLE> to your next phase, where <TR>s in that table would be selected by

	/table/tr

and <TD>'s within that <TR> might be selected

	/tr/td[1]
	/tr/td[2]
	etc.

Complete the coding of your new engine implementation by specifying TidyXML conversion in the ScraperFrame.
This causes Scraper repeat these Tidy conversions on each results page it processes.

=head1 EXAMPLES

Here is an example scraperFrame from a simple implementation for Dogpile.com

       [ 'TidyXML',
          [ 
            [ 'XPath', '/html/body',
              [
                [ 'HIT*' ,
                  [
                    [ 'XPath', '/body/p[hit()]',
                      [
                         [ 'A', 'url', 'title' ]
                        ,[ 'XPath', '/p/i', 'company' ]
                      ]
                    ],
                  ]
                ]
              ]
            ]
          ]
       ];

This took me a leisurely 30 minutes to discover and implement.
Of course, Dogpile is remarkably well formed to begin with, 
and even there a complete implementation does require a few more touches. 
Take a look at Dogpile.pm for further details.

=head1 SPECIAL THANKS

=over 8

=item To Dave Raggett <dsr@w3.org> (original author), and to Tor-Ivar Valåmo, and his SourceForge team, for TidyHTML.

Without this tool, I'd have wasted untold millennia trying to keep up with many search engines.
This tool, along with XPath and XmlSpy, makes configuring Scraper modules to new results pages extremely easy.
See TidyHTML at http://sourceforge.net/projects/tidyhtml/.

=back

=head1 AUTHOR and CURRENT VERSION

C<WWW::Scraper::TidyXML> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2002 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut



