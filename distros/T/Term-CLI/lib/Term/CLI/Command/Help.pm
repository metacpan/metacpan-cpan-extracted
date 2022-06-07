#=============================================================================
#
#       Module:  Term::CLI::Command::Help
#
#  Description:  Class for Term::CLI 'help' command.
#
#       Author:  Steven Bakker (SBAKKER), <sbakker@cpan.org>
#      Created:  18/Feb/2018
#
#   Copyright (c) 2018-2022 Steven Bakker
#
#   This module is free software; you can redistribute it and/or modify
#   it under the same terms as Perl itself. See "perldoc perlartistic."
#
#   This software is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#=============================================================================

package Term::CLI::Command::Help 0.057001;

use 5.014;
use warnings;
use version;

use List::Util 1.23 qw( first min );
use Types::Standard 1.000005 qw( ArrayRef Str );
use Term::CLI::Util qw( is_prefix_str get_options_from_array );
use Term::CLI::L10N qw( loc );

use Pod::Text::Termcap    2.06;
use Pod::Text::Overstrike 2.04;

my $POD_PARSER_CLASS = $Pod::Text::Termcap::VERSION >= 4.11
    ? 'Pod::Text::Termcap'
    : 'Pod::Text::Overstrike';

use Moo 1.000001;
use namespace::clean 0.25;

extends 'Term::CLI::Command';

has '+name' => ( default => sub {'help'} );

has '+callback' => (
    default => sub {
        sub {
            my $self = shift;
            $self->_execute_help(@_);
        }
    }
);

has '+options' => ( default => sub { [ 'pod|p', 'all|a' ] }, );

has '+description' => (
    default => sub {
        loc(      qq{Show help for any given command sequence (or a command\n}
                . qq{overview if no argument is given).\n\n}
                . qq{The C<--pod> (C<-p>) option will cause raw POD\n}
                . qq{to be shown.\n\n}
                . qq{The C<--all> (C<-a>) option will list help text for all commands.}
        );
    }
);

has '+summary' => ( default => sub { loc('show help') }, );

has '+_arguments' => (
    default => sub {
        [   Term::CLI::Argument::String->new(
                name      => 'cmd',
                min_occur => 0,
                max_occur => 0,
            )
        ]
    },
);

sub _format_pod {
    my ($self, $text) = @_;

    my $output;

    my $parser =
        $POD_PARSER_CLASS->new( width => $self->term->term_width - 1 );

    $parser->output_string( \$output );
    $parser->parse_string_document($text);
    return $output;
}

# ($pod, $text) = $self->_make_command_summary( %args );
sub _make_command_summary {
    my ( $self, %args ) = @_;

    my @cmd_path   = map { $_->name } @{ $args{cmd_path} };
    my $commands   = $args{commands};
    my $pod_prefix = $args{pod_prefix};

    my $text     = '';
    my $full_pod = '';

    my $item_length = 0;
    for my $cmd_ref (@$commands) {
        for my $usage ( $cmd_ref->usage_text( with_options => 'none' ) ) {
            my $item_text = join( ' ', ( map {"B<$_>"} @cmd_path ), $usage );
            $full_pod .= "=item $item_text\n\n";
            my $l = length( $item_text =~ s/[BCEIL] < ([^>]*) >/$1/grx );
            $item_length = $l if $l > $item_length;
        }
        $full_pod .= $cmd_ref->summary;
        $full_pod =~ s/\n*$/\n\n/sx;
    }

    my $max_over_width = int( ( $self->term->term_width - 4 ) / 2 );
    my $over_width     = min( $item_length + 4, $max_over_width );

    $full_pod = $pod_prefix . "=over $over_width\n\n$full_pod";
    $full_pod .= "=back\n\n";

    # Format POD to text, remove extraneous empty lines.
    $text = $self->_format_pod($full_pod);
    $text =~ s/\n\n+/\n/gxs;
    $text =~ s/^\n+//x;

    return ( $full_pod, $text );
}

sub _get_help {
    my ( $self, %args ) = @_;

    # Handle "--all" in a separate routine.
    if ( $args{options}->{all} ) {
        return $self->_get_all_help(%args);
    }

    # Top-level help, i.e. "help" without arguments.
    # Produce a simple command summary.
    if ( @{ $args{arguments} } == 0 ) {
        my ( $pod, $text ) = $self->_make_command_summary(
            cmd_path   => [],
            pod_prefix => "=head2 " . loc("Commands") . ":\n\n",
            commands   => [ $self->parent->commands ]
        );
        return ( %args, pod => $pod, text => $text );
    }

    # We've been given arguments to "help". Find the
    # appropriate command object, and work from there.

    my $cur_cmd_ref = $self->parent;
    my @cmd_ref_path;

    for my $cmd_name ( @{ $args{arguments} } ) {
        my $new_cmd_ref = $cur_cmd_ref->find_command($cmd_name);
        if ( !$new_cmd_ref ) {
            my @cmd_path = map { $_->name } @cmd_ref_path;
            return (
                %args,
                status => -1,
                error  => @cmd_path > 0
                ? "@cmd_path: " . $cur_cmd_ref->error
                : $cur_cmd_ref->error
            );
        }
        push @cmd_ref_path, $new_cmd_ref;
        $cur_cmd_ref = $new_cmd_ref;
    }

    my $pod = $self->_get_help_cmd(
        cmd_path => \@cmd_ref_path,
        style    => 'head1',
    );

    $pod =~ s/\n*$/\n\n/sx;

    my $pod2txt = $self->_format_pod($pod);

    # Only list sub-commands if there are more than one.
    if ( scalar( $cur_cmd_ref->commands ) > 1 ) {
        my ( $cmd_pod, $cmd_text ) = $self->_make_command_summary(
            cmd_path   => \@cmd_ref_path,
            pod_prefix => "=head2 " . loc("Sub-Commands") . ":\n\n",
            commands   => [ $cur_cmd_ref->commands ],
        );
        $pod     .= $cmd_pod;
        $pod2txt .= $cmd_text;
    }

    # Play fast and loose with the POD formatter output.
    # Remove leading and trailing newlines.
    $pod2txt =~ s/^\n+//sx;
    $pod2txt =~ s/\n+$//sx;

    return ( %args, pod => $pod, text => $pod2txt . "\n" );
}

sub _get_help_cmd {
    my ( $self, %args ) = @_;

    my $style    = $args{style} // 'item';
    my @cmd_path = @{ $args{cmd_path} };

    my $cmd = $cmd_path[-1];

    my $usage_prefix = join(
        ' ',
        map {
            $_->usage_text( with_options => 'none', with_subcommands => 0 )
        } @cmd_path[ 0 .. $#cmd_path - 1 ]
    );

    $usage_prefix .= ' ' if length $usage_prefix;

    my $pod;

    if ( $style =~ /head/ ) {
        $pod .= "=$style " . loc("Usage") . ":\n\n";
    }

    for my $usage ( $cmd->usage_text( with_options => 'both' ) ) {
        $pod .= "=item " if $style eq 'item';
        $pod .= "$usage_prefix$usage\n\n";
    }

    $pod =~ s/\n*$//sx;
    $pod .= "\n\n";

    my $description = ( $cmd->description || $cmd->summary );
    if ($description) {
        $pod .= "=$style " . loc("Description") . ":\n\n" if $style =~ /head/;
        $pod .= $description;
    }

    $pod =~ s/\n*$/\n\n/sx;

    return $pod;
}

sub _get_help_all_commands {
    my ( $self, %args ) = @_;

    my @cmd_path = @{ $args{cmd_path} // [] };
    my $cmd      = $cmd_path[-1] // $self->parent;

    my $pod = '';

    if ( $cmd->has_commands ) {
        for my $command ( $cmd->commands ) {
            $pod .= $self->_get_help_all_commands(
                cmd_path => [ @cmd_path, $command ] );
        }
        return $pod;
    }

    return $self->_get_help_cmd( cmd_path => \@cmd_path );
}

sub _get_all_help {
    my ( $self, %args ) = @_;

    my ( $pod1, $txt1 ) = $self->_make_command_summary(
        cmd_path   => [],
        pod_prefix => "=head1 " . loc("COMMAND SUMMARY") . "\n\n",
        commands   => [ $self->parent->commands ]
    );

    my $pod2 =
          "\n=head1 "
        . loc("COMMANDS") . "\n\n"
        . "=over\n\n"
        . $self->_get_help_all_commands()
        . "=back\n";

    my $txt2 = $self->_format_pod($pod2);

    # Play fast and loose with the POD formatter output.
    # Remove leading and trailing newlines.
    $txt2 =~ s/^\n+//sx;
    $txt2 =~ s/\n+$//sx;
    $txt2 .= "\n";

    return ( %args, pod => $pod1 . $pod2, text => "$txt1\n$txt2" );
}

sub complete {
    my ( $self, $text, $state ) = @_;

    my $processed       = $state->{processed}   //= [];
    my $unprocessed     = $state->{unprocessed} //= [];
    my $parsed_options  = $state->{options}     //= {};

    # uncoverable branch false
    if ( $self->has_options ) {

        Getopt::Long::Configure(qw(bundling require_order pass_through));

        my %opt_result = get_options_from_array(
            args         => $unprocessed,
            spec         => $self->options,
            result       => $parsed_options,
            pass_through => 1,
        );

        my $double_dash = $opt_result{double_dash};

        if ( !$double_dash && @{$unprocessed} == 0 && $text =~ /^-/x ) {

            # We have to complete a command-line option.
            return grep { is_prefix_str( $text, $_ ) } $self->option_names;
        }
    }

    my $cur_cmd_ref = $self->parent;
    while (@$unprocessed) {
        my $new_cmd_ref = $cur_cmd_ref->find_command( $unprocessed->[0] );

        return () if !$new_cmd_ref;

        push @{$processed}, {
            element => $new_cmd_ref,
            value   => shift @{$unprocessed},
        };
        $cur_cmd_ref = $new_cmd_ref;
    }

    return grep { is_prefix_str( $text, $_ ) } $cur_cmd_ref->command_names
        if $cur_cmd_ref->has_commands;

    return ();
}

# %args = HELP->_execute_help(%args);
#
# Callback for the builtin "help" command.
#
sub _execute_help {
    my ( $self, %args ) = @_;

    return %args if $args{status} < 0;

    %args = $self->_get_help(%args);

    return %args if $args{status} < 0;

    if ( $args{options}->{pod} ) {
        print "\n$args{pod}";
        return %args;
    }

    my $cli = $self->root_node;
    if ( $cli->can('write_pager') ) {
        return $cli->write_pager(%args);
    }

    my $ok = print $args{text}, $args{text} =~ /\n$/xms ? '' : "\n";

    if (!$ok) {
        $args{status} = -1;
        $args{error}  = $!;
    }
    return %args;
}

1;

__END__

=pod

=head1 NAME

Term::CLI::Command::Help - A generic 'help' command for Term::CLI

=head1 VERSION

version 0.057001

=head1 SYNOPSIS

 use Term::CLI;

 my $cli = Term::CLI->new(
    name => 'myapp',
    prompt => 'myapp> ',
    commands => [
        Term::CLI::Command::Help->new(),
        Term::CLI::Command->new( name => 'copy', ... ),
        Term::CLI::Command->new( name => 'move', ... ),
    ],
 );

 $cli->execute('help');
 # -> command summary

 say "\n----\n";

 $cli->execute('help copy');
 # -> detailed help on 'copy'.

(See L<EXAMPLE|/EXAMPLE> for a working example.)

=head1 DESCRIPTION

The C<Term::CLI::Command::Help> class is derived from
L<Term::CLI::Command>(3p) and implements
a generic "help" command for L<Term::CLI>(3p) applications.

The C<help> command accepts arguments that it will try to match against
the commands of its L<Term::CLI>(3p) parent.

It supports completion, as well as a C<--pod> option to dump raw POD text,
and a C<--all> option to show a command summary followed by extended
help on each commands.

=head1 CONSTRUCTORS

=over

=item B<new>
X<new>

Create a new C<Term::CLI::Command::Help> object and return a reference
to it.

The object provides appropriate default values for all attributes,
so there is no need to provide any.

If you want, you can override the default attributes; in that case,
see the L<Term::CLI::Command>(3p) documentation. Attributes that are
"safe" to override are:

=over

=item B<description> =E<gt> I<Str>

Override the default description for the C<help> command.

=item B<name> =E<gt> I<Str>

Override the name for the help command. Default is C<help>.

=item B<summary> =E<gt>

Override the default summary for the C<help> command.

=item B<usage> =E<gt>

Override the automatic usage string for the C<help> command.

=back

=back

=head1 OUTPUT FORMATTING

Help text is assumed to be in L<POD|perlpod> format, and will be formatted
for the terminal using L<Pod::Text::Termcap>(3p).

=head1 OUTPUT PAGING

The C<help> command will use the parent L<Term::CLI|Term::CLI>(3p)'s
L<write_pager()|Term::CLI/write_pager> method to pipe the formatted output
through a suitable pager.

=head1 EXAMPLE

Using the following code:

    use Term::CLI;

    my $cli = Term::CLI->new(
        name => 'myapp',
        prompt => 'myapp> ',
        commands => [
            Term::CLI::Command::Help->new(),

            Term::CLI::Command->new(
                name => 'copy',
                options => [ 'verbose!' ],
                summary => 'copy I<src> to I<dst>',
                description =>
                    qq{Copy I<src> to I<dst>.\n}
                    .qq{Show progress if C<--verbose> is given.},
                arguments => [
                    Term::CLI::Argument::Filename->new(name => 'src'),
                    Term::CLI::Argument::Filename->new(name => 'dst'),
                ],
            ),
            Term::CLI::Command->new(
                name => 'move',
                options => [ 'verbose!' ],
                summary => 'move I<src> to I<dst>',
                description =>
                    qq{Move I<src> to I<dst>.\n}
                    .qq{Move progress if C<--verbose> is given.},
                arguments => [
                    Term::CLI::Argument::Filename->new(name => 'src'),
                    Term::CLI::Argument::Filename->new(name => 'dst'),
                ],
            )
        ],
    );

    say "\n----\n";

    $cli->execute('help');
    # -> command summary

    say "\n----\n";

    $cli->execute('help copy');
    # -> detailed help on 'copy'.

The output would look something like this:

    ----

      Commands:
        help [cmd ...]                      Show help.
        copy src dst                        copy src to dst
        move src dst                        move src to dst

    ----

      Usage:
        copy [--verbose] src dst

      Description:
        Copy src to dst. Show progress if "--verbose" is given.

    ----

=head1 SEE ALSO

L<cat>(1),
L<less>(1),
L<more>(1),
L<perlpod>(1),
L<pg>(1),
L<Pod::Text::Termcap>(3p).
L<Term::CLI>(3p),
L<Term::CLI::Command>(3p).

=head1 AUTHOR

Steven Bakker E<lt>sbakker@cpan.orgE<gt>, 2018.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2018 Steven Bakker

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See "perldoc perlartistic."

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=begin __PODCOVERAGE

=head1 THIS SECTION SHOULD BE HIDDEN

This section is meant for methods that should not be considered
for coverage. This typically includes things like BUILD and DEMOLISH from
Moo/Moose. It is possible to skip these when using the Pod::Coverage class
(using C<also_private>), but this is not an option when running C<cover>
from the command line.

The simplest trick is to add a hidden section with an item list containing
these methods.

=over

=item BUILD

=item DEMOLISH

=back

=end __PODCOVERAGE

=cut
