package Mojolicious::Plugin::XML::LX;
use Mojo::Base 'Mojolicious::Plugin';

use 5.006;
use strict;
use warnings;

our $VERSION = '1.0';

use XML::LibXML;
use XML::Hash::LX   qw(hash2xml);

use Encode          qw(decode_utf8);
use Mojo::Util      qw(camelize xml_escape);

sub register {
    my ($self, $app, $conf) = @_;

    $conf ||= {};

    # Add XML type if not exists
    $app->types->type(xml => 'application/xml')
        unless $app->types->type('xml');

    # http://mojolicious.org/perldoc/Mojolicious/Guides/Rendering
    # #Adding-a-handler-to-generate-binary-data

    # Add XML handler
    $app->renderer->add_handler(xml => sub {
        my ($renderer, $c, $output, $options) = @_;

        my %opts = %$conf;
        $opts{encoding} = $options->{encoding} if $options->{encoding};

        my $data = delete $c->stash->{xml};
        my $dom = hash2xml $data, doc => 1, %opts;
        $$output = $dom->toString( 2 );
    });

    # Automatic apply XML handler
    $app->hook(before_render => sub {
        my ($c, $args) = @_;
        $args->{handler} = 'xml'
            if exists $args->{xml} || exists $c->stash->{xml};
    });
}

=head1 NAME

Mojolicious::Plugin::XML::LX - is a plugin
to support simple XML response from HASH.


=head1 SYNOPSIS

    # Mojolicious
    $app->plugin('XML::LX');

    # Mojolicious::Lite
    plugin 'XML::LX';

    # Controller
    $self->render(xml => {
        response => {
            -status => 'ok',
            message => 'hello world!',
        }
    });

    # You get:

    <?xml version="1.0" encoding="utf-8"?>
    <response status="ok">
        <message>hello world!</message>
    </response>


=head1 DESCRIPTION

L<Mojolicious::Plugin::XML::LX> based on L<XML::Hash::LX>
companion for L<XML::LibXML>.

All configuration parameters apply to L<XML::Hash::LX::hash2xml()>.

=head1 AUTHOR

Roman V. Nikolaev, C<< <rshadow at rambler.ru> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojolicious-plugin-xml-lx at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mojolicious-Plugin-XML-LX>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mojolicious::Plugin::XML::LX


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mojolicious-Plugin-XML-LX>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mojolicious-Plugin-XML-LX>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mojolicious-Plugin-XML-LX>

=item * Search CPAN

L<http://search.cpan.org/dist/Mojolicious-Plugin-XML-LX/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 Roman V. Nikolaev.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Mojolicious::Plugin::XML::LX
