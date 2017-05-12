# Copyright (c) 2003, Cornell University
# See the file COPYING for the status of this software

package SOAP::Clean::Security;

use strict;
use warnings;

use SOAP::Clean::Internal;
use SOAP::Clean::XML;

BEGIN {
  use Exporter   ();
  our (@ISA, @EXPORT);

  @ISA         = qw(Exporter);
  @EXPORT      = qw(
		   );
};

########################################################################

#Digitally signing a document
sub digsign {
  my ($doc,$keyfile,$certfile,$sigapp) = @_;
  my $in_tmp = "/tmp/tmpdsig.tmpl";
  my $in_tmp2 = "/tmp/tmpdsig2.tmpl";
  open DOCIN, "> $in_tmp" || die("SOAP-ENV:Server - Error! Line ".__LINE__);
  print DOCIN "$doc";
  close DOCIN ||
        die("SOAP-ENV:Server - Error! Line ".__LINE__);
  system ("$sigapp sign --privkey $keyfile,$certfile $in_tmp > $in_tmp2");
  my $newdoc = docinsert($in_tmp2);
  return $newdoc;
}

########################################################################

#Verifying a signed document
sub digverify {
  my ($doc,$certfile,$sigapp) = @_;
  my $in_tmp = "/tmp/tmpdsigsrv.tmpl";
  my $in_tmp2 = "/tmp/dsiganswer.tmpl";
  open DOCIN, "> $in_tmp" || die("SOAP-ENV:Server - Error! Line ".__LINE__);
  print DOCIN "$doc";
  close DOCIN ||
        die("SOAP-ENV:Server - Error! Line ".__LINE__);
  system ("$sigapp verify --trusted $certfile $in_tmp > $in_tmp2");
  open ANS, "< $in_tmp2";

  my $newdoc = <ANS>;
  return $newdoc;


}

########################################################################

# Take a document $d. Encrypt its body, !!! in place !!!
sub encrypt_body {
  my ($d,$privkeyenc,$pubkeyenc,$enctmpl,$appl) = @_;

  my $envelope = xml_get_child($d,$SOAP_ENV,'Envelope');

  # fixme: Which of these are really needed?
  $envelope->setAttribute("xmlns:wsse",$wsse);
  $envelope->setAttribute("xmlns:xenc",$xenc);
  $envelope->setAttribute("xmlns:ds",$ds);

  my $body = xml_get_child($envelope,$SOAP_ENV,'Body');

  ##first encrypt the body
  my $encrypted_body = encrypt(xml_to_string($body),
			       $privkeyenc,
			       $pubkeyenc,
			       $enctmpl,
			       $appl);
  # now add the wsse:Security tag to make sure that we adapt to
  # WS-Security standard
  my $new_body = element("wsse:Security",namespace("wsse",$wsse),
			 $encrypted_body);
  $envelope->replaceChild($body,$new_body);
}

########################################################################

sub encrypt {
  my ($doc,$privkey,$pubkey,$enctmpl,$sigapp) = @_;
  my $in_tmp = "/tmp/tmpenc.tmpl";
  my $in_tmp2 = "/tmp/encanswer.tmpl";
  #my $in_tmp = tmpnam();
  #my $in_tmp2 = tmpnam();
  open DOCIN, "> $in_tmp" || die("SOAP-ENV:Server - Error! Line ".__LINE__);
  print DOCIN "$doc";
  close DOCIN ||
        die("SOAP-ENV:Server - Error! Line ".__LINE__);
  system ("$sigapp encrypt --session-key-des3 --pubkey $pubkey --privkey $privkey --binary $in_tmp $enctmpl > $in_tmp2");
  #return;
  
  my $newdoc = docinsert($in_tmp2);
  unlink($in_tmp,$in_tmp2);

  return $newdoc;
}

########################################################################

########################################################################

sub decrypt {
  my ($doc,$privkey,$pubkey,$sigapp,$env_in) = @_;
  my %env = %{$env_in}; 
  my $in_tmp = "/tmp/tmpdec.tmpl";
  my $in_tmp2 = "/tmp/decanswer.tmpl";
  open DOCIN, "> $in_tmp" || die("SOAP-ENV:Server - Error! Line ".__LINE__);
  print DOCIN "$doc";
  close DOCIN ||
        die("SOAP-ENV:Server - Error! Line ".__LINE__);
  open ANS, "> $in_tmp2" || die("SOAP-ENV:Server - Error! Line ".__LINE__);
  ##Here we need to insert a dummy tag with all the namespaces to do this correctly
  print ANS "<SOAP-ENV:Body ";
  my $keys;
  foreach $keys (keys %env){
    my $el = $env{$keys};
    $keys =~ s/^(.*):$/$1/; 
    print ANS " xmlns:$keys=\"$el\"";
  }
  print ANS ">";
  close ANS || die("SOAP-ENV:Server - Error! Line ".__LINE__);
  system ("$sigapp decrypt --privkey $privkey --pubkey $pubkey $in_tmp >> $in_tmp2");
  open ANS, ">> $in_tmp2" || die("SOAP-ENV:Server - Error! Line ".__LINE__);

  print ANS "</SOAP-ENV:Body>\n";
  close ANS || die("SOAP-ENV:Server - Error! Line ".__LINE__);
  
  my $newdoc = docinsert($in_tmp2);
  return $newdoc;
}

########################################################################

sub verify_envelope {
  my ($server,$d) = @_;


  defined($server->{dsig}) ||
    die("Error! file \"".__FILE__."\", line ".__LINE__);

  my $verification = 
    digverify(xml_to_string($d),$server->{cert},$server->{appl});
  $verification eq "OK\n" ||
    die("Error, your signature is a fraud!");
}


########################################################################

sub decrypt_body {

  my ($server,$d) = @_;


  defined($server->{enc}) ||
    die("Error! file \"".__FILE__."\", line ".__LINE__);


  my ($envelope,$namespaces) =
    destruct_children
      ($d,{},$SOAP_ENV,'Envelope');

  my ($body,$body_namespaces) =
    destruct_children($envelope,$namespaces,
		      $SOAP_ENV,'Body');

  #destruct the children to get the wsse:Security tag out
  my ($wsse,$wsse_namespaces) =
    destruct_children($body,$body_namespaces,
		      $wsse,'Security');

  #Inside the wsse:Security tag is the xenc:EncryptedData tag
  #Destruct the wsse:security node to get data
  my ($encr,$encr_namespaces) =
    destruct_children($wsse,$wsse_namespaces,
		      $xenc,'EncryptedData');

  ##decrypt it
  my $new_body = decrypt(xml_to_string($encr),$server->{privkeyenc},
		  $server->{pubkeyenc},$server->{appl},
		  $encr_namespaces);

  $envelope->replaceChild($body,$new_body);
}

########################################################################

1;
