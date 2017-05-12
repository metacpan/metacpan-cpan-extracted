package Tenjin::Template;

use strict;
use warnings;
use Fcntl qw/:flock/;
use Carp;

our $VERSION = "1.000001";
$VERSION = eval $VERSION;

=head1 NAME

Tenjin::Template - A Tenjin template object, either built from a file or from memory.

=head1 SYNOPSIS

	# mostly used internally, but you can manipulate
	# templates like so

	my $template = Tenjin::Template->new('/path/to/templates/template.html');
	my $context = { scalar => 'scalar', arrayref => ['one', 2, "3"] };
	$template->render($context);

=head1 DESCRIPTION

This module is in charge of the task of compiling Tenjin templates.
Templates in Tenjin are compiled into standard Perl code (combined with
any Perl code used inside the templates themselves). Rendering a template
means C<eval>uating that Perl code and returning its output.

The Tenjin engine reads a template file or a template string, and creates
a Template object from it. Then the object compiles itself by traversing
the template, parsing Tenjin macros like 'include' and 'start_capture',
replaces Tenjin expressions (i.e. C<[== $expr =]> or C<[= $expr =]>) with the
appropriate Perl code, etc. This module ties a template object with
a context object, but all context manipulation (and the actual C<eval>uation
of the Perl code) is done by L<Tenjin::Context>.

If you're planning on using this module by itself (i.e. without the L<Tenjin>
engine), keep in mind that template caching and layout templates are not
handled by this module.

=cut

our $MACRO_HANDLER_TABLE = {
	'include' => sub { my $arg = shift;
		" \$_buf .= \$_context->{'_engine'}->render($arg, \$_context, 0);";
	},
	'start_capture' => sub { my $arg = shift;
		" my \$_buf_bkup=\$_buf; \$_buf=''; my \$_capture_varname=$arg;";
	},
	'stop_capture' => sub { my $arg = shift;
		" \$_context->{\$_capture_varname}=\$_buf; \$_buf=\$_buf_bkup;";
	},
	'start_placeholder' => sub { my $arg = shift;
		" if (\$_context->{$arg}) { \$_buf .= \$_context->{$arg}; } else {";
	},
	'stop_placeholder' => sub { my $arg = shift;
		" }";
	},
	'echo' => sub { my $arg = shift;
		" \$_buf .= $arg;";
	},
};

=head1 METHODS

=head2 new( [$filename, \%opts] )

Creates a new Tenjin::Template object, possibly from a file on the file
system (in which case C<$filename> must be provided and be an absolute
path to a template file). Optionally, a hash-ref of options can be
passed to set some customizations. Available options are 'escapefunc',
which will be in charge of escaping expressions (from C<[= $expr =]>) instead
of the internal method (which uses L<HTML::Entities>); and 'rawclass',
which can be used to prevent variables and objects of a certain class
from being escaped, in which case the variable must be a hash-ref
that has a key named 'str', which will be used instead. So, for example,
if you have a variable named C<$var> which is a hash-ref, and 'rawclass'
is set as 'HASH', then writing C<[= $var =]> on your templates will replace
C<$var> with C<< $var->{str} >>.

=cut

sub new {
	my ($class, $filename, $template_name, $opts) = @_;

	my $escapefunc = defined($opts) && exists($opts->{escapefunc}) ? $opts->{escapefunc} : undef;
	my $rawclass   = defined($opts) && exists($opts->{rawclass}) ? $opts->{rawclass} : undef;

	my $self = bless {
		'filename'   => $filename,
		'name'       => $template_name,
		'script'     => undef,
		'escapefunc' => $escapefunc,
		'rawclass'   => $rawclass,
		'timestamp'  => undef,
		'args'       => undef,
	}, $class;
	
	$self->convert_file($filename) if $filename;

	return $self;
}

=head2 render( [$_context] )

Renders the template, possibly with a context hash-ref, and returns the
rendered output. If errors have occurred when rendering the template (which
might happen since templates have and are Perl code), then this method
will croak.

=cut

sub render {
	my ($self, $_context) = @_;

	$_context ||= {};

	if ($self->{func}) {
		return $self->{func}->($_context);
	} else {
		$_context = $Tenjin::CONTEXT_CLASS->new($_context) if ref $_context eq 'HASH';			

		my $script = $self->{script};
		$script = $_context->_build_decl() . $script unless $self->{args};
		
		# rendering is actually done inside the context object
		# with the evaluate method. We pass either the name of
		# the template or the filename of the template for debug
		# purposes
		
		return $_context->evaluate($script, $self->{filename} || $self->{name});
	}
}

=head1 INTERNAL METHODS

=head2 convert_file( $filename )

Receives an absolute path to a template file, converts that file
to Perl code by calling L<convert()|convert( $input, $filename )> and
returns that code.

=cut

sub convert_file {
	my ($self, $filename) = @_;

	return $self->convert($self->_read_file($filename, 1), $filename);
}

=head2 convert( $input, [$filename] )

Receives a text of a template (i.e. the template itself) and possibly
an absolute path to the template file (if the template comes from a file),
and converts the template into Perl code, which is later C<eval>uated
for rendering. Conversion is done by parsing the statements in the
template (see L<parse_stmt()|parse_stmt( $bufref, $input )>).

=cut

sub convert {
	my ($self, $input, $filename) = @_;

	$self->{filename} = $filename;
	my @buf = ('my $_buf = ""; my $_V; ', );
	$self->parse_stmt(\@buf, $input);

	return $self->{script} = $buf[0] . " \$_buf;\n";
}

=head2 compile_stmt_pattern( $pl )

Receives a string which denotes the Perl code delimiter which is used
inside templates. Tenjin uses 'C<< <?pl ... ?> >>' and 'C<< <?PL ... ?> >>'
(the latter for preprocessing), so C<$pl> will be 'pl'. This method
returns a tranlsation regular expression which will be used for reading
embedded Perl code.

=cut

sub compile_stmt_pattern {
	my $pl = shift;

	my $pat = '((^[ \t]*)?<\?'.$pl.'( |\t|\r?\n)(.*?) ?\?>([ \t]*\r?\n)?)';
	return qr/$pat/sm;
}

=head2 stmt_pattern

Returns the default pattern (which uses 'pl') with the
L<previous_method|compile_stmt_pattern( $pl )>.

=cut

sub stmt_pattern {
	return compile_stmt_pattern('pl');
}

=head2 expr_pattern()

Defines how expressions are written in Tenjin templates (C<[== $expr =]>
and C<[= $expr =]>).

=cut

sub expr_pattern {
	return qr/\[=(=?)(.*?)(=?)=\]/s;
}

=head2 parse_stmt( $bufref, $input )

Receives a buffer which is used for saving a template's expressions
and the template's text, parses all expressions in the templates and
pushes them to the buffer.

=cut

sub parse_stmt {
	my ($self, $bufref, $input) = @_;

	my $pos = 0;
	my $pat = $self->stmt_pattern();
	while ($input =~ /$pat/g) {
		my ($pi, $lspace, $mspace, $stmt, $rspace) = ($1, $2, $3, $4, $5);
		my $start = $-[0];
		my $text = substr($input, $pos, $start - $pos);
		$pos = $start + length($pi);
		$self->parse_expr($bufref, $text) if $text;
		$mspace = '' if $mspace eq ' ';
		$stmt = $self->hook_stmt($stmt);
		$stmt .= $rspace if $rspace;
		$stmt = $mspace . $stmt if $mspace;
		$stmt = $lspace . $stmt if $lspace;
		$self->add_stmt($bufref, $stmt);
	}
	my $rest = $pos == 0 ? $input : substr($input, $pos);
	$self->parse_expr($bufref, $rest) if $rest;
}

=head2 hook_stmt( $stmt )

=cut

sub hook_stmt {
	my ($self, $stmt) = @_;

	## macro expantion
	if ($stmt =~ /\A(\s*)(\w+)\((.*?)\);?(\s*)\Z/) {
		my ($lspace, $funcname, $arg, $rspace) = ($1, $2, $3, $4);
		my $s = $self->expand_macro($funcname, $arg);
		return $lspace . $s . $rspace if defined($s);
	}

	## template arguments
	unless ($self->{args}) {
		if ($stmt =~ m/\A(\s*)\#\@ARGS\s+(.*)(\s*)\Z/) {
			my ($lspace, $argstr, $rspace) = ($1, $2, $3);
			my @args = ();
			my @declares = ();
			foreach my $arg (split(/,/, $argstr)) {
				$arg =~ s/(^\s+|\s+$)//g;
				next unless $arg;
				$arg =~ m/\A([\$\@\%])?([a-zA-Z_]\w*)\Z/ or croak "[Tenjin] $arg: invalid template argument.";
				croak "[Tenjin] $arg: only '\$var' is available for template argument." unless (!$1 || $1 eq '$');
				my $name = $2;
				push(@args, $name);
				push(@declares, "my \$$name = \$_context->{$name}; ");
			}
			$self->{args} = \@args;
			return $lspace . join('', @declares) . $rspace;
		}
	}

	return $stmt;
}

=head2 expand_macro( $funcname, $arg )

This method is in charge of invoking macro functions which might be used
inside templates. The following macros are available:

=over

=item * C<include( $filename )>

Includes another template, whose name is C<$filename>, inside the current
template. The included template will be placed inside the template as if
they were one unit, so the context variable applies to both.

=item * C<start_capture( $name )> and C<end_capture()>

Tells Tenjin to capture the output of the rendered template from the point
where C<start_capture()> was called to the point where C<end_capture()>
was called. You must provide a name for the captured portion, which will be
made available in the context as C<< $_context->{$name} >> for immediate
usage. Note that the captured portion will not be printed unless you do
so explicilty with C<< $_context->{$name} >>.

=item * C<start_placeholder( $var )> and C<end_placeholder()>

This is a special method which can be used for making your templates a bit
cleaner. Suppose your context might have a variable whose name is defined
in C<$var>. If that variable exists in the context, you simply want to print
it, but if it's not, you want to print and/or perform other things. In that
case you can call C<start_placeholder( $var )> with the name of the context
variable you want printed, and if it's not, anything you do between
C<start_placeholder()> and C<end_placeholder()> will be printed instead.

=item * echo( $exr )

Just prints the provided expression. You might want to use it if you're
a little too comfortable with PHP.

=back

=cut

sub expand_macro {
	my ($self, $funcname, $arg) = @_;

	my $handler = $MACRO_HANDLER_TABLE->{$funcname};
	return $handler ? $handler->($arg) : undef;
}

=head2 get_expr_and_escapeflag( $not_escape, $expr, $delete_newline )

=cut

## ex. get_expr_and_escapeflag('=', '$item->{name}', '')  => 1, '$item->{name}', 0
sub get_expr_and_escapeflag {
	my ($self, $not_escape, $expr, $delete_newline) = @_;

	return $expr, $not_escape eq '', $delete_newline eq '=';
}

=head2 parse_expr( $bufref, $input )

=cut

sub parse_expr {
	my ($self, $bufref, $input) = @_;

	my $pos = 0;
	$self->start_text_part($bufref);
	my $pat = $self->expr_pattern();
	while ($input =~ /$pat/g) {
		my $start = $-[0];
		my $text = substr($input, $pos, $start - $pos);
		my ($expr, $flag_escape, $delete_newline) = $self->get_expr_and_escapeflag($1, $2, $3);
		$pos = $+[0];
		$self->add_text($bufref, $text) if $text;
		$self->add_expr($bufref, $expr, $flag_escape) if $expr;
		if ($delete_newline) {
			my $end = $+[0];
			if (substr($input, $end, 1) eq "\n") {
				$bufref->[0] .= "\n";
				$pos++;
			}
		}
	}
	my $rest = $pos == 0 ? $input : substr($input, $pos);
	$self->add_text($bufref, $rest);
	$self->stop_text_part($bufref);
}

=head2 start_text_part( $bufref )

=cut

sub start_text_part {
	my ($self, $bufref) = @_;

	$bufref->[0] .= ' $_buf .= ';
}

=head2 stop_text_part( $bufref )

=cut

sub stop_text_part {
	my ($self, $bufref) = @_;

	$bufref->[0] .= '; ';
}

=head2 add_text( $bufref, $text )

=cut

sub add_text {
	my ($self, $bufref, $text) = @_;

	return unless $text;
	$text =~ s/([`\\])/\\$1/g;
	my $is_start = $bufref->[0] =~ / \$_buf \.= \Z/;
	$bufref->[0] .= $is_start ? "q`$text`" : " . q`$text`";
}

=head2 add_stmt( $bufref, $stmt )

=cut

sub add_stmt {
	my ($self, $bufref, $stmt) = @_;

	$bufref->[0] .= $stmt;
}

=head2 add_expr( $bufref, $expr, $flag_escape )

=cut

sub add_expr {
	my ($self, $bufref, $expr, $flag_escape) = @_;

	my $dot = $bufref->[0] =~ / \$_buf \.= \Z/ ? '' : ' . ';
	$bufref->[0] .= $dot . ($flag_escape ? $self->escaped_expr($expr) : "($expr)");
}

=head2 defun( $funcname, @args )

=cut

sub defun {   ## (experimental)
	my ($self, $funcname, @args) = @_;

	unless ($funcname) {
		my $funcname = $self->{filename};
		if ($funcname) {
			$funcname =~ s/\.\w+$//;
			$funcname =~ s/[^\w]/_/g;
		}
		$funcname = 'render_' . $funcname;
	}

	my $str = "sub $funcname { my (\$_context) = \@_; ";
	foreach (@args) {
		$str .= "my \$$_ = \$_context->{'$_'}; ";
	}
	$str .= $self->{script};
	$str .= "}\n";

	return $str;
}

=head2 compile()

=cut

## compile $self->{script} into closure.
sub compile {
	my $self = shift;

	if ($self->{args}) {
		$self->{func} = $Tenjin::CONTEXT_CLASS->to_func($self->{script}, $self->{name});
		return $self->{func};
	}
	return;
}

=head2 escaped_expr( $expr )

Receives a Perl expression (from C<[= $expr =]>) and escapes it. This will
happen in one of three ways: with the escape function defined in
C<< $opts->{escapefunc} >> (if defined), with a scalar string (if
C<< $opts->{rawclass} >> is defined), or with C<escape_xml()> from
L<Tenjin::Util>, which uses L<HTML::Entites>.

=cut

sub escaped_expr {
	my ($self, $expr) = @_;

	return "$self->{escapefunc}($expr)" if $self->{escapefunc};

	return "(ref(\$_V = ($expr)) eq '$self->{rawclass}' ? \$_V->{str} : escape_xml($expr)" if $self->{rawclass};

	return "escape_xml($expr)";
}

=head2 _read_file( $filename, [$lock_required] )

Receives an absolute path to a template file, reads its content and
returns it. If C<$lock_required> is passed (and has a true value), the
file will be locked for reading.

=cut

sub _read_file {
	my ($self, $filename, $lock_required) = @_;

	open(IN, "<:encoding($Tenjin::ENCODING)", $filename)
		or croak "[Tenjin] Can't open $filename for reading: $!";
	flock(IN, LOCK_SH) if $lock_required;

	read(IN, my $content, -s $filename);

	close(IN);

	return $content;
}

=head2 _write_file( $filename, $content, [$lock_required] )

Receives an absolute path to a template file and the templates contents,
and creates the file (or truncates it, if existing) with that contents.
If C<$lock_required> is passed (and has a true value), the file will be
locked exclusively when writing.

=cut

sub _write_file {
	my ($self, $filename, $content, $lock_required) = @_;

	my $enc = $Tenjin::ENCODING eq 'UTF-8' ? '>:utf8' : ">:encoding($Tenjin::ENCODING)";

	open(OUT, $enc, $filename)
		or croak "[Tenjin] Can't open $filename for writing: $!";
	flock(OUT, LOCK_EX) if $lock_required;
	print OUT $content;
	close(OUT);
}

1;

=head1 SEE ALSO

L<Tenjin>.

=head1 AUTHOR, LICENSE AND COPYRIGHT

See L<Tenjin>.

=cut
