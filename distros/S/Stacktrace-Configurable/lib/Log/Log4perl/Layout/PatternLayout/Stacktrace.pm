package Log::Log4perl::Layout::PatternLayout::Stacktrace;

use parent 'Stacktrace::Configurable';

use strict;
use 5.01;
our $VERSION = '0.05';
use warnings;
use Log::Log4perl ();
use Log::Log4perl::Layout::PatternLayout ();

sub cspec {
    our $recursion;
    return '(recursion detected)' if $recursion;
    local $recursion=1;
    __PACKAGE__->new(format=>$_[0]->{curlies})->get_trace->as_string;
}

sub register_cspec {
    my $char = $_[0];
    Log::Log4perl::Layout::PatternLayout::add_global_cspec($char, \&cspec);
}

sub import {
    my ($module, %o) = @_;
    no warnings 'uninitialized';
    my $char = $o{-char} // $o{char} // 'S';
    register_cspec $char if length $char == 1;
}

sub skip_package_re{qr/^Log::Log4perl/}

sub default_format {
    ('env=L4P_STACKTRACE,'.
     '%[nr=1,n]b%[nr=1,s=    ==== START STACK TRACE ===]b%[nr=1,n]b'.
     '%4b[%*n] at %f line %l%[n]b'.
     '%12b%[skip_package]s %[env=L4P_STACKTRACE_A]a'.
     '%[nr!L4P_STACKTRACE_MAX,c=%n    ... %C frames cut off]b'.
     '%[nr=$,n]b%[nr=$,s=    === END STACK TRACE ===]b');
}

1;
__END__

=encoding utf-8

=head1 NAME

Log::Log4perl::Layout::PatternLayout::Stacktrace - implement %S

=head1 SYNOPSIS

 use Log::Log4perl::Layout::PatternLayout::Stacktrace;

or

 use Log::Log4perl::Layout::PatternLayout::Stacktrace -char => $letter;

or

 use Log::Log4perl::Layout::PatternLayout::Stacktrace ();
 Log::Log4perl::Layout::PatternLayout::Stacktrace::register_cspec $char

=head1 DESCRIPTION

This module is a subclass of L<Stacktrace::Configurable>. It implements
a slightly different default format and, mainly, registers the letter C<S>
(or alternatively any letter you specify as value of the C<char> or C<-char>
options to the C<import> method) as custom cspec with
L<Log::Log4perl::Layout::PatternLayout>.

If the module is C<require>d or C<use>d without calling C<import>, e.g.
C<use Log::Log4perl::Layout::PatternLayout::Stacktrace ()>, no custom
cspec is registered. You can do it later by calling

 Log::Log4perl::Layout::PatternLayout::Stacktrace::register_cspec $char

=head2 How to generate a stack trace?

The simplest way is to include C<%S> (or whatever letter you registered) in
your layout specification. This then uses the default stack trace format.

Alternatively, you can specify your own stack trace format putting it in
curlies after the C<%S> like C<%S{[%*n] %f (%l)}>. Note, the curlies
parser in L<Log::Log4perl::Layout::PatternLayout> is not smart enough to
match nesting pairs of braces. It simply matches up to the next closing
brace character.

To overcome that you may put your actual format in an environment variable
and use it in the curlies: C<%S{env=ENVVAR}>.

=head2 The default format

The default format is designed to be used in a layout pattern like this

 %m%S%n

That is, first something is printed. In this case it is the actual message,
C<%M>. Then comes the stack trace (C<%S>) followed by a newline.

The resulting output will then look like this:

 The message
     ==== START STACK TRACE ===
     [1] at t/100-l4p.t line 65
             __ANON__ (Log::Log4perl::Logger=HASH(0x17c36e0), "The message")
     [2] at t/100-l4p.t line 20
             l1 ()
     === END STACK TRACE ===

You may notice there is a newline after the message. That's part of the
default format.

The default format also allows you to silence a stack trace completely. It
checks the environment variable C<L4P_STACKTRACE>. If set to C<off>, C<no>
or C<0>, C<%S> evaluates to the empty string.

There is another environment variable, C<L4P_STACKTRACE_A>. It controls what
to do with complex data types like arrayrefs or objects.

For example, if you specify
C<L4P_STACKTRACE_A=dump=CODE,dump=ARRAY,deparse,multiline=12>
you might see this output:

 The message
     ==== START STACK TRACE ===
     [1] at t/100-l4p.t line 65
             __ANON__ (
                 Log::Log4perl::Logger=HASH(0x17c36e0),
                 "The message"
             )
     [2] at t/100-l4p.t line 20
             l1 (
                 sub {    use warnings;    use strict 'refs';    2;},
                 [1,2,3]
             )
     === END STACK TRACE ===

Look at frame #2. It does not say C<CODE(...)> as you might expect for a
subroutine parameter. Instead it deparses the function. Also, if you look at
the 2nd parameter which is an arrayref. It is dumped with L<Data::Dumper>.

The last environment variable adhered to by the default format is
C<L4P_STACKTRACE_MAX>. It limits the number of frames printed. If for instance
set to 5, then only the topmost 5 frames are printed.

See L<StackTrace::Configurable> for more information.

To be precise, the default format is this:

 'env=L4P_STACKTRACE,'.
 '%[nr=1,n]b%[nr=1,s=    ==== START STACK TRACE ===]b%[nr=1,n]b'.
 '%4b[%*n] at %f line %l%[n]b'.
 '%12b%[skip_package]s %[env=L4P_STACKTRACE_A]a'.
 '%[nr!L4P_STACKTRACE_MAX,c=%n    ... %C frames cut off]b'.
 '%[nr=$,n]b%[nr=$,s=    === END STACK TRACE ===]b'

=head2 Overloaded C<"">, tied variables etc.

Stack traces are often used in combination with exceptions. Further, in Perl
operators can be overloaded. This module uses the C<""> operator to stringify
variables. What happens if this operator is overloaded and the overloading
function itself dies triggering a new stack trace? In that case we see
infinite recursion. You might argue that stringifying code that dies is a
bug by itself and I agree. Though, it does not hurt to forbid this kind
of recursion.

So, if you see in your expected stacktrace somewhere the string
C<(recursion detected)>, that's the reason. A recursing stacktrace has been
disrupted.

=head1 AUTHOR

Torsten Förtsch E<lt>torsten.foertsch@gmx.netE<gt>

=head1 COPYRIGHT

Copyright 2014- Torsten Förtsch

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<StackTrace::Configurable>

=cut
