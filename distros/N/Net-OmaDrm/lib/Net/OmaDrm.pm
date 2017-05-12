package Net::OmaDrm;

use strict;
use warnings;
use diagnostics;

#use MIME::Base64;

# See the bottom of this file for the POD documentation.  Search for the
# string '=head'.

# You can run this file through either pod2man or pod2html to produce pretty
# documentation in manual or html file format (these utilities are part of the
# Perl 5 distribution).

# Copyright (c) 2007 Christopherus Goo.  All rights reserved.
# It may be used and modified freely, but I do request that this copyright
# notice remain attached to the file.  You may modify this module as you
# wish, but if you redistribute a modified version, please attach a note
# listing the modifications you have made.

# The most recent version and complete docs are available at:
#   http://www.artofmobile.com/software/

# April 2007. Singapore.

$Net::OmaDrm::VERSION=0.1;

=head1 NAME

 Net::OmaDrm - Perl Module to encapsulate OMA DRM format for a media type

  Open Mobile Alliance (OMA) is a standards body founded by telecommunication companies which develops open standards for the mobile phone industry. In order to ensure interoperability across all implementations for Digital Rights Management (DRM), the OMA provides DRM specifications so that content providers, operators and mobile phone manufacturers can easily integrate the DRM solution as smoothly as possible.

   This module supports the OMA DRM version 1.0 method of sending content to the handset. A device will declare the support for OMA-DRM by including one of the method which is provided by this module:

    > Forward-lock
        * Content-Type
            - application/vnd.oma.drm.message
    > Combined delivery
        * Content-Type
            - application/vnd.oma.drm.message
            - application/vnd.oma.drm.rights+xml
        * o-ex:permission
            - o-dd:display
            - o-dd:play
        * o-ex:constraint
            - o-dd:count
            - o-dd:interval

   A detailed document of OMA-DRM can be found at:
     http://www.openmobilealliance.org/release_program/drm_v1_0.html
          
=head1 SYNOPSIS

  use Net::OmaDrm;

  my $mydrm = Net::OmaDrm->new($basepath);
  my $content= $mydrm->genForwardLock($content_name,$content_type);

=head1 DESCRIPTION

This module will encapulate the media type to a multi-type content with OMA DRM standard.

=head1 METHODS

=over 4

=item new

This method is used to create the OmaDrm object.

Usage:

  my $mydrm = Net::OmaDrm->new($basepath);

The complete list of arguments is:

  $basepath : This is the base path for the content.

=cut

sub new {
   my $class = shift || undef;
   return undef if( !defined $class);

   my $basepath = shift || undef;
   $basepath.='/' if ($basepath && !($basepath=~/\/$/));

   return bless { BASE_PATH  => $basepath
		}, $class;
}

sub readfile {
   my $class=shift;
   my $filename=shift;
   my $body;
   my $basepath = $class->{BASE_PATH} || '';
   $filename=$basepath.$filename;

   open WE, "$filename";
   my $count=1;
   my $partbody;
   while ($count>0) {
      $count = read WE, $partbody, 1;
      $body.=$partbody if ($count>0);
   }
   close WE;
   return $body;
}

sub getHeader {
   my $class=shift;
   return "Content-Type: application/vnd.oma.drm.message; boundary=boundary-1\r\n\r\n";
}

sub getContent {
   my $class=shift;
   my $parttype=shift;
   my $encoding=shift;
   my $parts=shift;

   my $body="--boundary-1\r\nContent-Type: $parttype\r\nContent-ID: <45678929547\@ArtOfMobile.bar>\r\n";
   $body.="Content-Transfer-Encoding: $encoding\r\n\r\n$parts\r\n--boundary-1--\r\n";

   return $body;
}

sub getRights {
   my $class=shift;
   my $interval=shift;
   my $count=shift;

   my $constraint='';
   $constraint.= "<o-ex:constraint><o-dd:count>$count</o-dd:count></o-ex:constraint>\n" if ($count);
   $constraint.= "<o-ex:constraint><o-dd:interval>$interval</o-dd:interval></o-ex:constraint>\n" if ($interval);

   my $body="--boundary-1\r\nContent-Type: application/vnd.oma.drm.rights+xml\r\nContent-Transfer-Encoding: binary\r\n\r\n";
   $body.=<<__CONTENT__RIGHT__;
<o-ex:rights xmlns:o-ex="http://odrl.net/1.1/ODRL-EX" xmlns:o-dd="http://odrl.net/1.1/ODRL-DD" > 
	<o-ex:context> 
		<o-dd:version>1.1</o-dd:version> 
	</o-ex:context> 
	<o-ex:agreement> 
		<o-ex:asset> 
			<o-ex:context> 
				<o-dd:uid>cid:45678929547\@ArtOfMobile.bar</o-dd:uid>
			</o-ex:context> 
		</o-ex:asset> 
		<o-ex:permission> 
			<o-dd:play>
				$constraint
			</o-dd:play>
			<o-dd:display>
				$constraint
			</o-dd:display>
		</o-ex:permission> 
	</o-ex:agreement>
</o-ex:rights>

__CONTENT__RIGHT__

}

=item genForwardLock

This method will generate the Forward Lock DRM with an input Media Type.

Usage:

  my $content= $mydrm->genForwardLock($content_name,$content_type);

The complete list of arguments is:

  $content_name : File name of the content.
  $content_type : Content Type.

=cut

sub genForwardLock {
   my $class = shift || undef;
   return undef if( !defined $class);
   my $name = shift || undef;
   return if (!defined $name);
   my $parttype = shift || undef;
   return if (!defined $parttype);

   return $class->genCombinedDelivery($name,$parttype,'','');
}

=item genCombinedDelivery

This method will generate multipart content with rights.

Usage:

  my $content= $mydrm->genCombinedDelivery($content_name,$content_type,$interval,$count);

Example:

  my $content= $mydrm->genCombinedDelivery("image.gif","image/gif",1,"");
  my $content= $mydrm->genCombinedDelivery("image.gif","image/gif","","P30S");

The complete list of arguments is:

  $content_name : File name of the content.
  $content_type : Content Type.
  $interval     : Interval that the content can play.
  $count        : Number of time that the content can play.

=cut

sub genCombinedDelivery {
   my $class = shift || undef;
   return undef if( !defined $class);
   my $name = shift || undef;
   return if (!defined $name);
   my $parttype = shift || undef;
   return if (!defined $parttype);
   my $interval = shift || undef;
   my $count = shift || undef;

   my $body=$class->readfile($name);

   my $content=$class->getHeader;
   $content.=$class->getRights($interval,$count) if ($interval || $count);
   #$content.=$class->getContent($parttype,'Base64',encode_base64($body));
   $content.=$class->getContent($parttype,'binary',$body);
   return $content;
}

=back 4

=head1 AUTHOR

Christopherus Goo <software@artofmobile.com>

=head1 COPYRIGHT

Copyright (c) 2007 Christopherus Goo.  All rights reserved.
This software may be used and modified freely, but I do request that this
copyright notice remain attached to the file.  You may modify this module
as you wish, but if you redistribute a modified version, please attach a
note listing the modifications you have made.

This software or the author aren't related to OMA in any way.

=cut

1;


