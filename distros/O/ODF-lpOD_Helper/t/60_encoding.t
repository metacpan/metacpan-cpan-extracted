#!/usr/bin/perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp, Data::Dumper::Interp, etc.
use t_TestCommon ':silent',
                 qw/bug ok_with_lineno like_with_lineno
                    rawstr showstr showcontrols displaystr 
                    show_white show_empty_string
                    fmt_codestring 
                    timed_run
                    mycheckeq_literal mycheck _mycheck_end
                  /;
use ODF::lpOD;
use ODF::lpOD_Helper qw/:chars :DEFAULT fmt_node fmt_match fmt_tree/;

#####################################################################
#
# Test encoding support (specifically, lack of breakage from :chars) 
# by creating a document containing "wide" chars, and manually 
# re-encoding it various ways and having ODF::lpOD read it back.
#
#####################################################################

our $debug = grep /-debug/, "@ARGV";

my $tmpdir;
if ($debug) {
  $tmpdir = "/tmp/".basename(__FILE__,".t")."-TEMP";
  note "**Using temp directory ",qsh($tmpdir);
  rmtree($tmpdir);
  make_path($tmpdir);
} else {
  $tmpdir = File::Temp::tempdir(CLEANUP => 1);
}

#-----------------------------------------------------
package MyXML;
use Carp;
use Data::Dumper::Interp;
use Encode qw(encode decode);
use Archive::Zip qw(:ERROR_CODES :CONSTANTS);
use Test2::V0; #for 'note' and 'diag'

use constant DEFAULT_MEMBER_NAME => "content.xml";

sub encode_xml($$;$) {
  my ($chars, $encoding, $desc) = @_;
  confess "bug" unless defined($chars) && defined($encoding);
  $chars =~ s/(<\?xml[^\?]*encoding=")([^"]+)("[^\?]*\?>)/$1${encoding}$3/s
    or confess qq(Could not find <?xml ... encoding="..."?>),
               ($desc ? " in $desc" : "");
  my $octets = encode($encoding, $chars, Encode::FB_CROAK|Encode::LEAVE_SRC);
  $octets
}

sub decode_xml($;$) {
  my ($octets, $desc) = @_;
  my $chars;
  my $encoding;
  if (length($octets) == 0) {
    $chars = "";
  } else {
    ($encoding) = ($octets =~ /<\?xml[^\?]*encoding="([^"]+)"[^\?]*\?>/);
    confess qq(Could not find <?xml ... encoding="..."?>),
            ($desc ? " in $desc" : "")
      unless $encoding;
    $chars = decode($encoding, $octets, Encode::FB_CROAK);
  }
  wantarray ? ($chars, $encoding) : $chars
}

sub new {
  my ($class, $path) = @_;
  my $zip = Archive::Zip->new();
  note "> Opening ",qsh($path)," at ",(caller(0))[2] if $main::debug;
  confess "Error reading $path ($!)"
    unless $zip->read($path) == AZ_OK;
  bless \$zip, $class
}

sub get_content {
  my $self = shift;
  my $member_name = $_[0] // DEFAULT_MEMBER_NAME;

  my $zip = $$self;

  my $member = $zip->memberNamed($member_name)
    // confess "No such member ",visq($member_name);

  decode_xml( $member->contents(), $member_name )
}

sub replace_content {  # $obj->set_content($chars, encoding => "...")
  my $self = shift;
  my ($chars, %opts) = @_;
  my $member_name = $opts{member_name} // DEFAULT_MEMBER_NAME;
  my $encoding = $opts{encoding};
  confess "encoding must be specified" unless $encoding;

  my $octets = encode_xml($chars, $encoding, "new content");

  my $zip = $$self;
  my $member = $zip->memberNamed($member_name)
    // confess "No such member ",visq($member_name);
  $zip->removeMember($member_name);
  my $new_member = $zip->addString($octets, $member_name);
  $new_member->desiredCompressionMethod( COMPRESSION_DEFLATED );
}

sub store {
  my ($self, $dest_path) = @_;
  confess "Destination path missing" unless $dest_path;
  my $zip = $$self;
  note "> Writing ",qsh($dest_path)," at ",(caller(0))[2] if $main::debug;
  $zip->writeToFileNamed($dest_path) == AZ_OK
    or confess "Write error ($!)";
}

#-----------------------------------------------------
package main;

my $teststring = "AAA 低重心 BBB";
my $testoctets_re = qr/(AAA .* BBB)/s;

my $orig_path = "$tmpdir/original.odt";
{ my $doc = odf_new_document('text');
  my $body = $doc->get_body;
  my $para = odf_create_paragraph( text => $teststring );
  $body->append_element($para);
  $doc->save(target => $orig_path);
  $doc->forget;
}

my $orig_xmltext;
{ my $obj = MyXML->new($orig_path);
  ($orig_xmltext, my $enc) = $obj->get_content();
  ok($enc eq "UTF-8", "Default odf encoding is UTF-8");
  $orig_xmltext =~ qr/\Q$teststring\E/ or die "'$teststring' NOT FOUND!";
}

# N.B. All these encodings still map 0-127 to ASCII, so it is possible
# to parse the xml header when re-reading.  This is not the case, for example,
# with UTF-16 (which depends on BOM detection).
for my $alt_enc (qw/UTF-8 big5 euc-kr x-sjis-cp932/) {
  note "--- ",visq($alt_enc)," ---";
  my $new_path = "$tmpdir/using_${alt_enc}.odt";
  { 
    # Encode content.xml differently
    my $alt_xmloctets = eval { MyXML::encode_xml($orig_xmltext, $alt_enc) };
    if ($@) { diag "$alt_enc does not work"; next }
    oops "not encoded??" if $alt_xmloctets =~ /\Q$teststring\E/;
    $alt_xmloctets =~ /$testoctets_re/
      or oops "can not find encoded octets";
    note "Octets in $alt_enc are ",vis($1);

    # Parse the alternatively-encoded xml with XML::Twig's parse()
    my $twig = XML::Twig->new();
    $twig->parse($alt_xmloctets);  # expects binary octets as input
    { my $found;
      foreach my $para ($twig->descendants('text:p')) {
        foreach ($para->descendants()) {
          # but returns Perl *characters* from the text() method
          $found++ if ($_->text()//"") eq $teststring
        }
      }
      ok($found, "XML::Twig parse()'d $alt_enc, text() returned chars");
    }
    # Create an alternate ODF file and read it via ODF::lpOD
    my $obj = MyXML->new($orig_path);
    $obj->replace_content($orig_xmltext, encoding => $alt_enc);
    $obj->store($new_path);
    $obj = undef;
    $obj = MyXML->new($new_path);
    my ($xml, $enc) = $obj->get_content();
    bug unless $enc eq $alt_enc;

    note "> Opening ",qsh($new_path)," as ODF doc..." if $debug;
    my $doc = odf_get_document($new_path);
    my $body = $doc->get_body;
    { my $found;
      foreach my $para ($body->get_paragraphs) {
        my $text = $para->get_text // next;
        $found=1 if $text =~ /\Q${teststring}\E/;
      }
      ok($found, "Re-read ODF doc with content.xml encoded with $alt_enc");
    }
  }
}

done_testing();
