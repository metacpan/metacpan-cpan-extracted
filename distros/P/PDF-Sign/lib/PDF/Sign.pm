package PDF::Sign;
#
# Originally inspired by Martin Schuette <info@mschuette.name> (2012)
#   https://mschuette.name/files/pdfsign.pl
#   BSD 2-Clause License - retained below as required
#
# Imported for study and proof of concept: Massimiliano Citterio (2019)
# Substantially rewritten and extended by Massimiliano Citterio (2023-2026)
#   - Refactored into reusable subs (prepare_file, sign_file, prepare_ts, ts_file)
#   - RFC3161 TSA timestamp support (ETSI.RFC3161 / DocTimeStamp)
#   - OpenSSL 1.x/3.x + LibreSSL compatibility (CAdES, ETSI.CAdES.detached)
#   - Visible signature widget with appearance stream
#   - Certificate chain support (-certfile)
#   - Cross-platform timezone handling (Linux / Windows)
#   - Process-safe temp files (PID in filename)
#   - openssl cms replacing smime+sed pipeline
#   - PDF32000-2008 12.8.1 compliant ByteRange implementation
#   - curl/LWP::UserAgent fallback for TSA requests
#
# @copyright (c) Citterio Massimiliano, Perl License (GPL/Artistic)
#
# --- BSD 2-Clause License (Martin Schuette, 2012) ---
# Copyright (c) 2012, Martin Schuette <info@mschuette.name>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# --- end BSD 2-Clause License ---

use strict;
use warnings;
use 5.010;

use Exporter 'import';
use Cwd qw(getcwd);
use POSIX qw(strftime);
use MIME::Base64 qw(decode_base64);
use File::Slurp qw(write_file);
# Crypt::OpenSSL::X509 intentionally not used - XS dependency with
# known installation issues on macOS (missing OpenSSL headers).
# Subject name extracted via openssl binary instead.

# PDF backend: PDF::API2 or PDF::Builder
my $PDF_BACKEND;
BEGIN {
    if (eval { require PDF::API2; PDF::API2->import(); 1 }) {
        $PDF_BACKEND = 'PDF::API2';
        require PDF::API2::Basic::PDF::Utils;
        PDF::API2::Basic::PDF::Utils->import();
    } elsif (eval { require PDF::Builder; PDF::Builder->import(); 1 }) {
        $PDF_BACKEND = 'PDF::Builder';
        require PDF::Builder::Basic::PDF::Utils;
        PDF::Builder::Basic::PDF::Utils->import();

    }

    sub PDFLiteral {
        if ($PDF_BACKEND eq 'PDF::API2'){
            return PDF::API2::Basic::PDF::Literal->new(@_);
        }
        if ($PDF_BACKEND eq 'PDF::Builder'){
            return PDF::Builder::Basic::PDF::Literal->new(@_);
        }
    }
    sub PDFForm {
        if ($PDF_BACKEND eq 'PDF::API2'){
            return PDF::API2::Resource::XObject::Form->new(@_);
        }
        if ($PDF_BACKEND eq 'PDF::Builder'){
            return PDF::Builder::Resource::XObject::Form->new(@_);
        }
    }
}

# LWP fallback detection (curl preferred)
my $HAS_LWP = eval { require LWP::UserAgent; 1 };

our $VERSION = '0.06';

our @EXPORT_OK = qw(
    config
    prepare_file
    sign_file
    prepare_ts
    ts_file
    cms_sign
    ts_query
    tsa_fetch
);

our %EXPORT_TAGS = (
    sign => [qw(prepare_file sign_file cms_sign)],
    ts   => [qw(prepare_ts ts_file ts_query tsa_fetch)],
    all  => \@EXPORT_OK,
);

# ============================================================
# Configuration - set these before calling any sub,
# or pass them as arguments where supported.
# All configurable via our() from the calling script.
# ============================================================
our $osslcmd    = 'openssl';
our $x509_pem;
our $x509_chain;
our $privkey_pem;
our $tsaserver  = 'http://timestamp.digicert.com';
our $tmpdir     = getcwd();
# Investigation on PDF::Buider breaking lenght of byterange

our $siglen     = 1024 * (($PDF_BACKEND // '') eq 'PDF::Builder' ? 8 : 8);
our $debug      = 0;

my $zerorange   = sprintf("0 %8d %8d %8d", 0, 0, 0);

# detect openssl version and cms availability once at load time
my $osslv = do {
    open(my $fh, '-|', $osslcmd, 'version')
        or die "Cannot exec openssl: $!";
    my $v = do { local $/; <$fh> };
    close $fh;
    chomp $v;
    $v;
};

# cms command availability - LibreSSL 2.x and very old OpenSSL may lack it
# fallback to smime if cms is not available.
# Note: openssl cms -help writes to stderr, so we redirect stderr to stdout
# using shell=1 here intentionally - input is a fixed string, no injection risk
my $has_cms = do {
    my $out = `$osslcmd cms -help 2>&1`;
    $out =~ /Usage[\s:]{1,2}cms[\s\[]{1,2}options/i ? '1' : '';
};

# ============================================================
# sub: config
# Configure PDF::Sign settings in one call.
# Preferred over setting package variables directly.
# All keys are optional - only provided keys are updated.
#
# Example:
#   PDF::Sign::config(
#       osslcmd     => '/usr/local/bin/openssl',
#       x509_pem    => '/path/to/cert.pem',
#       x509_chain  => '/path/to/chain.pem',
#       privkey_pem => '/path/to/privkey.pem',
#       tsaserver   => 'http://timestamp.digicert.com',
#       tmpdir      => '/tmp',
#       siglen      => 6144,
#       debug       => 1,
#   );
# ============================================================
sub config {
    my (%args) = @_;

    $osslcmd    = $args{osslcmd}     if exists $args{osslcmd};
    $x509_pem   = $args{x509_pem}    if exists $args{x509_pem};
    $x509_chain = $args{x509_chain}  if exists $args{x509_chain};
    $privkey_pem = $args{privkey_pem} if exists $args{privkey_pem};
    $tsaserver  = $args{tsaserver}   if exists $args{tsaserver};
    $tmpdir     = $args{tmpdir}      if exists $args{tmpdir};
    $siglen     = $args{siglen}      if exists $args{siglen};
    $debug      = $args{debug}       if exists $args{debug};

    # re-detect openssl version and cms availability if osslcmd changed
    if (exists $args{osslcmd}) {
        open(my $fh, '-|', $osslcmd, 'version')
            or die "Cannot exec $osslcmd: $!";
        $osslv = do { local $/; <$fh> };
        close $fh;
        chomp $osslv;

        my $cms_out = `$osslcmd cms -help 2>&1`;
        $has_cms = $cms_out =~ /Usage[\s:]{1,2}cms[\s\[]{1,2}options/i ? '1' : '';
    }

    return 1;
}

# ============================================================
# sub: prepare_file
# Prepares the PDF AcroForm structure for a CMS/CAdES signature.
# $presign = 1: visible signature widget on page 1
# $presign = 0: invisible signature field
# ============================================================
sub prepare_file {
    my $pdf     = $_[0];
    my $p       = $pdf->{'pdf'};
    my $presign = $_[1];
    my $reason  = $_[2] // "Digitally signed document";

    if (!(-e $privkey_pem && -e $x509_pem)) { return; }

    my $sigdict        = PDFDict();
    $sigdict->{Type}   = PDFName("Sig");
    $sigdict->{Filter} = PDFName("Adobe.PPKLite");
    $sigdict->{Reason} = PDFStr($reason);
    $sigdict->{Name}   = PDFStr(_cert_subject($x509_pem));
    my $isodatetimetz;
    # using %z for timeoffset only for well known supporting systems
    if ($^O eq 'linux'   || $^O eq 'darwin'  ||
        $^O eq 'freebsd' || $^O eq 'openbsd' ||
        $^O eq 'netbsd'  || $^O eq 'solaris') {
        $isodatetimetz = strftime("D:%Y%m%d%H%M%S%z", localtime);
        # Minutes in PDF should be wrapped into single quotes
        $isodatetimetz =~ s/([+-]\d{2}):?(\d{2})$/$1'$2'/;
    } else {
        # Calculate Time Zone Offset
        # (timegm-based: correct DST handling for all timezones,
        #  replaces the previous CET/CEST-only approach)
        my $t      = time();
        my @lt     = localtime($t);

        use Time::Local qw(timegm);
        my $offset_sec = timegm(@lt[0..5]) - $t;

        my $sign = ($offset_sec < 0) ? '-' : '+';
        my $abs  = abs($offset_sec);
        my $oh   = int($abs / 3600);
        my $om   = int(($abs % 3600) / 60);
        # Minutes in PDF should be wrapped into single quotes
        my $tzo  = sprintf("%s%02d'%02d'", $sign, $oh, $om);
        $isodatetimetz = strftime("D:%Y%m%d%H%M%S", @lt) . $tzo;
    }
    $sigdict->{M} = PDFStr($isodatetimetz);
    # ETSI.CAdES.detached only with OpenSSL 3+
    # LibreSSL (any version) and OpenSSL 1.x use adbe.pkcs7.detached
    if ($osslv =~ /^OpenSSL 3/) {
        $sigdict->{SubFilter} = PDFName('ETSI.CAdES.detached');
    } else {
        $sigdict->{SubFilter} = PDFName('adbe.pkcs7.detached');
    }

    $sigdict->{Contents}  = PDFStrHex("\0" x $siglen);
    $sigdict->{ByteRange} = PDFLiteral("[$zerorange]");
    $sigdict = $p->new_obj($sigdict);

    my @formarray;
    if ($presign) {
        my $sigannotdict = $pdf->open_page(1)->annotation();
        delete $sigannotdict->{Type};
        $sigannotdict->{Subtype} = PDFName("Widget");
        $sigannotdict->{F}       = PDFNum(4 + 128);  # + 128 + 256
        $sigannotdict->{V}       = $sigdict;
        $sigannotdict->{FT}      = PDFName("Sig");
        $sigannotdict->{T}       = PDFStr("Signature1");
        delete $sigannotdict->{Border};

        my $ap  = $sigannotdict->{AP} = PDFDict();
        my $n0  = PDFForm($p);
        $n0->bbox(0, 0, 150, 20);
        my $frm = PDFForm($p);
        $frm->bbox(0, 0, 150, 20);

        my ($s, $m, $h, $D, $M, $Y) = map { $_ = '0' . $_ if $_ < 9; $_ } localtime();
        $Y += 1900; $M += 1; $M = '0' . $M if $M < 9;
		# 0 0 0 rg = Color Black, /F1 6 Tf = font1 size 6
		# somehow buggy font selection on PDF::Builder
        $frm->{' stream'} = "q\n0 0 0 rg\nBT 1 0 0 1 0 0 Tm /F1 6 Tf\n" .
            "5 8 Td (Digitally signed D: $Y-$M-$D $h:$m:$s CET) Tj ET Q";
        #$frm->{' stream'} = "q Q";  # debug: empty appearance
        $frm->filter('FlateDecode');

        $ap->{N} = PDFForm($p);
        $ap->{N}->bbox(0, 0, 150, 20);
        $frm->resource('XObject', 'n0', $n0);
        $ap->{N}->resource('XObject', 'FRM', $frm);
        $ap->{N}->{' stream'} = "q 1 0 0 1 0 0 cm /FRM Do Q";
        $ap->{N}->filter('FlateDecode');

        $sigannotdict->{Rect} = PDFLiteral("[25 6 175 26]");
        if ($pdf->{catalog}->{Pages}->{Kids}->{' val'}[0]->{' objnum'}) {
            $sigannotdict->{P} = PDFLiteral(
                $pdf->{catalog}->{Pages}->{Kids}->{' val'}[0]->{' objnum'} . " 0 R");
        } else {
            $sigannotdict->{P} = $pdf->open_page(1);
        }
        $sigannotdict = $p->new_obj($sigannotdict);
        push @formarray, $sigannotdict;
    } else {
        my $sigformdict = PDFDict();
        $sigformdict->{Type}    = PDFName("Annot");
        $sigformdict->{Subtype} = PDFName("Widget");
        $sigformdict->{F}       = PDFNum(4 + 128);
        $sigformdict->{FT}      = PDFName("Sig");
        $sigformdict->{T}       = PDFStr("Signature1");
        $sigformdict->{V}       = $sigdict;
        if ($pdf->{catalog}->{Pages}->{Kids}->{' val'}[0]->{' objnum'}) {
            $sigformdict->{P} = PDFLiteral(
                $pdf->{catalog}->{Pages}->{Kids}->{' val'}[0]->{' objnum'} . " 0 R");
        } else {
            $sigformdict->{P} = $pdf->open_page(1);
        }
        $sigformdict->{Rect} = PDFLiteral("[0 0 0 0]");
        delete $sigformdict->{Border};
        $sigformdict = $p->new_obj($sigformdict);
        push @formarray, $sigformdict;
    }

    my $acroformdict = PDFDict();
    $acroformdict->{Fields}   = PDFArray(@formarray);
    $acroformdict->{SigFlags} = PDFNum(3);
    $acroformdict = $p->new_obj($acroformdict);

    $pdf->{catalog}->{'AcroForm'} = $acroformdict;
    $pdf->{pdf}->out_obj($pdf->{catalog});
}

# ============================================================
# sub: sign_file
# Applies the CMS/CAdES signature to the PDF byte stream.
# Returns the signed PDF as a string.
# ============================================================
sub sign_file {
    my $pdf = shift;
    my $data;
    $data = $pdf->to_string();

    if (!(-e $privkey_pem && -e $x509_pem)) { return $data; }

    my $sigbegin = rindex($data, '/Contents <00000000') + length '/Contents ';
    my $sigend   = index($data, '00000000>', $sigbegin) + length '00000000>';
    my $eofsize  = length($data) - $sigend;

    # PDF32000-2008 12.8.1
    # A byte range digest shall be computed over a range of bytes in the file, that shall be
    # indicated by the ByteRange entry in the signature dictionary. This range should be the
    # entire file, including the signature dictionary but excluding the signature value its-
    # elf (the Contents entry). Other ranges may be used but since they do not check for all
    # changes to the document, their use is not recommended.
    my $byterange = sprintf("/ByteRange [0 %8d %8d %8d]", $sigbegin, $sigend, $eofsize);
    $data =~ s/\/ByteRange \[$zerorange\]/$byterange/e;

    if ($sigend - $sigbegin != ($siglen + 1) * 2) {
        warn "sign_file: Wrong range selected. Skipped.\n";
        return $data; 
    }

    my $streamtext         = substr($data, 0, $sigbegin) . substr($data, $sigend, $eofsize);
    my $streamtextfilename = "$tmpdir/pdfsign_streamtext_$$.pdf";
    write_file($streamtextfilename, { binmode => ':raw' }, $streamtext);

    my $signature = cms_sign(
        signer   => $x509_pem,
        inkey    => $privkey_pem,
        in       => $streamtextfilename,
        certfile => $x509_chain || undef,
    );
    
    if (length($signature) > $siglen) { 
        warn "sign_file: Can't apply sign. It's too big for siglen. Skipped.\n";
        return $data;
    }
    
    my $sighex = PDFStrHex($signature)->as_pdf;
    # remove last ">" char
    chop $sighex;
    substr($data, $sigbegin, length($sighex), $sighex);

    unlink $streamtextfilename;
    return $data;
}

# ============================================================
# sub: prepare_ts
# Prepares the PDF AcroForm structure for a RFC3161 DocTimeStamp.
# Appends to existing AcroForm if a signature field already exists.
# TODO: $presign not yet implemented (visible timestamp widget)
# ============================================================
sub prepare_ts {
    my $pdf     = $_[0];
    my $p       = $pdf->{'pdf'};
    my $presign = $_[1];

    my $sigdict           = PDFDict();
    $sigdict->{Type}      = PDFName("DocTimeStamp");
    $sigdict->{Filter}    = PDFName("Adobe.PPKLite");
    # Ongoing investigation: first the chicken or the egg, the timestamp how do you know it first
    # seems to be correct not to indicate it here
    #$sigdict->{M} = PDFStr(strftime("D:%Y%m%d%H%M%S%z", localtime));
    $sigdict->{SubFilter} = PDFName('ETSI.RFC3161');
    $sigdict->{Contents}  = PDFStrHex("\0" x $siglen);
    $sigdict->{ByteRange} = PDFLiteral("[$zerorange]");
    $sigdict = $p->new_obj($sigdict);

    my @formarray;
    my $sigformdict = PDFDict();
    $sigformdict->{Type}    = PDFName("Annot");
    $sigformdict->{Subtype} = PDFName("Widget");
    $sigformdict->{F}       = PDFNum(4 + 128);
    $sigformdict->{FT}      = PDFName("Sig");
    $sigformdict->{T}       = PDFStr("Signature2");
    $sigformdict->{V}       = $sigdict;
    if ($pdf->{catalog}->{Pages}->{Kids}->{' val'}[0]->{' objnum'}) {
        $sigformdict->{P} = PDFLiteral(
            $pdf->{catalog}->{Pages}->{Kids}->{' val'}[0]->{' objnum'} . " 0 R");
    } else {
        $sigformdict->{P} = $pdf->open_page(1);
    }
    $sigformdict->{Rect} = PDFLiteral("[0 0 0 0]");
    delete $sigformdict->{Border};
    $sigformdict = $p->new_obj($sigformdict);
    push @formarray, $sigformdict;

    my $acroformdict = PDFDict();
    if ($pdf->{catalog}->{AcroForm}->{' objnum'}) {
        my $signprec = $pdf->{catalog}->{AcroForm}->{' objnum'} - 1;
        push @formarray, PDFLiteral("$signprec 0 R");
    }
    $acroformdict->{Fields}   = PDFArray(@formarray);
    $acroformdict->{SigFlags} = PDFNum(3);
    $acroformdict = $p->new_obj($acroformdict);
    $pdf->{catalog}->{'AcroForm'} = $acroformdict;
    $pdf->{pdf}->out_obj($pdf->{catalog});
}

# ============================================================
# sub: ts_file
# Applies the RFC3161 timestamp to the PDF byte stream.
# Returns the timestamped PDF as a string.
# ============================================================
sub ts_file {
    my $pdf = shift;
    my $data;
    $data = $pdf->to_string();

    my $sigbegin = rindex($data, '/Contents <00000000') + length '/Contents ';
    my $sigend   = index($data, '00000000>', $sigbegin) + length '00000000>';
    my $eofsize  = length($data) - $sigend;

    # PDF32000-2008 12.8.1
    # A byte range digest shall be computed over a range of bytes in the file, that shall be
    # indicated by the ByteRange entry in the signature dictionary. This range should be the
    # entire file, including the signature dictionary but excluding the signature value its-
    # elf (the Contents entry). Other ranges may be used but since they do not check for all
    # changes to the document, their use is not recommended.
    my $byterange = sprintf("/ByteRange [0 %8d %8d %8d]", $sigbegin, $sigend, $eofsize);
    $data =~ s/\/ByteRange \[$zerorange\]/$byterange/;

    if ($sigend - $sigbegin != ($siglen + 1) * 2) { return $data; }

    my $streamtext         = substr($data, 0, $sigbegin) . substr($data, $sigend, $eofsize);
    my $streamtextfilename = "$tmpdir/pdfsign_streamtext_$$.pdf";
    write_file($streamtextfilename, { binmode => ':raw' }, $streamtext);

    my $tsqfile = "$streamtextfilename.tsq";
    ts_query(
        in  => $streamtextfilename,
        out => $tsqfile,
    );

    my $timestamp = tsa_fetch(
        tsq     => $tsqfile,
        tsa_url => $tsaserver,
    );

    my $sighex = PDFStrHex($timestamp)->as_pdf;
    chop $sighex;
    substr($data, $sigbegin, length($sighex), $sighex);

    unlink $streamtextfilename;
    unlink $tsqfile;
    return $data;
}

# ============================================================
# sub: cms_sign
# Signs a file stream with openssl cms, returns raw DER bytes.
# Falls back to openssl smime if cms is not available
# (LibreSSL 2.x, very old OpenSSL).
# Supports OpenSSL 3+ (-cades, ETSI.CAdES.detached).
# ============================================================
sub cms_sign {
    my (%args) = @_;
    # args: signer, inkey, in, certfile (optional)

    my $signature;

    if ($has_cms) {
        my @cmd = (
            $osslcmd,
            'cms', '-nosmimecap', '-md', 'sha256', '-binary', '-sign',
        );
        # -cades only with OpenSSL 3+ (not LibreSSL)
        push @cmd, '-cades' if $osslv =~ /^OpenSSL 3/;

        push @cmd, '-signer',   $args{signer};
        push @cmd, '-certfile', $args{certfile} if $args{certfile};
        push @cmd, '-inkey',    $args{inkey};
        push @cmd, '-in',       $args{in};
        push @cmd, '-outform',  'pem';

        {
            local $/;
            open(my $fh, '-|', @cmd)
                or die "Cannot exec openssl cms: $!";
            $signature = <$fh>;
            close $fh
                or die "openssl cms failed (exit " . ($? >> 8) . ")";
        }
        #write_file("$tmpdir/pdfsign_debug_".substr($osslv,0,13).".p7s", {binmode => ':raw'}, $signature);

        # strip PEM header/footer lines (-----BEGIN/END CMS-----)
        $signature =~ s/^--.*--\n//mg;
        $signature = decode_base64($signature);

    } else {
        # fallback: openssl smime (LibreSSL 2.x, old OpenSSL)
        # smime produces S/MIME output - strip headers up to blank line,
        # then strip PEM armor, decode base64
        warn "PDF::Sign: cms not available, falling back to smime\n" if $debug;

        my @cmd = (
            $osslcmd,
            'smime', '-binary', '-sign', '-nodetach',
        );
        push @cmd, '-signer',   $args{signer};
        push @cmd, '-certfile', $args{certfile} if $args{certfile};
        push @cmd, '-inkey',    $args{inkey};
        push @cmd, '-in',       $args{in};
        push @cmd, '-outform',  'pem';

        {
            local $/;
            open(my $fh, '-|', @cmd)
                or die "Cannot exec openssl smime: $!";
            $signature = <$fh>;
            close $fh
                or die "openssl smime failed (exit " . ($? >> 8) . ")";
        }

        # strip S/MIME headers (everything up to and including blank line)
        $signature =~ s/\A.*?\n\n//s;
        # strip PEM armor
        $signature =~ s/^--.*--\n//mg;
        $signature = decode_base64($signature);
    }

    # TODO: debug mode - capture stderr separately (platform portability TBD)
    return $signature;
}

# ============================================================
# sub: ts_query
# Generates the .tsq file for the TSA request via openssl ts.
# Uses openssl.cnf if present in the current directory.
# ============================================================
sub ts_query {
    my (%args) = @_;
    # args: in (file to timestamp), out (output .tsq file)

    # sanitize paths - strip non path chars  to prevent shell injection
    # (shell form used intentionally for stderr redirection, see note below)
    (my $in_safe  = $args{in})  =~ s/[^\\\:\_\w\.\/\-]//g;
    (my $out_safe = $args{out}) =~ s/[^\\\:\_\w\.\/\-]//g;

    # NOTE: shell form used intentionally here (not list form) to allow
    # stderr redirection (2>/dev/null) and suppress openssl noise:
    #   "Using configuration from openssl.cnf"
    # This is acceptable in CGI/Apache context where error_log pollution
    # is a real operational concern. The input paths come from caller-
    # controlled configuration, not from external user input.

    my @cmd = (
        $osslcmd,
        'ts', '-query',
        '-data', "\"$in_safe\"",
        '-sha256', '-cert',
        '-out',  "\"$out_safe\"",
    );
    # use openssl.cnf only if present in current directory
    # avoid logging "Using configuration from openssl.cnf" in STDERR
    my $null = ($^O eq 'MSWin32' ? 'nul' : '/dev/null');

    push @cmd, '-config', "openssl.cnf", "2>$null" if -e 'openssl.cnf';

    local $" = " ";
    open(my $fh, '-|', "@cmd")
        or die "Cannot exec openssl ts: $!";
    # output goes to .tsq file, stdout is empty
    close $fh
        or die "openssl ts query failed (exit " . ($? >> 8) . ")";

    # TODO: debug mode - capture stderr separately (platform portability TBD)
    return 1;
}

# ============================================================
# sub: tsa_fetch
# Sends the .tsq to the TSA server, returns TimeStampToken DER.
# Uses curl if available, falls back to LWP::UserAgent.
#
# Note on substr($timestamp, 9, ...):
#   The TSA response is a TimeStampResp DER structure:
#     SEQUENCE {
#       status INTEGER(0),   -- 9 bytes: 30 03 02 01 00
#       TimeStampToken       -- the actual token to embed in PDF
#     }
#   We strip the outer wrapper and embed only the inner token.
#   This is intentional per RFC3161, not a workaround.
#
# Note on binmode:
#   The token is binary DER - binmode prevents Perl from mangling
#   0x0d bytes on Windows (CRLF translation).
# ============================================================
sub tsa_fetch {
    my (%args) = @_;
    # args: tsq (input .tsq file), tsa_url

    my $timestamp;

    # prefer curl if available in PATH
    my $curl = _which('curl');
    if ($curl) {
        my @cmd = (
            $curl, '-s',
            '-H', 'Content-Type: application/timestamp-query',
            '--data-binary', '@' . $args{tsq},
            $args{tsa_url},
        );
        local $/;
        open(my $fh, '-|', @cmd)
            or die "Cannot exec curl: $!";
        binmode $fh;  # DER is binary - critical on Windows
        $timestamp = <$fh>;
        close $fh
            or die "curl tsa_fetch failed (exit " . ($? >> 8) . ")";
    } elsif ($HAS_LWP) {
        my $tsq_data = do {
            open(my $fh, '<:raw', $args{tsq})
                or die "Cannot read tsq file: $!";
            local $/;
            <$fh>;
        };
        my $ua  = LWP::UserAgent->new(timeout => 30);
        my $res = $ua->post(
            $args{tsa_url},
            'Content-Type' => 'application/timestamp-query',
            Content        => $tsq_data,
        );
        die "TSA request failed: " . $res->status_line unless $res->is_success;
        $timestamp = $res->content;
    } else {
        die "tsa_fetch requires curl or LWP::UserAgent\n";
    }

    # strip TimeStampResp outer wrapper (9 bytes: SEQUENCE + status granted)
    # retain only the inner TimeStampToken DER for embedding in PDF
    # structure: 30 82 xx xx 30 03 02 01 00 [TimeStampToken starts here]
    $timestamp = substr($timestamp, 9, length($timestamp));

    # TODO: debug mode - capture stderr separately (platform portability TBD)
    return $timestamp;
}


# ============================================================
# sub: verify_signatures
# Reads and verifies all digital signatures in a PDF file.
# Returns an arrayref of hashrefs, one per signature field:
#
#   [{
#     type       => 'cms' | 'tsa',
#     subfilter  => 'ETSI.CAdES.detached' | 'adbe.pkcs7.detached' | 'ETSI.RFC3161',
#     signer     => 'CN=..., O=...',       # subject from sig dict or openssl output
#     signed_at  => 'D:20260329...',       # /M field from sig dict (cms only)
#     tsa_at     => '...',                 # timestamp from TSA token (tsa only)
#     valid      => '1' | '',             # cryptographic verification result
#     error      => '...',                # error message if valid is ''
#   }, ...]
#
# Verification uses openssl with -noverify (no CA chain check) by default.
# Pass ca_bundle => '/path/to/ca.pem' to enable full chain verification.
#
# Uses PDF::API2 (or PDF::Builder) to walk AcroForm signature fields,
# and extracts the DER blob directly from the ByteRange gap in the raw PDF.
# ============================================================
sub verify_signatures {
    my ($pdf_path, %args) = @_;
    my $ca_bundle = $args{ca_bundle};

    die "verify_signatures: file not found: $pdf_path\n" unless -e $pdf_path;

    # read raw PDF bytes - needed for ByteRange gap extraction
    open(my $fh, '<:raw', $pdf_path) or die "Cannot read $pdf_path: $!";
    my $raw = do { local $/; <$fh> };
    close $fh;

    # collect all real ByteRanges from raw PDF (skip zero placeholders)
    my @byteranges;
    my $scan_pos = 0;
    while (1) {
        my $br_pos = index($raw, '/ByteRange', $scan_pos);
        last if $br_pos < 0;
        my $br_str = substr($raw, $br_pos, 80);
        if ($br_str =~ m{/ByteRange\s*\[\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s*\]}) {
            my @br = ($1+0, $2+0, $3+0, $4+0);
            # skip placeholder (l1=0, o2=0, l2=0)
            push @byteranges, \@br
                unless $br[1] == 0 && $br[2] == 0 && $br[3] == 0;
        }
        $scan_pos = $br_pos + 10;
    }

    my @results;

    # open PDF via PDF::API2 to walk AcroForm signature fields
    my $pdf = $PDF_BACKEND->open($pdf_path);

    my $acroform = $pdf->{catalog}->{AcroForm};
    return [] unless $acroform;
    $acroform = $acroform->realise
        if $acroform->isa($PDF_BACKEND.'::Basic::PDF::Objind');

    my $fields = $acroform->{Fields};
    return [] unless $fields;
    $fields = $fields->realise
        if $fields->isa($PDF_BACKEND.'::Basic::PDF::Objind');

    my @field_list = $fields->elements;

    my $sig_index = 0;  # match fields to ByteRanges in order

    for my $field_ref (@field_list) {
        my $field = $field_ref;
        $field = $field->realise
            if $field->isa($PDF_BACKEND.'::Basic::PDF::Objind');

        # only process signature fields
        my $ft = $field->{FT} or next;
        next unless $ft->val eq 'Sig';

        # get signature value dict
        my $sigval = $field->{V} or next;
        $sigval = $sigval->realise
            if $sigval->isa($PDF_BACKEND.'::Basic::PDF::Objind');

        # extract metadata from sig dict
        my $subfilter = $sigval->{SubFilter} ? $sigval->{SubFilter}->val : '';
        my $signed_at = $sigval->{M}         ? $sigval->{M}->val         : '';
        my $signer    = $sigval->{Name}      ? $sigval->{Name}->val      : '';

        my $type = ($subfilter eq 'ETSI.RFC3161') ? 'tsa' : 'cms';

        # get ByteRange for this signature

        # estrai i primi 16 bytes hex del Contents per identificare il ByteRange
        my $contents_obj = $sigval->{Contents};
        my $contents_raw = $contents_obj ? $contents_obj->as_pdf : '';
        # as_pdf produce <3082...0000> - estrai i primi caratteri hex significativi
        my $contents_prefix = '';
        if ($contents_raw =~ m{<([0-9a-fA-F]{16,})}) {
            $contents_prefix = lc(substr($1, 0, 16));
        }

        # cerca il ByteRange il cui gap contiene questo prefix
        my $br;
        for my $candidate (@byteranges) {
            my $gap = substr($raw, $candidate->[1], $candidate->[2] - $candidate->[1]);
            my $gap_hex = '';
            if ($gap =~ m{<([0-9a-fA-F]+)>}) {
                $gap_hex = lc(substr($1, 0, 16));
            }
            if ($contents_prefix && $gap_hex eq $contents_prefix) {
                    $br = $candidate;
                    last;
            }
        }

        unless ($br) {
            push @results, {
                type => $type, subfilter => $subfilter,
                signer => $signer, signed_at => $signed_at,
                tsa_at => '', valid => '', error => 'ByteRange not found',
            };
            next;
        }

        # extract DER from the gap between ByteRange[1] and ByteRange[2]
        # this gap contains exactly: /Contents <hexDER 00padding>
        my $gap = substr($raw, $br->[1], $br->[2] - $br->[1]);
        my $contents_hex = '';
        if ($gap =~ m{<([0-9a-fA-F]+)>}) {
            $contents_hex = $1;
        }

        unless ($contents_hex) {
            push @results, {
                type => $type, subfilter => $subfilter,
                signer => $signer, signed_at => $signed_at,
                tsa_at => '', valid => '', error => 'Contents hex not found in ByteRange gap',
            };
            next;
        }

        # decode full hex to binary - then trim to actual ASN.1 length
        # do NOT use regex strip of trailing zeros: legitimate DER may end with 0x00
        # instead read the ASN.1 SEQUENCE length from the DER header
        my $der_full = pack('H*', $contents_hex);
        my $der = $der_full;
        if (length($der_full) >= 4 && ord(substr($der_full,0,1)) == 0x30) {
            my $len_byte = ord(substr($der_full,1,1));
            my $der_len;
            if ($len_byte & 0x80) {
                # long form length
                my $num_bytes = $len_byte & 0x7f;
                $der_len = 0;
                for my $i (0 .. $num_bytes-1) {
                    $der_len = ($der_len << 8) | ord(substr($der_full, 2+$i, 1));
                }
                $der_len += 2 + $num_bytes;  # header + content
            } else {
                # short form length
                $der_len = $len_byte + 2;
            }
            $der = substr($der_full, 0, $der_len) if $der_len <= length($der_full);
        }

        # rebuild signed content from the two ByteRange regions
        my $signed_content = substr($raw, $br->[0], $br->[1])
                           . substr($raw, $br->[2], $br->[3]);

        #warn "br: " . join(', ', @$br) . "\n";
        #warn "raw length: " . length($raw) . "\n";
        #warn "gap start: $br->[1], gap length: " . ($br->[2] - $br->[1]) . "\n";
        #warn "first bytes of gap: " . unpack('H*', substr($gap, 0, 20)) . "\n";
        #warn "contents_hex length: " . length($contents_hex) . "\n";
        #warn "der length after trim: " . length($der) . "\n";
        #warn "first bytes der: " . unpack('H*', substr($der, 0, 4)) . "\n";
        #warn "signed_content length: " . length($signed_content) . "\n";

        # write temp files for openssl
        my $tmp_der     = "$tmpdir/pdfsign_verify_der_".$$."_$type.tmp";
        my $tmp_content = "$tmpdir/pdfsign_verify_content_".$$."_$type.tmp";
        write_file($tmp_der,     { binmode => ':raw' }, $der);
        write_file($tmp_content, { binmode => ':raw' }, $signed_content);

        my ($valid, $error, $tsa_at) = ('', '', '');

        # estrai il certificato dal CMS DER
        my $tmp_cert = "$tmpdir/pdfsign_verify_cert_".$$."_$type.pem";
        `$osslcmd cms -inform DER -in \Q$tmp_der\E -verify -noverify -certsout \Q$tmp_cert\E -out /dev/null 2>/dev/null`;

        my $noverify = $ca_bundle
            ? "-CAfile \Q$ca_bundle\E"
            : (-e $tmp_cert ? "-CAfile \Q$tmp_cert\E -noverify" : '-noverify');

        if ($type eq 'cms') {
            # -binary: treat content as binary (required for PDF byte streams)
            # -out /dev/null: suppress verified content on stdout
            my $null = ($^O eq 'MSWin32' ? 'nul' : '/dev/null');

            #warn "CMD: $osslcmd cms -verify -binary -in $tmp_der -inform DER -content $tmp_content -out $null $noverify\n";

            my $out = `$osslcmd cms -verify -binary -in \Q$tmp_der\E -inform DER -content \Q$tmp_content\E -out $null $noverify 2>&1`;
            if ($? == 0 || $out =~ /Verification successful/i) {
                $valid = '1';
                # try to extract signer from openssl output if not in sig dict
                if (!$signer && $out =~ /subject=([^\n]+)/i) {
                    ($signer = $1) =~ s/^\s+|\s+$//g;
                }
            } else {
                ($error = $out) =~ s/\n/ /g;
                $error =~ s/^\s+|\s+$//g;
            }

        } elsif ($type eq 'tsa') {
            my $sys_ca = (-e '/etc/ssl/certs/ca-certificates.crt') 
                            ? '/etc/ssl/certs/ca-certificates.crt'      # Debian/Ubuntu
                            : (-e '/etc/ssl/cert.pem') 
                            ? '/etc/ssl/cert.pem'                       # macOS/FreeBSD
                            : undef;

            my $ts_verify_ca = $ca_bundle
                            ? "-CAfile \Q$ca_bundle\E"
                            : (-e $tmp_cert && -s $tmp_cert 
                            ? "-CAfile \Q$tmp_cert\E" 
                            : ($sys_ca ? "-CAfile \Q$sys_ca\E" : ''));

            #warn "CMD: $osslcmd ts -verify -in \Q$tmp_der\E -token_in -data \Q$tmp_content\E $ts_verify_ca 2>&1\n";

            my $out = `$osslcmd ts -verify -in \Q$tmp_der\E -token_in -data \Q$tmp_content\E $ts_verify_ca 2>&1`;
            if ($? == 0 || $out =~ /Verification:\s*OK/i) {
                $valid = '1';
            } else {
                ($error = $out) =~ s/\n/ /g;
                $error =~ s/^\s+|\s+$//g;
            }

            # extract human-readable timestamp from TSA token
            my $tsa_text = `$osslcmd ts -reply -in \Q$tmp_der\E -token_in -text 2>&1`;
            if ($tsa_text =~ /Time stamp:\s*([^\n]+)/i) {
                ($tsa_at = $1) =~ s/^\s+|\s+$//g;
            }
        }

        unlink $tmp_der, $tmp_content, $tmp_cert;

        push @results, {
            type      => $type,
            subfilter => $subfilter,
            signer    => $signer,
            signed_at => $signed_at,
            tsa_at    => $tsa_at,
            valid     => $valid,
            error     => $error,
        };
    }

    return \@results;
}


# ============================================================
# internal: _cert_subject
# Extracts subject name from a PEM certificate via openssl.
# Handles OpenSSL 1.x/3.x and LibreSSL output format differences:
#   1.x: subject= /C=IT/O=Org/CN=Name   (slash-separated, leading space)
#   3.x: subject=CN=Name, O=Org, C=IT   (comma-separated, RFC2253 order)
# Returns a normalized string suitable for the PDF /Name field.
# ============================================================
sub _cert_subject {
    my $pem = shift;
    open(my $fh, '-|', $osslcmd, 'x509', '-noout', '-subject', '-in', $pem)
        or die "Cannot exec openssl x509: $!";
    my $subject = do { local $/; <$fh> };
    close $fh
        or die "openssl x509 failed (exit " . ($? >> 8) . ")";
    chomp $subject;

    # OpenSSL 1.x/LibreSSL: "subject= /C=IT/O=Org/CN=Name"
    # normalize to "C=IT, O=Org, CN=Name"
    if ($subject =~ m{^subject=\s*/}) {
        $subject =~ s{^subject=\s*/}{};   # strip prefix and leading slash
        $subject =~ s{/}{, }g;            # slashes to comma-space
    }
    # OpenSSL 3.x: "subject=CN=Name, O=Org, C=IT"
    # just strip the prefix
    elsif ($subject =~ m{^subject=}) {
        $subject =~ s{^subject=\s*}{};
    }

    return $subject;
}

# ============================================================
# internal: _which
# Portable `which` - returns full path of binary or undef.
# ============================================================
sub _which {
    my $bin = shift;
    for my $dir (split /:/, ($ENV{PATH} // '')) {
        my $full = "$dir/$bin";
        return $full if -x $full;
    }
    return undef;
}
unless ($PDF_BACKEND) {
    # installa stub che muoiono per le funzioni che richiedono il backend
    no warnings 'redefine';
    no strict 'refs';
    for my $fn (qw(prepare_file sign_file prepare_ts ts_file)) {
        *{"PDF::Sign::$fn"} = sub {
            die "PDF::Sign: $fn requires PDF::API2 or PDF::Builder\n";
        };
    }
}

1;