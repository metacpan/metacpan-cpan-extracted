package Stacktrace::Configurable;

use strict;
use 5.01;
our $VERSION = '0.06';

use Stacktrace::Configurable::Frame;

use Scalar::Util qw/looks_like_number/;
use Data::Dumper ();
no warnings 'uninitialized';    ## no critic

our @attr;

BEGIN {
    @attr=(qw/format frames/);
    for (@attr) {
        my $attr=$_;
        no strict 'refs';
        *{__PACKAGE__.'::'.$attr}=sub : lvalue {
            my $I=$_[0];
            $I->{$attr}=$_[1] if @_>1;
            $I->{$attr};
        };
    }
}

sub skip_package_re {}
sub skip_package_number {1}

sub default_format {
    ('env=STACKTRACE_CONFIG,'.
     '%[nr=1,s=    ==== START STACK TRACE ===]b%[nr=1,n]b'.
     '%4b[%*n] at %f line %l%[n]b'.
     '%12b%[skip_package]s %[env=STACKTRACE_CONFIG_A]a'.
     '%[nr!STACKTRACE_CONFIG_MAX,c=%n    ... %C frames cut off]b'.
     '%[nr=$,n]b%[nr=$,s=    === END STACK TRACE ===]b%[nr=$,n]b');
}

sub get_trace {
    my $I=shift;

    my $i=$I->skip_package_number;
    my $skip_re=$I->skip_package_re;

    my $nr=1;

    my @trace;
    while (my @l=do {
        package
            DB;
        @DB::args=();
        CORE::caller $i++;
    }) {
        next if !@trace and $skip_re and $l[0]=~$skip_re;
        push @trace, Stacktrace::Configurable::Frame->new(@l, $nr++,
                                                          [@DB::args]);
    }

    $I->{frames}=\@trace;
    return $I;
}

sub new {
    my $class = shift;
    $class = ref($class)||$class;

    my $I = bless {}=>$class;
    for (my $i = 0; $i<@_; $ i+= 2) {
        my $m = $_[$i];
        $I->$m($_[$i+1]);
    }

    $I->{format} ||= $I->default_format;

    return $I;
}

sub _use_dumper {
    my $p = $_[0];
    return 0 if looks_like_number $_;
    ref and return $p->{dump} || $p->{pkg_dump}->{ref()} || do {
        my $arg = $_;
        !!map({ref($arg) =~ /$_/} @{$p->{pkg_dump_re}});
    };
    return 1;
}

sub fmt_b {                     # space & control
    my ($I, $frame, $width, $param) = @_;
    my $nr = $frame->{nr};
    $width //= 1;
    my $cutoff;
    if ($param =~ s/^nr!(\d+),//) {
        return '' unless $nr == $1;
        $cutoff = @{$I->{frames}} - $nr;
        $#{$I->{frames}} = $nr - 1;
    } elsif ($param =~ s/^nr!(\w+),//) {
        return '' unless length $ENV{$1} and $nr == $ENV{$1};
        $cutoff = @{$I->{frames}} - $nr;
        $#{$I->{frames}} = $nr - 1;
    } elsif ($param =~ s/^nr%(\d+)(?:=(\d+))?,//) {
        return '' unless $nr % $1 == ($2//0);
    } elsif ($param =~ s/^nr=(\d+|\$),//) {
        if ($1 eq '$') {
            return '' unless $nr == @{$I->{frames}};
        } else {
            return '' unless $nr == $1;
        }
    }

    if ($param =~ s/^c=//) {
        return '' if $cutoff <= 0;
        $param =~ s/%([Cn])/$1 eq 'C' ? $cutoff : "\n"/ge;
        return $param x $width;
    } elsif ($param =~ s/^s=//) {
        return $param x $width;
    } else {
        return +($param eq 'n'
                 ? "\n"
                 : $param eq 't'
                 ? "\t"
                 : ' ') x $width;
    }
}

sub fmt_n {                     # frame number
    my ($I, $frame, $width, $param) = @_;
    if ($width eq '*') {
        $width = length '' . (0 + @{$I->{frames}});
    } elsif ($width eq '-*') {
        $width = -length '' . (0 + @{$I->{frames}});
    }
    return sprintf "%${width}d", $frame->{nr};
}

sub fmt_s {                     # subroutine
    my ($I, $frame, $width, $param) = @_;
    if (my $eval = $frame->{evaltext}) {
        return "require $eval" if $frame->{is_require};
        $eval =~ s/([\\\'])/\\$1/g;
        return "eval '$eval'";
    }
    my $s = $frame->{subroutine};

    for (split /,\s*/, $param) {
        last if s/^skip_package// and $s =~ s!^.*::!!;
    }
    return $s;
}

sub fmt_a {                     # args
    my ($I, $frame, $width, $param) = @_;
    return '' unless $frame->{hasargs};
    my @param = split /,\s*/, $param;
    my %p;
    my @ml;
    for (@param) {
        ## no critic
        $p{dump} = 1,                          next if /^dump$/;
        $p{pkg_dump}->{$1} = 1,                next if m~^dump=(?!/)(.+)$~;
        push(@{$p{pkg_dump_re}}, $1),          next if m~^dump=/(.+)/$~;
        push(@param, split /,\s*/, $ENV{$1}),  next if /^env=(.+)/;
        $p{deparse} = 1,                       next if /^deparse$/;
        @ml = ($1||4, $2||4),                  next if m~^multiline(?:=(\d+)(?:\.(\d+))?)?$~;
    }
    if (@ml) {
        return "(\n".join(",\n", map {(' 'x($ml[0]+$ml[1])).$_} map {
            (!defined $_
             ? "undef"
             : _use_dumper (\%p)
             ? Data::Dumper->new([$_])->Useqq(1)->Deparse($p{deparse} || 0)
                           ->Indent(0)->Terse(1)->Dump
             : "$_");
        } @{$frame->{args}})."\n".(' 'x$ml[0]).")";
    } else {
        return '('.join(', ', map {
            (!defined $_
             ? "undef"
             : _use_dumper (\%p)
             ? Data::Dumper->new([$_])->Useqq(1)->Deparse($p{deparse} || 0)
                           ->Indent(0)->Terse(1)->Dump
             : "$_");
        } @{$frame->{args}}).')';
    }
}

sub fmt_f {                     # filename
    my ($I, $frame, $width, $param) = @_;
    my $fn = $frame->{filename};
    for (split /,\s*/, $param) {
        last if s/^skip_prefix=// and $fn =~ s!^\Q$_\E!!;
        last if s/^basename$// and $fn =~ s!^.*/!!;
    }
    return substr($fn, 0, $width) . '...' if $width > 0 and length $fn > $width;
    return '...' . substr($fn, $width) if $width < 0 and length $fn > -$width;
    return $fn;
}

sub fmt_l {                     # linenr
    my ($I, $frame, $width, $param) = @_;
    return sprintf "%${width}d", $frame->{line};
}

sub fmt_c {                     # context (void/scalar/list)
    my ($I, $frame, $width, $param) = @_;
    return (!defined $frame->{wantarray}
            ? 'void'
            : $frame->{wantarray}
            ? 'list'
            : 'scalar');
}

sub fmt_p {                     # package
    my ($I, $frame, $width, $param) = @_;
    my $pn = $frame->{package};
    for (split /,\s*/, $param) {
        last if s/^skip_prefix=// and $pn =~ s!^\Q$_\E!!;
    }
    return substr($pn, 0, $width) . '...' if $width > 0 and length $pn > $width;
    return '...' . substr($pn, $width) if $width < 0 and length $pn > -$width;
    return $pn;
}

sub as_string {
    my $I = shift;
    my $fmt = $I->{format};

    my %seen;
    while ($fmt =~ s/^env=(\w+)(,|$)//) {
        my $var = $1;
        return '' if $ENV{$var}=~/^(?:off|no|0)$/i;

        undef $seen{$var};
        unless (length $fmt) {
            $fmt = $ENV{$var} || $I->default_format;
            $fmt =~ /^env=(\w+)(,|$)/ and exists $seen{$1} and
                $fmt = 'format cycle detected';
        }
    }

    local $@;
    local $SIG{__DIE__};

    my $s = '';
    for my $frame (@{$I->{frames}}) {
        my $l = $fmt;
        $l =~ s/
                   %                         # leading %
                   (?:
                       (%)
                   |
                       (-?(?:\d+|\*))?       # width
                       (?:\[(.+?)\])?        # modifiers
                       ([bnasflcp])          # placeholder
                   )
               /$1 ? $1 : do {my $m="fmt_$4"; $I->$m($frame, $2, $3)}/gex;
        $s .= $l."\n";
    }
    chomp $s;

    return $s;
}

1;
__END__

=encoding utf-8

=head1 NAME

Stacktrace::Configurable - a configurable Perl stack trace

=head1 SYNOPSIS

 use Stacktrace::Configurable;

 Stacktrace::Configurable->new(format=>$fmt)->get_trace->as_string;

=head1 DESCRIPTION

The idea for C<Stacktrace::Configurable> came when I needed a easily readable
stack trace in L<Log::Log4perl> output. That distribution's pattern layout
can give you a stack trace but it's not very readable. There are other
modules out there that provide a caller stack, like L<Devel::StackTrace>
and L<Carp>. Choose what suits you best.

A stack trace is basically a list of stack frames starting with the place
where the L<< get_trace|/$obj->get_trace >> method is called down to the main
program. The first element in that list is also called the topmost frame.

Each frame of the list collected by L<< get_trace|/$obj->get_trace >> is a
L<Stacktrace::Configurable::Frame> object which provides simple
accessors for the information returned by C<caller>. Additionally,
a frame has a L<Stacktrace::Configurable::Frame/nr> attribute which
contains its position in the list starting from C<1> (topmost).

=head2 Constructor

The constructor C<< Stacktrace::Configurable->new >> is called with a
list of key/value pairs as parameters. After constructing an empty object
it uses each of those keys as method name and calls it passing the
value as parameter.

Example:

 $trace=Stacktrace::Configurable->new(format=>$fmt);

=head2 Attributes

Attributes are simple accessor methods that provide access to scalar
variables stored in the object. If called with a parameter the new value
is stored. The return value is always the new or current value.

These attributes are implemented:

=over 4

=item format

the format specification, see L<below|/Format>

=item frames

the stack trace. It is an arrayref of L<Stacktrace::Configurable::Frame>
objects usually initialized by the L<< get_trace|/$obj->get_trace >> method.

=back

=head2 Public Methods

=over 4

=item $obj->get_trace

collects the stack trace with the caller of C<get_trace> as the topmost
frame and stores it as C<< $obj->frames >>.

Returns the object itself to allow for chained calls like

 $obj->get_trace->as_string;

=item $obj->as_string

formats the stack trace according to the current format and returns
the resulting string.

=back

=head2 Methods interesting for subclassing

=over 4

=item $obj->skip_package_re

returns the empty list. If overwritten by subclasses, it should return
a regular expression matching package names which is used to skip stack
frames from the top of the stack. C<get_trace> starts to collect stack
frames from the top of the stack. If C<skip_package_re> returns a regexp,
it drops those frames as long as their C<package> matches the regexp.
Once a non-matching package is discovered all remaining frames are
included in the trace no matter what C<package>.

This allows you to skip frames internal to your subclass from the top
of the stack if you are not sure of the nesting level at which
C<get_trace> is called.

=item $obj->skip_package_number

Similar to C<skip_package_re>, only it specifies the actual nesting level.
For the base class (C<Stacktrace::Configurable>) 1 is returned.

=item $obj->default_format

this method returns a constant that is used by the constructor to
initialize the C<format> attribute if omitted.

The current default format is:

 'env=STACKTRACE_CONFIG,'.
 '%[nr=1,s=    ==== START STACK TRACE ===]b%[nr=1,n]b'.
 '%4b[%*n] at %f line %l%[n]b'.
 '%12b%[skip_package]s %[env=STACKTRACE_CONFIG_A]a'.
 '%[nr!STACKTRACE_CONFIG_MAX,c=%n    ... %C frames cut off]b'.
 '%[nr=$,n]b%[nr=$,s=    === END STACK TRACE ===]b%[nr=$,n]b'

=item $obj->fmt_b

=item $obj->fmt_n

=item $obj->fmt_s

=item $obj->fmt_a

=item $obj->fmt_f

=item $obj->fmt_l

=item $obj->fmt_c

=item $obj->fmt_p

these methods format a certain portion of a stack frame. They are called
as methods. So, the first parameter is the object itself. The following
parameters are:

=over 4

=item $frame

the frame to format

=item $width

the width part of the format specification

=item $param

the param part of the format specification

=back

Return value: the formatted string

=back

=head2 Private Methods

=over 4

=item $obj->_use_dumper

=back

=head2 Format

The format used by L<Stacktrace::Configurable> is inspired by C<printf> and
L<Log::Log4perl::Layout::PatternLayout>.

The first format component is an optional string starting with C<env=> and
ending in a comma, like

 env=STACKTRACE_CONFIG,

If this component is found C<as_string> consults the specified environment
variable for instructions. If the variable is C<off>, C<no> or C<0>, no
stack trace at all is created and C<as_string> returns the empty string.

If after stripping of that first component, the format becomes the empty
string the value of the environment variable or, if also empty, the
default format is used as format specification.

The rest of the format is a string with embedded format specifications or
I<fspec>. An fspec starts with a percent sign, C<%>. Then follows an
optional width component, an optional parameter component and the
mandatory format letter.

The width component is just an integer number optionally prepended with
a minus sign or an asterisk (C<*>). Not every fspec uses the width
component or does something useful for C<*>.

The parameter component is surrounded by brackets (C<[]>).

The parsing of an fspec is kept simple. So, it does not support nested
brackets or similar.

The following format letters are implemented:

=over 4

=item b

Originally the name C<b> was chosen because C<s> was already in use. It
stands for I<blank> or empty space. Though, it can generate arbitrary
output and be based on conditions.

The simplest form C<%b> just outputs one space. Add a width component,
C<%20b> and you get 20 spaces.

The parameter component is a set of 2 optional items separated by
comma. The first item specifies a condition. The second modifies the
string used in place of the space.

Let's first look at examples where the condition part is omitted. The
C<n> parameter tells to use a newline instead of a space. So,
C<%20[n]b> inserts 20 newline characters. The parameter C<t> does the
same only that a tabulator character is used. C<%20[t]b> results in
20 tabs. The 3rd option is the C<s=> parameter. It allows you to
specify arbitrary strings. C<%4[s=ab]b> results in

 abababab

Now, let's look at conditional output. The C<nr=> parameter matches a
specific stack frame given by its number. It is most useful at the start
and the end of the stack trace.

Examples:

 %[nr=1,s=stack trace start]b

if given at the beginning of the format, this specification prints the
string C<stack trace start> but only for the topmost frame.

 %[nr=$,s=stack trace end]b

C<nr=$> matches only for the last stack frame. So, the fspec above prints
C<stack trace end> at the end of the trace.

The C<nr!> condition also matches a specific frame given by its number.
But in addition to generate output it cuts off the trace after the
current frame. It is used if you want to print only the topmost N frames.
It is often used with the empty string as what to print, like

 %[nr!10,s=]b

This prints nothing but cuts off the stack trace after the 10th frame.

If the part after the exclamation mark is not a number but matches C<\w+>,
it is taken as the name of an environment variable. If set and if it is a
number, that number is taken instead of the literal number above.

In combination with this condition there is another parameter to specify
the string, C<c=> or the cutoff message. It is printed only if there has
been cut off at least one frame. Also, the cutoff message can contain C<%n>
and C<%C> (capital C). The former is replaced by a newline, the latter by
the number of frames cut off.

This allows for the following pattern:

 %[nr!MAX,c=%ncutting off remaining %C frames]n

Now, let's assume C<$ENV{MAX}=4> but the actual stack is 20 frames deep.
The specification tells to insert an additional newline for the 4th frame
followed by the string C<cutting off remaining 16 frames>.

The last condition is C<nr%N> and C<nr%N=M>. It can be used to insert a
special delimiter after every N stack frames.

 %[nr%10=1,n]b%80[nr%10=1,s==]b

prints a delimiter consisting of a newline and 80 equal signs after
every 10th frame.

The condition is true if C<frame_number % M == N> where N defaults to 0.

=item n

inserts the frame number. This format ignores the parameter component.
Width can be given as positive or negative number an is interpreted just
like in C<sprintf>. If width is C<*> or C<-*>, the actual width is taken
to fit the largest frame number.

Examples:

 %n
 %4n
 %-4n
 %*n
 %-*n

=item s

inserts the subroutine. The width component is ignored and only one
parameter is known, C<skip_package>. If specified, the package where the
function belongs to is omitted.

Examples:

 %s                   # might print "Pack::Age::fun"
 %[skip_package]s     # prints only "fun"

=item a

inserts the subroutine arguments. The width component is ignored. The
parameter component is a comma separated list of

=over 4

=item dump

all arguments are dumped using L<Data::Dumper>. The dumper object is
configured in a way to print the whole thing in one line.

This may cause very verbose stack traces.

=item dump=Pack::Age

all arguments for which C<ref> returns C<Pack::Age> are dumped using
L<Data::Dumper>.

You can, of course, also dump simple ARRAYs, HASHes etc.

=item dump=/regexp/

all arguments for which C<ref> matches the regexp are dumped using
L<Data::Dumper>.

If multiple such parameters are given, an argument that matches at least
one regexp is dumped.

=item deparse

if C<dump> or C<dump=CODE> is also specified, the dumper object is
configured to deparse the subroutine that is passed in the argument.

=item multiline

=item multiline=N

=item multiline=N.M

normally, all arguments are printed in one line separated by comma and space.
With this parameter every argument is printed on a separate line.

A format containing C<%s %[multiline]a> would for instance generate this
output:

 main::function (
         "param1",
         2,
         "p3"
     )

The surrounding parentheses are part of the C<%a> output.

C<N> and C<M> are indentation specifications. C<N> tells how many positions
the closing parenthesis is indented. C<M> tells how many positions further
each parameter is indented. The default value for both is 4.

=item env=ENVVAR

This parameter reads the environment variable C<ENVVAR> and appends it to
the parameter list.

=back

Examples:

 %[dump,deparse,multiline]a    # very verbose

=item f

inserts the file name. This fspec recognizes the following parameters:

=over 4

=item skip_prefix=PREFIX

if the file name of the stack frame begins with C<PREFIX>, it is cut off.

For instance, if your personal Perl modules are installed in
F</usr/local/perl>, then you might specify

 %[skip_prefix=/usr/local/perl/]f

=item basename

cuts off the directory part of the file name.

If a width component is specified and the file name is longer than the
absolute value of the given width, then if the width is positive, the
file name is cut at the end to meet the given width. If the width is
negative, the file name is cut at the start to meet the width. Then
an ellipsis (3 dots) is appended or prepended.

=back

=item l

inserts the line number. The width component is interpreted like in
C<sprintf>.

=item c

prints the context of the subroutine call as C<void>, C<scalar> or C<list>.

=item p

prints the package name of the stack frame.

The C<%p> fspec recognizes the C<skip_prefix> parameter just like C<%f>.

The width component is also interpreted the same way as for C<%f>.

=back

Examples:

 env=T,%f(%l)   # one line of "filename.pm(23)" for each frame
                # unless $ENV{T} is "off", "no" or "0"

 env=T,         # use the format given in $ENV{T}
                # unless $ENV{T} is "off", "no" or "0"

=head2 Subclassing

TODO

=head1 AUTHOR

Torsten Förtsch E<lt>torsten.foertsch@gmx.netE<gt>

=head1 COPYRIGHT

Copyright 2014- Torsten Förtsch

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Carp>, L<Devel::StackTrace>,
L<Log::Log4perl::Layout::PatternLayout::Stacktrace>

=cut
