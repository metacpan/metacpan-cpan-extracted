use strict;
use warnings;
package RT::Extension::AssetAutoName;

our $VERSION = '0.05';

=head1 NAME

RT-Extension-AssetAutoName - Auto generate a name for an asset

=head1 DESCRIPTION

This extension allows you to define templates to use for asset categories
that will be used if no name is set on an asset. You can use this
to generate the name based on CustomFields (or other values).

This was developed for tracking components of servers where the name
should be based on the make, model and serial number of a component.
Yet these should be stored individually as Custom Fields to ease searching
and reporting.

=head1 RT VERSION

Works with RT 4.4.x and 5.0.x.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::AssetAutoName');

Add templates for the categories you'd like to have use this extension:

    Set( %AssetAutoName, 2 => 'Card: __CF.28__ (__Status__)' );

28 is the CustomField to use, you can also specify the name here.

If the CustomField is a multi-value, then only the first value is used.

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 USAGE

If the asset name is not set, the empty string or just an x, we'll dynamically
generate a name based on a template.

It is useful to allow 'x' in the case that data is being bulk updated, it has
been reported that with some tools setting a short string is easier than
deleting the text.

=head1 AUTHOR

Andrew Ruthven, Catalyst Cloud Ltd E<lt>puck@catalystcloud.nz<gt>

=for html <p>All bugs should be reported via email to <a
href="mailto:bug-RT-Extension-AssetAutoName@rt.cpan.org">bug-RT-Extension-AssetAutoName@rt.cpan.org</a>
or via the web at <a
href="http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-AssetAutoName">rt.cpan.org</a>.</p>

=for text
    All bugs should be reported via email to
        bug-RT-Extension-AssetAutoName@rt.cpan.org
    or via the web at
        http://rt.cpan.org/Public/Dist/Display.html?Name=RT-Extension-AssetAutoName

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2018-2020 by Catalyst Cloud Ltd

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

package RT::Extension::AssetAutoName;
use strict;

{
    package # hide from PAUSE
        RT::Asset;
    no warnings 'redefine';

    *Name = sub {
        my $self = shift;
        my $name = $self->_Value('Name', @_);

        if (! defined $name || $name eq '' || $name eq 'x') {
            my $template = RT->Config->Get('AssetAutoName')->{$self->CatalogObj->id} 
                || RT->Config->Get('AssetAutoName')->{'_default'};

            $name = $self->_expand_name_template($template)
                if defined $template;
        }

        return $name;
    };

    # Take a template, find all the fields that we'll substitute.
    # Then if they're a CustomField, find the first value in the CustomField,
    # and substitute.
    # Otherwise if it is a readable field (that this user has access to),
    # read it and substitute.
    sub _expand_name_template {
        my $self     = shift;
        my $template = shift;

        my @fields = $template =~ /__(.*?)__/g;

        for my $field (@fields) {
            if ($field =~ /^(?:CF|CustomField).(.*)$/) {
                my $cf = $self->FirstCustomFieldValue($1) || 'CF not set';
                $template =~ s/__${field}__/$cf/;
            } elsif ($self->_Accessible($field => 'read')) {
                my $value = $self->$field || 'field not set';
                $template =~ s/__${field}__/$value/;
            }
        }

        return $template;
    }
}

1;
