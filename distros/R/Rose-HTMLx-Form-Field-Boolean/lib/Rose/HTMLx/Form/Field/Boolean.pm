package Rose::HTMLx::Form::Field::Boolean;
use warnings;
use strict;
use Rose::HTMLx::Form::Field::RadioButtonBoolean;
use base qw( Rose::HTML::Form::Field::RadioButtonGroup );

our $VERSION = '0.03';

=head1 NAME

Rose::HTMLx::Form::Field::Boolean - extend RHTMLO RadioButtonGroup

=cut

=head1 SYNOPSIS

 # see Rose::HTML::Form::Field::RadioButtonGroup
 
=head1 DESCRIPTION

This Field class is for boolean-type fields. The default labels are True
and False, paired with values 1 and 0 respectively.

=head1 METHODS

Only new or overridden methods are documented here.

=cut

sub _item_class {'Rose::HTMLx::Form::Field::RadioButtonBoolean'}

=head2 init

Sets up the object.

=cut

sub init {
    my $self = shift;
    $self->SUPER::init(@_);    # MUST do this first
    $self->xhtml_linebreak('');
    $self->radio_buttons( [ '1', '0' ] );
    $self->labels( { 1 => 'True', 0 => 'False' } );
    return $self;
}

=head2 xhtml_field

Returns the radio button pair within a <div class="boolean_group">
tagset.

=cut

sub xhtml_field {
    my ($self) = shift;
    my $sep = ( $self->linebreak ) ? $self->xhtml_linebreak : ' ';
    return '<div class="boolean_group">'
        . join( $sep, map { $_->xhtml_field } $self->items )
        . '</div>';
}

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-rose-htmlx-form-field-boolean at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Rose-HTMLx-Form-Field-Boolean>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Rose::HTMLx::Form::Field::Boolean

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Rose-HTMLx-Form-Field-Boolean>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Rose-HTMLx-Form-Field-Boolean>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Rose-HTMLx-Form-Field-Boolean>

=item * Search CPAN

L<http://search.cpan.org/dist/Rose-HTMLx-Form-Field-Boolean>

=back

=head1 ACKNOWLEDGEMENTS

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT & LICENSE

Copyright 2007 by the Regents of the University of Minnesota.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
