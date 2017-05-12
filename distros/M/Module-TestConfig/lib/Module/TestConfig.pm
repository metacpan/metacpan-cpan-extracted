# -*- perl -*-
#
# Module::TestConfig - asks questions and autowrite a module
#
# $Id: TestConfig.pm,v 1.33 2003/08/29 18:40:16 jkeroes Exp $

package Module::TestConfig;

require 5.008;
use strict;
use Carp;
use Fcntl;
use File::Basename	qw/dirname/;
use Params::Validate;
use Config::Auto;
use Module::TestConfig::Question;

# Dynamically loaded modules
#   Data::Dumper;
#   Text::FormatTable;
#   Term::ReadKey;
#   File::Path

our $VERSION = '0.05';

#------------------------------------------------------------
# Methods
#------------------------------------------------------------

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self = bless {}, $class;
    return $self->init(
	verbose   => 1,
	defaults  => 'defaults.config',
	file      => 'MyConfig.pm',
	package   => 'MyConfig',
	order     => [ qw/defaults/ ],
	questions => [ ],
	_defaults => { },
        qi       => 0,
        @_,
    );
}

sub init {
    my ( $self, %args )  = @_;

    while ( my ( $method, $args ) = each %args ) {
	if ( $self->can( $method ) ) {
	    $self->$method( $args );
	} else {
	    croak "Can't handle arg: '$method'. Aborting";
	}
    }

    $self->load_defaults;

    Params::Validate::validation_options(
	on_fail => sub { $_[0] =~ s/to.*did //; die "Your answer didn't validate.\n$_[0]" },
    );

    return $self;
}

sub load_defaults {
    my $self = shift;
    $self->{_defaults} = Config::Auto::parse( $self->{defaults} )
	if -r $self->{defaults};
}

sub verbose {
    my $self = shift;
    $self->{verbose} = shift if @_;
    $self->{verbose};
}

sub debug {
    my $self = shift;
    $self->{debug} = shift if @_;
    $self->{debug};
}

sub file {
    my $self = shift;
    $self->{file} = shift if @_;
    $self->{file};
}

sub package {
    my $self = shift;
    $self->{package} = shift if @_;
    $self->{package};
}

# The filename of the defaults file.
sub defaults {
    my $self = shift;
    $self->{defaults} = shift if @_;
    $self->{defaults};
}

# The defaults hash
sub _defaults {
    my $self = shift;
    $self->{_defaults} = shift if @_;
    $self->{_defaults};
}

sub order {
    my $self = shift;

    if ( @_ ) {
	my @order = ref $_[0] eq "ARRAY" ? @{ $_[0] } : @_;
	for my $order ( @order ) {
	    croak "Bad arg given to order(): '$order'"
		unless grep /^$order$/, qw/defaults env/;
	}
	$self->{order} = [ @order ];
    }

    return wantarray ? @{ $self->{order} } : $self->{order};
}

sub questions {
    my $self = shift;

    if ( @_ > 1 ) {
	$self->{questions}
	    = [ map { Module::TestConfig::Question->new( $_ ) } @_ ];
    } elsif ( @_ == 1 && ref $_[0] eq "ARRAY" ) {
	$self->{questions}
	    = [ map { Module::TestConfig::Question->new( $_ ) } @{ $_[0] } ];
    } elsif ( @_ ) {
	croak "questions() got bad args. Needs a list or arrayref.";
    }

    return wantarray ? @{ $self->{questions} } : $self->{questions};
}

sub answers {
    my $self = shift;
    $self->{answers} = shift if @_;
    return wantarray ? %{ $self->{answers} } : $self->{answers};
}

sub answer {
    my $self = shift;
    return $self->{answers}{+shift};
}

sub ask {
    my $self = shift;

    do {

	my $i	 = $self->{qi};
	my $q	 = $self->{questions}[$i];
	my $name = $q->name;

	# Skip the question?
	if ( $q->skip ) {
	    if ( ref $q->skip eq "CODE" ) {
		next if $q->skip->( $self );
	    } elsif ( not ref $q->skip ) {
		next if $q->skip;
	    } else {
		croak "Don't know how to handle question #$i\'s skip block";
	    }
	}

	my $attempts = 0;

	ASK: {
	    my @args = ( $name => $self->prompt( $q ) );

	    # Valid answer?
	    if ( $q->validate ) {
		croak "validate must be a hashref. Aborting"
		    unless ref $q->validate eq "HASH";

		eval { validate( @args, { $name => $q->validate } ) };

		if ( $@ ) {
		    warn $@;

		    if ( ++$attempts > 10 ) {
			warn "Let's just skip that question, shall we?\n\n";
			last ASK;
		    } else {
			warn "Please try again. [Attempt $attempts]\n\n";
			redo ASK;
		    }
		}
	    }

	    $self->{answers}{$name} = $args[-1];
	}

    } while ( $self->{qi}++ < scalar @{$self->{questions}} - 1 );

    return $self;
}

sub get_default {
    my ($self, $i) = @_;

    $i ||= $self->{qi};
    my $q = $self->{questions}[$i];
    my $default = $q->default;
    my $name    = $q->name
	or croak "No name defined for question \#$i.";

    for ( $self->order ) {
	if ( /^env/o ) {
	    return $ENV{"\U$name"} if defined $ENV{"\U$name"};
	    return $ENV{"\L$name"} if defined $ENV{"\L$name"};
	}

	return $self->{_defaults}{$name}
	    if /^defaults/ && $self->{_defaults}{$name};
    }

    # This will be undef unless set via answers()
    # or new( answers => {...} ).
    return $self->{answers}{$name} || $default;
}

sub save {
    my ($self) = @_;

    my $text = $self->package_text
	or croak "No text to save. Aborting.";

    my $dir = dirname( $self->{file} );
    unless ( -d $dir ) {
	require File::Path;
	File::Path::mkpath( [ $dir ], $self->{verbose})
	    or croak "Can't make path $dir: $!";
    }

    sysopen F, $self->{file}, O_CREAT | O_WRONLY | O_TRUNC, 0600
	or croak "Can't open '$self->{file}' for write: $!";
    print F  $text;
    close F or carp ("Can't close '$self->{file}'. $!"), return;

    print "Module::TestConfig saved $self->{file} with these settings:\n"
	. $self->report if $self->{verbose};
}

# Error in v.04:
#
#   Failed test 'save_defaults()'
#   at t/40_defaults.t line 40.
# found warning: Filehandle STDIN reopened as F only for output at /home/sand/.cpan/build/Module-TestConfig-0.04-pvLCvJ/blib/lib/Module/TestConfig.pm line 263.
# found carped warning: Skipping bad key with a separator in it: 'bro:ken' at t/40_defaults.t line 39
# expected to find carped warning: /^Skipping bad key/
# Looks like you failed 1 test of 28.
#
# We're going to ignore that STDIN warning here - ignoring it in t/40_defaults.t does nothing.

sub save_defaults {
    my $self = shift;
    my %args = ( file => $self->{defaults},
		 sep  => ':',
		 @_,
	       );

    # doesn't matter if this fails:
    rename $args{file}, "$args{file}.bak" if -e $args{file};

	no warnings "io";

    open  F, "> $args{file}"
        or carp ("Unable to write to $args{file}: $!"), return;

	use warnings "io";

    print F "# This defaults file was autogenerated by Module::TestConfig for $self->{package}\n\n";

    while ( my ($k, $v) = each %{ $self->{answers} } ) {
	carp ("Skipping bad key with a separator in it: '$k'"), next
	    if $k =~ /$args{sep}/;
	print F "$k$args{sep}$v\n";
    }

    close F or return;

    return 1;
}

# Try to report using the best metho
sub report {
    my $self = shift;

    eval { require Text::FormatTable };

    return $@
	? $self->report_plain
	: $self->report_pretty

}

# Report using Test::FormatTable
sub report_pretty {
    my $self = shift;

    croak "Can't use report_pretty() unless Text::AutoFormat is loaded."
	unless UNIVERSAL::can('Text::FormatTable', 'new');

    my $screen_width = eval { require Term::ReadKey; (Term::ReadKey::GetTerminalSize())[0] } || 79;
    my $table	     = Text::FormatTable->new( '| r | l |' );

    $table->rule('=');
    $table->head('Name', 'Value');
    $table->rule('=');

    for my $q ( @{ $self->{questions} } ) {
	if ( $q->noecho ) {
	    $table->row( $q->name, '*****' );
	} else {
	    $table->row( $q->name, $self->answer( $q->name ) );
	}
    }

    $table->rule('-');

    my $report = $table->render($screen_width);
    $report =~ s/^/\t/mg; # indent

    return $report;
}

# Report with plain text.
sub report_plain {
    my $self = shift;

    my $report = '';

    for my $q ( @{ $self->{questions} } ) {
	if ( $q->noecho ) {
	    $report .= $q->name . ": *****\n";
	} else {
	    $report .= $q->name . ": "
		    . $self->answer( $q->name ) . "\n";
	}
    }

    $report =~ s/^/\t/mg; # indent

    return $report;
}

sub package_text {
    my $self = shift;

    local $/ = undef;
    local $_ = <DATA>;

    my $pkg  = $self->{package};

    require Data::Dumper;
    $Data::Dumper::Terse = 2;
    my $answers = Data::Dumper->Dump( [$self->{answers}] );

    s/%%PACKAGE%%/$pkg/mg;
    s/%%ANSWERS%%/$answers/m;

    return $_;
}


# Based on ExtUtils::MakeMaker::prompt().
sub prompt {
    my $self  = shift;
    my $q     = shift || $self->{questions}[$self->{qi}];

    local $| = 1;

    croak "prompt() called incorrectly"
	unless defined $q->msg && defined $q->name;

    my $def      = $self->get_default;
    my $dispdef	 = defined $def ? " [$def] " : " ";
    $def	 = defined $def ? $def      : "";

    print $q->msg . $dispdef;

    my $ans = '';
    my $ISA_TTY = -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT)); # Pipe?

    if ( $ISA_TTY ) {
	if ( $Term::ReadKey::VERSION && $q->noecho ) {
	    ReadMode( 'noecho' );
	    chomp( $ans = ReadLine(0) );
	    ReadMode( 'normal' );
	    print "\n";
	} else {
	    chomp( $ans = <STDIN> );
	}
    } else {
        print "$def\n";
    }

    return $ans ne '' ? $ans : $def;
}

# Question index
sub qi {
    my $self = shift;
    $self->{qi} = shift if @_;
    $self->{qi};
}

#------------------------------------------------------------
# Docs
#------------------------------------------------------------

=head1 NAME

Module::TestConfig - Interactively prompt user to generate a config module

=head1 SYNOPSIS

  use Module::TestConfig;

  Module::TestConfig->new(
	verbose   => 1,
	defaults  => 'defaults.config',
	file      => 'MyConfig.pm',
	package   => 'MyConfig',
	order     => [ qw/defaults env/ ],
	questions => [
	  [ 'Would you like tea?' => 'tea', 'y' ],
	  [ 'Crumpets?' => 'crumpets', 'y' ],
	]
  )->ask->save;

# and in another module or test file:

  use MyConfig;

  my $config = MyConfig->new;
  print $config->tea eq 'y'
    ? "We're having tea today; splendid!"
    : "No tea, I'm afraid. P'raps tomorrow.";

  print $config->crumpets eq 'y'
    ? "Crumpets; lovely!"
    : "Alas, we have no crumpets today";


=head1 DESCRIPTION

This module prompts a user for info and writes a module for later use.
You can use it during the module build process (e.g. perl Makefile.PL)
to share info among your test files. You can also use it to install
that module into your site_perl.

Module::TestConfig writes an object-oriented file. You specify
the file's location as well as the package name. When you use()
the file, each of the questions' names will become an object method.

For example, if you asked the questions:

  Module::TestConfig->new(
	file      => 't/MyConfig.pm',
	package   => 'MyConfig',
	questions => [
	               [ 'Can you feel that bump?', 'feel',    'n' ],
	               [ 'Would you like another?', 'another', 'y' ],
  		       { msg     => 'How many fingers am I holding up?',
		         name    => 'fingers',
		         default => 11,
		       },
		     ],
  )->ask->save;

You'd see something like this:

  Can you feel that bump? [n] y
  Would you like another? [y] n
  How many fingers am I holding up? [11]
  Module::TestConfig saved t/MyConfig.pm with these settings:
  	===================
  	|    Name | Value |
  	===================
  	|    feel | y     |
  	| another | n     |
  	| fingers | 11    |
  	+---------+-------+

...and the file t/MyConfig.pm was written. To use it, add this to
another file:

  use MyConfig;

  my $config = MyConfig->new;
  print $config->fingers;  # prints 11
  print $config->feel;     # prints 'y'
  print $config->another;  # prints 'n'

=head1 PUBLIC METHODS

=over 2

=item new()

Args and defaults:

  verbose   => 1,
  defaults  => 'defaults.config',
  file      => 'MyConfig.pm',
  package   => 'MyConfig',
  order     => [ 'defaults' ],
  questions => [ ... ],

Returns: a new Module::TestConfig object.

=item questions()

Set up the questions that we'll ask of the user. This is a list (or
array) of questions. Each question can be in one of two forms, the
array form or the hash form. See L<Module::TestConfig::Question> for
more about the question's arguments.

Args:
  an array of question hashes (or question arrays)
  a  list  of question hashes (or question arrays)

e.g. (to keep it simple, I'll only give an example of a hash-style
question):

  [
    { question => "Question to ask:",
      name     => "foo",
      default  => 42,
      noecho   => 0,
      skip     => sub { shift->answer('bar') }, # skip if bar is true
      validate => { regex => /^\d+$/ }, # answer must be all numbers
    },
    ...
  ]

Returns:
  a  list of questions in list context
  an arrayref of questions in scalar context.

Here's an overview of the hash-style arguments to set up a question.
See L<Module::TestConfig::Question> for more details.

Args:

=over 4

=item question or msg:

A string like "Have you seen my eggplant?" or "Kittens:". They look
best when they end with a ':' or a '?'.

=item name:

A simple mnemonic used for looking up values later. Since it will turn
into a method name in the future, it ought to match /\w+/.

=item default or def:

optional. a default answer.

=item noecho:

optional. 1 or 0. Do we print the user's answer while they are typing?
This is useful when asking for for passwords.

=item skip:

optional. Accepts either a coderef or a scalar. The Module::TestConfig
object will be passed to the coderef as its first and only
argument. Use it to look up answer()s. If the coderef returns true or
the scalar is true, the current question will be skipped.

=item validate:

optional. A hashref suitable for Params::Validate::validate_pos().
See L<Params::Validate>. The question will loop over and over until
the user types in a correct answer - or at least one that validates.
After the user tries and fails 10 times, Module::TestConfig will give
up and skip the question.

e.g.

  Module::TestConfig->new(
	questions => [ { question  => 'Choose any integer: ',
			 name      => 'num',
			 default   => 0,
		         validate  => { regex => qr/^\d+$/ },
		       },
		       { question  => 'Pick an int between 1 and 10: ',
			 name      => 'guess',
			 default   => 5,
		         validate  => {
 			     callbacks => {
				 '1 <= guess <= 10',
				 sub { my $n = shift;
				       return unless $n =~ /^\d+$/;
				       return if $n < 1 || $n > 10;
				       return 1;
				     },
			     }
			 }
		       },
		     ]
  )->ask->save;

would behave like this when run:

  Pick a number, any integer:  [0] peach
  Your answer didn't validate.
  The 'num' parameter did not pass regex check
  Please try again. [Attempt 1]

  Pick a number, any integer:  [0] plum
  Your answer didn't validate.
  The 'num' parameter did not pass regex check
  Please try again. [Attempt 2]

  Pick a number, any integer:  [0] 5
  Pick an integer between 1 and 10:  [5] 12
  Your answer didn't validate.
  The 'guess' parameter did not pass the '1 <= guess <= 10' callback
  Please try again. [Attempt 1]

  Pick an integer between 1 and 10:  [5] -1
  Your answer didn't validate.
  The 'guess' parameter did not pass the '1 <= guess <= 10' callback
  Please try again. [Attempt 2]

  Pick an integer between 1 and 10:  [5] 3
  Module::TestConfig saved MyConfig.pm with these settings:
        =================
        |  Name | Value |
        =================
        |   num | 5     |
        | guess | 3     |
        +-------+-------+

=back

=item ask()

Asks the user the questions.

Returns: a Module::TestConfig object.

=item save()

Writes our answers to the file. The file created will always be
0600 for security reasons. This may change in the future. See
L<"SECURITY"> for more info.

=item defaults()

A file parsed by Config::Auto which may be used as default answers to
the questions. See L<"order()">

Default: "defaults.config"

Args: A filename or path.

Returns: A filename or path.

=item save_defaults()

Writes a new defaults file. The key-value separator should be either
':' or '=' to keep it compatible with L<Config::Auto>.  See
L<"order()"> for more about defaults.

Args and defaults:

   file => $object->defaults, # 'defaults.config'
   sep  => ':',

Returns: 1 on success, undef on failure. Any error message can be
found in $!.

=item file()

The filename that gets written during save().

Default: "MyConfig.pm"

Args: a filepath that should probably end in ".pm". e.g. "t/MyConfig.pm"

Returns: the filename or path.

=item package()

The file's package name written during save().

Default: "MyConfig"

Args: a package namespace. e.g. "Foo::Bar::Baz"

Returns: the set package.

=item order()

Default: [ 'defaults' ]

Args: [ qw/defaults env/ ]
      [ qw/env defaults/ ]
      [ qw/defaults/ ]
      [ qw/env/ ]
      [ ] # Don't preload defaults from file or env

Where do we look up defaults for the questions? They can come from
either a file, the environment or perhaps come combination of both.

=over 4

=item defaults:

a file read by Config::Auto that must parse to a hash of question
names and values.

=item env:

environment variables in either upper or lowercase.

=back

The following will also be checked, in order:

=over 4

=item answers:

Any answers already hard-set via answers().

=item a question's default:

A default supplied with the question.

=back

There's a security risk accepting defaults from the environment or
from a file. See L<"SECURITY">.

=item answer()

Get the current value of a question. Useful when paired with a skip
or validate.

Args: a question's name.

Returns: The current value or undef.

=item verbose()

Should the module be chatty while running? Should it print a report at
the end?

Default: 1

Args: 1 or 0

Returns: current value

=back

=head1 PROTECTED METHODS

These are documented primarily for subclassing.

=over 2

=item answers()

A user's questions get stored here. If you preset any answers before
calling ask(), they may be used as defaults. See L<"order()"> for
those rules.

Args: a hash of question names and answers

Returns: A hash in list context, a hashref in scalar context.

=item prompt()

Ask the user a question. It's your job to store the answer in
the answers().

Args: $question, $default_answer, \%options

Returns: the user's answer, a suitable default or ''.

=item get_default()

Get a question's default answer from env, file, answer() or the
question. It's printed with a prompt()ed question.

=item load_defaults()

Uses Config::Auto to parse the file specified by defaults(). Defaults
are stored in $obj-E<gt>{_defaults}.

=item package_text()

Returns the new file's text. This should take package() and
answers() into account.

=item qi()

The current question index.

Args: A number

Returns: The current number

=item report()

Returns a report of question names and values. Will be printed if the
object is in verbose mode. This calls report_pretty() or
report_plain() depending on whether Text::AutoFormat is
available. Won't print any passwords (questions called with C<noecho
=E<gt> 1> ) in plaintext.

=item report_pretty()

Prints the report like this:

        ==================
        |   Name | Value |
        ==================
        |    one | 1     |
        |    two | 2     |
        |  three | 3     |
        |  fruit | kiwi  |
        |   meat | pork  |
	| passwd | ***** |
        +--------+-------+

=item report_plain()

Prints the report like this:

	one: 1
	two: 2
	three: 3
	fruit: kiwi
	meat: pork
	passwd: *****

=back

=head1 SECURITY

The resultant file (MyConfig.pm by default) will be chmod'd to 0600
but it will remain on the system.

The default action is to load a file named 'defaults.config' and use
that for, well, defaults. If someone managed to put their own
defaults.config into your working directory, they might be able to
sneak a bad default past an unwitting user.

Using the environment as input may be a security risk - or a potential
bug - especially if your names mimic existing environment variables.

=head1 AUTHOR

Joshua Keroes E<lt>jkeroes@eli.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Joshua Keroes E<lt>jkeroes@eli.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Module::TestConfig::Question>
L<ExtUtils::MakeMaker>
L<Module::Build>

=cut

# Template for module generation follows:

__DATA__
# -*- perl -*-
#
# This module was autogenerated by Module::TestConfig

package %%PACKAGE%%;

use strict;
use Carp;
use vars '$AUTOLOAD';

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self = %%ANSWERS%%;
    return bless $self, $class;
}

sub AUTOLOAD {
    my $self = shift;

    ($AUTOLOAD) = $AUTOLOAD =~ /(\w+)$/;

    croak "No such method: $AUTOLOAD"
        unless defined $self->{$AUTOLOAD}
            || $AUTOLOAD eq "DESTROY";

    return $self->{$AUTOLOAD};
}

1;

