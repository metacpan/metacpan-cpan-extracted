use strict;
use warnings;
package RT::Extension::DateTAI64;

our $VERSION = '0.01';

=head1 NAME

RT-Extension-DateTAI64 - Display RT's Dates as TAI64 strings

=head1 INSTALLATION 

=over

=item perl Makefile.PL

=item make

=item make install

May need root permissions

=item Edit your /opt/rt4/etc/RT_SiteConfig.pm

Add this line:

    Set(@Plugins, qw(RT::Extension::DateTAI64));

or add C<RT::Extension::DateTAI64> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 AUTHOR

Kevin Falcone <falcone@bestpractical.com>

=head1 BUGS

All bugs should be reported via
L<http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-DateTAI64>
or L<bug-RT-Extension-DateTAI64@rt.cpan.org>.


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2012 by Best Practical Solutions

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

use Time::TAI64;
package RT::Date;

push @RT::Date::FORMATTERS, 'TAI64';

sub TAI64 {
    my $self = shift;
    my %args = @_;

    my @local = $self->Localtime($args{Timezone});
    my $epoch = $self->Timelocal('UTC',@local[0..5]);
    return Time::TAI64::unixtai64($epoch);

}

1;
