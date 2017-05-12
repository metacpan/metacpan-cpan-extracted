#
# Documentation for JFS2 quota classes interfaces
#
# See also http://publib.boulder.ibm.com/infocenter/pseries/v5r3/index.jsp?topic=/com.ibm.aix.basetechref/doc/basetrf2/quotactl.htm
# (Or search google for "Q_J2GETQUOTA")
#

__END__

=head1 JFS2 Quota Class Interface

The following commands are usable on AIX JFS2 file systems only:

=over 4

=item I<($bs,$bh,$bt, $is,$ih,$it) = Quota::jfs2_getlimit($dev, $class)>

Returns quota limits for the given class.

=item I<Quota::jfs2_putlimit($dev, $class, $bs,$bh,$bt, $is,$ih,$it)>

Sets quota limits for the given class.
Time limits are 32-bit epoch values.

=item I<Quota::jfs2_newlimit($dev, $bs,$bh,$bt, $is,$ih,$it)>

Creates a new limit class with the given quota limits.
Returns the class ID, or undef upon error.

=item I<Quota::jfs2_rmvlimit($dev, $class)>

Deletes the given class.

=item I<Quota::jfs2_deflimit($dev, $class)>

Sets the given class as default class.

=item I<Quota::jfs2_uselimit($dev, $class [,$uid [,isgrp]])>

Sets quota for the given user or group to the one specified by
the given class.

=item I<Quota::jfs2_getnextq($dev, $class)>

Used to iterate all class IDs. Returns the next class ID larger
then the given class ID.  Return undef upon error or at the end
of the list

=back

