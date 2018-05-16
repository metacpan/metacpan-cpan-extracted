package TaskPipe::PodReader::Settings;

use Moose;
with 'MooseX::ConfigCascade';


=head1 NAME

TaskPipe::PodReader::Settings - Settings for L<TaskPipe::PodReader>

=head1 METHODS

=over

=item pod_format

Command line tool POD formatting options

=cut

has pod_format => (is => 'ro', isa => 'HashRef', default => sub{{       
    head1 => {
        display => 'block',
        stacking => 'revert',
        indent => 0,
        after_indent => 2,
        color => 'on_blue',
        bottom_spacing => 2
    },

    head2 => {
        display => 'block',
        stacking => 'revert',
        indent => 0,
        after_indent => 2,
        color => 'blue',
        bottom_spacing => 2
    },

    head3 => {
        display => 'block',
        stacking => 'revert',
        indent => 0,
        after_indent => 2,
        color => 'magenta',
        bottom_spacing => 2
    },

    head4 => {
        display => 'block',
        stacking => 'revert',
        indent => 0,
        after_indent => 2,
        color => 'bright_magenta',
        bottom_spacing => 2
    },

    'over-text' => {
        display => 'block',
        stacking => 'nest',
        indent => 2
    },

    'over-number' => {
        display => 'block',
        stacking => 'nest',
        indent => 2
    },

    'over-bullet' => {
        display => 'block',
        stacking => 'nest',
        indent => 2,
        bottom_spacing => 1
    },

    'item-text' => {
        display => 'block',
        stacking => 'spot',
        color => 'yellow',
        indent => 0,
        after_indent => 2,
        bottom_spacing => 2
    },

    'item-number' => {
        display => 'block',
        stacking => 'nest',
        color => 'yellow',
        prepend => { 
            text => '@number. ',
            color => 'red'
        },
        bottom_spacing => 2
    },

    'item-bullet' => {
        display => 'block',
        stacking => 'nest',
        color => 'yellow',
        prepend => {
            text => '* ',
            color => 'red'
        },
        bottom_spacing => 1
    },

    'B' => {
        display => 'inline',
        color => 'bright_yellow'
    },

    'C' => {
        display => 'inline',
        color => 'cyan'
    },

    'I' => {
        display => 'inline',
        color => 'bright_white'
    },

    'L' => {
        display => 'inline',
        color => 'bright_green'
    },

    'E' => {
        display => 'inline',
        color => 'white'
    },

    'F' => {
        display => 'inline',
        color => 'bright_white'
    },

    'S' => {
        display => 'inline',
        color => 'cyan',
        wrap => 'verbatim'
    },

    'Para' => {
        display => 'block',
        stacking => 'nest',
        color => 'white',
        bottom_spacing => 2,
    },

    'Verbatim' => {
        display => 'block',
        stacking => 'nest',
        color => 'cyan',
        bottom_spacing => 2,
        wrap => 'verbatim'
    },

    'Document' => {
        display => 'block',
        stacking => 'nest',
        indent => 2
    }
}});

=item pod_format_mono

Command line tool monochrome pod formatting options - for file output

=back

=cut

has pod_format_mono => (is => 'ro', isa => 'HashRef', default => sub{{       
    head1 => {
        display => 'block',
        stacking => 'revert',
        indent => 0,
        after_indent => 2,
        color => undef,
        bottom_spacing => 2
    },

    head2 => {
        display => 'block',
        stacking => 'revert',
        indent => 0,
        after_indent => 2,
        color => undef,
        bottom_spacing => 2
    },

    head3 => {
        display => 'block',
        stacking => 'revert',
        indent => 0,
        after_indent => 2,
        color => undef,
        bottom_spacing => 2
    },

    head4 => {
        display => 'block',
        stacking => 'revert',
        indent => 0,
        after_indent => 2,
        color => undef,
        bottom_spacing => 2
    },

    'over-text' => {
        display => 'block',
        stacking => 'nest',
        indent => 2
    },

    'over-number' => {
        display => 'block',
        stacking => 'nest',
        indent => 2
    },

    'over-bullet' => {
        display => 'block',
        stacking => 'nest',
        indent => 2,
        bottom_spacing => 1
    },

    'item-text' => {
        display => 'block',
        stacking => 'nest',
        color => undef,
        indent => 0,
        after_indent => 2,
        bottom_spacing => 2
    },

    'item-number' => {
        display => 'block',
        stacking => 'nest',
        color => undef,
        prepend => { 
            text => '@number. ',
            color => 'red'
        },
        bottom_spacing => 2
    },

    'item-bullet' => {
        display => 'block',
        stacking => 'nest',
        color => undef,
        prepend => {
            text => '* ',
            color => undef
        },
        bottom_spacing => 1
    },

    'B' => {
        display => 'inline',
        color => undef
    },

    'C' => {
        display => 'inline',
        color => undef
    },

    'I' => {
        display => 'inline',
        color => undef
    },

    'L' => {
        display => 'inline',
        color => undef
    },

    'E' => {
        display => 'inline',
        color => undef
    },

    'F' => {
        display => 'inline',
        color => undef
    },

    'S' => {
        display => 'inline',
        color => undef,
        wrap => 'verbatim'
    },

    'Para' => {
        display => 'block',
        stacking => 'nest',
        color => undef,
        bottom_spacing => 2,
    },

    'Verbatim' => {
        display => 'block',
        stacking => 'nest',
        color => undef,
        bottom_spacing => 2,
        wrap => 'verbatim'
    },

    'Document' => {
        display => 'block',
        stacking => 'nest',
        indent => 2
    }
}});

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;
1;
