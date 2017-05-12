package Perl6::Placeholders;

use Filter::Simple;

our $VERSION = '0.07';

my %giftwrap = (
        'sort' => sub {"{$_[0]\->(\$a,\$b)}"},
        'grep' => sub {"{$_[0]\->(\$_)}"},
        'map'  => sub {"{$_[0]\->(\$_)}"},
        'sub'  => sub {$_[0]},
        ''     => sub {$_[0]},
);

use re 'eval';
our $code        = qr{ (?: [^{}]+ | \{ (??{ $code }) \} )* }x;
our $placeholder = qr{ (?: $code (?: (??{ $carvar }) $code ) )+ }x;
our $carvar      = qr{ (?: \$\w+ (?:
                        (?:->)?  (?:\[$placeholder\]|\{$placeholder\}) )+
                       | \$\^\w+
                       )
                     }x;

FILTER_ONLY 
        executable => sub {
                        s<(sub|sort|map|grep)?\s*(?=.*\$\^\w)\{($placeholder)\}> {
                                my ($context,$code) = ($1||"",$2);
                                my %vars;
                                @vars{$code =~ m/(\$\^\w+)/g} = ();
                                my $vars = join ',', sort keys %vars;
                                my $decl = qq{my($vars)=\@_;};
                                $decl = "" if $code =~ /\Q$decl/;
                                $code = qq{ sub {$decl $code } }; 
                                $code =~ s/\$\^(\w+)/\$$1/g;
                                "$context ". $giftwrap{$context}($code);
                        }ge;
                },

__END__

=head1 NAME

Perl6::Placeholders - Perl 6 implicitly declared parameters for Perl 5

=head1 VERSION

This document describes version 0.06 of Perl6::Placeholders,
released October 7, 2005.

=head1 SYNOPSIS

        use Perl6::Placeholders;

        my $add = { $^a + $^b };        # Create a sub that adds its two args

        print $add->(1,2), "\n";        # Call it

        # Use as map, grep, and sort blocks
        print join ",", sort { $^y <=> $^x } 1..10;
        print join "\n", map { $^value**2 } 1..10;
        print join "\n", map { $data{$_-1}.$^value**2 } 1..10;
        print join "\n", grep { $data{$^value} } 1..10;

        my $div = { $^x / $^y };        # Create a HOF that divides its two args

        print $div->(1,2), "\n";        # Do a division


=head1 DESCRIPTION

The Perl6::Placeholders module lets you try out the new Perl 6 implicit 
parameter specification syntax in Perl 5.

Perl 6 reserves all variables of the form C<$^name> or C<@^name> or
C<%^name> as "placeholders" that can be used to turn regular
blocks into subroutine references.

Any block containing one or more such placeholders
is treated as a reference to a subroutine in which the
placeholders are replaced by the appropriate
number and sequence of arguments.

That is, the expression:

        # Perl 6 code
        $check = { $^a == $^b**2 * $^c or die $^err_msg }; 

is equivalent to:

        # Perl 6 code
        $check = sub ($a, $b, $c, $err_msg) {
            $a == $b**2 * $c or die $err_msg
        };

This could then be invoked:

        # Perl 6 code
        $check.($i,$j,$k,$msg);
        
It is also be possible to interpolate an argument list into a static
expression like so:

        # Perl 6 code
        { $^a == $^b**2 * $^c or die $^err_msg }.($i,$j,$k,$msg);


The placeholders are sorted UTF8-abetically before they are used
to create the subroutine's parameter list. Hence the following:

        # Perl 6 code
        @reverse_sorted = sort {$^b <=> $^a} @list;

works as expected. That is, it's equivalent to:

        @reverse_sorted = sort sub($a,$b){$b <=> $a}, @list;


=head2 Declaring placeheld closures in Perl 5

The Perl6::Placeholders module allows you to use (almost) the same 
syntax in Perl 5.

That is, the expression:

        # Perl 5 code
        use Perl6::Placeholders;

        $check = { $^a == $^b**2 * $^c or die $^err_msg }; 

is equivalent to:

        # Perl 5 code

        $check = sub {
            my ($a, $b, $c, $err_msg) = @_;
            $a == $b**2 * $c or die $err_msg;
        };

This could then be invoked:

        # Perl 5 code
        $check->($i,$j,$k,$msg);
        
It is also be possible to interpolate an argument list into a static
expression like so:

        # Perl 5 code
        use Perl6::Placeholders;

        { $^a == $^b**2 * $^c or die $^err_msg }->($i,$j,$k,$msg);

Note that the placeholders are restricted to scalars (though a future
release may support array and hash parameters too).

The placeholders are sorted ASCIIbetically before they are used
to create the subroutine's parameter list. Hence the following:

        # Perl 5 code
        use Perl6::Placeholders;

        @reverse_sorted = sort {$^b <=> $^a} @list;

works as expected (even in earlier perls that don't support sub refs as sort
specifiers!)


=head1 DEPENDENCIES

The module is implemented using Filter::Simple
and requires that module to be installed. 

=head1 AUTHOR

Damian Conway (damian@conway.org)

=head1 MAINTAINER

Luke Palmer (lrpalmer gmail com)

=head1 BUGS

This module is not designed for serious implementation work.

It uses some relatively sophisticated heuristics to translate Perl 6
syntax back to Perl 5. It I<will> make mistakes if your code gets even
moderately tricky.

Nevertheless, bug reports are most welcome.

=head1 COPYRIGHT

Copyright (c) 2002, Damian Conway. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
  (see http://www.perl.com/perl/misc/Artistic.html)
