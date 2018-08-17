# TAP3::Tap3edit 
Is a Perl module for decoding, modifing and encoding Roaming GSM TAP/RAP/NRTRDE files.
This is the source code for prepairing the distribution. The module for installation can be found on https://metacpan.org/search?q=tap3edit

Please type `perldoc TAP3::Tap3edit` after installation to see the module usage information.

# Installation

- Automatically (Preferred method)

To install automatically (needs connection to the internet) use the command **cpan**.
Once inside its command line type following instruction:

  ```
  cpan[1]> install TAP3::Tap3edit
  ```
Note: This will install automatically all the dependencies too.

- Manually 

First the module has to be downloaded locally from https://metacpan.org/search?q=tap3edit
To install manually run these commands, substituting x.xx with the version number that you have downloaded.

  ```
  gunzip TAP3-Tap3edit-x.xx.tar.gz
  tar xvf TAP3-Tap3edit-x.xx.tar
  cd TAP3-Tap3edit-x.xx
  perl Makefile.PL
  make
  make test
  make install
  ```
Note: You will need to install all dependencies manually too.

# Local Installation

If you don't have root permissions and you want to test it locally.

  ```
  echo "PREFIX=$HOME/perllib \ "                              > $HOME/perl_local
  echo "INSTALLPRIVLIB=$HOME/perllib/lib/perl5 \ "           >> $HOME/perl_local
  echo "INSTALLSCRIPT=$HOME/perllib/bin \ "                  >> $HOME/perl_local
  echo "INSTALLSITELIB=$HOME/perllib/lib/perl5/site_perl \ " >> $HOME/perl_local
  echo "INSTALLBIN=$HOME/perllib/bin \ "                     >> $HOME/perl_local
  echo "INSTALLMAN1DIR=$HOME/perllib/lib/perl5/man \ "       >> $HOME/perl_local
  echo "INSTALLMAN3DIR=$HOME/perllib/lib/perl5/man/man3 "    >> $HOME/perl_local
  ```

  ```
  gunzip TAP3-Tap3edit-x.xx.tar.gz
  tar xvf TAP3-Tap3edit-x.xx.tar
  cd TAP3-Tap3edit-x.xx
  perl Makefile.PL `cat $HOME/perl_local`
  make
  make test
  make install
  ```

In your .profile add following lines:

  ```
  PERL5LIB=$HOME/perllib/lib/perl5:$HOME/perllib/lib/perl5/site_perl:
  export PERL5LIB
  ```

# Dependencies

This module requires these other modules and libraries:

- Convert::ASN1
- File::Spec
- File::Basename
- Carp

# Copyright

This program contains TAP, RAP and NRTRDE ASN.1 
Specification. The ownership of the TAP/RAP ASN.1 
Specifications belong to the GSM MoU Association 
(http://www.gsm.org) and should be used under following 
conditions:

Copyright (c) 2000 GSM MoU Association. Restricted − Con­
fidential Information.  Access to and distribution of this
document is restricted to the persons listed under the
heading Security Classification Category*. This document
is confidential to the Association and is subject to copy­
right protection.  This document is to be used only for
the purposes for which it has been supplied and informa­
tion contained in it must not be disclosed or in any other
way made available, in whole or in part, to persons other
than those listed under Security Classification Category*
without the prior written approval of the Association. The
GSM MoU Association (âAssociationâ) makes no representa­
tion, warranty or undertaking (express or implied) with
respect to and does not accept any responsibility for, and
hereby disclaims liability for the accuracy or complete­
ness or timeliness of the information contained in this
document. The information contained in this document may
be subject to change without prior notice.
