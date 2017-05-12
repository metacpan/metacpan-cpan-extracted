#!/usr/local/bin/perl -T
#set filetype=perl

#------------------------------------------------------------------------------
#
# Standard pragmas
#
#------------------------------------------------------------------------------

use strict;
use warnings;

use Mobile::Wurfl;
use CGI::Lite;

my @k = qw( groupid name value deviceid path );
my %formdata = CGI::Lite->new->parse_form_data();
my $wurfl = Mobile::Wurfl->new();
print "Content-Type: text/html\n\n";
my $g = $formdata{g};
my $ua = $wurfl->canonical_ua( $formdata{ua} ) || 'generic';
my $c = $formdata{c};
print "<form>user agent: <input size=50 name=ua value='$ua'>";
print 
    qq{group: <select onchange='if ( form.c ) form.c.value = ""; form.submit()' name='g'>}, 
    map( { my $s = $_ eq $g ? "selected" : "";  "<option $s value='$_'>$_</option>" } sort $wurfl->groups ),
    "</select>"
;
if ( $g )
{
    print 
        "capability: <select onchange='form.submit()' name='c'><option value=''></option>", 
        map( { my $s = $_ eq $c ? "selected" : "";  "<option $s value='$_'>$_</option>" } sort $wurfl->capabilities( $g ) ),
        "</select>"
    ;
}
print "</form>";
if ( $ua && $c )
{
    print "<table><tr>", map "<th>$_</th>", @k;
    warn "lookup $c for $ua ...\n";
    my $v = $wurfl->lookup( $ua, $c );
    print "<tr>", map( "<td valign=top>" . ( ref( $_ ) eq 'ARRAY' ? join( "<br/>", @$_ ) : $_ ) . "</td>", @$v{@k} ), "</tr>";
    print "</table>";
}

#------------------------------------------------------------------------------
#
# Start of POD
#
#------------------------------------------------------------------------------

=head1 NAME

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Ave Wrigley <Ave.Wrigley@itn.co.uk>

=head1 COPYRIGHT

Copyright (c) 2004 Ave Wrigley. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

#------------------------------------------------------------------------------
#
# End of POD
#
#------------------------------------------------------------------------------

