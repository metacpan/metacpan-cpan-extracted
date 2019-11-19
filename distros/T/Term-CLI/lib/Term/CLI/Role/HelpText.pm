#=============================================================================
#
#       Module:  Term::CLI::HelpText
#
#  Description:  Class for sets of (sub-)commands in Term::CLI
#
#       Author:  Steven Bakker (SBAKKER), <sbakker@cpan.org>
#      Created:  19/02/18
#
#   Copyright (c) 2018 Steven Bakker
#
#   This module is free software; you can redistribute it and/or modify
#   it under the same terms as Perl itself. See "perldoc perlartistic."
#
#   This software is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#=============================================================================

use 5.014_001;

package Term::CLI::Role::HelpText  0.051007 {

use Modern::Perl 1.20140107;

use Types::Standard 1.000005 qw(
    Maybe
    Str
);

use Moo::Role;
use namespace::clean 0.25;

requires 'options';
requires 'has_commands';
requires 'commands';

has usage => (
    is => 'rw',
    isa => Maybe[Str],
);

has description => (
    is => 'rw',
    isa => Maybe[Str],
);

has summary => (
    is => 'rw',
    isa => Str,
    default => sub{''},
);


sub get_options_summary {
    my $self = shift;
    my %args = (with_options => 'both', @_);

    my $with_options = 0x00;

    if ($args{with_options} =~ /short/i) {
        $with_options |= 0x01;
    }
    if ($args{with_options} =~ /long/i) {
        $with_options |= 0x02;
    }
    if ($args{with_options} =~ /both/i) {
        $with_options |= 0x03;
    }

    my @options;
    my $short_opts_no_arg = '';
    if (my $opt_specs = $self->options) {
        for my $spec (@$opt_specs) {
            my $long_arg = my $short_arg = '';
            if ($spec =~ /=(.*)$/) {
                $long_arg = "=I<$1>";
                $short_arg = "I<$1>";
            }
            elsif ($spec =~ /:(.*)$/) {
                $long_arg = "[=I<$1>]";
                $short_arg = "[I<$1>]";
            }
            for my $optname (split(qr/\|/, $spec =~ s/^([^!+=:]+).*/$1/r)) {
                if (length $optname == 1) {
                    if ($with_options & 0x01) {
                        if (length $short_arg == 0) {
                            $short_opts_no_arg .= $optname;
                        }
                        else {
                            push @options, "[B<-$optname>$short_arg]";
                        }
                    }
                }
                elsif ($with_options & 0x02) {
                    push @options, "[B<--$optname>$long_arg]";
                }
            }
        }
    }
    if (length $short_opts_no_arg) {
        push @options, "[B<-$short_opts_no_arg>]";
    }
    return join(' ', @options);
}


sub usage_text {
    my $self = shift;

    my %args = (
        with_options => 'both',
        with_arguments => 1,
        with_subcommands => 1,
        @_
    );

    if ($self->usage) {
        return $self->usage;
    }

    my $usage_prefix = 'B<'.$self->name.'>';
    my $usage_suffix = '';

    if ($args{with_arguments} and $self->has_arguments) {
        my @args;
        for my $arg ($self->arguments) {
            #my $name = 'I<'.$arg->name.'>';
            my $name = $arg->name;
            my $str = $arg->max_occur > 1 ? "I<${name}1>" : "I<$name>";

            if ($arg->min_occur > 1) {
                for my $n (2..$arg->min_occur) {
                    $str .= " I<${name}$n>";
                }
            }

            if ($arg->max_occur <= 0) {
                $str .= ' ...';
            }
            elsif ($arg->max_occur == $arg->min_occur + 1) {
                $str .= " [I<${name}".$arg->max_occur.">]" if $arg->max_occur > 1;
            }
            elsif ($arg->max_occur == 2 && $arg->min_occur <= 1) {
                $str .= " [I<${name}".$arg->max_occur.">]";
            }
            elsif ($arg->max_occur > $arg->min_occur) {
                $str .= ' ['
                        . "I<$name".($arg->min_occur+1).">"
                        . ' ... '
                        . "I<$name".$arg->max_occur.">"
                        . ']'
                        ;
            }

            if ($arg->min_occur <= 0) {
                $str = "[$str]";
            }
            push @args, $str;
        }
        $usage_suffix = join(' ', @args);
    }

    if ($args{with_subcommands} and $self->has_commands) {
        my @sub_commands = $self->commands;
        my $sub_commands_text;
        if (@sub_commands == 1) {
            $sub_commands_text
                = $sub_commands[0]->usage_text(%args, with_options => 'none');
        }
        else {
            $sub_commands_text
                = '{'.join('|', map { 'B<'.$_->name.'>' } @sub_commands).'}';
        }
        $usage_suffix .= ' ' if length $usage_suffix;
        $usage_suffix .= $sub_commands_text;
    }

    $usage_suffix = " $usage_suffix" if length $usage_suffix;

    my $opts = $self->get_options_summary( with_options => $args{with_options} );

    if (length $opts) {
        return "$usage_prefix $opts$usage_suffix";
    }
    else {
        return "$usage_prefix$usage_suffix";
    }
}


}

1;

__END__

=pod

=head1 NAME

Term::CLI::Role::HelpText - Role for generating help text in Term::CLI

=head1 VERSION

version 0.051007

=head1 SYNOPSIS

 package Term::CLI::Command {

    use Moo;

    with('Term::CLI::Role::HelpText');

    ...
 };

 my $cmd = Term::CLI::Command->new(
    name => 'file',
    options => ['verbose|v'],
    arguments => [
        Term::CLI::Argument::Filename->new(name => 'path'),
    ],
    commands => [
        Term::CLI::Command->new(name => 'info'),
        Term::CLI::Command->new(name => 'delete'),
        Term::CLI::Command->new(name => 'show'),
    ],
 );

 say $cmd->usage_text();
 # -> file [--verbose] [-v] path {info|delete|show}

 say $cmd->usage_text( with_options => 'long' );
 # -> file [--verbose] path {info|delete|show}

 say $cmd->usage_text( with_options => 'none');
 # -> file path {info|delete|show}

 say $cmd->usage_text( with_arguments => 0);
 # -> file [--verbose] [-v] {info|delete|show}

 say $cmd->usage_text( with_subcommands => 0);
 # -> file [--verbose] [-v] path

=head1 DESCRIPTION

Role for L<Term::CLI::Command>(3p) elements that need to have
help text.

This role is consumed by L<Term::CLI::Command>(3p).

The functionality of this role is primarily used by 
L<Term::CLI::Command::Help>(3p).

=head1 ATTRIBUTES

This role defines three additional attributes:

=over

=item B<description> =E<gt> I<Str>

Fragment of POD text that describes the command in some detail.
It is typically shown when help is requested for specifically
this command.

Default is C<undef>, which typically means that the
L<summary|/summary> attribute is used in its place.

=item B<summary> =E<gt> I<Str>

Short summary of the command (e.g. what you typically find in the B<NAME>
section of a manual page), that is typically displayed in a command
summary.

Default is an empty string.

=item B<usage> =E<gt> I<Str>

Optional attribute that should contain a single line of POD
documentation to describe the syntax of the command.

Default is C<undef>, which causes L<usage_text|/usage_text>
to automatically generate a usage line.

B<NOTE:> if this is specified, the L<usage_text|/usage_text>
method will always return this value.

=back

=head1 ACCESSORS

=over

=item B<description> ( [ I<Str> ] )
X<description>

Get or set the description help text.

=item B<summary> ( [ I<Str> ] )
X<summary>

Get or set the summary help text.

=item B<usage> ( [ I<Str> ] )
X<usage>

Get or set the static usage text.

=back

=head1 METHODS

=over

=item B<get_options_summary> ( [ B<with_options> =E<gt> I<VAL> )
X<get_options_summary>

Return a line of POD text for the command line options for this
command, depending on the value of the B<with_options> parameter.

This function is called by L<usage_text|/usage_text>. You'll
probably never need to call it directly.

=item B<usage_text> ( I<OPT> =E<gt> I<VAL>, ... )
X<usage_text>

Return a line of POD text with a usage summary for the command.

If the L<usage|/usage> attribute has been set, then this value is always
returned. Otherwise, the method will construct a POD fragment from the
command's name, options, arguments, and sub-commands.

The following parameters are recognised:

=over

=item B<with_options> =E<gt> {C<long>|C<short>|C<both>|C<none>}

Specify which command options to include in the usage text. Options are
C<long> to only include long options (e.g. C<< [B<--verbose>] >>),
C<short> to only include short options (e.g. C<< [B<-v>] >>),
C<both> for both short and long options (e.g. C<< [B<--verbose>] [B<-v>] >>),
or C<none> for none.

Default is C<both>.

=item B<with_arguments> =E<gt> {0|1}

Specify whether or not to include placeholders for command line arguments in
the usage line.

Default is C<1>.

=item B<with_subcommands> =E<gt> {0|1}

Specify whether or not to include the list of sub-commands in
the usage line.

Default is C<1>.

=back

=back

=head1 SEE ALSO

L<Term::CLI>(3p),
L<Term::CLI::Command::Help>(3p),
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
