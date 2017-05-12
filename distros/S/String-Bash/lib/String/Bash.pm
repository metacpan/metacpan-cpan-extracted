use strict;
use warnings;
package String::Bash;
BEGIN {
  $String::Bash::AUTHORITY = 'cpan:AJGB';
}
BEGIN {
  $String::Bash::VERSION = '1.110960';
}
#ABSTRACT: Parameter expansion in strings

use Sub::Exporter -setup => {
    exports => [qw( bash )],
};

use Regexp::Common qw( balanced );
use PadWalker qw( peek_my peek_our );
use Scalar::Util qw( blessed );



sub bash($@) {
    my $format = shift;

    my $lookup;
    my $setter;

    if ( defined $_[0] ) {
        if ( blessed $_[0] ) {
            my $obj = $_[0];
            $lookup = sub { my $var = shift; return $obj->$var; };
            $setter = sub { my $var = shift; $obj->$var(@_); };
        } else {
            if ( @_ == 1 && ref $_[0] eq 'HASH' ) {
                my $href = $_[0];
                $lookup = sub { return $href->{ $_[0] }; };
                $setter = sub { $href->{ $_[0] } = $_[1]; };
            } else {
                my %vars = @_;
                $lookup = sub { return $vars{ $_[0] }; };
                $setter = sub { $vars{ $_[0] } = $_[1]; };
            }
        }
    } else {

        my $allmyvars = peek_my(1);
        my $allourvars = peek_our(1);

        $lookup = sub {
            my $var = shift;
            $var = "\$$var";
            my $val = exists $allmyvars->{$var}
                ? $allmyvars->{$var} : $allourvars->{$var};

            return unless ref $val eq 'SCALAR';

            return ${ $val };
        };
        $setter = sub {
            my $var = shift;
            my $val = shift;
            $var = "\$$var";

            if ( exists $allmyvars->{$var} ) {
                ${ $allmyvars->{$var} } = $val;
            } elsif ( exists $allourvars->{$var} ) {
                ${ $allourvars->{$var} } = $val;
            }
        };
    };

    my $parser; $parser = sub {
        my $format = shift;

        return $format unless index($format, '%{') >= 0;

        my @ph = $format =~ /$RE{balanced}{-begin=>'%{'}{-end=>'}'}/gs;

        for my $e ( @ph ) {
            my $p = substr( $e, 2, -1);
            my $rep;
            if ( substr($p,0,1) eq '#' ) {
                my $name = substr($p, 1);
                my $val = $lookup->($name) || '';

                $rep = length($val);
            } elsif ( $p =~ /\A(\w+)(?:([:#%\/\^,])(.*))?\z/) {
                my ($name, $op, $reminder) = ($1, $2, $3);
                my $val = $lookup->($name);

                FINDREP: {
                    if ( ! $op ) { # %{param}
                        $rep = $val || '';
                        last FINDREP;
                    }
                    # expand reminder
                    $reminder = $parser->($reminder)
                        if index($reminder, '%{') >= 0;

                    if ( $op eq ':' ) {
                        my $control = substr($reminder, 0, 1);
                        if ( $reminder =~ /^\d+/ ) {
                            if ( $val ) {
                                my ($offset, $limit) = split(':', $reminder, 2);
                                if ( $limit ) {
                                    $rep = substr($val, $offset, $limit);
                                } else {
                                    $rep = substr($val, $offset);
                                };

                                last FINDREP;
                            };
                        };

                        if ( $control eq '+' ) {
                            if ( defined $val ) {
                                $rep = substr($reminder, 1);
                            } else {
                                $rep = '';
                            };
                            last FINDREP;
                        };


                        if ( defined $val ) {
                            $rep = $val || '';
                            last FINDREP;
                        } else {
                            if ( $control eq '-' ) {
                                $rep = substr($reminder, 1);
                            } elsif ( $control eq '=' ) {
                                $rep = substr($reminder, 1);
                                $setter->( $name, $rep );
                            }
                        };
                    } elsif ( $op eq '#' ) {
                        if ( $val ) {
                            my $control = substr($reminder, 0, 1);
                            my $qr = "^";

                            if ( $control eq '#' ) { # %{param##qr}
                                $reminder = substr( $reminder, 1);
                                $reminder =~ s/\*/\.*/g;
                                $reminder =~ s/\?/\./g;
                            } else {
                                $reminder =~ s/\?/\./g;
                                $reminder =~ s/\*/\.*?/g;
                            }

                            $qr .= $reminder;
                            ($rep = $val) =~ s/$qr//;
                        }
                    } elsif ( $op eq '%' ) {
                        if ( $val ) {
                            my $control = substr($reminder, 0, 1);
                            my $qr;
                            my $replacement = '';

                            if ( $control eq '%' ) { # %{param%%qr}
                                $qr = substr( $reminder, 1);
                                $qr =~ s/\*/\.*/g;
                            } else {
                                $replacement = substr($reminder, 0, index($reminder, '*'));
                                ($qr = $reminder) =~ s/\*/\.*?/g;
                            }
                            $qr =~ s/\?/\./g;

                            $qr = "$qr\$";
                            ($rep = $val) =~ s/$qr/$replacement/;
                        }
                    } elsif ( $op eq '/' ) {
                        if ( $val ) {
                            my $control = substr($reminder, 0, 1);
                            my ($search, $replacement);
                            if ( $control eq '/' ) { # %{param//search/replacement}
                                ($search, $replacement) = split('/', substr($reminder, 1) );
                                $search =~ s/\*/\.*?/g;
                                $search =~ s/\?/\./g;
                                $replacement ||= '';

                                ($rep = $val) =~ s/$search/$replacement/g;
                            } elsif ( $control eq '#' ) { # %{param/#search/replacement}
                                ($search, $replacement) = split('/', substr($reminder, 1) );
                                $search =~ s/\*/\.*?/g;
                                $search =~ s/\?/\./g;
                                $replacement ||= '';

                                ($rep = $val) =~ s/^$search/$replacement/;
                            } elsif ( $control eq '%' ) { # %{param/%search/replacement}
                                ($search, $replacement) = split('/', substr($reminder, 1) );
                                $search =~ s/\*/\.*?/g;
                                $search =~ s/\?/\./g;
                                $replacement ||= '';

                                ($rep = $val) =~ s/$search$/$replacement/;
                            } else {
                                ($search, $replacement) = split('/', $reminder);
                                $search =~ s/\*/\.*?/g;
                                $search =~ s/\?/\./g;
                                $replacement ||= '';

                                ($rep = $val) =~ s/$search/$replacement/;
                            }
                        }
                    } elsif ( $op eq '^' ) {
                        if ( $val ) {
                            my $control = substr($reminder, 0, 1);

                            if ( $control eq '^' ) { # %{param^^}
                                if ( $reminder eq '^' || $reminder eq '^?' ) {
                                    $rep = uc $val;
                                } else {
                                    my $matching = substr($reminder, 1);
                                    ($rep = $val) =~ s/($matching)/\u$1/g;
                                }
                            } else {
                                if ( length $reminder && $reminder ne '?' ) {
                                    ($rep = $val) =~ s/^($reminder)/\u$1/;
                                } else {
                                    $rep = ucfirst $val;
                                }
                            }
                        }
                    } elsif ( $op eq ',' ) {
                        if ( $val ) {
                            my $control = substr($reminder, 0, 1);

                            if ( $control eq ',' ) { # %{param,,}
                                if ( $reminder eq ',' || $reminder eq ',?' ) {
                                    $rep = lc $val;
                                } else {
                                    my $matching = substr($reminder, 1);
                                    ($rep = $val) =~ s/($matching)/\l$1/g;
                                }
                            } else {
                                if ( length $reminder && $reminder ne '?' ) {
                                    ($rep = $val) =~ s/^($reminder)/\l$1/;
                                } else {
                                    $rep = lcfirst $val;
                                }
                            }
                        }
                    };
                };
            };

            $rep = '' unless defined $rep;
            $format =~ s/\Q$e\E/$rep/g;
        };

        return $format;
    };

    my $result = $parser->( $format );

    return $result;
}


1;

__END__
=pod

=encoding utf-8

=head1 NAME

String::Bash - Parameter expansion in strings

=head1 VERSION

version 1.110960

=head1 SYNOPSIS

    use String::Bash qw( bash );

    # pass hashref
    print bash "Hello %{name:-Guest}!", { name => 'Alex' };

    # or key/value pairs
    print bash "Hello %{name:-Guest}!", name => 'Alex';

    # or object which can('name');
    my $user = My::Users->new( name => 'Alex' );
    print bash "Hello %{name:-Guest}!", $user;

    # or use lexical vars
    my $name = 'Alex';
    print bash "Hello %{name:-Guest}!";

all will print

    Hello Alex

or if I<name> is undefined or empty

    Hello Guest

=head1 DESCRIPTION

L<String::Bash> is based on shell parameter expansion from
L<Bash|http://www.gnu.org/software/bash/>, thus it allows to provide default
values, substrings and in-place substitutions, changing case of characters and
nesting.

The L<String::Bash> provides C<bash> exported with L<Sub::Exporter>.

=head1 REPLACEMENT VALUES

Replacements can be provided in four different ways:

=head2 Hash reference

    my $hashref = { param1 => 'value1', ... };
    print bash $format, $hashref;

=head2 KeyE<sol>value pairs

    print bash $format, param1 => 'value1', ...;

=head2 Object

    print bash $format, $object;

Please note that C<$object> needs to implement I<readE<sol>write> accessors (if
L<"%{param:=word}"> is used, otherwise I<read-only> are sufficient) for all
parameters used in C<$format>.

=head2 Lexical variables

    my $param1 = ...;
    our $param2 = ...;
    print bash $format;

Lexical (C<my>) and package (C<our>) scalar variables visible at the scope of
C<bash> caller are available as replacement.

=head1 FORMAT SYNTAX

Please assume that following variables are visible in below examples:

    my $param = 'hello';
    my $not_set;
    my $param2 = 'WELCOME';

=head2 %{param}

    print bash "%{param}"; # hello

Value of C<$param> is substituted.

=head2 %{param:-word}

    print bash "%{param:-word}";    # hello
    print bash "%{not_set:-word}";  # word

If C<$param> is unset or null, the expansion of I<word> is substituted.
Otherwise, the value of C<$param> is substituted.

The I<word> can be another parameter so nesting is possible:

    print bash "%{not_set:-%{param2}}"; # WELCOME

=head2 %{param:=word}

    print bash "%{not_set:=word}"; # word

If C<$param> is unset or null, the expansion of I<word> is assigned to
C<$param>. The value of C<$param> is then substituted.

Notes on replacement syntax:

=over 4

=item *

If L<"Object"> is passed as replacement than assignment will execute following
code:

    $obj->$param( 'word' );

=item *

If L<"KeyE<sol>value pairs"> are passed as replacement then the assignment
will be applied to occurrences of I<param> after the assignment has been done,
and will be disregarded after parsing is done.

=item *

If L<"Lexical variables"> are used, then their value will be set to I<word>.

=back

=head2 %{param:+word}

    print bash "%{param:+word}";   # word
    print bash "%{not_set:+word}"; #

If C<$param> is null or unset, nothing is substituted, otherwise the expansion
of I<word> is substituted.

=head2 %{param:offset}

=head2 %{param:offset:length}

    print bash "%{param:2}";     # llo
    print bash "%{param:2:2}";   # ll

Expands to up to I<length> characters of C<$param> starting at the character
specified by I<offset>. If I<length> is omitted, expands to the substring of
C<$param> starting at the character specified by I<offset>.

=head2 %{#param}

    print bash "%{#param}";   # 5

The length in characters of the value of C<$param> is substituted.

=head2 %{param#word}

=head2 %{param##word}

    print bash "%{param#he*l}";   # lo
    print bash "%{param##he*l}";  # o

The I<word> is expanded to produce a pattern (see L<"Pattern expansion">). If
the pattern matches the beginning of the value of C<$param>, then the result
of the expansion is the expanded value of C<$param> with the shortest matching
pattern (the I<'#'> case) or the longest matching pattern (the I<'##'> case)
deleted.

=head2 %{param%word}

=head2 %{param%%word}

    print bash "%{param%l*o}";   # hel
    print bash "%{param%%l*o}";  # he

The I<word> is expanded to produce a pattern (see L<"Pattern expansion">). If
the I<pattern> matches a trailing portion of the value of C<$param>, then the
result of the expansion is the value of C<$param> with the shortest matching
pattern (the I<'%'> case) or the longest matching pattern (the I<'%%'> case)
deleted.

=head2 %{param/pattern/string}

    print bash "%{param/l/t}";   # hetlo
    print bash "%{param//l/t}";  # hetto
    print bash "%{param/#h/t}";  # tello
    print bash "%{param/%o/t}";  # hellt

The I<pattern> is expanded to produce a pattern (see L<"Pattern expansion">).
The longest match of I<pattern> against C<$param> value is replaced with
I<string>. If I<pattern> begins with I<'/'>, all matches of I<pattern> are
replaced with I<string>. Normally only the first match is replaced.
If I<pattern> begins with I<'#'>, it must match at the beginning of the
value of C<$param>. If I<pattern> begins with I<'%'>, it must match at the end
of the C<$param>. If I<string> is null, matches of I<pattern> are deleted and
the I</> following I<pattern> may be omitted.

=head2 %{param^pattern}

=head2 %{param^^pattern}

=head2 %{param,pattern}

=head2 %{param,,pattern}

    print bash "%{param^}";     # Hello
    print bash "%{param^^}";    # HELLO
    print bash "%{param2,}";    # wELCOME
    print bash "%{param2,,}";   # welcome

    print bash "%{param^[hl]}";     # Hello
    print bash "%{param^^[hl]}";    # HeLLo
    print bash "%{param2,[WE]}";    # wELCOME
    print bash "%{param2,,[WE]}";   # weLCOMe

This expansion modifies the case of alphabetic characters in C<$param>. The
I<pattern> is expanded to produce a pattern (see L<"Pattern expansion">). The
I<'^'> operator converts lowercase letters matching pattern to uppercase; the
I<','> operator converts matching uppercase letters to lowercase. The I<'^^'>
and I<',,'> expansions convert each matched character in C<$param>; the I<'^'>
and I<','> expansions match and convert only the first character in the
value of C<$param>. If I<pattern> is omitted, it is treated like a I<'?'>, which
matches every character.

=head1 NOTES

=head2 Pattern expansion

Pattern expansion is performed using following rules (based on filename
expansion):

    # Character       # Replacement (perl syntax)
    *                 .*
    ?                 .
    [a-z]             [a-z]

Please do not use perl regular expression syntax in pattern substitutions, or
you may get unexpected results.

=head1 COMPATIBILITY WITH BASH

L<String::Bash> provides only syntax described above and some of Bash features
(like expansions of arrays) are not available - but please let me know if you
need them.

=for Pod::Coverage     bash

=head1 SEE ALSO

=over 4

=item *

L<Shell Parameter Expansion in Bash|http://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html#Shell-Parameter-Expansion>

=back

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

