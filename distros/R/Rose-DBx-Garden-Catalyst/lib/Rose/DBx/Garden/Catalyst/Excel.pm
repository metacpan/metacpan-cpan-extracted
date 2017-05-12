package Rose::DBx::Garden::Catalyst::Excel;
use strict;
use warnings;
use base qw( CatalystX::CRUD::YUI::Excel );
use Carp;
use Data::Dump qw( dump );
use Rose::DBx::Garden::Catalyst::TT;
use MRO::Compat;
use mro 'c3';

our $VERSION = '0.180';

=head1 NAME

Rose::DBx::Garden::Catalyst::Excel - View class for Excel output

=head1 DESCRIPTION

Rose::DBx::Garden::Catalyst::Excel is a subclass of 
CatalystX::CRUD::YUI::Excel.

=head1 CONFIGURATION

Configuration is the same as with CatalystX::CRUD::View::Excel. 
Read those docs.

The default config here is:

 __PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt'
 );

=cut

# default config here instead of new() so subclasses can more easily override.
__PACKAGE__->config( TEMPLATE_EXTENSION => '.tt' );
$Template::Directive::WHILE_MAX = 64000;

=head1 METHODS

The following methods are implemented in this class:

=cut

=head2 new

Overrides base new() method. Sets
etp_config->INCLUDE_PATH to the base
Rose::DBx::Garden::Catalyst::TT .tt files plus your local app root.
This means you can override the default .tt behaviour
by putting a .tt file with the same name in your C<root> template dir.

For example, to customize your C<.xls.tt> file, just copy the default one
from the C<Rose/DBx/Garden/Catalyst/TT/rdgc/list.xls.tt> in @INC and put it
in C<root/rdgc/list.xls.tt>.

=cut

sub new {
    my ( $class, $c, $arg ) = @_;
    my $self = $class->next::method( $c, $arg );

    my @inc_path = ( Path::Class::dir( $c->config->{root} ) );

    for my $tt_class (
        qw(
        CatalystX::CRUD::YUI::TT
        Rose::DBx::Garden::Catalyst::TT )
        )
    {

        my $template_base = Class::Inspector->loaded_filename($tt_class);
        $template_base =~ s/\.pm$//;
        push( @inc_path, Path::Class::dir($template_base) );
    }

    $self->etp_config->{INCLUDE_PATH} = \@inc_path;

    return $self;
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-rose-dbx-garden-catalyst at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Rose-DBx-Garden-Catalyst>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Rose::DBx::Garden::Catalyst

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Rose-DBx-Garden-Catalyst>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Rose-DBx-Garden-Catalyst>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Rose-DBx-Garden-Catalyst>

=item * Search CPAN

L<http://search.cpan.org/dist/Rose-DBx-Garden-Catalyst>

=back

=head1 ACKNOWLEDGEMENTS

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT & LICENSE

Copyright 2008 by the Regents of the University of Minnesota.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
