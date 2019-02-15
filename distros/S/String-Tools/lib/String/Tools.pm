use v5.12;

use warnings;

package String::Tools v0.19.045;
# ABSTRACT: Various tools for manipulating strings.


use Exporter 'import';

our @EXPORT    = qw();
our @EXPORT_OK = qw(
    define
    is_blank
    shrink
    stitch
    stitcher
    stringify
    subst
    subst_vars
    trim
    trim_lines
);

### Variables ###


our $BLANK  = '[[:cntrl:][:space:]]';


our $SUBST_VAR = qr/[[:alpha:]_]+\w*(?:[[:punct:]]\w+)*/;


our $THREAD = ' ';

### Functions ###

sub stringify(_);    # Forward declaration


sub define(_) { return $_[0] // !!undef }


sub is_blank(_) {
    local $_ = &stringify;
    return not( length() && !/\A$BLANK+\z/ );
}


sub shrink(_) {
    local $_ = trim(&stringify);
    s/$BLANK+/$THREAD/g;
    return $_;
}


sub stitch {
    my $str       = '';
    my $was_blank = 1;

    local $_;
    foreach my $s (map stringify, @_) {
        my $is_blank = is_blank($s);
        $str .= $THREAD unless ( $was_blank || $is_blank );
        $str .= $s;
        $was_blank = $is_blank;
    }

    return $str;
}


sub stitcher {
    local $THREAD = shift // $THREAD;
    return &stitch;
}


sub stringify(_) {
    local ($_) = @_;

    return not( defined() ) ? define() : do {
        my $ref = ref();
         !$ref                               ?            $_
        : $ref eq 'ARRAY'                    ?          "@$_"
        : $ref eq 'HASH'                     ?       "@{[%$_]}"
        : $ref eq 'REF' && ref($$_) ne 'REF' ? stringify($$_)
        : $ref eq 'SCALAR'                   ? stringify($$_)
        :                                                "$_"
        ;
    };
}


sub subst {
    my $str  = stringify( shift );
    @_ = ( $_ ) if defined($_) && ! @_;
    my %subst = 1 == @_ ? do {
            my $ref = ref( $_[0] );
              not($ref)       ? ( _ => +shift )
            : $ref eq 'ARRAY' ? @{ +shift }
            : $ref eq 'HASH'  ? %{ +shift }
            :                   ( _ => +shift );
        }
        : @_;

    if (%subst) {
        local $_;
        my $names = '(?:'
            . join( '|',
                map quotemeta,
                    sort { length($b) <=> length($a) || $a cmp $b }
                        grep { length() && /\A$SUBST_VAR\z/ }
                            keys %subst
            )
            . ')\b';
        $str =~ s[\$(?:\{\s*($names)\s*\}|($names))]
                 [ stringify( $subst{ $1 // $2 } ) ]eg;
    }

    return $str;
}


sub subst_vars(_) {
    local ($_) = &stringify;

    my @vars = /\$(\{\s*$SUBST_VAR\s*\}|$SUBST_VAR\b)/g;
    my %seen = ();
    return grep { !$seen{$_}++ }
        map { trim( $_, qr/\{\s*/, qr/\s*\}/ ) } @vars;
}


sub trim {
    local $_ = stringify( @_ ? shift : $_ );

    my ( $lead, $rear );
    my $count = scalar @_;
    if    ($count == 0) {}
    elsif ($count == 1) { $lead = shift; }
    else {
        # Could be:
        #   1. l => $value
        #   2. r => $value
        #   3. l => $value, r => $value
        #   or r => $value, l => $value
        #   4. $lead, $rear
        my %lr = @_;
        $lead = delete $lr{l} if exists $lr{l};
        $rear = delete $lr{r} if exists $lr{r};
        # At this point, there should be nothing in %lr,
        # so if there is, then this must be case 4.
        ( $lead, $rear ) = @_ if %lr;
    }

    $lead //= $BLANK . '+';
    s/\A$lead// if ( length $lead );

    $rear //= $lead;
    s/$rear\z// if ( length $rear );

    return $_;
}


sub trim_lines {
    local $_ = stringify( @_ ? shift : $_ );

    my ( $lead, $rear );
    my $count = scalar @_;
    if    ($count == 0) {}
    elsif ($count == 1) { $lead = shift; }
    else {
        # Could be:
        #   1. l => $value
        #   2. r => $value
        #   3. l => $value, r => $value
        #   or r => $value, l => $value
        #   4. $lead, $rear
        my %lr = @_;
        $lead = delete $lr{l} if exists $lr{l};
        $rear = delete $lr{r} if exists $lr{r};
        # At this point, there should be nothing in %lr,
        # so if there is, then this must be case 4.
        ( $lead, $rear ) = @_ if %lr;
    }

    $lead //= $BLANK . '+';
    s/^$lead//gm if ( length $lead );

    $rear //= $lead;
    s/$rear$//gm if ( length $rear );

    return $_;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

String::Tools - Various tools for manipulating strings.

=head1 SYNOPSIS

 use String::Tools qw(
    define
    is_blank
    shrink
    stitch
    stitcher
    stringify
    subst
    subst_vars
    trim
    trim_lines
 );

 my $val = define undef; # ''

 say is_blank(undef);    # 1  (true)
 say is_blank('');       # 1  (true)
 say is_blank("\t\n\0"); # 1  (true)
 say is_blank("0");      # '' (false)

 say shrink("  This is  a    test\n");  # 'This is a test'

 ## stitch ##
 say stitch( qw(This is a test) );  # "This is a test"
 say stitch(
    qw(This is a test), "\n",
    qw(of small proportions)
 );  # "This is a test\nof small proportions"

 # Format some other language in a more readable format,
 # yet keep the resulting string small for transport across the network.
 say stitch(qw(
    SELECT *
      FROM table
     WHERE foo = ?
       AND bar = ?
 ));
 # "SELECT * FROM table WHERE foo = ? AND bar = ?"

 ## subst ##
 my $date = 'Today is ${ day } of $month, in the year $year';
 say subst( $date,   day => '15th', month => 'August', year => 2013   );
 # OR
 say subst( $date, { day => '15th', month => 'August', year => 2013 } );
 # OR
 say subst( $date, [ day => '15th', month => 'August', year => 2013 ] );

 my $lookfor = 'The thing you're looking for is $_.';
 say               subst( $lookfor, 'this' );
 say 'No, wait! ', subst( $lookfor, _ => 'that' );

 say trim("  This is  a    test\n");    # 'This is  a    test'

 # Describe what to trim:
 say trim("  This is  a    test\n",
          l => '\s+', r => '\n+');      # 'This is  a    test'

=head1 DESCRIPTION

C<String::Tools> is a collection of tools to manipulate strings.

=head1 VARIABLES

=head2 C<$BLANK>

The default regular expression character class to determine if a string
component is blank.
Defaults to C<[[:cntrl:][:space:]]>.
Used in
L</is_blank( $string = $_ )>,
L</shrink( $string = $_ )>,
L</stitch( @list )>,
and
L</trim( $string = $_ ; $l = qrE<sol>$BLANK+E<sol> ; $r = $l )>.

=head2 C<$SUBST_VAR>

The regular expression for the
L<< /subst( $string ; %variables = ( _ => $_ ) ) >> function.
Starts with an alphabetic or underscore character, continues with any number
of word characters, and then is followed by any number of subpatterns that
begin with a single punctuation character and is followed by one or more
word characters.

If you want to change it for a particular use, it is highly recomended
that you C<local>'ize your change.

=head2 C<$THREAD>

The default thread to use while stitching a string together.
Defaults to a single space, C<' '>.
Used in L</shrink( $string = $_ )> and L</stitch( @list )>.

=head1 FUNCTIONS

=head2 C<define( $scalar = $_ )>

Returns C<$scalar> if it is defined,
or a defined but false value (which works in a numeric or string context)
if it's undefined.
Useful in avoiding the 'Use of uninitialized value' warnings.
C<$scalar> defaults to C<$_> if not specified.

=head2 C<is_blank( $string = $_ )>

Return true if C<$string> is blank.
A blank C<$string> is undefined, the empty string,
or a string that conisists entirely of L</$BLANK> characters.
C<$string> defaults to C<$_> if not specified.

=head2 C<shrink( $string = $_ )>

Trim C<$BLANK> characters from that lead and rear of C<$string>,
then combine multiple consecutive C<$BLANK> characters into one
C<$THREAD> character throughout C<$string>.
C<$string> defaults to C<$_> if not specified.

=head2 C<stitch( @list )>

Stitch together the elements of list with L</$THREAD>.
If an item in C<@list> is blank (as measured by L</is_blank( $string = $_ )>),
then the item is stitched without L</$THREAD>.

This approach is more intuitive than C<join>:

 say   join( ' ' => qw( 1 2 3 ... ), "\n", qw( Can anybody hear? ) );
 # "1 2 3 ... \n Can anybody hear?"
 say   join( ' ' => qw( 1 2 3 ... ) );
 say   join( ' ' => qw( Can anybody hear? ) );
 # "1 2 3 ...\nCan anybody hear?"
 #
 say stitch( qw( 1 2 3 ... ), "\n", qw( Can anybody hear? ) );
 # "1 2 3 ...\nCan anybody hear?"

 say   join( ' ' => $user, qw( home dir is /home/ ),     $user );
 # "$user home dir is /home/ $user"
 say   join( ' ' => $user, qw( home dir is /home/ ) ) .  $user;
 # "$user home dir is /home/$user"
 #
 say stitch( $user, qw( home dir is /home/ ), '', $user );
 # "$user home dir is /home/$user"

=head2 C<< stitcher( $thread => @list ) >>

Stitch together the elements of C<@list> with C<$thread> in place of
L</$THREAD>.

 say stitcher( ' ' => qw( 1 2 3 ... ), "\n", qw( Can anybody hear? ) );
 # "1 2 3 ...\nCan anybody hear?"

 say stitcher( ' ' => $user, qw( home dir is /home/ ), '', $user );
 # "$user home dir is /home/$user"

=head2 C<stringify( $scalar = $_ )>

Return an intelligently stringified version of C<$scalar>.
Attempts to avoid returning a string that has the reference name
and a hexadecimal number:
C<ARRAY(0xdeadbeef)>, C<My::Package=HASH(0xdeadbeef)>.

If C<$scalar> is undefined,
returns the result from L</define( $scalar = $_ )>.
If C<$scalar> is not a reference,
returns $scalar.
If C<$scalar> is a reference to an C<ARRAY>,
returns the stringification of that array (via C<"@$scalar">).
If C<$scalar> is a reference to a C<HASH>,
returns the stringification of that hash (via C<"@{[%$scalar]}">).
If C<$scalar> is a reference to a C<REF>,
and C<$$scalar> is not reference to a C<REF>,
calls itself as C<stringify($$scalar)>.
If C<$scalar> is a reference to a C<SCALAR>,
calls itself as C<stringify($$scalar)>.
If C<$scalar> is a reference that is not one of the previously mentioned,
returns the default stringification (via C<"$scalar">).

Since v0.18.277

=head2 C<< subst( $string ; %variables = ( _ => $_ ) ) >>

Take in C<$string>, and do a search and replace of all the variables named in
C<%variables> with the associated values.

The C<%variables> parameter can be a hash, hash reference, array reference,
list, scalar, or empty.  The single scalar is treated as if the name is the
underscore.  The empty case is handled by using underscore as the name,
and C<$_> as the value.

If you really want to replace nothing in the string, then pass in an
empty hash reference or empty array reference, as an empty hash or empty list
will be treated as the empty case.

Only names which are in C<%variables> will be replaced.  This means that
substitutions that are in C<$string> which are not mentioned in C<%variables>
are simply ignored and left as is.

The names in C<%variables> to be replaced in C<$string> must follow a pattern.
The pattern is available in variable L</C<$SUBST_VAR>>.

Returns the string with substitutions made.

=head2 C<subst_vars( $string = $_ )>

Search C<$string> for things that look like variables to be substituted.

Returns the unique list of variable names found, without the leading
C<$> or surrounding C<{}>.

 my $string = 'Name is $name, age is $age, birthday is ${ birthday }';
 my @vars = subst_vars($string);    # 'name', 'age', 'birtday'

=head2 C<trim( $string = $_ ; $l = qr/$BLANK+/ ; $r = $l )>

Trim C<string> of leading and trailing characters.
C<$string> defaults to C<$_> if not specified.
The paramters C<l> (lead) and C<r> (rear) are both optional,
and can be specified positionally, or as key-value pairs.
If C<l> is undefined, the default pattern is C</$BLANK+/>,
matched at the beginning of the string.
If C<r> is undefined, the default pattern is the value of C<l>,
matched at the end of the string.

If you don't want to trim the start or end of a string, set the
corresponding parameter to the empty string C<''>.

 say foreach map trim, @strings;

 say trim('  This is a test  ')
 # 'This is a test'

 say trim('--This is a test==', qr/-/, qr/=/);
 # '-This is a test='

 say trim('  This is a test!!', r => qr/[.?!]+/, l => qr/\s+/);
 # 'This is a test'

=head2 C<trim_lines( $string = $_ ; $l = qr/$BLANK+/ ; $r = $l )>

Similar to L</trim( $string = $_ ; $l = qr/$BLANK+/ ; $r = $l )>,
except it does it for each line in a string, not just the start
and end of a string.

 say trim_lines("\t This \n\n \t is \n\n \t a \n\n \t test \t\n\n")
 # "This\nis\na\ntest"

 say trim_lines( "\t\tThis\n\t\tis\n\t\ta\n\t\ttest", qr/\t/ );
 # "\tThis\n\tis\n\ta\n\ttest"

Since v0.18.270.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/rkleemann/String-Tools/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 TODO

Nothing?

=head1 SEE ALSO

C<stitch> is similar to L<perlfunc/join>.

C<subst> is similar to any templating system.

=head1 VERSION

This document describes version v0.19.045 of this module.

=head1 AUTHOR

Bob Kleemann <bobk@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014-2019 by Bob Kleemann.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
