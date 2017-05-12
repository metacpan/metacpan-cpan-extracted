# $Id: TSTP.pm,v 1.3 2002/12/17 18:10:21 matt Exp $

package POE::Component::TSTP;
use strict;
use POE;
use vars qw($VERSION);

$VERSION = '0.02';

sub create {
    my $class = shift;
    my %args = @_;
    
    POE::Session->create(
        inline_states => {
            _start => \&new,
            sigtstp => \&sigtstp,
        },
        args => [ $args{Alias}, $args{PreSuspend}, $args{PostSuspend} ],
    );
}

sub new {
    my ($kernel, $heap, $alias, $pre, $post) = 
       @_[KERNEL, HEAP, ARG0, ARG1, ARG2];
    
    $kernel->sig(TSTP => 'sigtstp');
    $kernel->alias_set($alias || 'tstp_handler');
    $heap->{PreSuspend} = $pre;
    $heap->{PostSuspend} = $post;
}

sub sigtstp {
    $_[HEAP]->{PreSuspend}->(@_) if $_[HEAP]->{PreSuspend};
    local $SIG{TSTP} = 'DEFAULT';
    kill(TSTP => $$);
    $_[KERNEL]->sig_handled();
    $_[HEAP]->{PostSuspend}->(@_) if $_[HEAP]->{PostSuspend};
}

1;
__END__

=head1 NAME

POE::Component::TSTP - A POE Component to handle Ctrl-Z

=head1 SYNOPSIS

  use POE;
  use POE::Component::TSTP;
  POE::Component::TSTP->create();
  # Rest of your POE program here

=head1 DESCRIPTION

By default, POE applications do not respond to Ctrl-Z due to slightly
strange signal handling semantics. This module fixes that.

You can pass in two options to the C<create()> routine:

=over 4

=item * Alias

An I<Alias> for the component. By default it is called "tstp_handler".

=item * PreSuspend

A subref that will be called just before suspending your program.

=item * PostSuspend

A subref that will be called just after your program has returned from
suspension (usually via the C<fg> command).

=back

=head1 AUTHOR

Matt Sergeant, matt@sergeant.org

=head1 LICENSE

This is free software. You may use it and distribute it under the same terms
as perl itself.

=cut
