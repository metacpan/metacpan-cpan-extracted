package Perl6::Gather;
use Perl6::Export;
use Carp;

our $VERSION = '0.42';

my %gatherers;

sub gather(&) is export(:DEFAULT) {
	croak "Useless use of 'gather' in void context" unless defined wantarray;
	my ($code) = @_;
	my $caller = caller;
	local @_;
	push @{$gatherers{$caller}}, bless \@_, 'Perl6::Gather::MagicArrayRef';
	die $@
		if !eval{ &$code } && $@ && !UNIVERSAL::isa($@, Perl6::Gather::Break);
	return @{pop @{$gatherers{$caller}}} if wantarray;
	return   pop @{$gatherers{$caller}}  if defined wantarray;
}

sub gathered() is export(:DEFAULT) {
	my $caller = caller;
	croak "Call to gathered not inside a gather" unless @{$gatherers{$caller}};
	return $gatherers{$caller}[-1];
}

sub take(@) is export(:DEFAULT) {
	@_ = $_ unless @_;
	my $caller = caller;
	croak "Call to take not inside a gather block"
		unless ((caller 3)[3]||"") eq 'Perl6::Gather::gather';
	push @{$gatherers{$caller}[-1]}, @_;
	return 0+@_;
}

my $breaker = bless [], 'Perl6::Gather::Break';

sub break() is export(:DEFAULT) {
	die $breaker;
}

package Perl6::Gather::MagicArrayRef;

use overload
	'bool' => sub { @{$_[0]} > 0      },
	'0+'   => sub { @{$_[0]} + 0      },
	'""'   => sub { join "", @{$_[0]} },
	'~'    => sub { join "", @{$_[0]} },
	fallback => 1;
;

1;
__END__

=head1 NAME

Perl6::Gather - Implements the Perl 6 'gather/take' control structure in Perl 5


=head1 SYNOPSIS

    use Perl6::Gather;

	@list = gather {
				# Try to extract odd numbers and odd number names...
				for (@data) {
					if (/(one|three|five|nine)$/) { take qq{'$_'}; }
					elsif (/^\d+$/ && $_ %2)      { take; }
				}
				# But use the default set if there aren't any of either...
				take @defaults unless gathered;
		    }



=head1 BACKGROUND

Perl 6 provides a new control structure -- C<gather> -- that allows
lists to be constructed procedurally, without the need for a temporary
variable. Within the block/closure controlled by a C<gather> any call to
C<take> pushes that call's argument list to an implicitly created array.
C<take> returns the number of elements it took.

At the end of the block's execution, the C<gather> returns the list of
values stored in the array (in a list context) or a reference to the array
(in a scalar context).

For example, instead of writing:

    # Perl 6 code...
    print do {
                my @wanted;
                for <> -> $line {
                    push @wanted, $line  if $line ~~ /\D/;
                    push @wanted, -$line if some_other_condition($line);
                }
                push @wanted, 'EOF';
                @wanted;
              };

in Perl 6 we can write:

    # Perl 6 code...
    print gather {
                    for <> -> $line {
                        take $line  if $line ~~ /\D/;
                        take -$line if some_other_condition($line);
                    }
                    take 'EOF';
                 }

and instead of:

	$text = do {
				my $string;
                for <> {
                    next if /^#|^\s*$/;
					last if /^__[DATA|END]__\n$/;
                    $string .= $_;
                }
                $string;
              };

we could write:

	$text = ~gather {
                for <> {
                    next if /^#|^\s*$/;
					last if /^__[DATA|END]__\n$/;
                    take;
                }
              }

As the above example implies, if C<take> is called without any
arguments, it takes the current topic. 

There is also a third function -- C<gathered> -- which returns a
reference to the implicit array being gathered. This is useful for
handling defaults:

    @odds = gather {
                for @data {
                    take if $_ % 2;
                    take to_num($_) if /[one|three|five|nine]$/;
                }
                take 1,3,5,7,9 unless gathered;
            }

It's also handy for creating the implicit array by some process more
complex than by simple sequential pushing. For example, if we needed to
prepend a count of non-numeric items:

    @odds = gather {
                for @data {
                    take if $_ %2;
                    take to_num($_) if /[one|three|five|nine]$/;
                }
                unshift gathered,  +grep(/[a-z]/i, @data);
            }


Conceptually C<gather>/C<take> is the generalized form from which both
C<map> and C<grep> derive. That is, we could implement those two functions
as:

    sub map ($transform is Code, *@list) {
        return gather {  for @list { take $transform($_) }  };
    }

    sub grep ($selected is Code|Rule, *@list) {
        return gather {  for @list { take when $selected }  }
    }


A C<gather> is also a very handy way of short-circuiting the
construction of a list. For example, suppose we wanted to generate a
single sorted list of lines from two sorted files, but only up to the
first line they have in common. We could gather the lines like this:

    my @merged_diff = gather {
        my $a = <$fh_a>;
        my $b = <$fh_b>;
        loop {
            if defined all $a,$b {
                if    $a eq $b { last }     # Duplicate means end of list
                elsif $a lt $b { take $a; $a = <$fh_a>; }
                else           { take $b; $b = <$fh_b>; }
            }
            elsif defined $a   { take $a; $a = <$fh_a>; }
            elsif defined $b   { take $b; $b = <$fh_b>; }
            else               { last }
        }
    }


=head1 DESCRIPTION

The Perl6::Gather module provides the same functionality in Perl 5.
So we could code some of the previous examples like so:

    # Perl 5 code...
    use Perl6::Gather;

    print gather {
                    for my $line (<>) {
                        take $line  if $line =~ /\D/;
                        take -$line if some_other_condition($line);
                    }
                    take 'EOF';
                 };

and:

    # Perl 5 code...
    use Perl6::Gather;

	$" = "";
	$text = ~gather {
                for (<>) {
                    next if /^#|^\s*$/;
					last if /^__(?:DATA|END)__$/;
                    take;
                }
              };

and:

    # Perl 5 code...
    use Perl6::Gather;

    @odds = gather {
                for (@data) {
                    take if $_ % 2;
                    take to_num($_) if /(?:one|three|five|nine)\z/;
                }
                take 1,3,5,7,9 unless gathered;
            };

Note that -- as the second example above implies -- the C<gathered> function
returns a special Perl 5 array reference that acts like a Perl 6 array
reference in boolean, numeric, and string contexts. Note too that that
array reference has the C<~> operator overloaded to provide string coercion
(as in Perl 6).


=head1 WARNING

The syntax and semantics of Perl 6 C<gather>'s is still being finalized
and consequently is at any time subject to change. The the syntax and
semantics of this module will track those changes when and if they occur.


=head1 AUTHOR

Damian Conway (damian@conway.org)


=head1 DEPENDENCIES

Perl6::Export


=head1 BUGS AND IRRITATIONS

It would be nice to be able to code the default case as:

    @odds = gather {
                for (@data) {
                    take if $_ % 2;
                    take to_num($_) if /(?:one|three|five|nine)\z/;
                }
            } or (1,3,5,7,9);

but Perl 5's C<or> imposes a scalar context on its left argument.
This is arguably a bug and definitely an irritation.

Comments, suggestions, and patches welcome.


=head1 COPYRIGHT

 Copyright (c) 2003, Damian Conway. All Rights Reserved.
 This module is free software. It may be used, redistributed
 and/or modified under the same terms as Perl itself.
