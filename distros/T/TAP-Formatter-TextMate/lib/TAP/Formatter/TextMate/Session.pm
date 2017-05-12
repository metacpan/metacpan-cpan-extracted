package TAP::Formatter::TextMate::Session;

use strict;
use TAP::Base;
use HTML::Tiny;
use URI::file;

our $VERSION = '0.1';
use base 'TAP::Formatter::Console::Session';

=head1 NAME

TAP::Formatter::TextMate::Session - Harness output delegate for TextMate output

=head1 VERSION

Version 0.1

=cut

$VERSION = '0.1';

=head1 DESCRIPTION

This provides output formatting for TAP::Harness.

=head1 SYNOPSIS

=cut

=head1 METHODS

=head2 C<result>

Called by the harness for each line of TAP it receives.

=cut

sub _flush_item {
    my $self  = shift;
    my $queue = $self->{queue};

    # Get the result...
    my $result = shift @$queue;

    $self->SUPER::result( $result );

    if ( $result->is_test && !$result->is_ok ) {
        my $html      = $self->_html;
        my $formatter = $self->formatter;

        my %def = ( file => $self->name, );

        # Look ahead in the queue for YAML. This is messy and is the
        # whole reason we need to have a queue.
        if ( my @yaml = grep { $_->is_yaml } @$queue ) {
            my $data = $yaml[0]->data;
            %def = ( %def, %$data ) if 'HASH' eq ref $data;
        }

        if ( my $file = delete $def{file} ) {
            $def{url} = URI::file->new_abs( $file );
        }

        $formatter->_newline;

        # See: http://macromates.com/blog/2005/html-output-for-commands/
        my $link = 'txmt://open?' . $html->query_encode( \%def );
        $formatter->_raw_output(
            $html->span(
                { class => 'fail' },
                [ $result->raw, ' (', [ \'a', { href => $link }, 'go' ], ')' ]
            ),
            $html->br,
            "\n"
        );
    }
}

sub _flush_queue {
    my $self  = shift;
    my $queue = $self->{queue};
    $self->_flush_item while @$queue;
}

sub result {
    my ( $self, $result ) = @_;
    # When we get the next test process the previous one
    $self->_flush_queue if $result->is_test && $self->{queue};
    push @{ $self->{queue} ||= [] }, $result;
}

=head2 C<close_test>

Called to close a test session.

=cut

sub close_test {
    my $self = shift;
    $self->_flush_queue;
    $self->SUPER::close_test;
}

sub _html {
    my $self = shift;
    return $self->{_html} ||= HTML::Tiny->new;
}

sub _should_show_count { 0 }

1;
