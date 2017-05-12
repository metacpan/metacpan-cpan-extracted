# ABSTRACT: Very quick and simple and unobtrusive option parser
package Opt::Imistic;
use strict;
use warnings;

our $VERSION = 0.05;

package Opt::Imistic::Option {
    use overload
        '""' => sub { $_[0]->[-1] },
        'bool' => sub { 1 }
}

my $putback = 0;
my %hints;

sub import {
    my $package = shift;

    {
        no warnings qw(uninitialized numeric);
        if (@_ and int $_[0] eq $_[0]) {
            $putback = shift;
        }
    }

    %hints = @_;

    if ($putback and @ARGV < $putback) {
        _not_enough_args();
    }

    # we alter @ARGV on purpose.
    while (my $arg = shift @ARGV) {
        last if $arg eq '--';

        if (substr($arg, 0, 2) eq '--') {
            # Double dash (Mario Kart) - long opt!
            substr $arg, 0, 2, '';

            my $val;

            if (index($arg, '=') > -1) {
                ($arg, $val) = split /=/, $arg;
                $val = [ split /,/, $val ] if $val =~ /,/;
            }
            else {
                $val = _can_has_value();
            }

            if (exists $hints{needs_val}{$arg} || exists $hints{demand}{$arg}) {
				my $die_message = "%s: value required but none given\n";
				$die_message .= "\n" . $hints{usage} if exists $hints{usage};

				die sprintf $die_message, $arg;
			}

            _store($arg, $val);
        }
        elsif (substr($arg, 0, 1) eq '-') {
            # single-letter opts
            substr $arg, 0, 1, '';
            my @opts = split //, $arg;

            if (defined(my $val = _can_has_value())) {
                _store(pop @opts, $val);
            }
            elsif (exists $hints{needs_val}{$arg} || exists $hints{demand}{$arg}) {
				my $die_message = "%s: value required but none given\n";
				$die_message .= "\n" . $hints{usage} if exists $hints{usage};

				die sprintf $die_message, $arg;
			}

            _store($_) for @opts;
        }
        else {
            # Put it back if options have ended.
            unshift @ARGV, $arg;
            last;
        }
    }

    for my $o ( keys %ARGV ) {
        # All args are arrayrefs now. This implements tm604's suggestion that we assume
        # it's a countable option if it appears several times, but never with a value.
        @{$ARGV{$o}} = scalar @{ $ARGV{$o} } unless grep defined, @{ $ARGV{$o} };
    }

    _store('-', $_) for @ARGV;

    if (exists $hints{demand}) {
        my $die_message = "Missing option: %s\n";
        $die_message .= "\n" . $hints{usage} if exists $hints{usage};

        for (keys %{ $hints{demand} }) {
            die sprintf($die_message, $_) unless exists $ARGV{$_};
        }
    }
}

# Stores repeated options in an array.
sub _store {
    my ($arg, $val) = @_;

    # tm604 suggested that, to accommodate an occurence such as:
    #   script --opt --opt --opt=foo --opt=123
    # we create opt => [ undef, undef, 'foo', '123' ].
    # Then we can collapse undef-only arrayrefs into counts later. So we don't
    # care if the val is undef. yay!

    $ARGV{$arg} //= bless [], "Opt::Imistic::Option";
    push @{ $ARGV{$arg} }, $val;
}

# Checks to see whether the next @ARGV is a value and returns it if so.
# shifts @ARGV so we skip it in the outer while loop. This is naughty but
# shut up :(
sub _can_has_value {
    my $val = $ARGV[0];

    return if not defined $val;

    if (index($val, '-') == 0 and $val ne '-') {
        # starts with - but isn't - means option. (Includes --)
        return;
    }

    if ($putback == @ARGV) {
        # next thing is not an option; we keep this many.
        return;
    }

    if ($putback > @ARGV) {
        # next thing is not an option; not enough things left.
        _not_enough_args();
    }

    # Next thing is an option and there are *more than* $putback args - we shift.
    return shift @ARGV;
}

# We couldn't satisfy $putback
sub _not_enough_args {
    my $die = "Expected $putback arguments; " . @ARGV . " given\n";

    if ($hints{usage}) {
        $die .= "\n" . $hints{usage};
    }

    die $die;
}

1;

__END__

=head1 NAME

Opt::Imistic - Optimistic option parsing

=head1 SYNOPSIS

    use Opt::Imistic;
    die if $ARGV{exit};

=head1

=head1 DESCRIPTION

Most option parsers end up doing the same thing but you have to write a whole
spec to do it. This one just gets all the options and then gets out of your way.

For the most part, your command-line options will probably be one of two things:
a toggle (or maybe a counter), or a key/value pair. Opt::Imistic assumes this
and parses your options. If you need more control over it, Opt::Imistic is not
for you and you might want to try a module such as L<Getopt::Long>. That being
said, see the L<CONFIGURATION> section for ways to configure Opt::Imistic.

The hash C<%ARGV> contains your arguments. The argument name is provided as the
key and the value is provided as the value. If you use the same argument
multiple times and sometimes without a value then that instance of the option
will be represented as undef. If you provide the option multiple times and none
has a value then your value is the count of the number of times the option
appeared.

All arguments in C<%ARGV> are now represented as array refs, blessed into a
package that stringifies them to the last instance of that argument and
boolifies to true. That means that you can always do

    @{ $ARGV{option_name} }

or

    $ARGV{option_name} =~ /cats/

or

    if ($ARGV{option_name})

without having to test what $ARGV{option_name} actually is.

This basically means that the way you use the option determines what it should
have been:

=over

=item Using it as an array ref means you expected zero or more values from it.

=item Using it as a string or number means you expected a single value out of
it.

=item Testing it means you only cared whether it was present or not.

=back

To follow convention, when you try to use an argument as a string, the end of
the internal arrayref is returned: this implements the common behaviour that the
I<last> option of the same name is honoured.

=head2 Options and arguments

Long options start with C<-->. Short options are single letters and start with
C<->. Multiple short options can be grouped without repeating the C<->, in the
familiar C<perl -lne> fashion.

For short options the value I<must> be separated from the option letter; but for
long options, both whitespace and a single C<=> are considered delimiters. This
is because Opt::Imistic doesn't take an option spec, and hence cannot
distinguish between single-letter options with values and several single-letter
options.

Repeated options with no values are counted. Repeated options with values are
concatenated in an array ref. Note that all options can be treated as array
refs.

The options are considered to stop on the first argument that does not start
with a C<-> and cannot be construed as the value to an option. You can use the
standard C<--> to force the end of option parsing. Everything after the last
option goes under the special key C<->, because that can never be an option
name. These are also left on @ARGV so that C<< <> >> still works.

Examples help

    script.pl -abcde

    a => 1
    b => 1
    c => 1
    d => 1
    e => 1

That one's obvious.

    script.pl -a foo.pl

    a => ['foo.pl']

    @ARGV = ()

Z<>

    script.pl -a -- foo.pl

    a => [ 1 ]
    - => [ 'foo.pl' ]

    @ARGV = ('foo.pl')

Z<>

    script.pl -foo

    f => [ 1 ]
    o => [ 2 ]

Z<>

    script.pl -foo bar

    f => [ 1 ]
    o => [undef, 'bar']

Z<>

    script.pl --foo bar --foo=bar

    foo => ['bar', 'bar']

Z<>

=head1 CONFIGURATION

Opt::Imistic can be crudely configured to deal with certain options specially.
Configuration is done by means of the import list, meaning all requirements
will have been satisfied before the program even finishes compiling.

=head2 Putback

If the first item in your import list is an integer, this will be used as the
putback value. Observe that this will be C<shift>ed from the C<import> list,
and the rest of the list will be used to construct a hash.

Putback refers to the act of putting arguments back onto C<@ARGV>. This allows
your script to be called with non-value options which are followed by actual
arguments:

    $ push.pl -v master

    # %ARGV
    {
      'v' => bless( [
                      'master'
                    ], 'Opt::Imistic::Option' )
    };


If C<push.pl> is an Opt::Imistic script, C<$ARGV{v}> would have the value
C<master>, and C<@ARGV> would not have anything on it at all.

To fix this, you tell Opt::Imistic that you need at least one argument:

    use Opt::Imistic (1);

Now, C<@ARGV> will always have at least one (non-option) entry. If this cannot
be satisfied, the script bails.

    $ push.pl -v master

    # %ARGV:
    {
      '-' => bless( [
                      'master'
                    ], 'Opt::Imistic::Option' ),
      'v' => [
               1,
             ]
    };

Note that C<$ARGV{'-'}> is a copy of the remaining C<@ARGV>.

The putback argument will be observed I<before> the C<demand> or C<needs_val>
options. This means that if you provide an option that needs a value, and not
enough arguments to the script itself, the script arguments will be checked
before the option's argument:

    use Opt::Imistic (1, needs_val => {remote => 1});

    $ push.pl --remote master
    remote: value required but none given

In this example, C<master> was used as the putback argument, leaving
C<--remote> with no value.

    use Opt::Imistic (2, needs_val => {remote => 1});

    $ push.pl --remote master
    Expected 2 arguments; 1 given

This is a bit clearer: putback wanted 2 arguments, so the script bailed before
C<--remote> even got a chance to look for arguments.

=head2 Required options

Sometimes your option is required. This is the case when it needs a value. It
doesn't make sense for an option to be required with no value, unless you
really want to make sure someone means it before they run your script. In that
case, you can check C<%ARGV> yourself.

Opt::Imistic will bail if any of the keys of the C<demand> hashref are missing.
It will also bail if the option is given without a value.

C<demand> is provided as a hashref simply to make it easier to look up items.

    use Opt::Imistic (demand => { branch => 1 });

This invocation means that C<--branch> must be given and have a value:

    $ push.pl
    Missing option: branch
    BEGIN failed--compilation aborted at push.pl line 4

    $ push.pl --branch
    branch: value required but none given
    BEGIN failed--compilation aborted at push.pl line 4.

=head2 Required values

Some options are, well, optional, but don't make sense without a value. For
this, use the needs_val hashref:

    use Opt::Imistic (needs_val => { branch => 1 });

Now if C<--branch> is given it must have a value, but if not, that's also fine:

    $ push.pl

    $ push.pl --branch
    branch: value required but none given
    BEGIN failed--compilation aborted at push.pl line 4.

=head2 Usage

If you provide a C<usage> key in the hash-like options list, it will be printed
with anything that causes Opt::Imistic to die.

    use Opt::Imistic (2,
        needs_val => { remote => 1 },
        usage => "Usage: push.pl [--remote=<remote>] branch\n"
    );

    Expected 2 arguments; 1 given

    Usage: push.pl [--remote=<remote>] branch

=head1 BUGS AND TODOS

It should be noted that Opt::Imistic does not observe a difference between
C<-f> and C<--f>.

Counted options lose their blessing as Opt::Imistic::Option, which may
sometimes break code that didn't expect it to be a counted option.

Usage messages cause the die line to be reported if they don't have their own newline.

Please report undesirable behaviour, but note the TODO list first:

=over

=item Implement hints to the parser to allow single options not to require
delimiting from their values

=item Implement further hints to alias options.

=item Allow usage to be a coderef.

=back

=head1 AUTHOR

Altreus <altreus@perl.org>
