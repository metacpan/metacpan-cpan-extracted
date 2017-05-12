package POE::Component::Sequence::Nested;

=head1 NAME

POE::Component::Sequence::Nested - Adds special features to nested sequences

=head1 SYNOPSIS

    use POE qw(Component::Sequence::Nested);

    POE::Component::Sequence
        ->new(
            {
                auto_pause => 1,
                auto_resume => 1,
                merge_heap => 1,
            },
            sub {
                POE::Component::Sequence
                    ->new(
                        sub {
                            my $subseq = shift;
                            $subseq->heap_set(
                                a => 5,
                                b => 19,
                                op => '+',
                            );
                        },
                    )->run;
            },
            sub {
                my $sequence = shift;
                my $math = join ' ', map { $sequence->heap_index($_) } qw(a op b);
                $sequence->heap_set(result => eval $math);
            }
        )
        ->add_callback(sub {
            my ($sequence, $result) = @_;
            print "Answer was " . $sequence->heap_index('result') . "\n";
        })
        ->run();

=head1 DESCRIPTION

A nested sequence is one in which the return value of an action is another Sequence.  When this is the case, we can perform some automated tasks which save each action from redundant calls.

By itself it does nothing, but given any of the following actions, it will do it's magic:

=head2 auto_resume 

=over 4

The parent sequence remains paused, but the child sequence has a callback added onto it which will resume the parent sequence:

  $child_sequence->add_callback(sub {
    $parent_sequence->resume;
  });

=back

=head2 auto_error

=over 4

This propogates a child sequence failure to the parent via $child->add_error_callback().  This would happen anyway if the child sequence throws an exception, but if the child sequence is already catching errors via another callback

=back

=head2 merge_heap

=over 4

The heap of the child sequence will be merged with the parent when it's complete:

  $child_sequence->add_finally_callback(sub {
    $parent_sequence->heap_set( $child_sequence->heap );
  });

This allows for shared heap access.

=back

=cut

use strict;
use warnings;
use POE::Component::Sequence;
use Scalar::Util qw(blessed);

BEGIN {
    unshift @POE::Component::Sequence::_plugin_handlers,
    sub {
        my ($self, $request) = @_;

        my $action = $request->{action};
        my $opt    = $request->{options};

        if (! defined $action || ! ref $action || ref $action ne 'CODE') {
            return { deferred => 1 };
        }

        my $return = $action->(@_);

        if ($return && ref $return && blessed $return
            && $return->isa('POE::Component::Sequence')) {
            if (delete $opt->{auto_resume}) {
                $return->add_finally_callback(sub {
                    $self->resume;
                });
            }
            if (delete $opt->{auto_error}) {
                $return->add_error_callback(sub {
                    $self->failed($_[1]);
                });
            }
            if (delete $opt->{merge_heap}) {
                $return->add_finally_callback(sub {
                    my %transaction_heap = $_[1]->heap;
                    $self->heap_set(%transaction_heap);
                });
            }
        }

        return { value => $return };
    };
}

1;

__END__

=head1 KNOWN BUGS

No known bugs, but I'm sure you can find some.

=head1 SEE ALSO

L<POE::Component::Sequence>

=head1 COPYRIGHT

Copyright (c) 2008 Eric Waters and XMission LLC (http://www.xmission.com/).
All rights reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with
this module.

=head1 AUTHOR

Eric Waters <ewaters@gmail.com>

=cut
