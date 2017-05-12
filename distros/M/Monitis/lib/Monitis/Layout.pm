package Monitis::Layout;

use warnings;
use strict;
require Carp;

use base 'Monitis';

sub add_page {
    my ($self, @params) = @_;

    my @mandatory = qw/title/;
    my @optional  = qw/columnCount/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_post('addPage' => $params);
}

sub add_module_to_page {
    my ($self, @params) = @_;

    my @mandatory = qw/moduleName pageId column row/;
    my @optional  = qw/dataModuleId height/;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_post('addPageModule' => $params);
}

sub delete_page {
    my ($self, @params) = @_;

    my @mandatory = qw/pageId/;
    my @optional  = qw//;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_post('deletePage' => $params);
}

sub delete_page_module {
    my ($self, @params) = @_;

    my @mandatory = qw/pageModuleId/;
    my @optional  = qw//;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_post('deletePageModule' => $params);
}

sub get_pages {
    my $self = shift;

    return $self->api_get('pages');
}

sub get_page_modules {
    my ($self, @params) = @_;

    my @mandatory = qw/pageName/;
    my @optional  = qw//;

    my $params = $self->prepare_params(\@params, \@mandatory, \@optional);

    return $self->api_get('pageModules' => $params);
}

__END__

=head1 NAME

Monitis::Layout - Layout manipulation

=head1 SYNOPSIS

    use Monitis::Layout;

=head1 DESCRIPTION

=head1 ATTRIBUTES

L<Monitis::Layout> implements following attributes:

=head1 METHODS

L<Monitis::Layout> implements following methods:

=head2 add_page

    my $response = $api->layout->add_page(
        title       => 'New Page',
        columnCount => 2
    );

Add new page to layout.

Mandatory parameters:

    title

Optional parameters:

    columnCount

Normal response is:

    {   "status" => "ok",
        "data"   => {"pageId" => 65272}
    }

=head2 add_module_to_page

    my $response = $api->layout->add_module_to_page(
        moduleName => 'New Module',
        pageId     => 65272,
        column     => 1,
        row        => 1
    );

Add new module to page.

Mandatory parameters:

    moduleName pageId column row

Optional parameters:

    dataModuleId height

Normal response is:

    {   "status" => "ok",
        "data"   => {"pageModuleId" => 202611}
    }


=head2 get_pages

    my $response = $api->layout->get_pages;

Normal response is:

    [   {   "id"    => 65272,
            "title" => "New Page"
        },

        # ...
    ]

=head2 get_page_modules

    my $response = $api->layout->get_page_modules(pageName => 'My Page');

Mandatory parameters:

    pageName

Normal response is:

    [   {   "id"           => 181342,
            "moduleName"   => Transaction,
            "dataModuleId" => 1978
        },

        # ...
    ]

=head2 delete_page_module

    my $response = $api->layout->delete_page_module(pageModuleId => 65272);

Deletes module from page.

Mandatory parameters:

    moduleId

Normal response is:

    {"status" => "ok"}

=head2 delete_page

    my $response = $api->layout->delete_page(pageId => 65272);

Deletes page.

Mandatory parameters:

    pageId

Normal response is:

    {"status" => "ok"}


=head1 SEE ALSO

L<Monitis>

Official API page: L<http://monitis.com/api/api.html#addPage>


=head1 AUTHOR

Yaroslav Korshak  C<< <ykorshak@gmail.com> >>
Alexandr Babenko  C<< <foxcool@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (C) 2006-2011, Monitis Inc.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

