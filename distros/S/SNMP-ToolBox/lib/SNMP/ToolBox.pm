package SNMP::ToolBox;
use strict;
use warnings;

use parent qw< Exporter >;

use Carp;


{
    no strict "vars";
    $VERSION = '0.03';
    @EXPORT  = qw< by_oid find_next_oid oid_encode >;

    if ($] < 5.008) {
        *by_oid = \&_by_oid_vstring;
    }
    else {
        *by_oid = \&_by_oid_classical;
    }
}


#
# _by_oid_classical()
# -----------------
# by Sebastien Aperghis-Tramoni
#
sub _by_oid_classical ($$) {
    my (undef, @a) = split /\./, $_[0];
    my (undef, @b) = split /\./, $_[1];
    my $n = $#a > $#b ? $#a : $#b;
    my $v = 0;
    $v ||= ($a[$_]||0) <=> ($b[$_]||0), $v && return $v for 0 .. $n;
    return $v
}


#
# _by_oid_vstring()
# ---------------
# by Vincent Pit
#
sub _by_oid_vstring ($$) {
    eval($_[0]) cmp eval ($_[1])
}


#
# find_next_oid()
# -------------
sub find_next_oid {
    my ($oid_list, $req_oid, $walk_base) = @_;

    croak "error: first argument must be an arrayref"
        unless ref $oid_list eq "ARRAY";

    $req_oid   ||= "";
    $walk_base ||= "";

    my ($first_idx, $next_oid_idx);

    for my $i (0 .. $#{$oid_list}) {
        # check if we are still within the given context, if given any
        next if $walk_base and index($oid_list->[$i], $walk_base) != 0;

        # keep track of the first entry within the given context
        $first_idx = $i if not defined $first_idx;

        # exact match of the requested entry
        if ($oid_list->[$i] eq $req_oid) {
            $next_oid_idx = $i + 1;
            last
        }
        # prefix match of the requested entry
        elsif (index($oid_list->[$i], $req_oid) == 0) {
            $next_oid_idx = $i;
            last
        }
    }

    # get the entry following the requested one
    my $next_oid = (defined $next_oid_idx and $next_oid_idx <= $#{$oid_list})
                 ? $oid_list->[$next_oid_idx]
                 : "NONE";

    # check that the resulting OID is still within context
    $next_oid = "NONE" if index($next_oid, $walk_base) != 0;

    return $next_oid
}


#
# oid_encode()
# ----------
sub oid_encode {
    return join ".", length($_[0]), unpack "c*", $_[0];
}


__PACKAGE__

__END__

=head1 NAME

SNMP::ToolBox - Set of SNMP-related utilities

=head1 VERSION

Version 0.03


=head1 SYNOPSIS

    use SNMP::ToolBox;

    # sort a list of OIDs
    @oid_list = sort by_oid @oid_list;

    # OID-encode a string
    $idx = oid_encode($name);


=head1 DESCRIPTION

This module contains a set of functions useful for writing SNMP-related
programs and modules: C<by_oid>, C<find_next_oid()>, C<oid_encode()>.


=head1 EXPORTS

The following functions are exported by default:

    by_oid  find_next_oid  oid_encode


=head1 FUNCTIONS

=head2 by_oid

Sub-routine suitable for being used with C<sort> for sorting OIDs.
Two implementations are included in this module: a classical one,
by splitting the OIDs and comparing each pair of components, and
another, by evaluating the OIDs as Perl v-strings. The fastest one
for the running version of Perl will be used.

B<Example:>

    @oid_list = sort by_oid @oid_list;

Even though the implementations proposed in this module are pretty
good, it is suggested to use C<Sort::Key::OID>'s C<oidsort()> when
possible, for it is roughly 40-50 times faster. Here is an example
on how to always use the best function available:

    use constant HAVE_SORT_KEY_OID
        => eval "use Sort::Key::OID 0.04 'oidsort'; 1" ? 1 : 0;

    @oid_list = HAVE_SORT_KEY_OID
              ? oidsort(@oid_list)
              : sort by_oid @oid_list;

Using a constant allows the Perl compiler to optimise away the dead
code early.


=head2 find_next_oid

Generic implementation of the algorithm to find the OID following
a given one in an ordered list of OIDs. Typically needed for
implementing a "getnext" feature in nearly any kind of server-side
SNMP extension (pass_persist, SMUX, AgentX, etc).

Expects the list of OIDs as an arrayref, the OID to request against
and an optional context. Returns the appropriate "next" OID or the
string C<"NONE">.

B<Arguments:>

=over

=item 1. I<(mandatory)> reference to an array containing the list of OIDs

=item 2. I<(optional)> OID to request against

=item 3. I<(optional)> OID context; when given, no OID outside of
this contexte will be returned

=back

B<Exemple:>

    my $oid = $walk_base;

    while ($oid ne "NONE") {
        $oid = get_next_oid(\@oid_list, $oid, $walk_base);
        # ...
    }


=head2 oid_encode

Returns the OID-encoded equivalent of the string given in argument.

B<Example>:

    my $idx = oid_encode($name);


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SNMP::ToolBox

You can also look for information at:

=over

=item * Search CPAN

L<http://search.cpan.org/dist/SNMP-ToolBox/>

=item * Meta CPAN

L<https://metacpan.org/release/SNMP-ToolBox>

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/Public/Dist/Display.html?Name=SNMP-ToolBox>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SNMP-ToolBox>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SNMP-ToolBox>

=back


=head1 BUGS

Please report any bugs or feature requests to
C<bug-snmp-toolbox at rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=SNMP-ToolBox>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.


=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni C<< <sebastien at aperghis.net> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Sebastien Aperghis-Tramoni.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

