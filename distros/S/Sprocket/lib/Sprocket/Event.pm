package Sprocket::Event;

use Class::Accessor::Fast;
use base qw( Class::Accessor::Fast );

use strict;
use warnings;

__PACKAGE__->mk_accessors( qw(
    hook
    source
) );

sub new {
    my $class = shift;
    bless( shift, ref $class || $class);
}


1;

__END__

=pod

=head1 NAME

Sprocket::Event - A wrapped event for Sprocket

=head1 ABSTRACT

Sprocket observer hook event data wrapper

=head1 DESCRIPTION

See L<Sprocket> for the observer hook semantics.

=head1 ACCESSORS

=over 4

=item hook

Returns the hook name for the event

=item source

The Sprocket component or plugin that is emitting the event.

=back

=head1 SEE ALSO

L<POE>, L<Sprocket>

=head1 AUTHOR

David Davis E<lt>xantus@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2007 by David Davis

Same as Perl, see the L<LICENSE> file

=cut

