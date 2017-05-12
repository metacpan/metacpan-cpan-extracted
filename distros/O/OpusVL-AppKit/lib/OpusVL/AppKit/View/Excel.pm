package OpusVL::AppKit::View::Excel;

use Moose;

BEGIN {
    extends 'Catalyst::View::Excel::Template::Plus';
}

__PACKAGE__->config->{TEMPLATE_EXTENSION} = '.tt';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::AppKit::View::Excel

=head1 VERSION

version 2.29

=head1 SYNOPSIS

In your controller action setup the data and detach to the view,

        $c->stash->{data} = $customers;
        $c->res->header('Content-Disposition', qq[attachment; filename="$filename"]);
        $c->detach('View::Excel');

In your view, action.xml.tt

    <workbook>
        <worksheet name="Customers">
            <row>
                <cell>Customers</cell>
            </row>
            <row>
                <cell>Created</cell>
                <cell>Name</cell>
                <cell>Channel</cell>
                <cell>Balance</cell>
                <cell>ID Number</cell>
            </row>
            [% FOREACH customer IN data %]
            <row>
                <format num_format="dd/mm/yyyy">
                    <cell type="date_time">[% customer.created.iso8601 %]</cell>
                </format>
                <cell>[% customer.name %]</cell>
                <cell>[% customer.details.channel %]</cell>
                <format num_format="£0.00">
                <cell>[% customer.balance %]</cell>
                </format>
                <cell type="string">332132111111232111</cell>
            </row>
            [% END %]

        </worksheet>
    </workbook>

=head1 DESCRIPTION

This is our Catalyst::View::Excel::Template::Plus view that makes use of Excel::Template::Plus
Assuming you have used the OpusVL::AppKit::RolesFor::Plugin->add_paths(__PACKAGE__) call 
in your module the excel templates should pick things up from the same place as all the regular
tt templates.  It just expects the filenames to end C<.xml.tt>.

=head1 NAME

OpusVL::AppKit::View::Excel

=head1 SEE ALSO

=over

=item * Excel::Template::Plus

L<http://search.cpan.org/perldoc?Excel::Template::Plus>

=item * OpusVL::AppKit::RolesFor::Plugin

L<OpusVL::AppKit::RolesFor::Plugin> - simplifies setting up the template paths for your modules.

=back

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
