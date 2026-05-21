package PDF::FacturX::Embed;
use strict;
use warnings;
use utf8;
use Exporter 'import';
use File::Temp qw(tempfile tempdir);
use File::Basename qw(basename);
use File::Spec;
use POSIX qw(strftime);
use Encode qw(encode_utf8);
use PDF::Builder;
use File::ShareDir qw(dist_dir);

our $VERSION = '0.01';

our @EXPORT_OK = qw(embed_xml_pdfa3 find_icc_profile);

###############################################################################
# embed_xml_pdfa3 — prend un PDF source + un XML Factur-X et produit un
# PDF/A-3 avec :
#   - l'XML embarqué comme « associated file » (AFRelationship = /Data)
#   - les métadonnées XMP Factur-X (pdfaid + fx)
#   - un OutputIntent sRGB (requis par PDF/A)
#
# Pilote Ghostscript (>= 10.x) via un fichier .ps pdfmark temporaire.
#
# Usage :
#   use PDF::FacturX::Embed qw(embed_xml_pdfa3);
#   my ($ok, $msg) = embed_xml_pdfa3(
#       pdf_in     => 'src.pdf',
#       xml        => $xml_string,    # chaîne Perl (caractères), UTF-8 interne
#       pdf_out    => 'dst.pdf',
#       profile    => 'basic',        # minimum|basicwl|basic|en16931
#       title      => 'Facture FA-2026-0042',
#       author     => 'Acme SARL',
#       creator    => 'PDF::FacturX',
#       tmp_dir    => '/path/to/tmp', # optionnel, défaut System tmp
#       gs         => 'gs',           # optionnel, défaut 'gs'
#       icc_path   => '/path.icc',    # optionnel, auto-détection sinon
#       on_warning => sub { warn @_ },# optionnel, capture warnings PDF::Builder
#   );
#   die $msg unless $ok;
###############################################################################

my %CONFORMANCE = (
    minimum => 'MINIMUM',
    basicwl => 'BASIC WL',
    basic   => 'BASIC',
    en16931 => 'EN 16931',
);

sub embed_xml_pdfa3 {
    my (%opt) = @_;
    my $pdf_in  = $opt{pdf_in}  or die "pdf_in requis\n";
    my $xml     = $opt{xml};    defined $xml or die "xml requis\n";
    my $pdf_out = $opt{pdf_out} or die "pdf_out requis\n";
    my $profile = $opt{profile} || 'basic';
    die "Profil inconnu: $profile\n" unless exists $CONFORMANCE{$profile};

    -r $pdf_in or die "PDF source introuvable : $pdf_in\n";

    my $icc_path = $opt{icc_path} || find_icc_profile();
    die "Profil ICC sRGB introuvable. Fournir icc_path ou installer ghostscript.\n"
        unless $icc_path && -r $icc_path;

    my $gs = $opt{gs} || 'gs';

    # Répertoire temporaire jetable. tmp_dir est optionnel : par défaut on
    # passe par File::Temp (système). File::Temp->newdir nettoie à la sortie
    # de portée, contrairement à tempdir(CLEANUP => 1) qui ne nettoie qu'à
    # la mort du processus (gênant dans les workers longue durée).
    my $tmpdir_obj;
    if ($opt{tmp_dir}) {
        -d $opt{tmp_dir} or die "tmp_dir introuvable : $opt{tmp_dir}\n";
        $tmpdir_obj = File::Temp->newdir('fx_XXXX', DIR => $opt{tmp_dir});
    }
    else {
        $tmpdir_obj = File::Temp->newdir('fx_XXXX');
    }
    my $tmpdir = "$tmpdir_obj";    # stringification → chemin
    my $ps_fp  = File::Spec->catfile($tmpdir, 'pdfmark.ps');

    # Le XML et le XMP sont inlinés dans le pdfmark PostScript en chaînes
    # Perl unicode ; `encode_utf8` n'est appliqué qu'UNE fois à la fin
    # avant écriture. Mélanger octets + unicode dans le heredoc provoque
    # un double-encodage silencieux (ex: « Poséidon » → « PosÃ©idon »).

    my $now      = strftime('%Y-%m-%dT%H:%M:%S', localtime());
    my $mod_date = strftime('%Y%m%d%H%M%S',      localtime());

    my $xmp = _build_xmp(
        profile => $profile,
        title   => $opt{title}   // 'Invoice',
        author  => $opt{author}  // '',
        creator => $opt{creator} // 'PDF::FacturX',
        date    => $now,
    );

    my $pdfmark = _build_pdfmark(
        xml      => $xml,
        xmp      => $xmp,
        icc_path => $icc_path,
        mod_date => $mod_date,
    );
    open my $pfh, '>:raw', $ps_fp or die "open $ps_fp: $!";
    print $pfh encode_utf8($pdfmark);
    close $pfh;

    my @cmd = (
        $gs,
        '-dPDFA=3',
        '-dPDFACompatibilityPolicy=1',
        '-dBATCH', '-dNOPAUSE', '-dQUIET',
        # NOSAFER : nécessaire pour que gs lise les fichiers référencés
        # dans le pdfmark (ICC, XML, XMP).
        '-dNOSAFER',
        '-sColorConversionStrategy=RGB',
        '-sProcessColorModel=DeviceRGB',
        '-sDEVICE=pdfwrite',
        "-sOutputFile=$pdf_out",
        $ps_fp,
        $pdf_in,
    );

    my $stderr_fp = File::Spec->catfile($tmpdir, 'gs.err');
    my $rc = system(join(' ', map { _shq($_) } @cmd) . " 2>$stderr_fp");
    my $err = '';
    if (open my $efh, '<:raw', $stderr_fp) {
        local $/;
        $err = <$efh>;
        close $efh;
    }

    if ($rc != 0) {
        return (0, "Ghostscript a échoué (code " . ($rc >> 8) . ") : $err");
    }
    unless (-s $pdf_out) {
        return (0, "Ghostscript n'a rien produit : $err");
    }

    # Post-traitement : gs ne sait pas poser un Metadata stream avec
    # /Type /Metadata /Subtype /XML (PDF/A-3 §6.6.2.1). On ouvre le PDF
    # produit avec PDF::Builder et on pose le XMP via xml_metadata().
    my ($ok, $msg) = _set_xmp_metadata($pdf_out, $xmp, $opt{on_warning});
    return (0, "PDF::Builder xml_metadata KO : $msg") unless $ok;

    return (1, "OK (" . (-s $pdf_out) . " octets)");
}

sub _set_xmp_metadata {
    my ($pdf_path, $xmp_bytes, $on_warning) = @_;

    # PDF::Builder open() peut imprimer des messages de version sur STDOUT.
    # Dans des contextes embedded (Dancer, mod_perl) ce flux peut polluer
    # la sortie HTTP. On capture STDOUT/STDERR le temps de l'appel et on
    # relaie via le callback $on_warning.
    my $buf = '';
    my ($saved_out, $saved_err);
    open $saved_out, '>&', \*STDOUT or return (0, "dup stdout: $!");
    open $saved_err, '>&', \*STDERR or return (0, "dup stderr: $!");
    close STDOUT;
    close STDERR;
    open STDOUT, '>', \$buf
        or do { _restore_fds($saved_out, $saved_err); return (0, "muzzle stdout: $!") };
    open STDERR, '>', \$buf
        or do { _restore_fds($saved_out, $saved_err); return (0, "muzzle stderr: $!") };

    my ($ok, $msg) = (1, 'xmp set');
    eval {
        my $pdf = PDF::Builder->open($pdf_path);
        $pdf->xml_metadata($xmp_bytes);
        $pdf->saveas($pdf_path);
        1;
    } or do { ($ok, $msg) = (0, "PDF::Builder: $@") };

    _restore_fds($saved_out, $saved_err);

    if (length $buf && ref $on_warning eq 'CODE') {
        $on_warning->("[PDF::FacturX::Embed] PDF::Builder: $buf");
    }
    return ($ok, $msg);
}

sub _restore_fds {
    my ($saved_out, $saved_err) = @_;
    close STDOUT;
    open STDOUT, '>&', $saved_out;
    close STDERR;
    open STDERR, '>&', $saved_err;
    close $saved_out;
    close $saved_err;
}

###############################################################################
# find_icc_profile — cherche un profil ICC sRGB :
#   1. Dans les emplacements standards de Ghostscript (homebrew, /usr/share)
#   2. Sinon, repli sur le sRGB embarqué dans share/icc/sRGB.icc
###############################################################################
sub find_icc_profile {
    my @bases = (
        '/opt/homebrew/Cellar/ghostscript',
        '/usr/local/Cellar/ghostscript',
        '/opt/homebrew/share/ghostscript',
        '/usr/local/share/ghostscript',
        '/usr/share/ghostscript',
    );
    my @names = qw(default_rgb.icc sRGB2014.icc sRGB.icc srgb.icc);

    for my $base (@bases) {
        next unless -d $base;
        for my $name (@names) {
            my @hits = _find_file_shallow($base, $name, 6);
            return $hits[0] if @hits;
        }
    }

    # Repli : profil ICC embarqué dans la dist
    my $share_dir;
    eval { $share_dir = dist_dir('PDF-FacturX'); 1 } or do {
        my $here = __FILE__;
        my @parts = File::Spec->splitpath($here);
        my $dir   = $parts[1];
        $share_dir = File::Spec->catdir($dir, '..', '..', '..', 'share');
    };
    my $bundled = File::Spec->catfile($share_dir, 'icc', 'sRGB.icc');
    return $bundled if -r $bundled;

    return undef;
}

sub _find_file_shallow {
    my ($dir, $name, $max_depth) = @_;
    return () if $max_depth < 0;
    opendir(my $dh, $dir) or return ();
    my @entries = grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh;
    my @out;
    for my $e (@entries) {
        my $p = File::Spec->catfile($dir, $e);
        if (-d $p) {
            push @out, _find_file_shallow($p, $name, $max_depth - 1);
        }
        elsif ($e eq $name) {
            push @out, $p;
        }
    }
    return @out;
}

###############################################################################
# pdfmark PostScript — injecte OutputIntent, XML embarqué, AF, Names/EF.
# Le XMP est posé après coup par PDF::Builder (gs ne sait pas écrire un
# stream /Type /Metadata /Subtype /XML compatible PDF/A-3 §6.6.2.1).
###############################################################################
sub _build_pdfmark {
    my (%a) = @_;
    my $icc_path = _ps_string($a{icc_path});
    my $mod_ps   = _ps_string("D:$a{mod_date}");
    my $xml_ps   = _ps_string_bytes($a{xml});

    return <<"PS";
%!PS-Adobe-3.0

% ── OutputIntent sRGB (requis par PDF/A) ──────────────────────────────
[/_objdef {icc_PDFA} /type /stream /OBJ pdfmark
[{icc_PDFA} << /N 3 /Alternate /DeviceRGB >> /PUT pdfmark
[{icc_PDFA} $icc_path (r) file /PUT pdfmark
[/_objdef {OutputIntent_PDFA} /type /dict /OBJ pdfmark
[{OutputIntent_PDFA} <<
  /Type /OutputIntent
  /S /GTS_PDFA1
  /DestOutputProfile {icc_PDFA}
  /OutputConditionIdentifier (sRGB)
  /Info (sRGB IEC61966-2.1)
>> /PUT pdfmark
[{Catalog} << /OutputIntents [{OutputIntent_PDFA}] >> /PUT pdfmark

% ── XML Factur-X embarqué ─────────────────────────────────────────────
% Deux /PUT séparés : le dict en premier pour poser /Type /Subtype,
% puis le contenu en STRING inline (pas `file` : `file` refait le dict
% à zéro et on perd /Type /Subtype — bug PDF/A-3 6.8 test 1).
[/_objdef {fxXML} /type /stream /OBJ pdfmark
[{fxXML}
  << /Type /EmbeddedFile
     /Subtype (text/xml) cvn
     /Params << /ModDate $mod_ps >>
  >> /PUT pdfmark
[{fxXML} $xml_ps /PUT pdfmark

% ── FileSpec (AFRelationship = /Data) ──────────────────────────────────
[/_objdef {fxFS} /type /dict /OBJ pdfmark
[{fxFS} <<
  /Type /Filespec
  /F (factur-x.xml)
  /UF (factur-x.xml)
  /Desc (Factur-X Invoice)
  /AFRelationship /Data
  /EF << /F {fxXML} /UF {fxXML} >>
>> /PUT pdfmark

% ── Catalog : /AF + /Names /EmbeddedFiles ──────────────────────────────
[{Catalog} <<
  /AF [{fxFS}]
  /Names <<
    /EmbeddedFiles <<
      /Names [(factur-x.xml) {fxFS}]
    >>
  >>
>> /PUT pdfmark
PS
}

###############################################################################
# XMP — namespaces pdfaid, fx (Factur-X), dc, xmp + extension schema PDF/A-3.
###############################################################################
sub _build_xmp {
    my (%a) = @_;
    my $conformance = $CONFORMANCE{$a{profile}};
    my $title   = _xml_esc($a{title});
    my $author  = _xml_esc($a{author});
    my $creator = _xml_esc($a{creator});
    my $date    = _xml_esc($a{date});

    return <<"XMP";
<?xpacket begin="" id="W5M0MpCehiHzreSzNTczkc9d"?>
<x:xmpmeta xmlns:x="adobe:ns:meta/">
 <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">

  <rdf:Description rdf:about=""
      xmlns:pdfaid="http://www.aiim.org/pdfa/ns/id/">
   <pdfaid:part>3</pdfaid:part>
   <pdfaid:conformance>B</pdfaid:conformance>
  </rdf:Description>

  <rdf:Description rdf:about=""
      xmlns:fx="urn:factur-x:pdfa:CrossIndustryDocument:invoice:1p0#">
   <fx:DocumentType>INVOICE</fx:DocumentType>
   <fx:DocumentFileName>factur-x.xml</fx:DocumentFileName>
   <fx:Version>1.0</fx:Version>
   <fx:ConformanceLevel>$conformance</fx:ConformanceLevel>
  </rdf:Description>

  <rdf:Description rdf:about=""
      xmlns:pdfaExtension="http://www.aiim.org/pdfa/ns/extension/"
      xmlns:pdfaSchema="http://www.aiim.org/pdfa/ns/schema#"
      xmlns:pdfaProperty="http://www.aiim.org/pdfa/ns/property#">
   <pdfaExtension:schemas>
    <rdf:Bag>
     <rdf:li rdf:parseType="Resource">
      <pdfaSchema:schema>Factur-X PDFA Extension Schema</pdfaSchema:schema>
      <pdfaSchema:namespaceURI>urn:factur-x:pdfa:CrossIndustryDocument:invoice:1p0#</pdfaSchema:namespaceURI>
      <pdfaSchema:prefix>fx</pdfaSchema:prefix>
      <pdfaSchema:property>
       <rdf:Seq>
        <rdf:li rdf:parseType="Resource">
         <pdfaProperty:name>DocumentFileName</pdfaProperty:name>
         <pdfaProperty:valueType>Text</pdfaProperty:valueType>
         <pdfaProperty:category>external</pdfaProperty:category>
         <pdfaProperty:description>Name of the embedded XML invoice file</pdfaProperty:description>
        </rdf:li>
        <rdf:li rdf:parseType="Resource">
         <pdfaProperty:name>DocumentType</pdfaProperty:name>
         <pdfaProperty:valueType>Text</pdfaProperty:valueType>
         <pdfaProperty:category>external</pdfaProperty:category>
         <pdfaProperty:description>INVOICE</pdfaProperty:description>
        </rdf:li>
        <rdf:li rdf:parseType="Resource">
         <pdfaProperty:name>Version</pdfaProperty:name>
         <pdfaProperty:valueType>Text</pdfaProperty:valueType>
         <pdfaProperty:category>external</pdfaProperty:category>
         <pdfaProperty:description>Factur-X version</pdfaProperty:description>
        </rdf:li>
        <rdf:li rdf:parseType="Resource">
         <pdfaProperty:name>ConformanceLevel</pdfaProperty:name>
         <pdfaProperty:valueType>Text</pdfaProperty:valueType>
         <pdfaProperty:category>external</pdfaProperty:category>
         <pdfaProperty:description>Factur-X conformance level</pdfaProperty:description>
        </rdf:li>
       </rdf:Seq>
      </pdfaSchema:property>
     </rdf:li>
    </rdf:Bag>
   </pdfaExtension:schemas>
  </rdf:Description>

  <rdf:Description rdf:about=""
      xmlns:dc="http://purl.org/dc/elements/1.1/">
   <dc:format>application/pdf</dc:format>
   <dc:title><rdf:Alt><rdf:li xml:lang="x-default">$title</rdf:li></rdf:Alt></dc:title>
   <dc:creator><rdf:Seq><rdf:li>$author</rdf:li></rdf:Seq></dc:creator>
  </rdf:Description>

  <rdf:Description rdf:about=""
      xmlns:xmp="http://ns.adobe.com/xap/1.0/">
   <xmp:CreatorTool>$creator</xmp:CreatorTool>
   <xmp:CreateDate>$date</xmp:CreateDate>
   <xmp:ModifyDate>$date</xmp:ModifyDate>
  </rdf:Description>

 </rdf:RDF>
</x:xmpmeta>
<?xpacket end="w"?>
XMP
}

# Encode une chaîne texte courte (ASCII) en literal PostScript (…).
sub _ps_string {
    my ($s) = @_;
    $s =~ s/\\/\\\\/g;
    $s =~ s/\(/\\(/g;
    $s =~ s/\)/\\)/g;
    return "($s)";
}

# Encode des octets arbitraires (UTF-8 multi-octets, etc.) en literal PostScript.
sub _ps_string_bytes {
    my ($bytes) = @_;
    $bytes =~ s/\\/\\\\/g;
    $bytes =~ s/\(/\\(/g;
    $bytes =~ s/\)/\\)/g;
    return "($bytes)";
}

sub _xml_esc {
    my ($s) = @_;
    $s //= '';
    $s =~ s/&/&amp;/g;
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    $s =~ s/"/&quot;/g;
    return $s;
}

# Shell-quote pour construire la commande gs (évite les surprises sur les paths).
sub _shq {
    my ($s) = @_;
    return $s unless $s =~ /[^\w.\/=:-]/;
    $s =~ s/'/'\\''/g;
    return "'$s'";
}

1;

__END__

=encoding utf-8

=head1 NAME

PDF::FacturX::Embed - Embed Factur-X XML into a PDF/A-3 envelope

=head1 SYNOPSIS

    use PDF::FacturX::Embed qw(embed_xml_pdfa3);

    my ($ok, $msg) = embed_xml_pdfa3(
        pdf_in   => 'invoice.pdf',
        xml      => $factur_x_xml,
        pdf_out  => 'invoice-fx.pdf',
        profile  => 'en16931',
        title    => 'Invoice FA-2026-0042',
        author   => 'Acme SARL',
    );
    die $msg unless $ok;

=head1 DESCRIPTION

Wraps an existing PDF into a PDF/A-3 envelope with the Factur-X XML
attached as an associated file (AFRelationship = /Data) and the required
XMP metadata stream. Drives Ghostscript (>= 10.x) for the heavy lifting,
then PDF::Builder for the final XMP write that Ghostscript cannot perform
correctly per PDF/A-3 §6.6.2.1.

=head1 REQUIREMENTS

=over 4

=item * Ghostscript 10.x or later, as the C<gs> binary in PATH (override
with the C<gs> option).

=item * An sRGB ICC profile (auto-detected from common Ghostscript install
paths; bundled fallback at C<share/icc/sRGB.icc>).

=back

=head1 FUNCTIONS

=head2 embed_xml_pdfa3(%opts)

Returns C<(1, $message)> on success or C<(0, $error)> on failure.
Required: C<pdf_in>, C<xml>, C<pdf_out>. Optional: C<profile>, C<title>,
C<author>, C<creator>, C<tmp_dir>, C<gs>, C<icc_path>, C<on_warning>.

=head2 find_icc_profile()

Returns a path to an sRGB ICC profile or C<undef>.

=head1 LICENSE

Same terms as Perl itself (Artistic License 2.0).

=cut
