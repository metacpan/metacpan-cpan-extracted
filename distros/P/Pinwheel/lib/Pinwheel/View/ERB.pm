package Pinwheel::View::ERB;

use strict;
use warnings;

use Carp;
use Exporter;

use Pinwheel::View::String;
use Pinwheel::View::Wrap;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(parse_template);


our $OPEN_TAG_RE = qr{
    (.*?)
    <%(=?)
}x;
our $CLOSE_TAG_RE = qr{
    \s*
    ((?:
        (?:(['"])(?:\\.|[^\2])*?\2)
        | (?:\#.*?(?=-?%>))
        | [^'"]
    )*?)
    \s*
    (-?)%>
}x;
our $TEXT = 1;
our $CODE = 2;

our $slow_attrs;

BEGIN {
    my ($pkg, %attrs, $s);

    $pkg = \%Pinwheel::View::Wrap::;
    foreach (keys %$pkg) {
        map { $attrs{$_} = 1 } @{$pkg->{$_}{'WRAP_METHODS'}};
    }

    $s = '(?:' . join('|', keys %attrs) . ')';
    $slow_attrs = qr/^${s}$/;
}


sub parse_template
{
    my ($s, $name) = @_;
    my ($writer, $lineno, $line, $addnl);

    $name = 'anonymous' if (!$name);
    $writer = code_writer($name);
    $addnl = 0;
    foreach $line (split(/\r?\n/, $s)) {
        $lineno++;
        $addnl = parse_template_line($line, $lineno, $writer, $addnl);
    }
    if ($addnl && $s =~ /\n\s*$/) {
        $writer->{echo_raw}('"\n"');
    }
    return compile($writer->{eof}(), $name);
}

sub parse_template_line
{
    my ($line, $lineno, $writer, $addnl) = @_;
    my ($linetype, @parts, $echo);
    my ($text, $type, $data);

    # Collect the parts (text and code) and classify the line:
    #   bit 0: contains non-whitespace text
    #   bit 1: contains code which outputs something, ie <%= ... %>
    #   bit 2: contains code which does not output anything, ie <% ... %>
    $linetype = 0;
    while ($line =~ /\G$OPEN_TAG_RE/gc) {
        $echo = ($2 eq '=');
        if ($1 ne '') {
            push @parts, [$TEXT, $1];
            $linetype |= 1 if ($1 !~ /^\s*$/);
        }
        $line =~ /\G$CLOSE_TAG_RE/gc ||
            $writer->{error}("Missing %>", $lineno);
        if ($1 !~ /^\s*$/) {
            push @parts, [$CODE, $1, $echo];
            $linetype |= $echo ? 2 : 4;
        }
    }
    if ($line =~ /\G(.*[^\s])\s*$/) {
        push @parts, [$TEXT, $1];
        $linetype |= 1;
    }

    # If the line contains code, supply the line number for error messages
    # (both compile time and runtime)
    $writer->{line}($lineno) if ($linetype & 6);

    # Write this line of the template
    $text = $addnl ? "\n" : '';
    push @parts, [-1, undef];
    do {
        ($type, $data, $echo) = @{shift(@parts)};
        if ($type != $TEXT && $text ne '') {
            $writer->{echo_raw}($writer->{string}($text));
            $text = '';
        }
        $text .= $data if ($type == $TEXT && $linetype != 4);
        parse_code(lexer($data), $writer, $echo) if ($type == $CODE);
    } while ($type != -1);

    return ($linetype != 4);
}


sub code_writer
{
    my $name = shift;
    my ($strings, %stridx, %functions);
    my ($code, @blocks, $lineno);

    $strings = [];
    $code = '';
    $lineno = '?';

    return {
        open => sub {
            push @blocks, [$_[0], $_[1], $lineno];
        },
        need => sub {
            _error("Unexpected '$_[1]'", $lineno, $name)
                if (scalar(@blocks) < 1 || $blocks[-1][0] ne $_[0]);
        },
        close => sub {
            my $block = pop(@blocks);
            _error("Unexpected 'end'", $lineno, $name) unless $block;
            return $block->[1];
        },
        eof => sub {
            _error("Unclosed '$blocks[-1][0]'", $blocks[-1][2], $name)
                if (scalar(@blocks) > 0);
            my @fnlist = keys(%functions);
            return ($code, $strings, \@fnlist);
        },
        string => sub {
            if (!exists($stridx{$_[0]})) {
                $stridx{$_[0]} = push(@$strings, $_[0]) - 1;
            }
            return '$strings->[' . $stridx{$_[0]} . ']';
        },
        error => sub {
            _error($_[0], $_[1] ? $_[1] : $lineno, $name);
        },
        function => sub {
            $functions{$_[0]} = 1;
        },
        echo => sub {
            $code .= "\$r .= $_[0];\n";
        },
        echo_raw => sub {
            $code .= "\$r->concat_raw($_[0]);\n";
        },
        do => sub {
            $code .= "$_[0];\n";
        },
        line => sub {
            $lineno = $_[0];
            $code .= "\$lineno = $_[0];\n";
        }
    };
}


# ==============================================================================


sub parse_code
{
    my ($lexer, $writer, $echo) = @_;
    my ($left, $conditional, $type, $next_type);

    $type = $lexer->(1)[0];
    $next_type = $lexer->(2)[0];
    if ($type eq '') {
        $writer->{error}('Invalid syntax') if ($lexer->(1)[1] ne '');
        $left = '';
    } elsif ($type eq 'STMT') {
        $left = parse_statement($lexer, $writer);
        $writer->{do}($left);
    } elsif (($type eq 'ID' || $type eq '@ID') && $next_type eq '=') {
        $left = parse_assign($lexer, $writer);
        $writer->{do}($left);
    } elsif ($type eq 'ID' && $next_type eq ',') {
        $left = parse_unpack($lexer, $writer);
        $writer->{do}($left);
    } else {
        $left = parse_expr($lexer, $writer);
        $conditional = parse_conditional($lexer, $writer) || '';
        $writer->{$echo ? 'echo' : 'do'}($left . $conditional);
    }
    $writer->{error}('Invalid syntax') if ($lexer->(1)[0] ne '');
    return $left;
}


sub parse_statement
{
    my ($lexer, $writer) = @_;
    my ($left, $token, $stmt, $expr);

    $token = $lexer->(1);
    $stmt = $token->[1];
    if ($stmt eq 'for') {
        $left = parse_for($lexer, $writer);
    } elsif ($stmt eq 'if') {
        $writer->{open}('if', '}');
        $lexer->(); # Absorb 'if'
        $expr = parse_test_expr($lexer, $writer);
        $left = "if ($expr) {";
    } elsif ($stmt eq 'elsif') {
        $writer->{need}('if', 'elsif');
        $lexer->(); # Absorb 'elsif'
        $expr = parse_test_expr($lexer, $writer);
        $left = "} elsif ($expr) {";
    } elsif ($stmt eq 'else') {
        $writer->{need}('if', 'else');
        $lexer->(); # Absorb 'else'
        $left = "} else {";
    } else { # elsif ($stmt eq 'end') {
        $lexer->(); # Absorb 'end'
        $left = $writer->{close}();
    }
    return $left;
}

sub parse_conditional
{
    my ($lexer, $writer) = @_;
    my ($expr, $token);

    $token = $lexer->(1);
    return if ($token->[0] ne 'STMT' || $token->[1] ne 'if');

    $lexer->(); # Absorb 'if'
    $expr = parse_test_expr($lexer, $writer);
    return " if ($expr)";
}

sub parse_for
{
    my ($lexer, $writer) = @_;
    my ($left, $token, @vars);

    $lexer->(); # Absorb 'for'
    $writer->{open}('for', '}');
    do {
        $token = $lexer->();
        $writer->{error}('Expected variable') unless ($token->[0] eq 'ID');
        push @vars, $token->[1];
        $token = $lexer->();
    } while ($token->[0] eq ',');
    $writer->{error}("Expected 'in'") unless ($token->[0] eq 'in');

    $left = 'foreach (@{' . parse_expr($lexer, $writer) . '}) ';
    if (scalar(@vars) == 1) {
        $left .= '{ $locals->{\'' . $vars[0] . '\'} = $_;';
    } else {
        $left .= '{ @$locals{qw(' . join(' ', @vars) . ')} = @$_;';
    }

    return $left;
}

sub parse_test_expr
{
    my ($lexer, $writer) = @_;
    my ($left, $right, $token);

    $left = parse_test_cmp($lexer, $writer);
    while ($token = $lexer->(1)) {
        last if ($token->[0] ne 'or' && $token->[0] ne 'and');
        $lexer->(); # Absorb 'or'/'and'
        $right = parse_test_cmp($lexer, $writer);
        if ($token->[0] eq 'or') {
            $left = "($left || $right)";
        } else {
            $left = "($left && $right)";
        }
    }
    return $left;
}

sub parse_test_cmp
{
    my ($lexer, $writer) = @_;
    my ($left, $right, $token, $cmp);

    $left = parse_expr($lexer, $writer);
    while ($token = $lexer->(1)) {
        $cmp = $token->[0];
        last unless ($cmp =~ /^==|!=|<=|>=|<|>$/);
        $lexer->(); # Absorb comparison operator
        $right = parse_expr($lexer, $writer);
        if ($cmp eq '==') {
            $left = "($left eq $right)";
        } elsif ($cmp eq '!=') {
            $left = "($left ne $right)";
        } else {
            $left = "($left $cmp $right)";
        }
    }
    return $left;
}


sub parse_assign
{
    my ($lexer, $writer) = @_;
    my ($right, $ns, $token);

    $token = $lexer->();
    $ns = ($token->[0] eq 'ID') ? "\$locals->" : "\$globals->";
    $lexer->(); # Absorb '='
    $right = parse_expr($lexer, $writer);
    return "$ns\{'$token->[1]'\} = $right";
}

sub parse_unpack
{
    my ($lexer, $writer) = @_;
    my ($left, $right, $token, @vars);

    do {
        $token = $lexer->();
        $writer->{error}('Expected variable') unless ($token->[0] eq 'ID');
        push @vars, $token->[1];
        $token = $lexer->();
    } while ($token->[0] eq ',');
    $writer->{error}("Expected '='") unless ($token->[0] eq '=');

    $left = '@$locals{qw(' . join(' ', @vars) . ')}';
    $right = parse_expr($lexer, $writer);
    return $left . ' = @{' . $right . '}';
}


sub parse_expr
{
    my ($lexer, $writer) = @_;
    my ($left, $right, $token);

    $left = parse_product($lexer, $writer);
    while ($token = $lexer->(1)) {
        last if ($token->[0] ne '+' && $token->[0] ne '-');
        $lexer->(); # Absorb '+' or '-'
        $right = parse_product($lexer, $writer);
        if ($token->[0] eq '+') {
            $left = "_add($left, $right)";
        } else {
            $left = "($left - $right)";
        }
    }
    return $left;
}

sub parse_product
{
    my ($lexer, $writer) = @_;
    my ($left, $right, $token, $op);

    $left = parse_neg($lexer, $writer);
    while ($token = $lexer->(1)) {
        $op = $token->[0];
        last if ($op ne '*' && $op ne '/' && $op ne '%');
        $lexer->(); # Absorb '*', '/', or '%'
        $right = parse_neg($lexer, $writer);
        $left = "($left $op $right)";
    }
    return $left;
}

sub parse_neg
{
    my ($lexer, $writer) = @_;
    my ($left, $token);

    $token = $lexer->(1);
    if ($token->[0] eq '') {
        $writer->{error}('Missing or invalid expression');
    } elsif ($token->[0] eq '!') {
        my ($n, $fn);
        do { $lexer->(); $n++; } while ($lexer->(1)[0] eq '!');
        $left = ($n & 1) ? '!' : '!!';
        $left .= "(" . parse_atom($lexer, $writer) . ')';
    } elsif ($token->[0] eq '-') {
        $lexer->(); # Absorb '-'
        $left = '-' . parse_atom($lexer, $writer);
    } else {
        $left = parse_atom($lexer, $writer);
    }
    return $left;
}

sub parse_atom
{
    my ($lexer, $writer) = @_;
    my ($left, $token);

    $token = $lexer->(1);
    if ($token->[0] eq 'NUM') {
        $left = $lexer->()->[1];
    } elsif ($token->[0] eq 'STR') {
        $left = $writer->{string}($lexer->()->[1]);
    } elsif ($token->[0] eq 'SYM') {
        $left = $writer->{string}($lexer->()->[1]);
    } elsif ($token->[0] eq '(') {
        $lexer->(); # Absorb '('
        $left = parse_test_expr($lexer, $writer);
        $token = $lexer->();
        $writer->{error}('Missing )') unless ($token->[0] eq ')');
    } elsif ($token->[0] eq '{') {
        $left = parse_hash($lexer, $writer);
    } elsif ($token->[0] eq '[') {
        $left = parse_array($lexer, $writer);
    } elsif ($token->[0] eq 'ID' && $lexer->(2)[0] eq '(') {
        $left = parse_call($lexer, $writer);
    } elsif ($token->[0] eq 'ID' || $token->[0] eq '@ID') {
        $left = parse_attr($lexer, $writer);
    } else {
        $writer->{error}('Missing or invalid expression');
    }
    return $left;
}

sub parse_array
{
    my ($lexer, $writer) = @_;
    my ($left, $token);

    $left = '[';
    $token = $lexer->(); # Absorb '['
    $token = $lexer->(1);
    while ($token->[0] ne ']') {
        $left .= parse_expr($lexer, $writer) . ', ';
        $token = $lexer->(1);
        last if ($token->[0] ne ',');
        $token = $lexer->();
    }
    $token = $lexer->(); # Absorb ']'
    $writer->{error}('Missing ]') if ($token->[0] ne ']');
    return $left . ']';
}

sub parse_hash
{
    my ($lexer, $writer) = @_;
    my ($left, $token);

    $left = '{';
    $token = $lexer->(); # Absorb '{'
    $token = $lexer->();
    while ($token->[0] ne '}') {
        $writer->{error}('Expected key') if ($token->[0] ne 'SYM');
        $left .= "'$token->[1]' => ";
        $token = $lexer->();
        $writer->{error}("Expected '=>'") if ($token->[0] ne '=>');
        $left .= parse_expr($lexer, $writer) . ', ';
        $token = $lexer->();
        last if ($token->[0] ne ',');
        $token = $lexer->();
    }
    $writer->{error}('Missing }') if ($token->[0] ne '}');
    return $left . '}';
}

sub parse_call
{
    my ($lexer, $writer) = @_;
    my ($left, $fn, $token, @params);

    $fn = $lexer->()->[1];
    $writer->{function}($fn);
    $lexer->(); # Absorb '('

    $token = $lexer->(1);
    if ($token->[0] ne ')') {
        do {
            if ($lexer->(1)[0] eq 'SYM' && $lexer->(2)[0] eq '=>') {
                push @params, "'" . $lexer->()->[1] . "'";
                $lexer->(); # Absorb '=>'
            }
            push @params, parse_expr($lexer, $writer);
            $token = $lexer->();
        } while ($token->[0] eq ',');
    } else {
        $lexer->(); # Absorb ')'
    }
    $writer->{error}('Missing )') if ($token->[0] ne ')');

    if ($lexer->(1)[0] eq 'do') {
        $lexer->(); # Absorb 'do'
        $writer->{error}('Invalid syntax') if ($lexer->(1)[0] ne '');
        push @params, "sub { my \$r = \$r->clone([])";
        $writer->{open}('do', '$r->to_string(); })');
        $left = "\$fns->{'$fn'}->(" . join(', ', @params);
    } else {
        $left = "\$fns->{'$fn'}->(" . join(', ', @params) . ')';
    }

    return $left;
}

sub parse_attr
{
    my ($lexer, $writer) = @_;
    my ($left, $token, @attribs, $ns, $fn, $s);

    $token = $lexer->();
    $ns = ($token->[0] eq 'ID') ? "\$locals->" : "\$globals->";
    $left = "$ns\{'$token->[1]'\}";
    $fn = '_getattr';
    $s = $lexer->(1)[0];
    while ($s eq '.' || $s eq '[') {
        $lexer->(); # Absorb '.'
        if ($s eq '.') {
            $token = $lexer->();
            $writer->{error}('Missing attribute')
                if ($token->[0] ne 'ID' && $token->[0] ne 'STMT');
            $fn = '_getattr_slow' if ($token->[1] =~ $slow_attrs);
            push @attribs, "'$token->[1]'";
        } else {
            push @attribs, parse_expr($lexer, $writer);
            $token = $lexer->();
            $writer->{error}("Expected ']'") if ($token->[0] ne ']');
        }
        $s = $lexer->(1)[0];
    }
    if (scalar(@attribs) > 0) {
        $left = "$fn($left, " . join(', ', @attribs) . ')';
    }

    return $left;
}


# ==============================================================================


sub _add
{
    return $_[0]->add($_[1]) if ref($_[0]);
    return $_[1]->radd($_[0]) if ref($_[1]);
    return $_[0] + $_[1] if ($_[0] =~ /^-?\d+$/ && $_[1] =~ /^-?\d+$/);
    return $_[0] . $_[1];
}

sub _getattr
{
    my $obj = shift;
    $obj = ((ref($obj) eq 'HASH') ? $obj->{$_} : $obj->$_) foreach (@_);
    return $obj;
}

sub _getattr_slow
{
    my $obj = shift;

    foreach (@_) {
        $obj = ref($obj) ? (
            ref($obj) eq 'ARRAY' ? $Pinwheel::View::Wrap::array->$_($obj) : (
                ref($obj) eq 'HASH' ? $obj->{$_} : $obj->$_
            )
        ) : $Pinwheel::View::Wrap::scalar->$_($obj);
    }

    return $obj;
}

sub _error
{
    my ($msg, $lineno, $name) = @_;
    die "$msg in '$name' at line $lineno\n";
}


sub compile
{
    my ($code, $strings, $fns, $name) = @_;
    my $checkfns;
    $name = 'anonymous' if (!$name);
    $checkfns = '';
    foreach (@$fns) {
        $checkfns .=
            "die \"Unknown function '$_' in '$name'\"" .
            " unless exists(\$fns->{'$_'});\n";
    }
    return eval <<EOF
sub {
    my (\$locals, \$globals, \$fns) = \@_;
    my (\$r, \$lineno);
    \$r = Pinwheel::View::String->new('', \\&_escape);
    \$lineno = 0;
    $checkfns
    eval {
        local \$SIG{__WARN__} = sub {
            chomp(my \$msg = shift);
            die "\$msg at \$name line \$lineno";
        };
        no warnings qw(uninitialized);
        $code
        1
    };
    _error(\$@, \$lineno, \$name) if (\$@);
    return \$r;
}
EOF
}

sub _escape
{
    my ($s) = @_;
    return unless defined($s);
    return $s unless ($s =~ /[&<>'"\x80-\xff]/);
    $s =~ s/&/&amp;/g;
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    $s =~ s/'/&#39;/g;
    $s =~ s/\"/&quot;/g;
    $s =~ s/([\xc0-\xef][\x80-\xbf]+)/_make_utf8_entity($1)/ge;
    return $s;
}

sub _make_utf8_entity
{
    my ($i, @bytes) = split(//, shift());
    $i = ord($i) & ((ord($i) < 0xe0) ? 0x1f : 0x0f);
    $i = ($i << 6) + (ord($_) & 0x3f) foreach @bytes;
    return "&#$i;";
}


# ==============================================================================


sub lexer
{
    my $s = shift;
    my @buf;
    my $lexer = sub {
        while (1) {
            return ['STMT', $1] if $s =~ /\G(if|elsif|else|for|end)(?!\w)/gcx;
            return [',',    ''] if $s =~ /\G,/gc;
            return ['=>',   ''] if $s =~ /\G=>/gc;
            return ['.',    ''] if $s =~ /\G\./gc;
            return [$1,     ''] if $s =~ /\G(==|!=|<=|>=|[-=+*\/%<>!]|[{}])/gc;
            return ['do',   ''] if $s =~ /\Gdo(?!\w)/gc;
            return ['in',   ''] if $s =~ /\Gin(?!\w)/gc;
            return ['or',   ''] if $s =~ /\G(\|\||or(?!\w))/gc;
            return ['and',  ''] if $s =~ /\G(\&\&|and(?!\w))/gc;
            return ['(',    ''] if $s =~ /\G\(/gc;
            return [')',    ''] if $s =~ /\G\)/gc;
            return ['[',    ''] if $s =~ /\G\[/gc;
            return [']',    ''] if $s =~ /\G\]/gc;
            return ['NUM',  $1] if $s =~ /\G(\d+)/gc;
            return ['STR',  $2] if $s =~ /\G(['"])(.*?)\1/gc;
            return ['ID',   $1] if $s =~ /\G([A-Za-z_]\w*)/gc;
            return ['@ID',  $1] if $s =~ /\G@([A-Za-z_]\w*)/gc;
            return ['SYM',  $1] if $s =~ /\G:([A-Za-z_]\w*)/gc;
            last                if $s !~ /\G(?:\s+|#.*)/gc; 
        }
        $s =~ /\G(.*)/;
        return ['', $1];
    };
    return sub {
        if ($_[0]) {
            my $n = shift;
            push @buf, &$lexer() while (@buf < $n);
            return $buf[$n - 1];
        } else { 
            return shift(@buf) if (@buf > 0);
            return &$lexer();
        }
    };
}


1;


__DATA__

=head1 NAME

Pinwheel::View::ERB - Simple templating based on Ruby's erb syntax

=head1 SYNOPSIS

    my $src = 'Hello <%= "world" %>';

    $template = Pinwheel::View::ERB::parse_template($src);
    $template = Pinwheel::View::ERB::parse_template($src, $name);

    $result = &$template($locals, $globals, $fns);

=head1 DESCRIPTION

Pinwheel::View::ERB implements a simple subset of Ruby's erb templating syntax (as used in
.rhtml templates in Ruby on Rails).

=head1 ROUTINES

=over 4

=item C<parse_template(CONTENT)> or C<parse_template(CONTENT, NAME)>

Parse the string in CONTENT as a template, optionally associating NAME with the
result for use in error messages.  The return value is a function reference
that can be called to generate the output.

=item C<&$template(LOCALS, GLOBALS, FNS)>

Render the template (the result of C<parse_template>) and return the result as
a string.  The LOCALS and GLOBALS hashes contain the local and global
namespaces, and may be updated by the template.  The FNS hash specifies which
functions should be exposed to the template.

=back

=head1 AUTHOR

A&M Network Publishing <DLAMNetPub@bbc.co.uk>

=cut
