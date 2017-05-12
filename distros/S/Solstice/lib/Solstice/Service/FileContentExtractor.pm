package Solstice::Service::FileContentExtractor;

# $Id: LoginRealm.pm 2257 2005-05-19 17:31:38Z jlaney $

=head1 NAME

Solstice::Service::FileContentExtractor - Extract text content from a variety of file types.

=head1 SYNOPSIS

    use Solstice::Service::FileContentExtractor;

    my $service = Solstice::Service::FileContentExtractor->new();
   
    # Adding an extractor for a specific file type:
    $service->addExtractor({
        type     => 'text/plain',
        function => \&extract_text_function, 
    });
   
    my $file = Solstice::Resource::File::BlackBox();
    
    # Extracting content from a file
    my $text = $service->extract($file);
  
=head1 DESCRIPTION

=cut

use 5.006_000;
use strict;
use warnings;

use constant TRUE  => 1;
use constant FALSE => 0;

use base qw(Solstice::Service::Memory);

# Built-in extraction functions
my %default_extractors = ( 
    'text/plain'               => \&_extract_txt,
    'text/html'                => \&_extract_html,
    'application/pdf'          => \&_extract_pdf,
    'application/msword'       => \&_extract_doc,
    'application/excel'        => \&_extract_xls,
    'application/mspowerpoint' => \&_extract_ppt,
    'audio/mpeg'               => \&_extract_mp3,
    'application/rtf'          => \&_extract_rtf,
    'text/xml'                 => \&_extract_txt,
);

=head2 Export

None by default.

=head2 Methods

=over 4

=cut

=item new()

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->_init();
    
    return $self;
}

=item addExtractor(\$params)

Add a content extractor function, The passed %params is
    {
        type     => 'content type',
        function => a reference to a function,
    }

=cut

sub addExtractor {
    my $self = shift;
    my $params = shift || {};

    my $type     = $params->{'type'};
    my $function = $params->{'function'};

    return FALSE unless defined $type and defined $function;
    
    my $extractors = $self->get('extractors') || {};

    my $synonyms = $self->getContentTypeService()->getSynonymsForContentType($type);
    for my $content_type (@$synonyms) {
        $extractors->{$content_type} = $function;
    }
    
    $self->set('extractors', $extractors);
    
    return TRUE;
}

=item extract($file)

=cut

sub extract {
    my $self = shift;
    my $file = shift;
    return unless defined $file and $file->getContentType();

    my $function = $self->get('extractors')->{$file->getContentType()};
    return unless $function;

    my $text= '';
    eval { $text = &$function($file) };
    warn $@ if ($@ && $self->getConfigService()->getDevelopmentMode());

    # Condense the content to space-delimited tokens
    $text =~ s/\s+/ /g;

    return $text;
}

=back

=head2 Private Methods

=over 4

=cut

=item _init()

=cut

sub _init {
    my $self = shift;

    return if $self->get('extractors_initialized');

    for my $type (keys %default_extractors) {
        $self->addExtractor({
            type     => $type,
            function => $default_extractors{$type},
        });
    }

    $self->set('extractors_initialized', TRUE);

    return;
}

=back

=head2 Private Functions

=over 4

=cut

## Built-in extractors
## no critic

## Plain TXT
sub _extract_txt {
    my $file = shift;

    my $text = '';
    open(my $FILE, '<', $file->getPath())
        or die "Cannot open ".$file->getPath().": $!";

    my @lines = <$FILE>;
    $text = join("\n", @lines);
    close($FILE);

    return $text;
}

## HTML
sub _extract_html {
    my $file = shift;

    my $tree = HTML::TreeBuilder->new();

    $tree->parse_file($file->getPath());
    my $text = $tree->as_text();

    $tree->delete();

    return $text;
}

## PDF
sub _extract_pdf {
    my $file = shift;

    Solstice->new()->loadModule('CAM::PDF');

    my $document = CAM::PDF->new($file->getPath());

    my $text = '';
    for my $page (1 .. $document->numPages()) {
        if (my $ptext = $document->getPageText($page)) {
            $text .= "$ptext\n";
        }
    }
    return $text;
}

## MSWord DOC
sub _extract_doc {
    my $file = shift;

    my $config = Solstice::ConfigService->new();
    my $catdoc = $config->get('catdoc_path');
    my $charsets = $config->get('charset_path');
    return '' unless $catdoc and -e $catdoc;

    my $path = $file->getPath();
    my $charset_flag = $charsets ? "-z $charsets" : '';
    my $text = `$catdoc -s 8859-1 $charset_flag $path`;
    return $text;
}

## MSExcel XLS
sub _extract_xls {
    my $file = shift;

    Solstice->new()->loadModule('Text::CSV_XS');

    my $config = Solstice::ConfigService->new();
    my $xls2csv = $config->get('xls2csv_path');
    my $charsets = $config->get('charset_path');
    return '' unless $xls2csv and -e $xls2csv;

    my $path = $file->getPath();
    my $charset_flag = $charsets ? "-z $charsets" : '';
    my $csv = `$xls2csv -s 8859-1 $charset_flag $path`;

    my $parser = Text::CSV_XS->new({binary => TRUE});

    my $text = '';
    my @lines = split(/\n+/, $csv);
    for my $line (@lines) {
        $line =~ s/^\s+//g;
        next unless $parser->parse($line);
        $text .= join(' ', $parser->fields())."\n";
    }
    return $text;
}

## MSPowerPoint PPT
sub _extract_ppt {
    my $file = shift;

    my $config = Solstice::ConfigService->new();
    my $catppt = $config->get('catppt_path');
    my $charsets = $config->get('charset_path');
    return '' unless $catppt and -e $catppt;

    my $path = $file->getPath();
    my $charset_flag = $charsets ? "-z $charsets" : '';
    my $text = `$catppt -s 8859-1 $charset_flag $path`;
    return $text;
}

## MP3
sub _extract_mp3 {
    my $file = shift;

    Solstice->new()->loadModule('MP3::Info');

    my $metadata = MP3::Info::get_mp3tag($file->getPath());

    my $text = '';
    for my $value (values %$metadata) {
        next if (!defined $value || ref $value);
        $text .= "$value\n";
    }
    return $text;
}

## RTF
sub _extract_rtf {
    my $file = shift;

    Solstice->new()->loadModule('RTF::Lexer');

    my $parser = RTF::Lexer->new(in => $file->getPath());
    
    my $text = my $token = '';
    do {
        $token = $parser->get_token();

        if ($token->[0] == $parser->ENHEX) {
            $text .= pack('H2', $token->[1]);
        } elsif ($token->[0] == $parser->CSYMB && $token->[1] =~ /^\s+$/) {
            $text .= $token->[1];
        } elsif ($token->[0] == $parser->PTEXT || $token->[0] == $parser->ENBIN) {
            $text .= $token->[1];
        }
    } until $parser->is_stop_token($token);
    return $text;
}

## XML, Not in use - we're just using the txt extractor for xml files
sub _extract_xml {
    my $file = shift;
    
    Solstice->new()->loadModule('XML::LibXML');

    my $parser = XML::LibXML->new();

    my $doc = $parser->parse_file($file->getPath());

    my $text = $doc->toString();

    return $text;
}


1;

__END__

=back

=head1 AUTHOR

Educational Technology Development Group E<lt>catalyst@u.washington.eduE<gt>

=head1 VERSION

$Revision: 597 $

=head1 SEE ALSO

=cut

=head1 COPYRIGHT

Copyright 1998-2007 Office of Learning Technologies, University of Washington

Licensed under the Educational Community License, Version 1.0 (the "License");
you may not use this file except in compliance with the License. You may obtain
a copy of the License at: http://www.opensource.org/licenses/ecl1.php

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied.  See the License for the
specific language governing permissions and limitations under the License.

=cut
