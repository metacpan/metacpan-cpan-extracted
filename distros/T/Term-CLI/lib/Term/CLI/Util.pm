#=============================================================================
#
#       Module:  Term::CLI::Util
#
#  Description:  Utility functions for Term::CLI
#
#       Author:  Steven Bakker (SBAKKER), <sbakker@cpan.org>
#      Created:  21/01/2022
#
#   Copyright (c) 2022 Steven Bakker
#
#   This module is free software; you can redistribute it and/or modify
#   it under the same terms as Perl itself. See "perldoc perlartistic."
#
#   This software is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#=============================================================================

package Term::CLI::Util 0.061000;

use 5.014;
use warnings;
use parent qw( Exporter );

use List::Util qw( first );
use Getopt::Long 2.38 qw( GetOptionsFromArray );
use namespace::clean;

# When "pass_through" is enabled, Getopt::Long >= 2.51 will leave a
# "--" in the argument list, but older versions won't.
my $HAVE_OLD_GETOPT = $Getopt::Long::VERSION < 2.51;

BEGIN {
	our @EXPORT_OK   = qw(
        get_options_from_array
        is_prefix_str
        find_obj_name_matches
        find_text_matches
    );
	our @EXPORT      = ();
	our %EXPORT_TAGS = ( all => \@EXPORT_OK );
}

sub is_prefix_str {
    my ($substr, $str) = @_;
    return rindex( $str, $substr, 0 ) == 0;
}

sub get_options_from_array {
    my %args = @_;
    my ($arguments, $result, $opt_specs, $pass_through) =
        @args{qw(args result spec pass_through)};

    $result //= {};

    my $double_dash;

    Getopt::Long::Configure(
        qw(bundling require_order),
        ($pass_through ? '' : 'no_') . 'pass_through'
    );

    if ( $pass_through && $HAVE_OLD_GETOPT ) {
        $double_dash = first { $_ eq '--' } @{$arguments};
    }

    $double_dash //= q{};

    my $error = q{};
    my $ok    = do {
        local ( $SIG{__WARN__} ) = sub { chomp( $error = join( q{}, @_ ) ) };
        GetOptionsFromArray( $arguments, $result, @{$opt_specs} );
    };

    if ( $pass_through && !$HAVE_OLD_GETOPT ) {
        if ( @{$arguments} && $arguments->[0] eq '--' ) {
            $double_dash = shift @{$arguments};
        }
    }

    return (
        success     => $ok,
        error_msg   => $error,
		$pass_through ? ( double_dash => $double_dash ne q{} ) : (),
    );
}

sub find_obj_name_matches {
    my ( $text, $list, %opt ) = @_;

    return if !$list || @$list == 0;

    my $exact = $opt{exact};

    if ( @$list <= 10 || ( !$exact && @$list <= 45 ) ) {
        my @found;
        foreach (@{$list}) {
            my $n = $_->name;
            next if $n lt $text;
            if (rindex( $n, $text, 0 ) == 0) {
                push @found, $_;
                return @found if $exact && $n eq $text;
                next;
            }
            last;
        }
        return @found;
    }

    my ( $lo, $hi ) = ( 0, $#{$list} );

    while ($lo < $hi) {
        my $mid = int( ($lo + $hi) / 2 );
        my $cmp = $text cmp $list->[$mid]->name;
        if ($cmp < 0) {
            $hi = $mid;
            next;
        }
        if ($cmp > 0) {
            if ($lo == $hi-1) {
                $lo++;
                last;
            }
            $lo = $mid;
            next;
        }
        return $list->[$mid] if $exact;
        $lo = $hi = $mid;
        last;
    }

    my @found;
    foreach (@{$list}[$lo..$#{$list}]) {
        my $n = $_->name;
        if (rindex( $n, $text, 0 ) == 0) {
            push @found, $_;
            next;
        }
        last;
    }
    return @found;
}


sub find_text_matches {
    my ( $text, $list, %opt ) = @_;

    return if !$list || @$list == 0;

    my $exact = $opt{exact};

    if ( @$list <= 45 || ( !$exact && @$list <= 215 ) ) {
        my @found;
        foreach (@{$list}) {
            next if $_ lt $text;
            if (rindex( $_, $text, 0 ) == 0) {
                push @found, $_;
                return @found if $exact && $_ eq $text;
                next;
            }
            last;
        }
        return @found;
    }

    my ( $lo, $hi ) = ( 0, $#{$list} );

    while ($lo < $hi) {
        my $mid = int( ($lo + $hi) / 2 );
        my $cmp = $text cmp $list->[$mid];
        if ($cmp < 0) {
            $hi = $mid;
            next;
        }
        if ($cmp > 0) {
            if ($lo == $hi-1) {
                $lo++;
                last;
            }
            $lo = $mid;
            next;
        }
        return $list->[$mid] if $exact;
        $lo = $hi = $mid;
        last;
    }

    my @found;
    foreach (@{$list}[$lo..$#{$list}]) {
        if (rindex( $_, $text, 0 ) == 0) {
            push @found, $_;
            next;
        }
        last;
    }
    return @found;

}

1;

__END__

=pod

=head1 NAME

Term::CLI::Util - utility functions for Term::CLI(3p)

=head1 VERSION

version 0.061000

=head1 SYNOPSIS

 use Term::CLI::Util qw( :all );

 use Data::Dumper;

 my %result = get_options_from_array(
    args         => \@ARGV,
    spec         => [ 'verbose|v', 'debug|d' ]
    result       => \(my %options),
    pass_through => 1,
 );

 say "Result: ", Data::Dumper->Dump(
    [ \%result, \%options, \@ARGV ],
    [ 'result', 'options', 'ARGV' ]
 );

 is_prefix_str( 'foo', 'foobar' ); # returns true.
 is_prefix_str( 'bar', 'foobar' ); # returns false.

=head1 DESCRIPTION

Provide utility functions for various modules in the
L<Term::CLI|Term::CLI>(3p) collection.

=head1 EXPORTED FUNCTIONS

No functions are exported by default. Functions need be imported explicitly
by name, or by specifying the C<:all> tag, which will import all functions.

=head1 FUNCTIONS

=over

=item B<find_obj_name_matches>
X<find_obj_matches>

    LIST = find_obj_name_matches( TEXT, OBJ_LIST_REF );
    LIST = find_obj_name_matches( TEXT, OBJ_LIST_REF, exact => 1 );

Find objects in I<OBJ_LIST_REF> (an C<ArrayRef>) where I<TEXT> is a
prefix for the object's C<name> attribute. The list I<must> be sorted
on C<name> field.

If the C<exact> options is specified to be true, an exact name match
will result in exactly one item to be returned.

=item B<find_text_matches>
X<find_text_matches>

    LIST = find_string_matches( TEXT, STRING_LIST_REF );
    LIST = find_string_matches( TEXT, STRING_LIST_REF, exact => 1 );

Same as L<find_obj_name_matches> above, except that the second argument
refers to a I<sorted> list of scalars (strings), rather than objects.

=item B<get_options_from_array>
X<get_options_from_array>

    HASH = get_options_from_array(
        args => ArrayRef,
        spec => ArrayRef,
        [ result => HashRef, ]
        [ pass_through => Bool, ]
    );

Parse the command line options in the C<args> array according to the options
specified in the C<spec> array. Recognised options are stored in the C<result>
hash.

This is a fancy wrapper around
L<GetOptionsFromArray|Getopt::Long/GetOptionsFromArray>
from
L<Getopt::Long|Getopt::Long>(3p).

This function, however, sets the following configuration flags for
C<Getopt::Long>: C<bundling>, C<require_order> and either C<pass_through>
or C<no_pass_through>, depending on the C<pass_through> parameter it was
given.

Unlike C<Getopt::Long>, this function will remove the option terminating
"double dash" (C<-->) argument from the argument list, even if
C<pass_through> is true.

The return value is a hash with the following keys:

=over

=item C<success>

A boolean indicating whether the option parsing was successful or not. If
false, the C<error_msg> key will hold a diagnostic message.

=item C<error_msg>

A string holding the error message from C<Getopt::Long>. If C<success> is
true, this will be an empty string.

=item C<double_dash>

A boolean indicating whether option parsing was stopped due to encountering
a C<--> word in the argument list.

This is only present if C<pass_through> was specified with a true value.

=back

=item B<is_prefix_str>
X<is_prefix_str>

    BOOL = is_prefix_str( SUBSTR, STRING );

Returns whether I<SUBSTR> is a prefix of I<STRING>.

=back

=head1 EXAMPLES

Consider the following script, called C<getopt_test.pl>:

    use 5.014;
    use warnings;
    use Data::Dumper;
    use Term::CLI::Util qw( get_options_from_array );

    my ($pass_through, @args) = @ARGV;

    my %options;

    my %result = get_options_from_array(
        args         => \@args,
        spec         => [ 'verbose|v+', 'debug|d' ],
        result       => \%options,
        pass_through => $pass_through,
    );

    print Data::Dumper->Dump(
        [ \%result, \%options, \@args ],
        [ '*result', '*options', '*args' ]
    );

=head2 With correct input

With C<pass_through>:

    $ perl getopt_test.pl 1 -vv --debug -- foo bar
    %result = (
                'success' => 1,
                'error_msg' => '',
                'double_dash' => 1
              );
    %options = (
                 'debug' => 1,
                 'verbose' => 2
               );
    @args = (
              'foo',
              'bar'
            );

Without C<pass_through>:

    $ perl getopt_test.pl 0 -vv --debug -- foo bar
    %result = (
                'success' => 1,
                'error_msg' => '',
              );
    %options = (
                 'debug' => 1,
                 'verbose' => 2
               );
    @args = (
              'foo',
              'bar'
            );

Note the difference in output: in the case where C<pass_through> is enabled,
there is an entry in the result for C<double_dash> (which in this case is
true).

=head2 With incorrect input

With C<pass_through>:

    $ perl getopt_test.pl 1 -vv --debug --bad -- foo bar
    %result = (
                'success' => 1,
                'error_msg' => '',
                'double_dash' => ''
              );
    %options = (
                 'verbose' => 2
               );
    @args = (
              '--bad',
              '--debug',
              '--',
              'foo',
              'bar'
            );

Without C<pass_through>:

    $ perl getopt_test.pl 0 -vv --debug -- foo bar
	%result = (
	            'success' => '',
	            'error_msg' => 'Unknown option: bad'
	          );
	%options = (
	             'debug' => 1,
	             'verbose' => 2
	           );
	@args = (
	          'foo',
	          'bar'
	        );

=head1 SEE ALSO

L<Term::CLI|Term::CLI>(3p),
L<Getopt::Long|Getopt::Long>(3p).

=head1 CAVEATS

When C<pass_through> is enabled, L<Getopt::Long> should leave a
C<--> in the argument list when it encounters it; however, versions
before 2.51 do not do so.

This module tries to compensate for that when it detects an older
L<Getopt::Long|Getopt::Long> version by searching for C<--> in
the argument list beforehand. There are still instances where this
can go wrong, though:

=over

=item *

Input is C<--foo -- --verbose> and option C<foo> happens to take an
argument.

=item *

Input is I<--opt1 arg1 arg2> and I<arg2> happens to be C<-->.

=back

However, since the C<double_dash> flag is really only used in command
completion, this is not a very major issue.

=head1 AUTHOR

Steven Bakker E<lt>Steven.Bakker@ams-ix.netE<gt>, AMS-IX B.V.; 2022.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2022 AMS-IX B.V.; All rights reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See "perldoc perlartistic."

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
