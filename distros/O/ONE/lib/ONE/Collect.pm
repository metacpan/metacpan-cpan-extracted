# ABSTRACT: Collect 
package ONE::Collect;
{
  $ONE::Collect::VERSION = 'v0.2.0';
}
use strict;
use warnings;
use AnyEvent;
use Any::Moose;

has '_cv' => (isa=>'AnyEvent::CondVar', is=>'rw');


sub listener {
    my $self = shift;
    my( $todo ) = @_;
    
    # Create a new CV if we don't have one yet
    my $cv = $self->_cv;
    unless ( $cv ) {
        $self->_cv( $cv = AE::cv );
    }

    # Begin processing
    $cv->begin;

    # Here we wrap the event listener and, after the first call, remove ourselves
    my $wrapped;
    $wrapped = sub { 
        my $self = shift;
        $self->remove_listener( $self->current_event, $wrapped );
        $self->on( $self->current_event, $todo );
        $todo->(@_); 
        $cv->end;
        undef $wrapped;
    };
    return $wrapped;
}



sub complete {
    my $self = shift;
    return unless defined $self->_cv;
    $self->_cv->wait;
}


__PACKAGE__->meta->make_immutable();
no Any::Moose;


1;


__END__
=pod

=head1 NAME

ONE::Collect - Collect 

=head1 VERSION

version v0.2.0

=head1 DESCRIPTION

=head1 METHODS

=head2 our listener( CodeRef $todo )

This wraps the $todo listener for later use by the complete method.

=head2 our complete()

Wait until all of the wrapped events have triggered at least once.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<ONE|ONE>

=back

=head1 AUTHOR

Rebecca Turner <becca@referencethis.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Rebecca Turner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut

