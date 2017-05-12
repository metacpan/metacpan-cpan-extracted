use strict;
package Siesta::Deferred;
use base qw( Siesta::DBI );

__PACKAGE__->set_up_table('deferred');
__PACKAGE__->has_a(who     => 'Siesta::Member' );
__PACKAGE__->has_a(message => 'Siesta::Message',
                   deflate => 'as_string',
                  );

=head1 NAME

Siesta::Deferred - a deferred message in the system

=head1 DESCRIPTION

=head1 METHODS

=head2 resume

release a deferred message and continue it's processing

=cut

sub resume {
    my $self = shift;

    my $mail = $self->message;
    $mail->plugins([ map {
        Siesta::Plugin->retrieve( $_ )->promote
      } split /,/, $self->plugins ]);

    $self->delete;
    $mail->process;
}

1;
