use v5.12;

use warnings;

package String::Tools;
# ABSTRACT: Various tools for handling strings.
our $VERSION = '0.14.163'; # VERSION


use Exporter 'import';

our @EXPORT    = qw();
our @EXPORT_OK = qw(define is_blank shrink stitch stitcher subst trim);


our $THREAD = ' ';


our $BLANK  = '[[:cntrl:][:space:]]';


sub define(_) { return $_[0] // '' }


sub is_blank(_) {
    local $_ = shift;
    return 1 unless defined() && length();
    return /\A$BLANK+\z/;
}


sub shrink(_) {
    local $_ = trim(shift);
    s/$BLANK+/$THREAD/g if defined;
    return $_;
}


sub stitch {
    local $_;
    my $str = '';
    my $was_blank = 1;

    foreach my $s (map define, @_) {
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


sub subst {
    my $str  = shift;
    @_ = ( $_ ) if defined($_) && ! @_;

    my %subst;
    if ( 1 == @_ ) {
        my $ref = ref $_[0];
        if    ( $ref eq 'HASH' )  { %subst = %{ +shift }     }
        elsif ( $ref eq 'ARRAY' ) { %subst = @{ +shift }     }
        else                      { %subst = ( _ => +shift ) }
    } else { %subst = @_ }

    if (%subst) {
        local $_;
        my $names = join( '|', map quotemeta, grep length, sort keys %subst );
        $str =~ s[\$(?:\{\s*($names)\s*\}|($names)\b)]
                 [$subst{ $1 // $2 }]g;
    }

    return $str;
}


sub trim {
    local $_ = @_ ? shift : $_;
    return $_ unless defined;

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

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

String::Tools - Various tools for handling strings.

=head1 VERSION

version 0.14.163

=head1 SYNOPSIS

 use String::Tools qw(define is_blank shrink stitch stitcher subst trim);

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

=head2 C<$THREAD>

The default thread to use while stitching a string together.
Defaults to a single space, C<' '>.
Used in L</shrink( $string = $_ )> and L</stitch( @list )>.

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

=head1 FUNCTIONS

=head2 C<define( $scalar = $_ )>

Returns C<$scalar> if it is defined, or the empty string if it's undefined.
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

Returns the string with substitutions made.

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

 say map trim, @strings;

 say trim('  This is a test  ')
 # 'This is a test'

 say trim('--This is a test==', qr/-/, qr/=/);
 # '-This is a test='

 say trim('  This is a test!!', r => qr/[.?!]+/, l => qr/\s+/);
 # 'This is a test'

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/rkleemann/String-Tools/issues or by email to
bug-String-Tools@rt.cpan.org.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 TODO

Nothing?

=head1 SEE ALSO

L<perlfunc/join>, Any templating system.

=head1 AUTHOR

Bob Kleemann <bobk@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Bob Kleemann.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
