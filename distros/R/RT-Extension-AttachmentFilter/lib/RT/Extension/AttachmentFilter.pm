package RT::Extension::AttachmentFilter;

use strict;
use warnings;
require RT::Interface::Web;
package HTML::Mason::Commands;

our $VERSION = '0.01';

=head1 NAME

RT-Extension-AttachmentFilter - Set forbidden attachments file names or extensions

=head1 DESCRIPTION


Ses RT extension allows to forbid some files names or extensions from web
attachment upload.

It's use may be to match an existing mail policy.

The filter can be defined per queue so queues that do not have outgoing emails
configured can have less restrictions.

See the configuration example under L</INSTALLATION>.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::AttachmentFilter');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::AttachmentFilter));

or add C<RT::Extension::AttachmentFilter> to your existing C<@Plugins> line.

Then configure the limits using the $AttachmentFilter config option. This
option takes the generic form of:

    Set( $AttachmentFilter, 
        '*'    => 'regexp',
        queue1 => 'regexp',
    );

which allows to set limit per queue. '*' means for all queues that do
not have a specific filter.

'regexp' is a perl regular expression against the filename.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 IMPLEMENTATION DETAILS

=head2 Methods

=head3 CheckAttachmentName

This is the main routine, it takes an attachment file name and an optional
queue (name, id or object) and validate it against RT $AttachmentFilter
configuration.

Returns undef if allowed, (1, error message) else.

=cut

sub CheckAttachmentFilter {
    my %args = (
        FileName => '',
        Queue       => '',
        @_
    );

    my $filters = RT->Config->Get('AttachmentFilter');

    return undef unless ( $filters );
    return undef unless ( $args{'FileName'} );

    if ( ref($filters) ne 'HASH' ) {
        RT->Logger->crit("Configuration error, AttachmentFilter must be a HASH");
    }

    my $filter;
    my $SystemQueue = RT::Queue->new( RT->SystemUser );
    if ( $args{'Queue'} ) {
        if ( ref($args{'Queue'}) eq 'RT::Queue' ) {
            $SystemQueue->Load( $args{'Queue'}->id );
        } else {
            $SystemQueue->Load( $args{'Queue'} );
        }
        
        if ( $SystemQueue && $SystemQueue->id ) {
            $filter = $filters->{$SystemQueue->Name} || $filters->{'*'};
        } else {
            RT->Logger->error( "Wrong queue passed to RT::Extension::AttachmentFilter->CheckAttachmentFilter" );
        }
    
    }

    $filter ||= $filters->{'*'}; 

    unless ( $filter ) {
        return undef;
    }

    if ( $args{'FileName'} =~ m/$filter/ ) {
        return 1, loc("File name [_1] forbidden", $args{'FileName'});
    }

    return undef;
}


=head1 TODO

=over 4

=item Dynamic enforcement using javascript

=back

=head1 AUTHOR

Emmanuel Lacour, E<lt>elacour@home-dn.netE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-AttachmentFilter@rt.cpan.org|mailto:bug-RT-Extension-AttachmentFilter@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-AttachmentFilter>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2016 by Emmanuel Lacour <elacour@home-dn.net>

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
