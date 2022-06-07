#=============================================================================
#
#       Module:  Term::CLI::CommandSet
#
#  Description:  Class for sets of (sub-)commands in Term::CLI
#
#       Author:  Steven Bakker (SBAKKER), <sbakker@cpan.org>
#      Created:  05/02/18
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

package Term::CLI::Role::CommandSet 0.057001;

use 5.014;
use warnings;

use Carp qw( croak );
use Scalar::Util qw( reftype );
use Term::CLI::L10N qw( loc );
use Term::CLI::Util qw( find_obj_name_matches );

use Types::Standard 1.000005 qw(
    ArrayRef
    Bool
    CodeRef
    InstanceOf
    ConsumerOf
    Maybe
);

use Moo::Role;
use namespace::clean 0.25;

my $ERROR_STATUS  = -1;

requires qw( parent root_node );

has '+parent' => (
    is       => 'rwp',
    weak_ref => 1,
    isa      => Maybe[ ConsumerOf ['Term::CLI::Role::CommandSet'] ],
);

has _command_list => (
    is       => 'rw',
    isa      => Maybe [ArrayRef|CodeRef],
    init_arg => 'commands',
    writer   => '_set_command_list',
    trigger  => 1,
    coerce   => sub {
        my ($arg) = @_;
        if (ref $arg && reftype $arg eq 'ARRAY') {
            # clone and sort array.
            return [ sort { $a->name cmp $b->name } @{$arg} ];
        }
        return $arg;
    }
);

has callback => (
    is        => 'rw',
    isa       => Maybe [CodeRef],
    predicate => 1
);

has require_sub_command => (
    is      => 'ro',
    isa     => Bool,
    default => sub { 1 },
);

# $self->_set_command_list($ref) => $self->_trigger__command_list($ref);
#
# Trigger to run whenever the object's _commands array ref is set.
#
sub _trigger__command_list { ## no critic (ProhibitUnusedPrivateSubroutines)
    my ( $self, $cmd_list ) = @_;

    return if !$cmd_list;

    # Set the parent for each command object.
    if (ref $cmd_list && reftype $cmd_list eq 'ARRAY') {
        for my $cmd_obj ( @{$cmd_list} ) {
            $cmd_obj->_set_parent($self);
        }
    }
    return;
}

# Get the command list reference, expand a CODE ref if necessary.
sub _get_command_list {
    my ($self) = @_;

    my $command_list = $self->_command_list;

    return undef if !ref $command_list;

    return $command_list if reftype $command_list eq 'ARRAY';

    if (reftype $command_list ne 'CODE') {
        croak "internal error: 'command' ($command_list) is ",
            "neither a CodeRef nor an ArrayRef!";
    }

    $command_list = $command_list->($self);

    if (!ref $command_list || reftype $command_list ne 'ARRAY') {
        croak "'command' CodeRef should return an ARRAY ref, not ",
            ref $command_list     ? reftype( $command_list ) :
            defined $command_list ?  "'$command_list'"       :
            '(undef)';
    }

    return $self->_set_command_list($command_list);
}

sub commands {
    my ($self) = @_;
    my $command_list = $self->_get_command_list // [];
    return @{ $command_list };
}

sub command_names {
    my ($self) = @_;
    my $command_list = $self->_get_command_list or return;
    my @l = map { $_->name } @{$command_list};
    return @l;
}

sub has_commands {
    my ($self) = @_;
    my $command_list = $self->_get_command_list or return !1;
    return scalar( @{$command_list} ) > 0;
}

sub add_command {
    my ( $self, @commands ) = @_;

    my $cmd_list = $self->_get_command_list;

    if (!$cmd_list) {
        $cmd_list = \@commands;
        $self->_set_command_list($cmd_list);
        return $self;
    }

    for my $cmd_obj ( @commands ) {
        $cmd_obj->_set_parent( $self );
    }

    push @{$cmd_list}, @commands;
    @{$cmd_list} = sort { $a->name cmp $b->name } @{$cmd_list};

    return $self;
}

sub delete_command {
    my ( $self, @commands ) = @_;

    my $cmd_list = $self->_get_command_list or return;

    my %to_delete = map { (ref $_ ? $_->name : $_ ) => 1 } @commands;

    my @deleted;

    for my $index (reverse 0..$#{$cmd_list}) {
        my $cmd_obj = $cmd_list->[$index];
        if ( $to_delete{$cmd_obj->name} ) {
            my $cmd_obj = splice @{$cmd_list}, $index, 1;
            $cmd_obj->_set_parent(undef);
            push @deleted, $cmd_obj;
        }
    }
    return @deleted;
}

sub find_matches {
    my ( $self, $text ) = @_;
    return find_obj_name_matches($text, $self->_get_command_list);
}

sub find_command {
    my ( $self, $text ) = @_;

    my @matches = find_obj_name_matches(
        $text, $self->_get_command_list, exact => 1 );

    return $self->set_error( loc( "unknown command '[_1]'", $text ) )
        if @matches == 0;

    return $matches[0] if @matches == 1 || $matches[0]->name eq $text;

    return $self->set_error(
        loc("ambiguous command '[_1]' (matches: [_2])",
            $text,
            join( ', ', map { $_->name } @matches )
        )
    );
}

sub try_callback {
    my ( $self, %args ) = @_;

    if ( $self->has_callback && defined $self->callback ) {
        return $self->callback->( $self, %args );
    }
    return %args;
}

# CLI->_set_completion_attribs();
#
# Set some attributes in the Term::ReadLine object related to
# custom completion.
#
sub _set_completion_attribs {
    my ($self) = @_;
    my $root = $self->root_node;
    my $term = $root->term;


    # set Completion for current object
    $term->Attribs->{completion_function} = sub { $self->complete_line( @_ ) };

    # Default: '"
    $term->Attribs->{completer_quote_characters} = $root->quote_characters;

    # Default: \n\t\\"'`@$><=;|&{( and <space>
    $term->Attribs->{completer_word_break_characters} = $root->word_delimiters;

    # Default: <space>
    $term->Attribs->{completion_append_character} =
        substr( $root->word_delimiters, 0, 1 );

    return;
}

# See POD X<complete_line>
sub complete_line {
    my ( $self, $text, $line, $start ) = @_;

    my $root = $self->root_node;

    $self->_set_completion_attribs;

    my $quote_char = $self->term->completion_quote_character;

    my @words;

    if ( $start > 0 ) {
        if ( length $quote_char ) {

            # ReadLine thinks the $text to be completed is quoted.
            # The quote character will precede the $start of $text.
            # Make sure we do not include it in the text to break
            # into words...
            $start--;
        }
        ( my $err, @words ) =
            $root->_split_line( substr( $line, 0, $start ) );
    }

    my @list;

    if ( @words == 0 ) {
        @list = map { $_->name } $self->find_matches( $text );
    }
    elsif ( my $cmd = $self->find_command( $words[0] ) ) {
        shift @words;
        @list = $cmd->complete(
            $text => {
                processed   => [{
                    element => $cmd,
                    value   => $cmd->name,
                }],
                unprocessed => \@words,
                options => {},
            }
        );
    }

    return @list if length $quote_char; # No need to worry about spaces.

    # Escape spaces in reply if necessary.
    my $delim = $root->word_delimiters;
    return map {s/([$delim])/\\$1/rgx} @list;
}

sub readline {    ## no critic (ProhibitBuiltinHomonyms)
    my ( $self, %args ) = @_;

    my $root = $self->root_node;

    my $prompt = $args{prompt} // $self->prompt;
    my $skip   = exists $args{skip} ? $args{skip} : $root->skip;

    $self->_set_completion_attribs;

    my $input;
    while ( defined( $input = $root->term->readline($prompt) ) ) {
        next if defined $skip && $input =~ $skip;
        last;
    }
    return $input;
}

# OBJ->_split_line( $text );
#
# Attempt to split $text into words. Use a custom split function if
# necessary.
#
sub _split_line {
    my ( $self, $text ) = @_;
    my $root_node = $self->root_node;
    return $root_node->split_function->( $root_node, $text );
}

sub execute { return shift->execute_line(@_) }  ## DEPRECATED

sub execute_line {
    my ( $self, $cmd ) = @_;

    my ( $error, @cmd ) = $self->_split_line($cmd);

    my %args = (
        status       => 0,
        error        => q{},
        command_line => $cmd,
        command_path => [$self],
        unprocessed  => \@cmd,
        processed    => [],
        options      => {},
        arguments    => [],
    );

    $args{unparsed} = $args{unprocessed};

    return $self->try_callback( %args, status => $ERROR_STATUS,
        error => $error )
        if length $error;

    if ( @cmd == 0 ) {
        $args{error}  = loc("missing command");
        $args{status} = $ERROR_STATUS;
    }
    elsif ( my $cmd_ref = $self->find_command( $cmd[0] ) ) {
        my $cmd = shift @{$args{unprocessed}};
        %args = $cmd_ref->execute_command(
            %args, 
            processed => [ { element => $cmd_ref, value => $cmd } ],
        );
    }
    else {
        $args{error}  = $self->error;
        $args{status} = $ERROR_STATUS;
    }

    return $self->try_callback(%args);
}


1;

__END__

=pod

=head1 NAME

Term::CLI::Role::CommandSet - Role for (sub-)commands in Term::CLI

=head1 VERSION

version 0.057001

=head1 SYNOPSIS

 package Term::CLI::Command {

    use Moo;

    with('Term::CLI::Role::CommandSet');

    ...
 };

 my $cmd = Term::CLI::Command->new( ... );

 $cmd->callback->( %args ) if $cmd->has_callback;

 if ( $cmd->has_commands ) {
    my $cmd_ref = $cmd->find_command( $cmd_name );
    die $cmd->error unless $cmd_ref;
 }

 say "command names:", join(', ', $cmd->command_names);

 $cmd->callback->( $cmd, %args ) if $cmd->has_callback;

 %args = $cmd->try_callback( %args );

=head1 DESCRIPTION

Role for L<Term::CLI>(3p) elements that contain
a set of L<Term::CLI::Command>(3p) objects.

This role is used by L<Term::CLI>(3p) and L<Term::CLI::Command>(3p).

=head1 ATTRIBUTES

This role defines two additional attributes:

=over

=item B<commands> =E<gt> { I<ArrayRef> | I<CodeRef> }

Either an C<ArrayRef> containing C<Term::CLI::Command>
object instances that describe the sub-commands that the command takes,
a C<CodeRef> that returns such an C<ArrayRef>, or C<undef>.

Note that the elements of the array are copied over to an internal
array, so modifications to the C<ArrayRef> will not be seen.

In case a C<CodeRef> is specified, the C<CodeRef> will be called only
once, i.e. when the list of commands needs to be expanded. This allows
for delayed object creation, which can be useful in deeper levels of the
command hierarchy to reduce startup time.

See also the L<commands|/commands> accessor below.

=item B<callback> =E<gt> I<CodeRef>

Reference to a subroutine that should be called when the command
is executed, or C<undef>.

=item B<require_sub_command> =E<gt> I<Bool>

Default is 1 (true).

If the list of C<commands> is not empty, it is normally required that the input
contains one of these sub-commands after the "parent" command word. However, it
may be desirable to allow the parent command to appear "naked", i.e. without a
sub-command.

For such cases, set the C<require_sub_command> to a false value.

See also L<Term::CLI::Role::CommandSet|Term::CLI::Role::CommandSet/ATTRIBUTES>.

=back

=head1 ACCESSORS AND PREDICATES

=over

=item B<commands>
X<commands>

Returns an C<ArrayRef> containing C<Term::CLI::Command>
object instances that describe the sub-commands that the command takes,
or C<undef>.

Note that, although a C<CodeRef> can be specified in the constructor, the
actual I<accessor> will never return the C<CodeRef>. Rather, it
will call the C<CodeRef> once and store the result in an C<ArrayRef>.

=item B<has_callback>
X<has_callback>

=item B<has_commands>
X<has_commands>

Predicate functions that return whether or not any (sub-)commands
have been added to this object.

=item B<callback> ( [ I<CODEREF> ] )
X<callback>

I<CODEREF> to be called when the command is executed. The callback
is called as:

   OBJ->callback->(OBJ,
        status       => Int,
        error        => Str,
        options      => HashRef,
        arguments    => ArrayRef[Value],
        command_line => Str,
        command_path => ArrayRef[InstanceOf['Term::CLI::Command']],
   );

Where:

=over

=item I<CLI_REF>

Reference to the current C<Term::CLI> object.

=item C<status>

Indicates the status of parsing/execution so far.
It has the following meanings:

=over

=item I<E<lt> 0>

Negative status values indicate a parse error. This is a sign that no
action should be taken, but some error handling should be performed.
The actual parse error can be found under the C<error> key. A typical
thing to do in this case is for one of the callbacks in the chain (e.g.
the one on the C<Term::CLI> object) to print the error to F<STDERR>.

=item I<0>

The command line parses as valid and execution so far has been successful.

=item I<E<gt> 0>

Some error occurred in the execution of the action. Callback functions need
to set this by themselves.

=back

=item C<error>

In case of a negative C<status>, this will contain the parse error. In
all other cases, it may or may not contain useful information.

=item C<options>

Reference to a hash containing all command line options.
Compatible with the options hash as set by L<Getopt::Long>(3p).

=item C<arguments>

Reference to an array containing all the arguments to the command.
Each value is a scalar value, possibly converted by
its corresponding L<Term::CLI::Argument>'s
L<validate|Term::CLI::Argument/validate> method (e.g. C<3e-1> may have
been converted to C<0.3>).

=item C<unparsed> (DEPRECATED)

=item C<unprocessed>

Reference to an array containing all the words on the command line that
have not been parsed as arguments or sub-commands yet. In case of parse
errors, this often contains elements, and otherwise should be empty.

=item C<command_line>

The complete command line as given to the
L<Term::CLI::execute|Term::CLI/execute> method.

=item C<command_path>

Reference to an array containing the "parse tree", i.e. a list
of object references that represent the commands and sub-commands
that led up to this point:

    [
        InstanceOf['Term::CLI'],
        InstanceOf['Term::CLI::Command'],
        ...
    ]

The first item in the C<command_path> list is always the top-level
L<Term::CLI> object.

The I<OBJ_REF> will be somewhere in that list; it will be the last
one if it is the "leaf" command.

=item C<processed>

More elaborate "parse tree": a list of hashes that represent all the
elements on the command line that led up to this point, minus the
L<Term::CLI> object itself.

    [
        {
            element => InstanceOf['Term::CLI::Command'],
            value   => String
        },
        {
            element => InstanceOf['Term::CLI::Argument'],
            value   => String
        },
        {
            element => InstanceOf['Term::CLI::Argument'],
            value   => String
        },
        ...
    ]

=back

The callback is expected to return a hash (list) containing at least the
same keys. The C<command_path>, C<arguments>, and C<options> should
be considered read-only.

Note that a callback can be called even in the case of errors, so you
should always check the C<status> before doing anything.

=item B<commands>
X<commands>

Return the list of subordinate C<Term::CLI::Command> objects
(i.e. "sub-commands") sorted on C<name>.

=back

=head1 METHODS

=over

=item B<add_command> ( I<CMD_REF>, ... )
X<add_command>

Add the given I<CMD_REF> command(s) to the list of (sub-)commands, setting
each I<CMD_REF>'s L<parent|/parent> in the process.

=item B<command_names>
X<command_names>

Return the list of (sub-)command names, sorted alphabetically.

=item B<complete_line> ( I<TEXT>, I<LINE>, I<START> )
X<complete_line>

Called when the user hits the I<TAB> key for completion.

I<TEXT> is the text to complete, I<LINE> is the input line so
far, I<START> is the position in the line where I<TEXT> starts.

The function will split the line in words and delegate the
completion to the first L<Term::CLI::Command> sub-command,
see L<Term::CLI::Command|Term::CLI::Command/complete>.

=item B<delete_command> ( I<CMD>, ... )
X<delete_command>

Remove the given I<CMD> command(s) from the list of (sub-)commands,
setting each object's L<parent|/parent> attribute to C<undef>.

I<CMD> can be a string denoting a command name, or a
L<Term::CLI::Command|Term::CLI::Command> object reference; if it
is a reference, its C<name> will be used to locate the appropriate
(sub-)command.

Return the list of objects that were removed.

=item B<execute> ( I<Str> ) B<### DEPRECATED>
X<execute>

=item B<execute_line> ( I<Str> )
X<execute_line>

Parse and execute the command line consisting of I<Str>
(see the return value of L<readline|/readline> above).

The command line is split into words using
the L<split_function|/split_function>.
If that succeeds, then the resulting list of words is
parsed and executed, otherwise a parse error is generated
(i.e. the object's L<callback|Term::CLI::Role::CommandSet/callback>
function is called with a C<status> of C<-1> and a suitable C<error>
field).

For specifying a custom word splitting method, see
L<split_function|/split_function>.

Example:

    while (my $line = $cli->readline(skip => qr/^\s*(?:#.*)?$/)) {
        $cli->execute_line($line);
    }

The command line is parsed depth-first, and for every
L<Term::CLI::Command>(3p) encountered, that object's
L<callback|Term::CLI::Role::CommandSet/callback> function
is executed (see
L<callback in Term::CLI::Role::Command|Term::CLI::Role::CommandSet/callback>).

The C<execute_line> function returns the results of the last called callback
function.

=over

=item *

Suppose that the C<file> command has a C<show> sub-command that takes
an optional C<--verbose> option and a single file argument.

=item *

Suppose the input is:

    file show --verbose foo.txt

=item *

Then the parse tree looks like this:

    (cli-root)
        |
        +--> Command 'file'
                |
                +--> Command 'show'
                        |
                        +--> Option '--verbose'
                        |
                        +--> Argument 'foo.txt'

=item *

Then the callbacks will be called in the following order:

=over

=item 1.

Callback for 'show'

=item 2.

Callback for 'file'

=item 3.

Callback for C<Term::CLI> object.

=back

=back

The return value from each L<callback|Term::CLI::Role::CommandSet/callback>
(a hash in list form) is fed into the next callback function in the
chain. This allows for adding custom data to the return hash that will
be fed back up the parse tree (and eventually to the caller).

=item B<find_matches> ( I<Str> )
X<find_matches>

Return a list of all commands in this object that match the I<Str>
prefix.

=item B<find_command> ( I<Str> )
X<find_command>

Check whether I<Str> uniquely matches a command in this C<Term::CLI>
object. Returns a reference to the appropriate
L<Term::CLI::Command|Term::CLI::Command> object if successful; otherwise,
it sets the object's C<error> field and returns C<undef>.

Example:

    my $sub_cmd = $cmd->find_command($prefix);
    die $cmd->error unless $sub_cmd;

=item B<readline> ( [ I<ATTR> =E<gt> I<VAL>, ... ] )
X<readline>

Read a line from the input connected to L<term|/term>, using
the L<Term::ReadLine> interface.

By default, it returns the line read from the input, or
an empty value if end of file has been reached (e.g.
the user hitting I<Ctrl-D>).

The following I<ATTR> are recognised:

=over

=item B<skip> =E<gt> I<RegEx>

Override the object's L<skip|/skip> attribute.

Skip lines that match the I<RegEx> parameter. A common
call is:

    $text = CLI->readline( skip => qr{^\s+(?:#.*)$} );

This will skip empty lines, lines containing whitespace, and
comments.

=item B<prompt> =E<gt> I<Str>

Override the prompt given by the L<prompt|/prompt> method.

=back

Examples:

    # Just read the next input line.
    $line = $cli->readline;
    exit if !defined $line;

    # Skip empty lines and comments.
    $line = $cli->readline( skip => qr{^\s*(?:#.*)?$} );
    exit if !defined $line;

=item B<try_callback> ( I<ARGS> )
X<try_callback>

Wrapper function that will call the object's C<callback> function if it
has been set, otherwise simply returns its arguments.

=back

=head1 SEE ALSO

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

=item parent

=item BUILD

=item DEMOLISH

=back

=end __PODCOVERAGE

=cut
