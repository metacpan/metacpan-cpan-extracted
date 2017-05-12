package String::Snip;
$String::Snip::VERSION = '0.002';
use strict;
use warnings;

use String::Truncate;

{
    our $the_closure;

    sub _hook_closure{
        return &{$the_closure}(@_);
    }

    sub snip{
        my ( $string, $opts ) = @_;
        $string ||= '';
        $opts ||= {};
        my $max_length = $opts->{max_length} || 2000;
        my $short_length = $opts->{short_length} || 100;
        my $substr_regex = $opts->{substr_regex} || '\\S+';
        if( $max_length < 100 ){ $max_length = 100; }
        if( $short_length < 50 ){ $short_length = 50 };

        local $the_closure = sub{
            my ($str) = @_;
            if( length($str) < $max_length ){
                return $str;
            }
            my $chardiff = length($str);
            return String::Truncate::elide($str, $short_length,
                                           { truncate => 'middle',
                                             marker => ' ..[SNIP (was '.$chardiff.'chars)].. '
                                         });
        };
        $string =~ s/($substr_regex)/_hook_closure($1)/egs;
        return $string;
    }
}

1;

__END__

=head1 NAME

String::Snip - Shorten large substrings in your strings

=head1 SYNOPSIS

 use String::Snip;

 my $large_string = 'blabla , somethingelse=AStringThatIsMuchTooLongToBeDisplayedInALogEntryORAnywhereSensible';

 print String::Snip::snip($large_string);
 # Prints 'blabla, somethingelse=AStringThat ..[SNIP 2345chars].. whereSensible'

=head2 snip

Pure function. Returns the given string with its long substrings shortened.

Usage:

  print String::Snip::snip($large_string);

  print String::Snip::snip($large_string, { max_length => 1000 });

Options:

=over

=item max_length

Maximum length of a substring. After this length, it gets truncated to a string of C<< short_length >> characters. Default to 2000.
There is a hard bottom limit at 100.

=item short_length

Length of shortened substrings. Defaults to 100.
There is a hard bottom limit at 50.

=item substr_regex

The regex that captures the substring of this string. Defaults to C<< \S+ >>, which will capture any consecutive non-space
strings. If you want this to capture multiline large strings, you can use C<< [\\S\\n]+ >>.

=back

=head1 IDEAS

=head2 Keep the option of outputting your full string

Use that in your log outputs, reserving the full output when your log is in debug mode:

 if( $something_is_debug ){
    $log->debug("Full string:".$large_string);
 }
 $log->info(String::Snip::snip($large_string));

=head2 Use that when you trace large data blobs

For instance if you deal with base64 encoded binary files, it's likely you will have your log filled with meaningless
base64 giant strings. Use this to shorten them!

=head1 CAVEATS

If you use that on structured data (like a JSON structure), this might render your
data invalid. For instance if you have a large base64 string in your JSON, it will be broken
by this. To avoid this being an issue, make sure you have a way to output the whole untouched
thing should you need it.


=head1 SEE ALSO

L<String::Truncate>

=for HTML <a href="https://travis-ci.org/jeteve/String-Snip"><img src="https://travis-ci.org/jeteve/String-Snip.svg?branch=master"></a>

=cut
