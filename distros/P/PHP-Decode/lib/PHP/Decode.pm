#
# parse and transform PHP source files
#
package PHP::Decode;

use strict;
use warnings;
use PHP::Decode::Parser;
use PHP::Decode::Transformer;

our $VERSION = '0.302';

sub new {
	my ($class, %args) = @_;

	my $parser = PHP::Decode::Parser->new(strmap => {},
		exists $args{inscript} ? (inscript => $args{inscript}) : (),
		exists $args{filename} ? (filename => $args{filename}) : (),
		exists $args{max_strlen} ? (max_strlen => $args{max_strlen}) : (),
		exists $args{log} ? (log => $args{log}) : (),
		exists $args{debug} ? (debug => $args{debug}) : (),
		exists $args{warn} ? (warn => $args{warn}) : ());

	my $ctx = PHP::Decode::Transformer->new(parser => $parser,
		exists $args{skip} ? (skip => $args{skip}) : (),
		exists $args{with} ? (with => $args{with}) : (),
		exists $args{max_loop} ? (max_loop => $args{max_loop}) : (),
		exists $args{log} ? (log => \&_log_cb) : (),
		exists $args{warn} ? (warn => \&_warn_cb) : ());

	return bless {
		ctx => $ctx,
	}, $class;
}

sub _log_cb {
	my ($ctx, $action, $stmt, $fmt) = (shift, shift, shift, shift);

	my $parser = $ctx->{parser};
	my $flg = $ctx->{skipundef} ? '! ' : '';
	if ($ctx->{incall}) {
		$parser->{log}->($flg . "[$ctx->{infunction}] $action $stmt", $fmt, @_);
	} elsif ($ctx->{infunction}) {
		$parser->{log}->("<$ctx->{infunction}> $action $stmt", $fmt, @_);
	} else {
		$parser->{log}->($flg . "$action $stmt", $fmt, @_);
	}
}

sub _warn_cb {
	my ($ctx, $action, $stmt, $fmt) = (shift, shift, shift, shift);

	my $parser = $ctx->{parser};
	my $flg = $ctx->{skipundef} ? '! ' : '';
	if ($ctx->{incall}) {
		$parser->{warn}->($flg . "[$ctx->{infunction}] $action $stmt", $fmt, @_);
	} elsif ($ctx->{infunction}) {
		$parser->{warn}->("<$ctx->{infunction}> $action $stmt", $fmt, @_);
	} else {
		$parser->{warn}->($flg . "$action $stmt", $fmt, @_);
	}
}

sub parse {
	my ($self, $line) = @_;
	my $parser = $self->{ctx}{parser};
	my $str = $parser->setstr($line);

	return $self->{ctx}->parse_eval($str);
}

sub exec {
	my ($self, $stmt) = @_;

	return $self->{ctx}->exec_eval($stmt);
}

sub eval {
	my ($self, $line) = @_;
	my $parser = $self->{ctx}{parser};
	my $str = $parser->setstr($line);

	my $stmt = $self->{ctx}->parse_eval($str);
	return $self->{ctx}->exec_eval($stmt);
}

sub format {
	my ($self, $stmt, $fmt) = @_;
	my $parser = $self->{ctx}{parser};

	return $parser->format_stmt($stmt, $fmt);
}

1;

__END__

=head1 NAME

PHP::Decode - Parse and transform obfuscated php code

=head1 SYNOPSIS

  # Create an instance

  sub warn_msg {
	my ($action, $fmt) = (shift, shift);
	my $msg = sprintf $fmt, @_;
	print 'WARN: ', $action, ': ', $msg, "\n";
  }
  my $php = PHP::Decode->new(warn => \&warn_msg);

  # Parse and transform php code

  my $stmt = $php->eval('<?php echo "test"; ?>');

  # Expand to code again

  my $code = $php->format($stmt, {indent => 1});
  print $code;

  # Output: echo 'test' ; $STDOUT = 'test' ;

=head1 DESCRIPTION

The PHP::Decode module applies static transformations to PHP statements parsed
by the L<PHP::Decode::Parser> module and returns the transformed PHP code.

The decoder uses a custom php parser which does not depend on a special php
version. It supports most php syntax of interpreters from php5 to php8.
This is a pure perl implementation and requires no external php interpreter.

The parser assumes that the input file is a valid php script, and does
not enforce strict syntactic checks. Unrecognized tokens are simply passed
through.

The parser converts the php code into a unified form when the resulting
output is formatted (for example intermittent php-script-tags and variables
from string interpolation are removed and rewritten to php echo statements).
The parsed result is available before other transformations are applied.

The transformer is run by calling the exec-method on the parsed php statements,
and partially executes the php code. It tries to apply all possible static
code transformations based on php variables and values defined in the script.

The transformer does not implement php functions with any kind of side-effect
that require access to external resources like file-io or network-io. Statements
with references to unresolvable input values like cgi-variables or file-content
are skipped and corresponding variables are marked as unresolved.

The transformer supports many of the pure php built-in functions, but not all
function parameters are supported. Function calls with unresolved parameters
are skipped and kept unmodified in the transformer output. In most cases the
resulting php code will be valid and produce the same results as the original
script.

While the transformer executes, all script output to stdout (like echo or
print statements) is captured and appended as a '$STDOUT = <str>' statement
to the transformed code.

The format method converts the resulting php statements to php code again,
and allows to output the code in indented form or as a single line.

=head2 Malware analysis

The php decoder was mainly developed on a case-by-case basis to support
malware analysis. It proved to be useful when applied to many obfuscated
malware scipts found in the wild.

One aim is to expose the active parts of malware scripts. For example
statements which try to execute arbitrary code passed via cgi-variables
might be visible after a script was decoded.

Since newer php versions are adding new syntax and deprecating older syntax,
there is always room for improvement of the decoder.

Newer php versions started to deprecate some features like obscure variants
of the eval call used by malware scripts. So older malware might be rendered
invalid when executed by more recent interpreters.

Here is an example for a decoded malware file: L<https://github.com/bdzwillo/php_decode/blob/master/docs/example.md>

=head2 php_decode

The php_decode tool included in the distribution, is a command line client
for the L<PHP::Decode> module and allows to select most of the features
via command line options when run on a php script:

   Decode an obfuscated php script:
   > php_decode <php-file>

   Just Show the parsed output:
   > php_decode -p <php-file>

=head1 METHODS

=head2 new

  $php = PHP::Decode->new(%args);

The new contructor returns a PHP::Decode object.
Arguments are passed in key => value pairs.

The new constructor dies when arguments are invalid.

The accepted arguments are:

=over 4

=item inscript: set to indicate that paser starts inside of script

=item filename: optional script filename (if not stdin or textstr)

=item max_strlen: max strlen for debug strings

=item warn: optional handler to log warning messages

=item log: optional handler to log info messages

=item debug: optional handler to log debug messages

=item max_loop: optional max iterations for php loop execution (default: 10000)

=item skip: optional transformer features to skip on execution

=item $skip->{call}: skip function calls

=item $skip->{loop}: skip loop execution

=item $skip->{null}: dont' assume null for undefined vars

=item $skip->{stdout}: don't include STDOUT

=item with: optional transformer features to use for execution

=item $with->{getenv}: eval getenv() for passed enviroment hash

=item $with->{translate}: translate self-contained funcs to native code (experimental)

=item $with->{optimize_block_vars}: remove intermediate block vars on toplevel

=item $with->{invalidate_tainted_vars}: invalidate vars after tainted calls

=back

=head2 parse

Parse a php code string.

    $stmt = $php->parse($str);

The php code is tokenized and converted to an internal representation of php
statements. In most cases the result will be a tree starting with a block ('#blk')
which contains a list of the toplevel statements from the php script.

For more information about the statement types, see the L<PHP::Decode::Parser> Module.

=head2 exec

Execute a php statement.

    $stmt = $php->exec($stmt);

The exec method applies static transformations to the passed php statements,
and returns the resulting statements. Examples for transformations are:

- calculation of expressions with constant values, arrays and strings.

- execution of built-in php functions (see: L<PHP::Decode::Func> Module).

The accepted arguments are:

=over 4

=item stmt: the toplevel php statement to execute

=back

=head2 eval

Parse and Execute a php code string.

    $stmt = $php->eval($str);

The eval() method combines the parse() and exec() methods.

=head2 format

Format a php statement to a php code string.

    $code = $php->format($stmt, $fmt);

The accepted arguments are:

=over 4

=item stmt: the toplevel php statement to format

=item fmt: optional format flags

=item $fmt->{indent}: output indented multiline code

=item $fmt->{unified}: unified #str/#num output

=item $fmt->{mask_eval}: mask eval in strings with pattern

=item $fmt->{escape_ctrl}: escape control characters in output strings

=item $fmt->{avoid_semicolon}: avoid semicolons after braces

=item $fmt->{max_strlen}: max length for strings in output

=back

=head1 SEE ALSO

The git repository for PHP::Decode on cpan is L<https://github.com/bdzwillo/php_decode>.

=over 4

=item * PHP code parser L<PHP::Decode::Parser>

=item * PHP ordered arrays L<PHP::Decode::Array>

=item * PHP code transformer L<PHP::Decode::Transformer>

=item * php_decode client L<php_decode>

=back

Required by PHP::Decode::Array:
Ordered Hash L<Tie::IxHash>

Required by PHP::Decode::Transformer:

=over 4

=item * Base64 encode/decode L<MIME::Base64>

=item * Zlib compress/decompress L<Compress::Zlib>

=item * MD5 hash L<Digest::MD5>

=item * SHA1 hash L<Digest::SHA1>

=item * HTML text encode/decode L<HTML::Entities>

=item * URL encode/decode L<URI::Escape>

=back

Since many built-in PHP functions relate directly to their perl
counterparts, perl is a good match for php emulation. (see for example
the PHP string functions: L<https://php.net/manual/en/ref.strings.php>)

=head1 AUTHORS

Barnim Dzwillo @ Strato AG

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2023 by Barnim Dzwillo

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
