package SysConfig::XML;

our $VERSION = '0.2';

#####################################################################
# XML.pm
# by Patrick Devine
# patrick@bubblehockey.org
#
# This software is covered under the same terms as Perl itself.
#
# WARNING:
#
# This software is no where near finished and lots of stuff will
# probably change before it is officially released (as 1.0).
#

use SysConfig;
@ISA = qw/ SysConfig /;

$TAB	= 2;

#####################################################################
# method:	xml
# function:	creates a scalar containing all of the data necessary
#		for to create a kickstart file

sub xml {
  my $self	= shift;
  my $version	= shift;

  my $buf;
  my $settings	= $self->{settings};


  $buf = _hash_pair( $settings, $TAB, '' );

  \$buf;


}

sub _hash_pair {
  my $data_set	= shift;
  my $offset	= shift;
  my $node_name	= shift;

  my $buf;

  if( ref( $data_set ) eq 'HASH' ) {
    for( sort keys %{ $data_set } ) {

      if( ref( $data_set->{$_} ) eq 'HASH' ) {
        $buf .= ' ' x $offset . "<$_>\n";
        $buf .= _hash_pair( $data_set->{$_}, $offset + $TAB, '' );
        $buf .= ' ' x $offset . "</$_>\n";
      } elsif( ref( $data_set->{$_} ) eq 'ARRAY' ) {
        #$buf .= ' ' x $offset . "<$_>\n";
        $buf .= _hash_pair( $data_set->{$_}, $offset, $_ );
        #$buf .= ' ' x $offset . "</$_>\n";
      } else {
        $buf .= ' ' x $offset . "<$_>";
        $buf .= _hash_pair( $data_set->{$_}, 0, '' ) . "</$_>\n";
      }
    }
  } elsif( ref( $data_set ) eq 'ARRAY' ) {
    for my $array ( @{ $data_set } ) {
      if( ref( $array ) eq 'ARRAY' ) {
        $buf .= ' ' x $offset . "<$node_name>";
        $buf .= _hash_pair( $array, 0, '' );
	$buf .= "</$node_name>\n";
      } elsif( ref( $array ) eq 'HASH' ) {
        $buf .= ' ' x $offset . "<$node_name>\n";
        $buf .= _hash_pair( $array, $offset + $TAB, '' );
        $buf .= ' ' x $offset . "</$node_name>\n";
      } else {
        $buf .= ' ' x $offset . "<$node_name>";
        $buf .= _hash_pair( $array, 0, '' );
	$buf .= "</$node_name>\n";
      }
    }

  } else {
    $buf .= ( $data_set ? "$data_set" : 'true' );
  }

  $buf;

}


1;

__END__

=head1 NAME

Kickstart - generate RedHat Kickstart files.

=head1 DESCRIPTION

XML.pm uses the B<SysConfig.pm> module to allow a perl script to make
method calls which generate an XML file.

=item auth { KEY => VALUE, ... }

=item auth

The auth method allows for the configuration of various authentication
parameters such as MD5 and Shadow passwords, and NIS, LDAP, Kerberos and
Hesiod configuration.

    enablemd5		use md5 password encryption
    enablenis		enable NIS support
    nisdomain		specify a domain name for NIS
    nisserver		specify a server to use with NIS
    useshadow		use shadow passwords
    enableldap		enable LDAP user authentication
    ldapserver		specify an LDAP server
    ldapbasedn		specify the base LDAP domain name
    enablekrb5		enable Kerberos 5 authentication
    krb5realm		specify the Kerberos realm
    krb5kdc		specify a list of KDC values
    krb5adminserver	specify the master KDC
    enablehesiod	enable Hesiod support for directory lookup
    hesiodlhs		specify heriod lhs (left-hand side)
    hesiodrhs		specify heriod rhs (right-hand side)

=item clearpart all | linux

=item clearpart

Specify which partitions on a disk to remove in order to set up the correct
partitions.

    all		removes all partitions
    linux	remove ext2, swap raid partitions

=item device

=item device

Not currently working.

=item driverdisk

=item driverdisk { KEY => VALUE, ... }

Specify a disk which will be copied to the root directory of the installed
system.

    partition	specify the partition containing the driver disk
    type	specify the file system type of the partition

=item install

=item install

[text to come]

=item inst_type

=item inst_type

[text to come]

=item keyboard VALUE

=item keyboard

The keyboard method is used to specify the type of keyboard which is
attached to a system.

Valid values for x86 architecture include:

C<azerty>, C<be-latin1>, C<be2-latin1>, C<fr-latin0>, C<fr-latin1>, C<fr-pc>,
C<fr>, C<wangbe>, C<ANSI-dvorak>, C<dvorak-l>, C<dvorak-r>, C<dvorak>,
C<pc-dvorak-latin1>, C<tr_f-latin5>, C<trf>, C<bg>, C<cf>, C<cz-lat2-prog>,
C<cz-lat2>, C<defkeymap>, C<defkeymap_V1.0>, C<dk-latin1>, C<dk. emacs>,
C<emacs2>, C<es>, C<fi-latin1>, C<fi>, C<gr-pc>, C<gr>, C<hebrew>, C<hu101>,
C<is-latin1>, C<it-ibm>, C<it>, C<it2>, C<jp106>, C<la-latin1>, C<lt>,
C<lt.l4>, C<nl>, C<no-latin1>, C<no>, C<pc110>, C<pl>, C<pt-latin1>,
C<pt-old>, C<ro>, C<ru-cp1251>, C<ru-ms>, C<ru-yawerty>, C<ru>, C<ru1>, C<ru2>,
C<ru_win>, C<se-latin1>, C<sk-prog-qwerty>, C<sk-prog>, C<sk-qwerty>,
C<tr_q-latin5>, C<tralt>, C<trf>, C<trq>, C<ua>, C<uk>, C<us>, C<croat>,
C<cz-us-qwertz>, C<de-latin1-nodeadkeys>, C<de-latin1>, C<de>, C<fr_CH-latin1>,
C<fr_CH>, C<hu>, C<sg-latin1-lk450>, C<sg-latin1>, C<sg>, C<sk-prog-qwertz>,
C<sk-qwertz>, C<slovene>

and for Sparc:

C<sun-pl-altgraph>, C<sun-pl>, C<sundvorak>, C<sunkeymap>, C<sunt4-es>,
C<sunt4-no-latin1>, C<sunt5-cz-us>, C<sunt5-de-latin1>, C<sunt5-es>,
C<sunt5-fi-latin1>, C<sunt5-fr-latin1>, C<sunt5-ru>, C<sunt5-uk>, C<sunt5-us-cz>

=item lang

=item lang

The lang method is used to specify the type of language which will be used
during the installation.

Valid languages include:

C<cs_CZ>, C<en_US>, C<fr_FR>, C<de_DE>, C<hu_HU>, C<is_IS>, C<id_ID>, C<it_IT>,
C<ja_JP.ujis>, C<no_NO>, C<pl_PL>, C<ro_RO>, C<sk_SK>, C<sl_SI>, C<es_ES>,
C<ru_RU.KOI8-R>, C<uk_UA>

Use C<en_US> to specify US english.

=item lilo { KEY => VALUE, ... }

=item lilo

  append	specify arguments to be passed to the kernel
  linear	specify that LILO to work in linear mode
  location	specify the locatation where LILO will be written

=item lilocheck 1

=item lilocheck

If set, LILO will not perform an installation onto a system which has LILO
written in the master boot record of the first hard drive.

=item mouse VALUE

=item mouse

The mouse method specifies which mouse type should be configured for the
system.

Valid mouse types include:

C<alpsps/2>, C<ascii>, C<asciips/2>, C<atibm>, C<generic>, C<generic3>,
C<genericps/2>, C<generic3ps/2>, C<geniusnm>, C<geniusnmps/2>,
C<geniusnsps/2>, C<thinking>, C<thinkingps/2>, C<logitech>,
C<logitechcc>, C<logibm>, C<logimman>, C<logimmanps/2>, C<logimman+>,
C<logimman+ps/2>, C<microsoft>, C<msnew>, C<msintelli>, C<msintellips/2>,
C<msbm>, C<mousesystems>, C<mmseries>, C<mmhittab>, C<sun>, C<none>

=item network

=item network

[text to come]

=item packages

=item packages

[text to come]

=item part

=item part

    asprimary
    bytes-per-inode
    dir
    grow
    maxsize
    noformat
    ondisk
    onpart
    onprimary
    size
    type

[text to come]

=item post

=item post

[text to come]

=item pre

=item pre

[text to come]

=item raid

=item raid

    device	specify the name of the device (eg. md0, ...)
    dir		specify the mount point of the raid device
    level	specify the raid level to use (0, 1 or 5)
    partitions	an array of partitions to use for the device

=item reboot 1

=item reboot

Use the reboot method to specify that the system should be rebooted after
completing the installation.

=item rootpw { iscrypted => 1, rootpw => '..' } | VALUE

=item rootpw

The rootpw method can either be called by passing a hash reference to it, or
with a scalar value.  If the root password being specified is already
encrypted, you should call rootpw with a hash reference and set C<iscrypted>
to be on.

  iscrypted	specify that the password is encrypted
  rootpw	specify the root password

=item skipx 1

=item skipx

It is possible to skip X11 configuration entirely by using the skipx method.

=item timezone { utc => 1, timezone => '..' } | VALUE

=item timezone

The timezone method can be called by passing a hash reference to it, or with
a scalar value.  If the hardware clock is set to Greenwich Mean Time, you
should call the method with a hash reference and set C<utc> to be on.

  timezone	specify the timezone the system will be located in
  utc		specify that the hardware clock is set to UTC

=item upgrade

=item upgrade

[text to come]

=item xconfig

=item xconfig

The xconfig method can be used to configure the X Windowing System.

    card		specify which type of card to use
    defaultdesktop	specify to use kde or gnome
    hsync		specify the horizontal sync freq.
    monitor		specify what type of monitor to use
    noprobe		specify to not probe the monitor
    startxonboot	specify using run level 5 (instead of 3)
    vsync		specify the vertical sync freq.

=item zerombr 1

=item zerombr

Specify that the master boot record of the primary drive should be initialized.


=head1 AUTHOR INFORMATION

Written by Patrick Devine, 2001.

=cut

