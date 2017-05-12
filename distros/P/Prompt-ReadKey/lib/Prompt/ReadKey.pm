#!/usr/bin/perl

package Prompt::ReadKey;
use Moose;

use Prompt::ReadKey::Util;

use Carp qw(croak);
use Term::ReadKey;
use List::Util qw(first);
use Text::Table;
use Text::Sprintf::Named;

our $VERSION = "0.04";

has default_prompt => (
	init_arg => "prompt",
	isa => "Str",
	is  => "rw",
);

has additional_options => (
	isa => "ArrayRef[HashRef]",
	is  => "rw",
	auto_deref => 1,
);

has auto_help => (
	isa => "Bool",
	is  => "rw",
	default => 1,
);

has help_headings => (
	isa => "ArrayRef[HashRef[Str]]",
	is  => "rw",
	default => sub {[
		{ name => "keys", heading => "Key" },
		{ name => "name", heading => "Name" },
		{ name => "doc",  heading => "Description" },
	]},
);

has help_header => (
	isa => "Str",
	is  => "rw",
	default => "The list of available commands is:",
);

has help_footer => (
	isa => "Str",
	is  => "rw",
);

has help_keys => (
	isa => "ArrayRef[Str]",
	is  => "rw",
	auto_deref => 1,
	default => sub { [qw(h ?)] },
);

has default_options => (
	init_arg => "options",
	isa => "ArrayRef[HashRef]",
	is  => "rw",
	auto_deref => 1,
);

has allow_duplicate_names => (
	isa => "Bool",
	is  => "rw",
	default => 0,
);

has readkey_mode => (
	isa => "Int",
	is  => "rw",
	default => 0, # normal getc, change to get timed
);

has readmode => (
	isa => "Int",
	is  => "rw",
	default => 3, # cbreak mode
);

has echo_key => (
	isa => "Bool",
	is  => "rw",
	default => 1,
);

has auto_newline => (
	isa => "Bool",
	is  => "rw",
	default => 1,
);

has return_option => (
	isa => "Bool",
	is  => "rw",
	default => 0,
);

has return_name => (
	isa => "Bool",
	is  => "rw",
	default => 1,
);

has case_insensitive => (
	isa => "Bool",
	is  => "rw",
	default => 1,
);

has repeat_until_valid => (
	isa => "Bool",
	is  => "rw",
	default => 1,
);

has prompt_format => (
	isa => "Str",
	is  => "rw",
	default => '%(prompt)s [%(option_keys)s] ',
);

sub prompt {
	my ( $self, %args ) = @_;

	my @options = $self->prepare_options(%args);

	$self->do_prompt(
		%args,
		options      => \@options,
		prompt       => $self->format_prompt( %args, options => \@options, option_count => scalar(@options) ),
	);
}

sub do_prompt {
	my ( $self, %args ) = @_;

	my $repeat = $self->_get_arg_or_default( repeat_until_valid => %args );

	prompt: {
		if ( my $opt = $self->prompt_once(%args) ) {

			if ( $opt->{reprompt_after} ) { # help, etc
				$self->option_to_return_value(%args, option => $opt); # trigger callback
				redo prompt;
			}

			return $self->option_to_return_value(%args, option => $opt);
		}

		redo prompt if $repeat;
	}

	return;
}

sub prompt_once {
	my ( $self, %args ) = @_;

	$self->print_prompt(%args);
	$self->read_option(%args);
}

sub print_prompt {
	my ( $self, %args ) = @_;
	$self->print($self->_get_arg_or_default( prompt => %args ));
}

sub print {
	my ( $self, @args ) = @_;
	local $| = 1;
	print @args;
}

sub prepare_options {
	my ( $self, %args ) = @_;

	$self->filter_options(
		%args,
		options => [
			$self->sort_options(
				%args,
				options => [
					$self->process_options(
						%args,
						options => [ $self->gather_options(%args) ]
					),
				],
			),
		],
	);
}

sub process_options {
	my ( $self, @args ) = @_;
	map { $self->process_option( @args, option => $_ ) } $self->_get_arg_or_default(options => @args);
}

sub process_option {
	my ( $self, %args ) = @_;
	my $opt = $args{option};

	my @keys = $opt->{key} ? delete($opt->{key}) : @{ $opt->{keys} || [] };

	unless ( @keys ) {
		croak "either 'key', 'keys', or 'name' is a required option" unless $opt->{name};
		@keys = ( substr $opt->{name}, 0, 1 );
	}

	$opt->{keys} = \@keys;

	return $opt;
}

sub gather_options {
	my ( $self, %args ) = @_;

	return (
		# explicit or default options
		$self->_get_arg_or_default(options => %args),

		# static additional options from the object *and* options passed on the arg list
		$self->additional_options(),
		_get_arg(additional_options => %args),

		# the help command
		$self->create_help_option(%args),
	);
}

sub get_help_keys {
	my ( $self, @args ) = @_;

	if ( $self->_get_arg_or_default( auto_help => @args ) ) {
		return $self->_get_arg_or_default( help_keys => @args );
	}
}

sub create_help_option {
	my ( $self, @args ) = @_;

	if ( my @keys = $self->get_help_keys(@args) ) {
		return {
			reprompt_after => 1,
			doc            => "List available commands",
			name           => "help",
			keys           => \@keys,
			callback       => "display_help",
			is_help        => 1,
			special_option => 1,
		}
	}

	return;
}

sub display_help {
	my ( $self, @args ) = @_;

	my @options = $self->_get_arg_or_default(options => @args);

	my $help = join("\n\n", grep { defined }
		$self->_get_arg_or_default(help_header => @args),
		$self->tabulate_help_text( @args, help_table => [ map { $self->option_to_help_text(@args, option => $_) } @options ] ),
		$self->_get_arg_or_default(help_footer => @args),
	);

	$self->print("\n$help\n\n");
}

sub tabulate_help_text {
	my ( $self, %args ) = @_;

	my @headings = $self->_get_arg_or_default( help_headings => %args );

	my $table = Text::Table->new( map { $_->{heading}, \"   " } @headings );

	my @rows = _get_arg( help_table => %args );

	$table->load( map {
		my $row = $_;
		[ map { $row->{ $_->{name} } } @headings ];
	} @rows );

	$table->body_rule("   ");

	return $table;
}

sub option_to_help_text {
	my ( $self, %args ) = @_;
	my $opt = $args{option};

	return {
		keys => join(", ", grep { /^[[:graph:]]+$/ } @{ $opt->{keys} } ),
		name => $opt->{name} || "",
		doc => $opt->{doc}  || "",
	};
}

sub sort_options {
	my ( $self, @args ) = @_;
	$self->_get_arg_or_default(options => @args);
}

sub filter_options {
	my ( $self, %args ) = @_;

	my @options = $self->_get_arg_or_default(options => %args);

	croak "No more than one default is allowed" if 1 < scalar grep { $_->{default} } @options;

	foreach my $field ( "keys", ( $self->_get_arg_or_default( allow_duplicate_names => %args ) ? "name" : () ) ) {
		my %idx;

		foreach my $option ( @options ) {
			my $value = $option->{$field};
			my @values = ref($value) ? @$value : $value;
			push @{ $idx{$_} ||= [] }, $option for grep { defined } @values;
		}

		foreach my $key ( keys %idx ) {
			delete $idx{$key} if @{ $idx{$key} } == 1;
		}

		if ( keys %idx ) {
			# FIXME this error sucks
			require Data::Dumper;
			croak "duplicate value for '$field': " . Data::Dumper::Dumper(\%idx);
		}
	}

	return @options;
}

sub prompt_string {
	my ( $self, @args ) = @_;
	if ( my $string = $self->_get_arg_or_default(prompt => @args) ) {
		return $self->format_string(
			@args,
			format => $string,
		);
	} else {
		croak "'prompt' argument is required";
	}
}

sub get_default_option {
	my ( $self, @args ) = @_;

	if ( my $default = $self->_get_arg_or_default( default_option => @args ) ) {
		return $default;
	} else {
		return first { $_->{default} } $self->_get_arg_or_default( options => @args );
	}
}

sub format_options {
	my ( $self, %args ) = @_;

	my $default_option = $self->get_default_option(%args) || {};

	my @options = grep { not $_->{special_option} } $self->_get_arg_or_default(options => %args);

	if ( $self->_get_arg_or_default( case_insensitive => %args ) ) {
		return join "", map {
			my $default = $default_option == $_;
			map { $default ? uc : lc } grep { /^[[:graph:]]+$/ } @{ $_->{keys} };
		} @options;
	} else {
		return join "", grep { /^[[:graph:]]+$/ } map { @{ $_->{keys} } } @options;
	}
}

sub format_string {
	my ( $self, %args ) = @_;
	Text::Sprintf::Named->new({ fmt => $args{format} })->format({ args => \%args })
}

sub format_prompt {
	my ( $self, @args ) = @_;

	my $format = $self->_get_arg_or_default( prompt_format => @args );


	$self->format_string(
		@args,
		format => $format,
		prompt      => $self->prompt_string(@args),
		option_keys => $self->format_options(@args),
	);
}

sub read_option {
	my ( $self, @args ) = @_;

	my @options = $self->_get_arg_or_default(options => @args);

	my %by_key = map {
		my $opt = $_;
		map { $_ => $opt } map { $self->process_char( @args, char => $_ ) } @{ $_->{keys} };
	} @options;

	my $c = $self->process_char( @args, char => $self->read_key(@args) );

	if ( defined $c ) {
		if ( exists $by_key{$c} ) {
			return $by_key{$c};
		} elsif ( $c =~ /^\s+$/ ) {
			if ( my $default = $self->get_default_option(@args) ) {
				return $default;
			}
		}
	}

	$self->invalid_choice(@args, char => $c);

	return;
}

sub invalid_choice {
	my ( $self, %args ) = @_;

	my $output;
	my $c = $args{char};

	if ( defined($c) and $c =~ /^[[:graph:]]+$/ ) {
		$output = "'$c' is not a valid choice, please select one of the options.";
	} else {
		$output = "Invalid input, please select one of the options.";
	}

	if ( my @keys = $self->get_help_keys(%args) ) {
		$output .= " Enter '$keys[0]' for help.";
	}

	$self->print("$output\n");
}

sub option_to_return_value {
	my ( $self, %args ) = @_;

	my $opt = $args{option};

	if ( $opt->{special_option} ) {
		if ( my $cb = $opt->{callback} ) {
			return $self->$cb(%args);
		} else {
			return $opt;
		}
	} else {
		return $opt if $self->_get_arg_or_default(return_option => %args);

		if ( my $cb = $opt->{callback} ) {
			return $self->$cb(%args);
		} else {
			return (
				$self->_get_arg_or_default(return_name => %args)
					? $opt->{name}
					: $opt
			);
		}
	}
}

sub read_key {
	my ( $self, %args ) = @_;

    ReadMode( $self->_get_arg_or_default( readmode => %args ) );

	my $sigint = $SIG{INT} || sub { exit 1 };

    local $SIG{INT} = sub {
		ReadMode(0);
		print "\n" if $self->_get_arg_or_default( auto_newline => %args );
		$sigint->();
	};

	my $readkey_mode = $self->_get_arg_or_default( readkey_mode => %args );

	my $c = ReadKey($readkey_mode);

	if ( $c eq chr(0x1b) ) {
		$c .= ReadKey($readkey_mode);
		$c .= ReadKey($readkey_mode);
	}

    ReadMode(0);

    die "Error reading key from user: $!" unless defined($c);

    print $c if $c =~ /^[[:graph:]]+$/ and $self->_get_arg_or_default( echo_key => %args );

    print "\n" if $c ne "\n" and $self->_get_arg_or_default( auto_newline => %args );

    return $c;
}

sub process_char {
	my ( $self, %args ) = @_;

	my $c = $args{char};

	if ( $self->_get_arg_or_default( case_insensitive => %args ) ) {
		return lc($c);
	} else {
		return $c;
	}
}

__PACKAGE__

__END__

=pod

=head1 NAME

Prompt::ReadKey - Darcs style single readkey option prompt.

=head1 SYNOPSIS

	my $p = Prompt::ReadKey->new;

	my $name = $p->prompt(
		prompt => "blah",
		options => [
			{ name => "foo" },
			{
				name => "bar",
				default => 1,
				doc => "This is the bar command", # used in help message
				keys => [qw(b x)],                # defaults to substr($name, 0, 1)
			},
		],
	);

=head1 DESCRIPTION

This module aims to provide a very subclassible L<Term::ReadKey> based prompter
inspired by Darcs' (L<http://darcs.net>) fantastic command line user interface.

Many options exist both as accessors for default values, and are passable as
named arguments to the methods of the api.

The api is structured so that the underlying methods are usable as well, you
don't need to use the high level api to make use of this module if you don't
want to.

=head1 METHODS

=over 4

=item prompt %args

Display a prompt, with additinal formatting and processing of additional and/or
default options, an automated help option, etc.

=item do_prompt %args

Low level prompt, without processing of options and prompt reformatting.

Affected by C<repeat_until_valid>.

=item prompt_once %args

Don't prompt repeatedly on invalid answers.

=item print_prompt %args

Just delegates to C<print> using the C<prompt> argument.

=item prepare_options %args

Returns a list of options, based on the arguments, defaults, various flags,
etc.

=item process_options %args

Delegates to C<process_option> for a list of options.

=item process_option %args

Low level option processor, checks for validity mostly.

=item gather_options

Merges the explicit default options, additional options, and optional help
option.

=item get_help_keys %args

Returns a list of keys that trigger the help command. Defaults to C<?> and
C<h>.

If C<auto_help> is true then it returns C<help_keys>.

=item create_help_option %args

Creates an option from the C<get_help_keys> key list.

=item display_help %args

Prints out a help message.

Affected by C<help_footer> and C<help_header>, delegates to
C<option_to_help_text> and C<tabulate_help_text> for the actual work, finally
sending the output to C<print>.

=item tabulate_help_text %args

Uses L<Text::Table> to pretty print the help.

Affected by the C<help_headings> option.

=item option_to_help_text %args

Makes a hashref of text values from an option, to be formatted by
C<tabulate_help_text>.

=item sort_options %args

Sort the options. This is a stub for subclassing, the current implementation
leaves the options in the order they were gathered.

=item filter_options %args

Check the set of options for validity (duplicate names and keys, etc).

Affected by the C<allow_duplicate_names> option.

=item prompt_string %args

Returns the prompt string (from default or args).

=item format_options %args

Format the option keys for the prompt. Appeneded to the actual prompt by C<format_prompt>.

Concatenates the key skipping options for which C<is_help> is true in the spec.

If the C<case_insensitive> option is true then the default command's key will
be uppercased, and the rest lowercased.

=item format_prompt %args

Append the output of C<format_options> in brackets to the actual prompt, and adds a space.

=item read_option %args

Wrapper for C<read_key> that returns the option selected.

=item invalid_choice %args

Called when an invalid key was entered. Uses C<print> internally.

=item option_to_return_value %args

Process the option into it's return value, triggerring callbacks or mapping to
the option name as requested.

=item read_key %args

calls C<ReadMode> and C<ReadKey> to get a single character from L<Term::ReadKey>.

Affected by C<echo_key>, C<auto_newline>, C<readkey_mode>, C<readmode>.

=item process_char %args

Under C<case_insensitive> mode will lowercase the character specified.

Called for every character read and every character in the option spec by
C<read_option>.

=item print @text

The default version will just call the builtin C<print>. It will locally set
C<$|> to 1, though that is probably superflous (I think C<ReadKey> will flush
anyway).

This is the only function that does not take named arguments.

=back

=head1 OPTIONS AND ATTRIBUTES

These attributes control default values for options.

=over 4

=item prompt

The prompt to display.

=item options

The options to prompt for.

=item additional_options

Additional options to append to the default or explicitly specified options.

Defaults to nothing.

=item auto_help

Whether or not to automatically create a help command.

=item help_headings

The headings of the help table.

Takes an array of hash refs, which are expected to have the C<name> and
C<heading> keys filled in. The array is used for ordering and displaying the
help table.

Defaults to B<Key>, B<Name>, B<Description>.

=item help_header

Text to prepend to the help message.

Defaults to a simple description of the help screen.

=item help_footer

Text to append to the help message.

No default value.

=item help_keys

The keys that C<create_help_option> will assign to the help option.

Defaults to C<?> and C<h>.

=item allow_duplicate_names

Whether or not duplicate option names are allowed. Defaults to 

=item readkey_mode

The argument to pass to C<ReadKey>. Default to C<0>. See L<Term::ReadKey>.

=item readmode

The value to give to C<ReadMode>. Defaults to C<3>. See L<Term::ReadKey>.

=item echo_key

Whether or not to echo back the key entered.

=item auto_newline

Whether or not to add a newline after reading a key (if the key is not newline
itself).

=item return_option

Overrides C<return_name> and the callback firing mechanism, so that the option
spec is always returned.

=item return_name

When returning a value from C<option_to_return_value>, and there is no
callback, will cause the name of the option to be returned instead of the
option spec.

Defaults to true.

=item case_insensitive

Option keys are treated case insensitively.

Defuaults to true.

=item repeat_until_valid

When invalid input is entered, reprompt until a valid choice is made.

=back

=head1 AUTHOR

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT

	Copyright (c) 2008 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut
