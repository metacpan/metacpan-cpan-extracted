use warnings;
use strict;

package RT::Extension::CustomizeContentType;

our $VERSION = "1.01";
use RT::Attachment;

package RT::Attachment;

my $new = sub {
    my $self         = shift;
    my $content_type = shift;

    return $content_type
      unless $self->Filename && $self->Filename =~ /\.(\w+)$/;
    my $ext = lc $1;

    my $config = RT->Config->Get('ContentTypes') or return $content_type;
    return $config->{$ext} || $content_type;
};

my $old = __PACKAGE__->can('ContentType');
if ($old) {
    no warnings 'redefine';
    *ContentType = sub {
        my $self = shift;
        my $content_type = $old->( $self, @_ );
        return $content_type unless defined $content_type;
        return $new->( $self, $content_type );
    };
}
else {
    *ContentType = sub {
        my $self         = shift;
        my $content_type = $self->_Value('ContentType');
        return $content_type unless defined $content_type;
        return $new->( $self, $content_type );
    };
}

1;
__END__

=head1 NAME

RT::Extension::CustomizeContentType - Customize Attachments' ContentType

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

If you are using RT 4.2 or greater, add this line:

    Plugin('RT::Extension::CustomizeContentType');

For RT 4.0, add this line:

    Set(@Plugins, qw(RT::Extension::CustomizeContentType));

or add C<RT::Extension::CustomizeContentType> to your existing C<@Plugins> line.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 CONFIGURATION

Set the %ContentTypes configuration variable to a hash of extension and
desired content-type:

    Set(
        %ContentTypes,
        (
            't'    => 'text/x-perl-script',
            'psgi' => 'text/x-perl-script',
        )
    );

=head2 Microsoft Office

Older versions of IE often upload newer Microsoft Office documents with the
generic C<application/octet-stream> MIME type instead of something more
appropriate.  This causes RT to offer the file for download using the generic
content type, which confuses users and doesn't launch Office for them.  You can
fix that by L<installing this extension|/INSTALLATION> and using the
configuration below:

    Set(%ContentTypes,
        'docm' => 'application/vnd.ms-word.document.macroEnabled.12',
        'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'dotm' => 'application/vnd.ms-word.template.macroEnabled.12',
        'dotx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.template',
        'potm' => 'application/vnd.ms-powerpoint.template.macroEnabled.12',
        'potx' => 'application/vnd.openxmlformats-officedocument.presentationml.template',
        'ppam' => 'application/vnd.ms-powerpoint.addin.macroEnabled.12',
        'ppsm' => 'application/vnd.ms-powerpoint.slideshow.macroEnabled.12',
        'ppsx' => 'application/vnd.openxmlformats-officedocument.presentationml.slideshow',
        'pptm' => 'application/vnd.ms-powerpoint.presentation.macroEnabled.12',
        'pptx' => 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        'xlam' => 'application/vnd.ms-excel.addin.macroEnabled.12',
        'xlsb' => 'application/vnd.ms-excel.sheet.binary.macroEnabled.12',
        'xlsm' => 'application/vnd.ms-excel.sheet.macroEnabled.12',
        'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'xltm' => 'application/vnd.ms-excel.template.macroEnabled.12',
        'xltx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.template',
    );

Config contributed by Nathan March.

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 BUGS

All bugs should be reported via email to

    L<bug-RT-Extension-CustomizeContentType@rt.cpan.org|mailto:bug-RT-Extension-CustomizeContentType@rt.cpan.org>

or via the web at

    L<rt.cpan.org|http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-CustomizeContentType>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2014 by Best Practical Solutions

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
