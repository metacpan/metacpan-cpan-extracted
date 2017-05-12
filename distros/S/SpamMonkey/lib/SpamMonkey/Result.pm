package SpamMonkey::Result;

=head1 NAME

SpamMonkey::Result - Result object for spam test

=head1 SYNOPSIS

    if ($result->is_spam) {
        $result->rewrite;
        print $result->email->as_string;
    }

=head1 DESCRIPTION

This class provides utility methods for dealing with the results of a
SpamMonkey test.

=head1 METHODS

=head2 is_spam

Returns true if the message scores more than the required threshold.

=cut

sub is_spam {
    my $self = shift;
    $self->{score} > $self->{monkey}{conf}{settings}{required_score};
}

=head2 hits

Returns a list of the names of rules that matched.

=head2 describe_hits

Returns a list of the descriptions of rules that matched.

=cut

sub hits {
    my $self = shift;
    @{$self->{matched}||[]};
}

sub describe_hits {
    my $self = shift;
    map { $self->{monkey}{conf}{descriptions}{$_} || $_ } $self->hits
}

=head2 score

Returns the score for this test.

=cut

sub score { shift->{score} }

1;
