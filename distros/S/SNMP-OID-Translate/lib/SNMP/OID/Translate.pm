package SNMP::OID::Translate;
$SNMP::OID::Translate::VERSION = '0.0005';

use strict;
use warnings;
use v5.08;

require Exporter;
our @EXPORT_OK = qw( translateObj translate );

require DynaLoader;
our @ISA = qw(DynaLoader Exporter);
bootstrap SNMP::OID::Translate;

use vars qw(
  $auto_init_mib $use_long_names
  %MIB $verbose
  $best_guess
);


$auto_init_mib = 1; # enable automatic MIB loading at session creation time
$use_long_names = 0; # non-zero to prefer longer mib textual identifiers rather
                   # than just leaf indentifiers (see translateObj)
                   # may also be set on a per session basis(see UseLongNames)
%MIB = ();      # tied hash to access libraries internal mib tree structure
                # parsed in from mib files
$verbose = 0;   # controls warning/info output of SNMP module,
                # 0 => no output, 1 => enables warning and info
                # output from SNMP module itself (is also controlled
                # by SNMP::debugging)
$best_guess = 0;  # determine whether or not to enable best-guess regular
                  # expression object name translation.  1 = Regex (-Ib),
		  # 2 = random (-IR)


sub translateObj {
   SNMP::OID::Translate::init_snmp("perl");
   my $obj = shift;
   my $temp = shift;
   my $include_module_name = shift || "0";
   my $long_names = $temp || $SNMP::OID::Translate::use_long_names;

   return undef if not defined $obj;
   my $res;
   if ($obj =~ /^\.?(\d+\.)*\d+$/) {
      $res = SNMP::OID::Translate::_translate_obj($obj,1,$long_names,$SNMP::OID::Translate::auto_init_mib,0,$include_module_name);
   } elsif ($obj =~ /(\.\d+)*$/ && $SNMP::OID::Translate::best_guess == 0) {
      my $pre = substr($obj, 0, $-[0]);
      my $match = substr($obj, $-[0], $+[0]-$-[0]);
      $res = SNMP::OID::Translate::_translate_obj($pre,0,$long_names,$SNMP::OID::Translate::auto_init_mib,0,$include_module_name);
      $res .= $match if defined $res and defined $match;
   } elsif ($SNMP::OID::Translate::best_guess) {
      $res = SNMP::OID::Translate::_translate_obj($obj,0,$long_names,$SNMP::OID::Translate::auto_init_mib,$SNMP::OID::Translate::best_guess,$include_module_name);
   }

   return($res);
}


sub translate {
    [ map { translateObj($_) } ref($_[0]) eq 'ARRAY' ?  @{$_[0]} : @_ ];
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SNMP::OID::Translate

=head1 VERSION

version 0.0005

=head1 SYNOPSIS

    use SNMP::OID::Translate;
    my $oid = $SNMP::OID::Translate:::translateObj('ifDescr');

=head1 VARIABLES

=over 4

=item $use_long_names

Returns the complete name rather than the short version.  Most of the time you
don't need or want this.

=item $best_guess

Setting this to 1 will enable regex lookups for names, so things like
'if.*Status' work.  With this turned on you can't append the instance or use a
period in the query because it treats it as regex.

Setting this to 2 turns on "random access".  I'm not sure what that does.  See
the snmpcmd manpage for -Ib (regex) and -IR (random access)

Defaults to 0.

=item $verbose

Enable verbose messages.  Defaults to false.

=item $auto_init_mib

enable automatic MIB loading at session creation time.  Defaults to true.

=back

=head1 SUBROUTINES

=head2 translateObj

    my $oid = translateObj('ifDescr');

Translate object identifier(tag or numeric) into alternate representation
(i.e., sysDescr => '.1.3.6.1.2.1.1.1' and '.1.3.6.1.2.1.1.1' => sysDescr)
when $SNMP::OID::Translate::use_long_names or second arg is non-zero the translation will
return longer textual identifiers (e.g., system.sysDescr).  An optional
third argument of non-zero will cause the module name to be prepended
to the text name (e.g. 'SNMPv2-MIB::sysDescr').  If no Mib is loaded
when called and $SNMP::OID::Translate::auto_init_mib is enabled then the Mib will be
loaded. Will return 'undef' upon failure.

=head2 translate

    my $result = translate([ 'ifDescr', 'ifInOctets' ]);

This will translate an arrayref or list of objects into their OIDs or
translate OIDs into their names.  Returns an arrayref.

=head1 AUTHOR

bugs, comments, questions to C<< <rdrake at cpan.org> >>

=head1 Copyright

Most of the source code is directly copied from the L<SNMP> modules.  I am
leaving their copyright notice intact but please direct complaints, feature
requests or whatever to me (RDRAKE)

     Copyright (c) 1995-2000 G. S. Marzot. All rights reserved.
     This program is free software; you can redistribute it and/or
     modify it under the same terms as Perl itself.

     Copyright (c) 2001-2002 Networks Associates Technology, Inc.  All
     Rights Reserved.  This program is free software; you can
     redistribute it and/or modify it under the same terms as Perl
     itself.

=head1 AUTHOR

Robert Drake <rdrake@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Robert Drake.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
