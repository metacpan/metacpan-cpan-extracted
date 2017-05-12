use strict;
use warnings;
package RT::Extension::BounceEmail;

our $VERSION = '0.03';

=head1 NAME

RT-Extension-BounceEmail - Add the ability to Bounce Emails

=head1 DESCRIPTION

if one does not want to alter the content of an email with a forward
"bounce" is the way to go

=head1 RT VERSION

Works with RT 4.2


=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item C<make initdb>

Only for first-time installation

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::BounceEmail');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::BounceEmail));

or add C<RT::Extension::BounceEmail> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Mark Hofstetter, University of Vienna mark.hofstetter@univie.ac.at
Kai Storbeck, Kai@xs4all.nl

=head1 BUGS

or via the web at

    L<https://github.com/MarkHofstetter/RT-Extension-BounceEmail/issues>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2015 by Mark Hofstetter

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

require RT::Transaction;
$RT::Transaction::_BriefDescriptions{"Bounce Transaction"} = sub {
        my $self = shift;

        return ( "Bounced [_2]Transaction #[_1][_3]",
            $self->Field,
            [\'<a href="#txn-', $self->Field, \'">'], \'</a>'); #loc()
};

1;
