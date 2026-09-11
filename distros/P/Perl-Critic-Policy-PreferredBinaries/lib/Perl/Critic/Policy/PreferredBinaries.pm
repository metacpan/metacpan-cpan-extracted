package Perl::Critic::Policy::PreferredBinaries;
$Perl::Critic::Policy::PreferredBinaries::VERSION = '0.002';
# 5.014, which is as low as the house style allows: RequireDefault wants /aa on
# every pattern, and /aa arrived in 5.14.  Kept that low rather than at the
# 5.041 applications here are written against, because a policy runs on
# whatever perl the code being criticised is criticised with.
use 5.014;

use strict;
use warnings FATAL => 'all';

use re '/aa';

use parent 'Perl::Critic::Policy';

use Perl::Critic::Utils qw{ :severities :classification :ppi $SEVERITY_MEDIUM $TRUE $FALSE };

use Perl::Critic::Exception::Configuration::Generic ();

use Config::INI::Reader ();
use File::Basename      ();
use Scalar::Util        ();

# ABSTRACT: Recommend a perl sub over shelling out to a binary that does the same job



sub supported_parameters {
    return (
        {
            name        => 'config',
            description => 'Config::INI file listing binaries and what to use instead.',
            behavior    => 'string',
        },

        # The library runners that hand a command to the system the way
        # `system` does.  They are always read because a policy that caught only
        # `system` would be a policy people route around by reaching for
        # IPC::Run3, which is a step sideways rather than the step this is
        # asking for.
        {
            name                       => 'runners',
            description                => 'More subs to read as runners of a command.',
            behavior                   => 'string list',
            list_always_present_values => [qw{ run3 run capture capturex runx systemx }],
        },
    );
}

use constant default_severity => $SEVERITY_MEDIUM;
use constant default_themes   => qw{ maintenance certrec };

use constant applies_to => qw{
  PPI::Token::Word
  PPI::Token::QuoteLike::Backtick
  PPI::Token::QuoteLike::Command
};

use constant DEFAULT_CONFIG => '.preferred_binaries.ini';

# The builtins that hand a command to the system.  The library runners that do
# the same are the defaults of the runners parameter.
my %BUILTIN  = map { $_ => 1 } qw{ system exec };
my %PIPE_OPS = map { $_ => 1 } ( '-|', '|-' );

sub initialize_if_enabled {
    my ( $self, $config ) = @_;

    $self->{_preferred} = $self->_parse_config( $self->_config_file($config) );

    # A call is matched on the last part of its name, so a runner configured
    # with its package has to be too, or it would never match anything.
    $self->{_runners} = { map { ( split( q{::}, $_ ) )[-1] => 1 } keys %{ $self->{_runners} } };

    return $TRUE;
}

sub _config_file {
    my ( $self, $config ) = @_;

    $config //= $self->__get_config;

    my $file = $config->get('config');
    $file = DEFAULT_CONFIG unless defined $file && length $file;
    $file =~ s{^~}{$ENV{HOME} // q{}};

    return $file;
}

# A missing file is not an error.  This policy is in the default set of the
# distributions that use it, and most of them have nothing to say about
# binaries -- refusing to run would make every one of those a configuration
# problem to suppress.
sub _parse_config {
    my ( $self, $file ) = @_;

    return {} unless length $file && -e $file;

    # Slurped rather than read_file, for compatibility with Test::MockFile.
    my $content;
    {
        local $/ = undef;
        open( my $fh, '<', $file ) or $self->_throw("Cannot open config file '$file': $!");
        $content = <$fh>;
        close($fh);
    }

    my $parsed = eval { Config::INI::Reader->read_string($content) }
      or $self->_throw("Invalid configuration file '$file'");

    my %preferred;
    foreach my $section ( keys %$parsed ) {
        next if $section eq '_';

        my $entry = $parsed->{$section};
        next unless ref $entry eq 'HASH';

        # The section name is a command line: the binary and any leading
        # arguments that have to match with it.
        my @words = split( ' ', $section );
        next unless @words;

        $words[0] = File::Basename::basename( $words[0] );
        $preferred{ join( ' ', @words ) } = $entry;
    }

    return \%preferred;
}

sub _throw {
    my ( $self, $message ) = @_;

    return Perl::Critic::Exception::Configuration::Generic->throw( message => __PACKAGE__ . " $message" );
}

sub violates {
    my ( $self, $elem ) = @_;

    return () unless %{ $self->{_preferred} // {} };

    my @violations;
    foreach my $command ( $self->_commands_in($elem) ) {
        my ( $key, $entry ) = $self->_match($command) or next;

        my $reason = $entry->{reason} // q{};
        $reason = substr( $reason, 1, -1 ) if $reason =~ m/\A".*"\z/s;

        my $what =
          defined $entry->{prefer}
          ? "Prefer $entry->{prefer} to shelling out to '$key'"
          : "Shelling out to '$key' is not recommended";

        # A severity named on the entry rather than on the policy, which is how
        # Perl::Critic::Policy::PreferredModules does the same thing: the
        # violation takes the policy's severity as it is made, so the way to
        # give it another is to have another in place while it is made.
        local $self->{_severity} = $entry->{severity} if defined $entry->{severity};

        push(
            @violations,
            $self->violation(
                $what,
                ( length $reason ? $reason : "$key has an answer in perl; use it rather than a process" ),
                $elem,
            )
        );
    }

    return @violations;
}

# The command lines this element hands to a shell, as arrayrefs of leading
# literal words.  More than one, because IPC::Run takes a pipeline of arrayrefs.
sub _commands_in {
    my ( $self, $elem ) = @_;

    return ( _words_from_string( _inside_quotelike($elem) ) )
      if $elem->isa('PPI::Token::QuoteLike::Backtick') || $elem->isa('PPI::Token::QuoteLike::Command');

    return () unless $elem->isa('PPI::Token::Word');

    my $word = "$elem";

    return $self->_from_open($elem)      if $word eq 'open'                                           && is_function_call($elem);
    return $self->_from_arguments($elem) if $BUILTIN{$word}                                           && is_function_call($elem);
    return $self->_from_runner($elem)    if $self->{_runners}{ ( split( q{::}, $word ) )[-1] // q{} } && !is_hash_key($elem);

    return ();
}

# open( $fh, '-|', 'curl', ... ) and the two-argument open( $fh, "curl ... |" ).
sub _from_open {
    my ( $self, $elem ) = @_;

    my @args = parse_arg_list($elem);
    return () unless @args >= 2;

    my $mode = _literal( _first_token( $args[1] ) );
    return () unless defined $mode;

    if ( $PIPE_OPS{$mode} ) {
        return () unless @args >= 3;
        return ( _words_from_args( @args[ 2 .. $#args ] ) );
    }

    # Two-argument form: the mode is the command, with a pipe on one end.
    return () unless $mode =~ s{\A\s*\|}{} || $mode =~ s{\|\s*\z}{};

    return ( _words_from_string($mode) );
}

sub _from_arguments {
    my ( $self, $elem ) = @_;

    my @args = parse_arg_list($elem);
    return () unless @args;

    # A single string argument is a shell command line; a list, or an arrayref
    # as the runners take, is already split into words.
    return ( _words_from_args(@args) );
}

# A runner is matched by name, and its command is either positional -- the
# first argument, often an arrayref, as IPC::Run3 and IPC::Run take it -- or the
# value of a named `command =>`, which is how IPC::Cmd::run takes it, in any
# position among the other named arguments.
sub _from_runner {
    my ( $self, $elem ) = @_;

    my @args = parse_arg_list($elem);
    return () unless @args;

    my @named = _named_command(@args);
    return @named if @named;

    return ( _words_from_args(@args) );
}

sub _named_command {
    my (@args) = @_;

    my @tokens = map { ref $_ eq 'ARRAY' ? @$_ : $_ } @args;
    foreach my $i ( 0 .. $#tokens ) {
        my $token = $tokens[$i];
        next unless Scalar::Util::blessed($token) && $token->isa('PPI::Token::Word') && "$token" eq 'command';

        my $value = $i + 1;
        $value++ while $value <= $#tokens && Scalar::Util::blessed( $tokens[$value] ) && $tokens[$value]->isa('PPI::Token::Operator');
        return () if $value > $#tokens;

        return _words_from_args( [ $tokens[$value] ] );
    }

    return ();
}

# Each argument is a list of PPI tokens.  An arrayref argument is a command in
# its own right, which is how IPC::Run3 and IPC::Run spell one.
sub _words_from_args {
    my (@args) = @_;

    my @commands;
    my @literal;

    foreach my $arg (@args) {
        my @tokens = ref $arg eq 'ARRAY' ? @$arg : ($arg);

        if ( @tokens == 1 && Scalar::Util::blessed( $tokens[0] ) && $tokens[0]->isa('PPI::Structure::Constructor') ) {
            push( @commands, _words_from_constructor( $tokens[0] ) );
            next;
        }

        my @words = map { _literal_words($_) } @tokens;

        # Once a word cannot be read literally there is nothing further to say
        # about this command: what follows may be arguments to something else
        # entirely.
        last unless @words;
        push( @literal, @words );
    }

    unshift( @commands, \@literal ) if @literal;

    # One bare string is a shell command line rather than a word.
    if ( @literal == 1 && $literal[0] =~ m/\s/ ) {
        $commands[0] = ( _words_from_string( $literal[0] ) )[0];
    }

    return @commands;
}

# An arrayref argument is a command in its own right.  Its children are an
# expression rather than a run of tokens, so this descends one level to find
# them.
sub _words_from_constructor {
    my ($node) = @_;

    my @children = $node->schildren;
    @children = $children[0]->schildren
      if @children == 1 && Scalar::Util::blessed( $children[0] ) && $children[0]->isa('PPI::Statement');

    my @words;
    foreach my $token (@children) {
        next if Scalar::Util::blessed($token) && $token->isa('PPI::Token::Operator') && "$token" eq ',';

        my @literal = _literal_words($token);
        last unless @literal;
        push( @words, @literal );
    }

    return @words ? ( \@words ) : ();
}

# parse_arg_list gives an arrayref of tokens per argument; this is the first
# one, for the arguments that are a single literal.
sub _first_token {
    my ($arg) = @_;

    return $arg unless ref $arg eq 'ARRAY';
    return $arg->[0];
}

# A qw{} list is several words; anything else quoted is one.
sub _literal_words {
    my ($token) = @_;

    # parse_arg_list hands back an arrayref per argument, and an argument can
    # itself be a list -- so anything that is not a PPI node is not a word.
    return () unless Scalar::Util::blessed($token);
    return ()              if $token->isa('PPI::Token::Operator') && "$token" eq ',';
    return ()              if $token->isa('PPI::Token::Whitespace');
    return ()              if $token->isa('PPI::Structure::List') || $token->isa('PPI::Structure::Constructor');
    return $token->literal if $token->isa('PPI::Token::QuoteLike::Words');

    my $literal = _literal($token);
    return defined $literal ? ($literal) : ();
}

sub _literal {
    my ($token) = @_;

    return undef unless Scalar::Util::blessed($token) && $token->isa('PPI::Token::Quote');

    # ->literal is only on the ones with no interpolation to worry about;
    # ->string on an interpolating quote hands back the source, which is a
    # perfectly good answer for the leading words of a command.
    return $token->can('literal') ? $token->literal : $token->string;
}

# What is between the delimiters of a backtick or qx token.  PPI records the
# separator and not the span, so this takes the delimiters off the content
# rather than asking: one leading `qx`, then one character at each end, which
# covers `...`, qx{...}, qx(...) and qx/.../ alike.
sub _inside_quotelike {
    my ($elem) = @_;

    my $content = $elem->content;
    $content =~ s/\Aqx//;

    return q{} if length($content) < 2;
    return substr( $content, 1, -1 );
}

# The leading words of a shell command line, stopping at anything that is not
# one -- a variable, a pipe, a redirection.
sub _words_from_string {
    my ($string) = @_;

    return () unless defined $string;

    my @words;
    foreach my $word ( split( ' ', $string ) ) {
        last if $word =~ m/[\$\@\|<>;&`]/;
        push( @words, $word );
    }

    return @words ? ( \@words ) : ();
}

# The longest configured section whose words are the leading words of this
# command.  Longest first, so [ssh-keygen -y] beats [ssh-keygen].
sub _match {
    my ( $self, $command ) = @_;

    return () unless ref $command eq 'ARRAY' && @$command;

    my @words = @$command;
    $words[0] = File::Basename::basename( $words[0] );

    foreach my $length ( reverse 1 .. scalar @words ) {
        my $key   = join( ' ', @words[ 0 .. $length - 1 ] );
        my $entry = $self->{_preferred}{$key} or next;
        return ( $key, $entry );
    }

    return ();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::Critic::Policy::PreferredBinaries - Recommend a perl sub over shelling out to a binary that does the same job

=head1 VERSION

version 0.002

=head1 SYNOPSIS

With C<ssh-keygen>, C<dig> and C<curl> named in F<.preferred_binaries.ini> --
see L</CONFIGURATION> -- each of these is reported, along with what to use
instead:

    my ( $path, $name, $url );

    system( 'ssh-keygen', '-t', 'rsa', '-f', $path );
    my $out = `dig +short $name`;
    open( my $fh, '-|', 'curl', '-s', $url ) or die "curl: $!";

=head1 DESCRIPTION

L<Perl::Critic::Policy::logicLAB::ProhibitShellDispatch> says not to shell out.
This says what to do instead, for the binaries somebody has already worked out
an answer for -- which is what makes the difference between a rule people
suppress and a rule people follow.

It is the shelling-out counterpart of
L<Perl::Critic::Policy::PreferredModules>, and deliberately the same shape: an
INI file of sections and C<prefer>/C<reason> pairs, so one convention covers
both halves of "we already decided this".

Nothing is configured by default.  A distribution with no
F<.preferred_binaries.ini> gets no violations, because the policy has no
opinion of its own about which binaries are worth replacing -- only about
recording the ones you have decided.

=head2 What it looks at

Anywhere a command reaches a shell or an C<exec>:

=over 4

=item * C<system> and C<exec> as function calls, in list or string form.  Not
as a method name -- C<< $obj->system(...) >> -- and not as a hash key.

=item * backticks and C<qx//>.

=item * a piped C<open>, either C<< '-|' >> or C<< '|-' >>, in two- or
three-argument form.

=item * runners, B<by name>: C<run3>, C<run>, C<capture>, C<capturex>, C<runx>
and C<systemx>, and any more named in L</runners>.  Called bare, fully
qualified (C<IPC::Run3::run3>, C<IPC::Run::run>, C<IPC::Cmd::run>,
C<IPC::System::Simple::capturex>) or as a method.
The command is the first argument -- an arrayref, as IPC::Run3 and IPC::Run
take it, or a list -- or the value of a named C<< command => >>, as IPC::Cmd
takes it, wherever it falls among the other named arguments.  An arrayref of
numbers in front of the command, which is how IPC::System::Simple takes the exit
values it allows, is passed over.  A runner name used as a hash key is not a
call and is not read as one.

=back

L<Capture::Tiny> is not on that list.  What it captures is a block of perl, not
a command, and any shell-out inside the block is one of the above and is
reported as that.  Its C<capture> shares a name with IPC::System::Simple's,
but a block holds no command this can read, so it has nothing to say about one.

In each case it takes the first word of the command, drops any directory in
front of it, and looks that up.  So C<< /usr/bin/ssh-keygen >> and
C<< ssh-keygen >> are the same binary, and C<< $ENV{SSH_KEYGEN} >> is not one
it can see -- a name computed at runtime is a name this cannot know, and it
says nothing rather than guessing.

=head2 Commands on other machines

Runners are matched by name, methods included, because a runner is usually
wrapped in a method of the same name and this cannot see what a method does.
That cuts one way it is worth knowing about: a method called C<run> or
C<capture> that runs its command on I<another> machine -- over ssh, say -- is
read as a local runner, and gets advice that makes no sense for it.  An
in-process module cannot stand in for a program running somewhere else.

That is not something this policy should be concerned with, and the answer is
in the method's name rather than in a C<## no critic> at every call: name it
for what it does and keep it off the list above -- C<run_cmd>, C<run_there>,
anything that is not on it.  A local runner called something else is invisible
until it is named in L</runners>, which is the same rule seen from the other
side: the name is the only thing this reads.

=head2 Matching a flag as well as a binary

A section name may carry arguments: C<< [ssh-keygen -y] >> matches only an
invocation whose first two words are C<ssh-keygen> and C<-y>.  The longest
matching section wins, so a bare C<< [ssh-keygen] >> can name the general
answer while C<< [ssh-keygen -y] >> names the one for reading a public key
back.

Only leading words count, and only literal ones.  C<< [ssh-keygen -y] >> does
not match C<< ssh-keygen -q -y >>, because working out whether two argument
lists mean the same thing is a job for something that understands the binary.

=head1 CONFIGURATION

In F<.perlcriticrc>:

    [PreferredBinaries]
    config  = ~/.preferred_binaries.ini
    runners = run_local

In F<.preferred_binaries.ini>:

    [ssh-keygen]
    prefer = Provisioner::Utils::write_ssh_keypair
    reason = "In-process: no quoting to get wrong, no temp file, and errors you can catch"

    [ssh-keygen -y]
    prefer = Provisioner::Utils::ssh_pubkey_from_private
    reason = "Derives the public half with CryptX"

    [wget]
    reason = "Nothing here should be fetching anything with this"

    [curl]
    prefer = HTTP::Tiny
    reason = "One HTTP client, and one place redirects and timeouts are decided"

    [dig]
    prefer = Net::DNS
    reason = "Parsing dig output is parsing a UI"

=head2 config

Path to the INI file.  C<~> is expanded.  Defaults to
F<.preferred_binaries.ini> in the current directory.

Sections are binary names, optionally with leading arguments.  Each takes:

=over 4

=item * C<prefer> -- what to use instead.  A module name, or a fully qualified
sub, or a method call written however your readers will recognise it.  Printed
verbatim.

=item * C<reason> -- why, in a few words.  Printed after it.

=item * C<severity> -- 1 to 5 for this entry alone.

=back

B<A section with no C<prefer> is a ban rather than a recommendation>, and is
reported as one: "Shelling out to 'wget' is not recommended".  That is how
L<Perl::Critic::Policy::PreferredModules> reads a section with no C<prefer>,
and it is worth knowing because consecutive sections look like they share the
entry below them and do not:

    [wget]
    [curl]
    prefer = HTTP::Tiny

names one ban and one recommendation, not two recommendations.  Config::INI
carries nothing forward, so each section needs its own C<prefer> if that is
what it means.

=head2 runners

More subs to read as runners, separated by whitespace -- a project's own
wrapper around C<system>, say.  Each is read the way the defaults are: by name,
called bare, fully qualified or as a method, with the command as its first
argument or its named C<< command => >>.

These are B<added to> the defaults -- C<run3>, C<run>, C<capture>,
C<capturex>, C<runx> and C<systemx> -- and never replace them, so there is no
way to take one of those off the list.

A package in front of a name is dropped: C<My::Util::run_local> is read as
C<run_local>, because that is all that is read of a call to it.  So it matches
C<Other::run_local> and C<< $obj->run_local >> as well.

=for Pod::Coverage supported_parameters

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/Troglodyne-Internet-Widgets/perl-critic-policy-preferredbinaries/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
