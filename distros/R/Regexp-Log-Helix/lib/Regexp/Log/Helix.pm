package Regexp::Log::Helix;

use strict;
use base qw( Regexp::Log );
use vars qw( $VERSION %DEFAULT %FORMAT %REGEXP );

$VERSION = sprintf("%d.%02d", q$Revision: 1.4 $ =~ /(\d+)\.(\d+)/);

=head1 NAME

Regexp::Log::Helix - A regular expression parser for Helix
log format.

=head1 SYNOPSIS

    my $foo = Regexp::Log::Helix->new(
	  format  => ':style11_3',
          capture => [qw( ip date req )],
    );
    my $re = $foo->regexp;

=head1 DESCRIPTION

This module parses access logs created by Real's Helix 11.

For more information on how to use this module, please see Regexp::Log.

=head1 ABSTRACT

Regexp::Log::Helix enables simple parsing of log files created by Helix.

=cut

# default values
%DEFAULT = ( 
       format => (q(%ip %rfc %authuser %date ).
                  q(%request %status %bytes ).
                  q(%useragent %clientid %clientstats ).
                  q(%filesize %filetime %conntime %resends %failedresends ).
                  q(%streamcomp %starttime %serverip)),

       capture => [qw( ip rfc authuser date
                       request status bytes 
                       ua id stats
                       filesize filetime conntime resends failedresends
                       components startts serverip )]
            );

# predefined format strings
%FORMAT = (
	':default'  => q(%ip %rfc %authuser %date %request %status %bytes %useragent %clientid %clientstats ).
                      q(%filesize %filetime %conntime %resends %failedresends %streamcomp %starttime %serverip),

	':style11_3'  => q(%ip %rfc %authuser %date %request %status %bytes %useragent %clientid %clientstats ).
                      q(%filesize %filetime %conntime %resends %failedresends %streamcomp %starttime %serverip),
);

# the regexps that match the various fields
%REGEXP = ( '%ip'  => '(?#=ip).*?(?#!ip)',
            '%rfc' => '(?#=rfc).*?(?#!rfc)',                                # rfc931
            '%authuser' => '(?#=authuser).*?(?#!authuser)',                 # authuser
	    '%date'     => '(?#=date)\[(?#=ts)\d{2}/\w{3}/\d{4}(?::\d{2}){3} [-+]\d{4}(?#!ts)\](?#!date)\s?',

            '%request'  => '(?#=request)"(?#=req)(?#=req_method)\w+(?#!req_method) (?#=req_file)[^\s\?]+(?#!req_file)(?:\?(?#=req_query)\S+(?#!req_query))? (?#=req_protocol).*?(?#!req_protocol)(?#!req)"(?#!request)',
	    '%status'   => '(?#=status)\d+(?#!status)',
            '%bytes'       => '(?#=bytes)-|\d+(?#!bytes)',                # bytes
            '%useragent'   => '(?#=useragent)\[(?#=ua).*?(?#!ua)\](?#!useragent)',         
            '%clientid'    => '(?#=clientid)\[(?#=id).*?(?#!id)\](?#!clientid)',
            '%clientstats' => '(?#=clientstats)\[(?#=stats).*?(?#!stats)\](?#!clientstats)',
            '%filesize'    => '(?#=filesize)\d*?(?#!filesize)',
            '%filetime'    => '(?#=filetime)\d*?(?#!filetime)',
            '%conntime'    => '(?#=conntime)\d*?(?#!conntime)',
            '%resends'     => '(?#=resends)\d*?(?#!resends)',
            '%failedresends' => '(?#=failedresends)\d*?(?#!failedresends)',
            '%streamcomp'  => '(?#=streamcomp)\[(?#=components).*?(?#!components)\](?#!streamcomp)',
	    '%starttime'   => '(?#=starttime)\[(?#=startts)\d{2}/\w{3}/\d{4}(?::\d{2}){3}(?#!startts)\](?#!starttime)',
            '%serverip'    => '(?#=serverip)\S+(?#!serverip)',
);
1;

__END__

=head1 CAPTURE FIELDS

=over 4

=item * ip rfc authuser date ts 

=item * request req req_method req_file req_query req_protocol

=item * status bytes

=item * ua id stats

=item * filesize filetime conntime resends failedresends

=item * components startts serverip

=back

=head1 SEE ALSO

L<Regexp::Log>, L<Regexp::Log::Common>

=head1 AUTHOR

Ben H Kram <bkram@barkley.dce.harvard.edu>

=head1 COPYRIGHT


   Copyright 2006, Harvard University.  All rights reserved.

   This library is free software; you can redistribute it
   and/or modify it under the same terms as Perl itself.


=head1 TODO

I have only written support for logging style 3.  Adding 1,2 and 4 may be helpful.

=head1 CHANGES

$Log: Helix.pm,v $
Revision 1.4  2006/08/22 21:40:03  bkram
Added support for req_method req_file req_query req_protocol

Revision 1.3  2006/08/22 16:52:17  bkram
fixed version formatting

Revision 1.2  2006/08/22 16:46:43  bkram
prepping for CPAN


=cut
