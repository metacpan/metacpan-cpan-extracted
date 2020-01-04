package String::Sprintf;
use strict;
use Carp;

use vars qw($VERSION);
$VERSION     = '1.001';


sub formatter {  # constructor
    my $class = shift;
    (@_ % 2) and croak "Odd number of arguments";
    my %handler = @_;
    $handler{'*'} ||= 'sprintf';   # default

    # sanity check
    my @errors;
    while(my($k, $v) = each %handler) {
        UNIVERSAL::isa($v, 'CODE')
          or !defined $v
          or $v eq 'sprintf'
          or push @errors, $k;
    }
    if(@errors) {
        my $errors = join ', ', @errors;
        my($s, $have) = @errors == 1 ? ('', 'has') : ('s', 'have');
        croak "Format$s $errors $have no CODE ref as a handler";
    }
    return bless \%handler, $class;
}

sub sprintf {
    my($self, $string, @values) = @_;
    my $i = 0;
    $string =~ s(\%(?:\%|([+\-\d.]*)([a-zA-Z]))){
      $2 ? do {
        if(ref(my $handler = $self->{$2} || $self->{'*'})) {
            $handler->($1, $values[$i++], \@values, $2);
        } else {
            CORE::sprintf("%$1$2", $values[$i++]);
        }
      } : '%'
    }ge;
    return $string;
}

42;

__END__

=encoding utf8

=head1 NAME

String::Sprintf - Custom overloading of sprintf

=head1 SYNOPSIS

    use String::Sprintf;
    my $f = String::Sprintf->formatter(
      N => sub {
        my($width, $value, $values, $letter) = @_;
        return commify(sprintf "%${width}f", $value);
      }
    );

    my $out = $f->sprintf('(%10.2N, %10.2N)', 12345678.901, 87654.321);
    print "Formatted result: $out\n";

    sub commify {
        my $n = shift;
        $n =~ s/(\.\d+)|(?<=\d)(?=(?:\d\d\d)+\b)/$1 || ','/ge;
        return $n;
    }

=head1 DESCRIPTION

How often has it happened that you wished for a format that (s)printf just doesn't support? Have you ever wished you could overload sprintf with custom formats? Well, I know I have. And this module provides a way to do just that.

=head1 USAGE

So what is a formatter? Think of it as a "thing" that contains custom settings and behaviour for C<sprintf>. Any formatting style that you don't set ("overload") falls back to the built-in keyword C<sprintf>.

You can make a minimal formatter that behaves just like C<sprintf> (and that is actually using C<sprintf> internally) with:

  # nothing custom, all default:
  my $default = String::Sprintf->formatter();
  print $default->sprintf("%%%02X\n", 35);

  # which produces the same result as:
  print sprintf("%%%02X\n", 35);   # built-in

Because of the explicit use of these formatters, you can, of course, use several different formatters at the same time, even in the same expression. That is why it's better that it doesn't actually I<really> overload the built-in C<sprintf>. Plus, it was far easier to implement this way.

The syntax used is OO Perl, though I don't really consider this as an object-oriented module. For example, I foresee no reason for subclassing, and all formatters behave differently. That's what they're for.

=head1 METHODS

=head2 class method:

=head3 formatter( 'A' => \&formatter_A, 'B' => \&formatter_B, ... )

This returns a formatter object that holds custom formatting definitions, each associated with a letter, for its method C<sprintf>. Its arguments consist of hash-like pairs of each a formatting letter (case sensitive) and a sub ref that is used for callbacks, and that is expected to return the formatted substring.

A key of C<*> is the default format definition which will be used if
no other definition matches. If you don't specify a C<*> format, the
formatter uses Perl's builtin C<sprintf>.

=head2 callback API

A callback is supposed to behave like this:

  sub callback {
      my($width, $value, $values, $letter) = @_;
      ...
      return $formatted_string;
  }

=head3 Arguments: my($width, $value, $values, $letter) = @_;

There are 4 arguments passed to the callback functions, in order of descending importance. So the more commonly used parameters come first - and yes, that's my mnemonic. They are:


=head4 $width

The part that got put between the '%' and the letter.

=head4 $value

The current value from the arguments list, the one you're supposed to format.

=head4 $values = \@value

An array ref containing the whole list of all passed arguments, in case you want to support positional indexed values by default, as is done in strftime

=head4 $letter

The letter that caused the callback to be invoked. This is only provided for the cases where you use a common callback sub, for more than one letter, so you can still distinguish between them.

=head3 return value: a string

The return value in scalar context of this sub is inserted into the final, composed result, as a string.

=head2 instance method:

=head3 sprintf($formatstring, $value1, $value2, ...)

This method inserts the values you pass to it into the formatting string, and returns the constructed string. Just like the built-in C<sprintf> does.

If you're using formatting letters that are I<not> provided when you built the formatter, then it will fall back to the native formatter: L<perlfunc/sprintf>. So you need only to provide formatters for which you're not happy with the built-ins.

=head1 EXPORTS

Nothing. What did you expect?

=head1 TODO

=over 4

=item * overload strftime too

=item * proper support for position indexed values, like C<"%2$03X">

=back


=head1 SEE ALSO

L<perlfunc/sprintf>, sprintf(3), L<POSIX/strftime>

=head1 BUGS

You tell me...?

=head1 SUPPORT

Currently maintained by brian d foy C<< <bdfoy@cpan.org> >> and hosted
on GitHub (https://github.com/briandfoy/string-sprintf).

=head1 AUTHOR

    Bart Lateur
    CPAN ID: BARTL
    Me at home, eating a hotdog
    bart.lateur@pandora.be
    L<http://perlmonks.org/?node=bart>
    L<http://users.pandora.be/bartl/>

=head1 REPOSITORY

L<https://github.com/briandfoy/string-sprintf>

=head1 LICENSE AND COPYRIGHT

(c) Bart Lateur 2006.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

My personal terms are like this: you can do whatever you want with this software: bundle it with any software, be it for free, released under the GPL, or commercial; you may redistribute it by itself, fix bugs, add features, and redistribute the modified copy. I would appreciate being informed in case you do the latter.

What you may not do, is sell the software, as a standalone product.
