use strict; use warnings;
package Stump::Heavy;

# What follows is an ongoing refactoring of Larry's original code as given to
# Ingy @ YAPC::Riga 2011:

use utf8;

my %COLOR = qw(
    S Red
    E Purple
    B Blue
    G Green
    C Cyan
    M Magenta
    Y Yellow
    O Orange
    R Red
    L Lavender
    P Purple
    K Black
    g Gray
    W White
);

binmode(STDIN, ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');


sub para2odp {

my $input = 'stump.input';
my $build = 'stump';
my $template = 'stump.odp';

die "Invalid template" unless -e $template;
system "mkdir $build; cd $build; unzip ../$template"
    unless -d $build;

open CONTENT, ">:utf8", "$build/content.xml"
    or die "Can't create $build/content.xml: $!";
system "rm -rf $build/Pictures/*";

my $text;
my @para;
{
    open IN, '<:utf8', $input or die "Can't open $input: $!";
    local $/ = "";
    chomp(@para = <IN>);
    close IN;
}

print CONTENT <<'END';
<?xml version="1.0" encoding="UTF-8"?>

<office:document-content xmlns:office='urn:oasis:names:tc:opendocument:xmlns:office:1.0' xmlns:rpt='http://openoffice.org/2005/report' grddl:transformation='http://docs.oasis-open.org/office/1.2/xslt/odf2rdf.xsl' xmlns:math='http://www.w3.org/1998/Math/MathML' xmlns:field='urn:openoffice:names:experimental:ooo-ms-interop:xmlns:field:1.0' xmlns:ooo='http://openoffice.org/2004/office' xmlns:form='urn:oasis:names:tc:opendocument:xmlns:form:1.0' xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:of='urn:oasis:names:tc:opendocument:xmlns:of:1.2' xmlns:dom='http://www.w3.org/2001/xml-events' xmlns:oooc='http://openoffice.org/2004/calc' xmlns:style='urn:oasis:names:tc:opendocument:xmlns:style:1.0' xmlns:script='urn:oasis:names:tc:opendocument:xmlns:script:1.0' xmlns:presentation='urn:oasis:names:tc:opendocument:xmlns:presentation:1.0' xmlns:tableooo='http://openoffice.org/2009/table' xmlns:css3t='http://www.w3.org/TR/css3-text/' xmlns:grddl='http://www.w3.org/2003/g/data-view#' xmlns:smil='urn:oasis:names:tc:opendocument:xmlns:smil-compatible:1.0' xmlns:dr3d='urn:oasis:names:tc:opendocument:xmlns:dr3d:1.0' xmlns:text='urn:oasis:names:tc:opendocument:xmlns:text:1.0' office:version='1.2' xmlns:number='urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0' xmlns:ooow='http://openoffice.org/2004/writer' xmlns:xforms='http://www.w3.org/2002/xforms' xmlns:xlink='http://www.w3.org/1999/xlink' xmlns:formx='urn:openoffice:names:experimental:ooxml-odf-interop:xmlns:form:1.0' xmlns:anim='urn:oasis:names:tc:opendocument:xmlns:animation:1.0' xmlns:table='urn:oasis:names:tc:opendocument:xmlns:table:1.0' xmlns:xhtml='http://www.w3.org/1999/xhtml' xmlns:officeooo='http://openoffice.org/2009/office' xmlns:draw='urn:oasis:names:tc:opendocument:xmlns:drawing:1.0' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:meta='urn:oasis:names:tc:opendocument:xmlns:meta:1.0' xmlns:fo='urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0' xmlns:svg='urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0' xmlns:chart='urn:oasis:names:tc:opendocument:xmlns:chart:1.0' xmlns:dc='http://purl.org/dc/elements/1.1/'>
  <office:scripts />
  <office:automatic-styles>
    <style:style style:name='dp1' style:family='drawing-page'>
      <style:drawing-page-properties presentation:background-visible='true' presentation:display-date-time='true' draw:fill='solid' draw:fill-image-width='0cm' draw:fill-color='#ffffff' presentation:display-page-number='false' presentation:display-footer='true' draw:fill-image-height='0cm' presentation:background-objects-visible='true' />
    </style:style>
    <style:style style:name='dp2' style:family='drawing-page'>
      <style:drawing-page-properties presentation:display-date-time='true' presentation:display-page-number='false' presentation:display-footer='true' presentation:display-header='true' />
    </style:style>
    <style:style style:name='dp3' style:family='drawing-page'>
      <style:drawing-page-properties presentation:background-visible='true' presentation:display-date-time='true' presentation:display-page-number='false' presentation:display-footer='true' presentation:background-objects-visible='true' />
    </style:style>
    <style:style style:parent-style-name='standard' style:name='middling' style:family='graphic'>
      <style:graphic-properties svg:stroke-color='#000000' draw:stroke='none' fo:max-height='0cm' draw:fill='none' draw:fill-color='#ffffff' draw:auto-grow-height='true' draw:textarea-vertical-align='middle' fo:min-height='0cm' draw:auto-grow-width='false' />
    </style:style>
    <style:style style:name='gr2' style:family='graphic'>
      <style:graphic-properties style:protect='size' />
    </style:style>
    <style:style style:parent-style-name='standard' style:name='takahashi' style:family='graphic'>
      <style:graphic-properties svg:stroke-color='#000000' draw:stroke='none' fo:min-width='3.296cm' draw:textarea-horizontal-align='center' draw:textarea-vertical-align='middle' draw:fill='none' draw:fill-color='#ffffff' draw:auto-grow-height='true' fo:min-height='1.578cm' draw:auto-grow-width='true' />
    </style:style>
    <style:style style:parent-style-name='standard' style:name='gr4' style:family='graphic'>
      <style:graphic-properties draw:red='0%' draw:stroke='none' draw:contrast='0%' draw:textarea-horizontal-align='center' draw:blue='0%' draw:fill='none' fo:clip='rect(0cm, 0cm, 0cm, 0cm)' draw:textarea-vertical-align='middle' draw:gamma='100%' draw:luminance='0%' draw:green='0%' draw:color-mode='standard' draw:image-opacity='100%' style:mirror='none' />
    </style:style>
    <style:style style:parent-style-name='Default-notes' style:name='pr1' style:family='presentation'>
      <style:graphic-properties draw:fill-color='#ffffff' draw:auto-grow-height='true' fo:min-height='12.573cm' />
    </style:style>
    <style:style style:parent-style-name='Default-notes' style:name='pr2' style:family='presentation'>
      <style:graphic-properties fo:min-width='16.771cm' draw:fill-color='#ffffff' draw:auto-grow-height='true' fo:min-height='12.573cm' />
    </style:style>
    <style:style style:name='P1' style:family='paragraph'>
      <style:paragraph-properties fo:text-align='start' />
      <style:text-properties style:font-size-complex='12pt' fo:font-family='&apos;Liberation Mono&apos;' style:font-family-generic='modern' style:font-size-asian='12pt' style:font-pitch='fixed' fo:font-size='12pt' />
    </style:style>
    <style:style style:name='P2' style:family='paragraph'>
      <style:text-properties fo:font-size='20pt' />
    </style:style>
    <style:style style:name='P3' style:family='paragraph'>
      <style:paragraph-properties fo:text-align='center' />
      <style:text-properties style:font-size-complex='20pt' style:font-size-asian='20pt' fo:font-size='20pt' />
    </style:style>
    <style:style style:name='P4' style:family='paragraph'>
      <style:paragraph-properties fo:text-align='center' />
    </style:style>
END
    for my $pt (5..20,25,30,40,50) {
        print CONTENT <<"END";
    <style:style style:name='M$pt' style:family='text'>
      <style:text-properties style:font-size-complex='${pt}pt' fo:font-family='&apos;Liberation Mono&apos;' style:font-family-generic='modern' style:font-size-asian='${pt}pt' style:font-pitch='fixed' fo:color='#000000' fo:font-size='${pt}pt' />
    </style:style>
    <style:style style:name='S$pt' style:family='text'>
      <style:text-properties style:font-size-complex='${pt}pt' fo:font-family='&apos;Liberation Sans&apos;' style:font-family-generic='modern' style:font-size-asian='${pt}pt' fo:color='#000000' fo:font-size='${pt}pt' />
    </style:style>
END
    }
    print CONTENT <<"END";
    <style:style style:name='Magenta' style:family='text'>
      <style:text-properties fo:color='#ff20c0' />
    </style:style>
    <style:style style:name='Lavender' style:family='text'>
      <style:text-properties fo:color='#b040f0' />
    </style:style>
    <style:style style:name='Red' style:family='text'>
      <style:text-properties fo:color='#ff0000' />
    </style:style>
    <style:style style:name='Orange' style:family='text'>
      <style:text-properties fo:color='#ff8000' />
    </style:style>
    <style:style style:name='Yellow' style:family='text'>
      <style:text-properties fo:color='#ffff00' />
    </style:style>
    <style:style style:name='Green' style:family='text'>
      <style:text-properties fo:color='#00c000' />
    </style:style>
    <style:style style:name='Cyan' style:family='text'>
      <style:text-properties fo:color='#00e0e0' />
    </style:style>
    <style:style style:name='Blue' style:family='text'>
      <style:text-properties fo:color='#0000e0' />
    </style:style>
    <style:style style:name='Purple' style:family='text'>
      <style:text-properties fo:color='#900090' />
    </style:style>
    <style:style style:name='Black' style:family='text'>
      <style:text-properties fo:color='#000000' />
    </style:style>
    <style:style style:name='Gray' style:family='text'>
      <style:text-properties fo:color='#808080' />
    </style:style>
    <style:style style:name='White' style:family='text'>
      <style:text-properties fo:color='#ffffff' />
    </style:style>
    <text:list-style style:name='L1'>
      <text:list-level-style-bullet text:level='1' text:bullet-char='●'>
        <style:list-level-properties />
        <style:text-properties fo:font-family='StarSymbol' style:use-window-font-color='true' fo:font-size='45%' />
      </text:list-level-style-bullet>
      <text:list-level-style-bullet text:level='2' text:bullet-char='●'>
        <style:list-level-properties text:space-before='0.6cm' text:min-label-width='0.6cm' />
        <style:text-properties fo:font-family='StarSymbol' style:use-window-font-color='true' fo:font-size='45%' />
      </text:list-level-style-bullet>
      <text:list-level-style-bullet text:level='3' text:bullet-char='●'>
        <style:list-level-properties text:space-before='1.2cm' text:min-label-width='0.6cm' />
        <style:text-properties fo:font-family='StarSymbol' style:use-window-font-color='true' fo:font-size='45%' />
      </text:list-level-style-bullet>
      <text:list-level-style-bullet text:level='4' text:bullet-char='●'>
        <style:list-level-properties text:space-before='1.8cm' text:min-label-width='0.6cm' />
        <style:text-properties fo:font-family='StarSymbol' style:use-window-font-color='true' fo:font-size='45%' />
      </text:list-level-style-bullet>
      <text:list-level-style-bullet text:level='5' text:bullet-char='●'>
        <style:list-level-properties text:space-before='2.4cm' text:min-label-width='0.6cm' />
        <style:text-properties fo:font-family='StarSymbol' style:use-window-font-color='true' fo:font-size='45%' />
      </text:list-level-style-bullet>
      <text:list-level-style-bullet text:level='6' text:bullet-char='●'>
        <style:list-level-properties text:space-before='3cm' text:min-label-width='0.6cm' />
        <style:text-properties fo:font-family='StarSymbol' style:use-window-font-color='true' fo:font-size='45%' />
      </text:list-level-style-bullet>
      <text:list-level-style-bullet text:level='7' text:bullet-char='●'>
        <style:list-level-properties text:space-before='3.6cm' text:min-label-width='0.6cm' />
        <style:text-properties fo:font-family='StarSymbol' style:use-window-font-color='true' fo:font-size='45%' />
      </text:list-level-style-bullet>
      <text:list-level-style-bullet text:level='8' text:bullet-char='●'>
        <style:list-level-properties text:space-before='4.2cm' text:min-label-width='0.6cm' />
        <style:text-properties fo:font-family='StarSymbol' style:use-window-font-color='true' fo:font-size='45%' />
      </text:list-level-style-bullet>
      <text:list-level-style-bullet text:level='9' text:bullet-char='●'>
        <style:list-level-properties text:space-before='4.8cm' text:min-label-width='0.6cm' />
        <style:text-properties fo:font-family='StarSymbol' style:use-window-font-color='true' fo:font-size='45%' />
      </text:list-level-style-bullet>
      <text:list-level-style-bullet text:level='10' text:bullet-char='●'>
        <style:list-level-properties text:space-before='5.4cm' text:min-label-width='0.6cm' />
        <style:text-properties fo:font-family='StarSymbol' style:use-window-font-color='true' fo:font-size='45%' />
      </text:list-level-style-bullet>
    </text:list-style>
  </office:automatic-styles>
  <office:body>
    <office:presentation>
END

my $page = 0;

use Cwd ();
for (@para) {
    $page++;
    my $verbatim = /^\s/;
    s/^    //mg if $verbatim;
    s/^`//mg;
    if (/\bi:(.*)/) {
      my $name = Cwd::abs_path("image/$1");
      (my $safename = $name) =~ s/\//__/g;
      system "cp $name $build/Pictures/$safename";
      print CONTENT <<"END";
      <draw:page draw:style-name='dp1' draw:name='page$page' draw:master-page-name='Default'>
        <office:forms form:automatic-focus='false' form:apply-design-mode='false' />
        <draw:frame svg:y='0cm' draw:style-name='gr4' svg:x='0cm' draw:layer='layout' svg:width='10.008cm' svg:height='8.001cm' draw:text-style-name='P4'>
          <draw:image xlink:href='Pictures/$safename' xlink:actuate='onLoad' xlink:show='embed' xlink:type='simple'>
            <text:p />
          </draw:image>
        </draw:frame>
      </draw:page>
END
    }
    elsif (/\bh:(.*)/) {
        my $link = $1;
        print CONTENT <<"END";
      <draw:page draw:style-name='dp3' draw:name='page$page' draw:master-page-name='Default'>
        <draw:frame svg:y='4cm' draw:style-name='takahashi' svg:x='5cm' draw:layer='layout' draw:text-style-name='P3'>
          <draw:text-box>
            <text:p text:style-name='P3'>
                <text:a xlink:href='http:$link'>http:$link</text:a>
            </text:p>
          </draw:text-box>
        </draw:frame>
      </draw:page>
END
    }
    elsif (/\bf:(.*)/) {
        my $file = $1;
        print CONTENT <<"END";
      <draw:page draw:style-name='dp3' draw:name='page$page' draw:master-page-name='Default'>
        <draw:frame svg:y='4cm' draw:style-name='takahashi' svg:x='5cm' draw:layer='layout' draw:text-style-name='P3'>
          <draw:text-box>
            <text:p text:style-name='P1'>
                <text:span text:style-name='M5'>
                <text:a xlink:href='file:$file'>$file</text:a>
                </text:span>
            </text:p>
          </draw:text-box>
        </draw:frame>
      </draw:page>
END
    }
    else {
        my @lines = split(/^/, $_);
        my $maxlen = 1;
        for my $line (@lines) {
            $line =~ s/\t/        /g;
            $line =~ s/( +)/"\xa0" x length($1)/ge;
            my $temp = $line;
            $temp =~ s/`?\b([a-zA-Z])<(.*?)>/$2/g;
            $temp =~ s/`?\b([a-zA-Z])://g;
            $temp =~ s/[\x{2000}-\x{ffff}]/XXX/g;
            $maxlen = length($temp) if $maxlen < length($temp);
        }
        for my $line (@lines) {
            $line =~ s/`?\b([a-zA-Z])<(.*?)>/<text:span text:style-name='$COLOR{$1}'>$2<\/text:span>/g;
            $line =~ s/`?\b([a-zA-Z]):(.*)/<text:span text:style-name='$COLOR{$1}'>$2<\/text:span>/g;
        }
        if ($verbatim) {
            print CONTENT <<"END";
      <draw:page draw:style-name='dp3' draw:name='page$page' draw:master-page-name='Default'>
        <draw:frame svg:y='2cm' draw:style-name='middling' svg:x='0.4cm' draw:layer='layout' svg:width='10.5cm' svg:height='3.639cm' draw:text-style-name='P1'>
          <draw:text-box>
END
            my $t = 'M' . (
                $maxlen > 70 ? 5 :
                $maxlen > 50 ? 7 :
                $maxlen > 40 ? 9 :
                $maxlen > 30 ? 12 :
                $maxlen > 20 ? 14 :
                $maxlen > 10 ? 20 :
                30
            );
            for my $line (@lines) {
                print CONTENT <<"END";
            <text:p text:style-name='P1'>
              <text:span text:style-name='$t'>$line</text:span>
            </text:p>
END
            }
            print CONTENT <<"END";
          </draw:text-box>
        </draw:frame>
      </draw:page>
END
        }
        else {
            print CONTENT <<"END";
      <draw:page draw:style-name='dp3' draw:name='page3' draw:master-page-name='Default'>
        <draw:frame svg:y='4cm' draw:style-name='takahashi' svg:x='5cm' draw:layer='layout' draw:text-style-name='P3'>
          <draw:text-box>
END
            my $t = 'S' . (
                $maxlen > 70 ? 5 :
                $maxlen > 60 ? 7 :
                $maxlen > 50 ? 8 :
                $maxlen > 45 ? 9 :
                $maxlen > 40 ? 10 :
                $maxlen > 35 ? 11 :
                $maxlen > 28 ? 14 :
                $maxlen > 24 ? 17 :
                $maxlen > 20 ? 20 :
                $maxlen > 15 ? 25 :
                $maxlen > 10 ? 30 :
                $maxlen > 8 ? 35 : 40
            );
            for my $line (@lines) {
                print CONTENT <<"END";
            <text:p text:style-name='P3'>
              <text:span text:style-name='$t'>$line</text:span>
            </text:p>
END
            }
            print CONTENT <<"END";
          </draw:text-box>
        </draw:frame>
      </draw:page>
END
        }
    }
}

print CONTENT <<'END';
      <presentation:settings presentation:mouse-visible='false' />
    </office:presentation>
  </office:body>
</office:document-content>
END

system("chdir $build; zip -r -u ../stump.odp *");

}

1;
