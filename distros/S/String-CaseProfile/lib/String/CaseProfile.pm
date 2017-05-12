package String::CaseProfile;

use 5.008;
use strict;
use warnings;
use Carp qw(carp);

use Exporter;
use base 'Exporter';
our @EXPORT_OK = qw(
                    get_profile
                    set_profile
                    copy_profile
                   );

our %EXPORT_TAGS = ( 'all' => [ @EXPORT_OK ] );

our $VERSION = '0.18';


my $word_re =  qr{
                    \b(?:\p{Lu}{1,2}\.)+(?:\P{L}|$)
                    |
                    \b\p{Lu}{1,2}\/\p{Lu}{1,2}\b
                    |
                    (?:
                        \p{L}
                        |
                        (?<=\p{L})[-'\x92_&](?=\p{L})
                        |
                        (?<=[lL])\xB7(?=[lL])
                        |
                        \d
                    )+
                 }x;


my %types = (
                '1st_uc' => 'f',
                'all_uc' => 'u',
                'all_lc' => 'l',
                'other'  => 'o',
             );


sub get_profile {
    my $string = shift;
    
    my (@excluded, $strict);
    
    if (ref $_[0] eq 'HASH') {
        
        if ($_[0]->{exclude}) {
            @excluded = @{$_[0]->{exclude}};
        }
        
        $strict   = $_[0]->{strict};
        
    } else {
        
        if ( defined $_[0] ) {
            @excluded = @{ $_[0]} ;
        }
        
    }

    # read excluded words, if any
    my %excluded;
    if ( @excluded > 0 ) {
        $excluded{$_}++ foreach ( @excluded );
    }
    
    my @words = $string =~ /($word_re)/g;
    
    my @word_types;
    if ( @words == 1 && length $words[0] == 1 ) {
        
        if ($words[0] =~ /^\p{Lu}$/) {
            
            push @word_types, 'all_uc';
            
        } elsif ($words[0] =~ /^\p{Ll}$/) {
            
            push @word_types, 'all_lc';
            
        } else {
            
            push @word_types, 'other';
        }
        
    } else {
        
        @word_types = map {
            
                            _exclude($_, \%excluded)
                            ?
                            'excluded'
                            :
                            _word_type($_)
                            
                          } @words;
        
    }
    
    my %profile;
    ( $profile{fold}, $profile{string_type} ) = _string_type($strict, @word_types);
    
    for (my $i = 0; $i <= $#words; $i++) {
        push @{$profile{words}}, {
                                    word => $words[$i],
                                    type => $word_types[$i],
                                 }
    }
    
    $profile{report} = _create_report($string, \%profile);
    
    return %profile;
}


sub _exclude {
    my ($word, $excluded_href) = @_;
    
    return 1 if $excluded_href->{$word}; 

    if ($word =~ /[-']/) {
        my @pieces = split /[-']/, $word;
        my @excluded = grep { $excluded_href->{$_} } @pieces;
        if (@excluded) { return 1 } else { return 0 };
    } else {
        return 0;
    }
}

sub _create_report {
    my ($string, $prof_href) = @_;
    
    my %prof = %{$prof_href};
    
    my $report;
    $report .= "String:  $string\n";
    $report .= "Type:    $prof{string_type}\n";
    $report .= "Pattern: $prof{fold}\n\n";
    $report .= "Word                Type\n--------------------------\n";
    for ( my $i = 0; $i < scalar(@{$prof{words}}); $i++ ) {
        $report .= sprintf "%-20s%-20s\n", $prof{words}[$i]->{word},
                                           $prof{words}[$i]->{type};
    }
    
    return $report;
}


sub set_profile {
    my ($string, %ref_profile) = @_;

    my %string_profile = get_profile($string, $ref_profile{exclude});
    
    my @words = map { $_->{word} } @{$string_profile{words}};
    my @word_types = map { $_->{type} } @{$string_profile{words}};
    
    my $force = $ref_profile{'force_change'};
    
    # validate string_type
    my ($legal, $ref_string_type);
    if ($ref_profile{string_type}) {
        $ref_string_type = $ref_profile{string_type};
        if ($types{$ref_string_type} && $ref_string_type ne 'other') {
            $legal = 1;
        } elsif ($ref_string_type eq 'other') {
            return $string;
        } else {
            carp "Illegal value of string_type";
        }
    }
    
    my @transformed;
    
    if ($legal) {
        if ($ref_string_type eq '1st_uc') {
            if ($word_types[0] eq 'excluded') {
                $transformed[0] = $words[0];
            } else {
                $transformed[0] = _transform(
                                              '1st_uc',
                                              $words[0],
                                              $word_types[0],
                                              $force
                                            );
            }
            for (my $i = 1; $i <= $#words; $i++) {
                if ($word_types[$i] eq 'excluded') {
                    push @transformed, $words[$i];
                } else {
                    push @transformed, _transform(
                                                  'all_lc',
                                                  $words[$i],
                                                  $word_types[$i],
                                                  $force
                                                 );
                }
            }
        } else {
            for (my $i = 0; $i <= $#words; $i++) {
                if (
                    $word_types[$i] eq 'excluded' 
                    && $ref_string_type ne 'all_uc'
                   ) {
                        push @transformed, $words[$i];
                } else {
                    push @transformed, _transform(
                                                  $ref_string_type,
                                                  $words[$i],
                                                  $word_types[$i],
                                                  $force
                                                 );
                }
            }
        }
        
    # custom profile
    } elsif ($ref_profile{custom}) {
        
        # validate default type
        my ($type, $default_type);
        if ($ref_profile{custom}->{default}) {
            $type = $ref_profile{custom}->{default};
            if ($types{$type} && $types{$type} ne 'other') {
                $default_type = $type;
            } else {
                carp "Illegal default value in custom profile";
            }
        }
        
        for (my $i = 0; $i <= $#word_types; $i++) {
            
            my $in_index = $ref_profile{custom}->{index}->{$i};
            my $trigger_type = $ref_profile{custom}->{$word_types[$i]};
            
            if ($in_index) {
                if (
                    $word_types[$i] eq 'excluded' 
                    && $in_index ne 'all_uc'
                   ) {
                        push @transformed, $words[$i];
                } elsif ($in_index ne $word_types[$i]) {
                    push @transformed, _transform(
                                                  $in_index,
                                                  $words[$i],
                                                  $word_types[$i],
                                                  $force
                                                 );
                } else {
                    push @transformed, $words[$i];
                }
            } elsif ($trigger_type) {
                if (
                    $word_types[$i] eq 'excluded' 
                    && $ref_string_type ne 'all_uc'
                   ) {
                        push @transformed, $words[$i];
                } else {
                    push @transformed, _transform(
                                                  $trigger_type,
                                                  $words[$i],
                                                  $word_types[$i],
                                                  $force
                                                 );
                }

            } elsif ($default_type) { # use default type
                if (
                    $word_types[$i] eq 'excluded' 
                    && $ref_string_type ne 'all_uc'
                   ) {
                        push @transformed, $words[$i];
                } else {
                    push @transformed, _transform(
                                                  $default_type,
                                                  $words[$i],
                                                  $word_types[$i],
                                                  $force
                                                 );
                }
            } else {
                push @transformed, $words[$i];
            }
        }
    }
    
    # transform string
    if (@transformed) {
        for (my $i = 0; $i <= $#words; $i++) {
            $string =~ s/\b$words[$i]\b/$transformed[$i]/;
        }
    }

    return $string;
}


sub copy_profile {
    my %options = @_;
    
    my $from    = $options{from};
    my $to      = $options{to};
    my $strict  = $options{strict};
    my $exclude = $options{exclude};
    
    if ( $from && $to ) {
        
        if ( $exclude || $strict ) {
            
            my %ref_profile = get_profile( $from, {
                                                   exclude => $exclude,
                                                   strict => $strict
                                                  }
                                         );
            
            $ref_profile{exclude} = $exclude;
            
            return set_profile( $to, %ref_profile );
            
        } else {
            
            return set_profile($options{to}, get_profile($options{from}));
            
        }
        
    } elsif ( !$from && !$to ) {
        
        carp "Missing parameters\n";
        return '';
        
    } elsif ( !$from ) {
        
        carp "Missing reference string\n";
        return $to;
        
    } else {
        
        carp "Missing target string\n";
        return '';
        
    }
}


sub _word_type {
    my ($word) = @_;
    
    if ($word =~ /^[bcdfghjklmnpqrstvwxyz]$/i) {
        return 'other';
    } elsif ($word =~ /^\p{Lu}(?:\p{Ll}|[-'\x92\xB7])*$/) {
        return '1st_uc';
    } elsif ($word =~ /^(?:\p{Ll}|[-'\x92\xB7])+$/) {
        return 'all_lc';
    } elsif ($word =~ /^(?:\p{Lu}|[-'\x92\xB7])+$/) {
        return 'all_uc';
    } else {
        return 'other';
    }
    
}


sub _string_type {
    
    my $strict = shift;
    my @types = @_;
    
    my $types_str = join "", map { $types{$_} } grep { $_ ne 'excluded' } @types;
    
    # remove 'other' word types
    my $clean_str = $types_str;
    $clean_str =~ s/o//g unless $strict;
    
    my $string_type;
    
    if ($clean_str =~ /^fl*$/) {    
        $string_type = '1st_uc';        
    } elsif ($clean_str =~ /^u+$/) {
        $string_type = 'all_uc';
    } elsif ($clean_str =~ /^l+$/) {
        $string_type = 'all_lc';
    } else {
        $string_type = 'other';
    }
    
    return ($types_str, $string_type);
}


sub _transform {
    my ($type, $word, $word_type, $force) = @_;
    
    return $word if ($word_type eq 'other' && !$force);
    
    my %dispatch = (
                    '1st_uc' => ucfirst(lc($word)),
                    'all_uc' => uc($word),
                    'all_lc' => lc($word),
                    'other'  => $word,
                   );
    
    $dispatch{$type};
}


1;
__END__

=encoding utf8

=head1 NAME

String::CaseProfile - Get/Set the letter case profile of a string

=head1 VERSION

Version 0.18 - February 9, 2010

=head1 SYNOPSIS

    use String::CaseProfile qw(get_profile set_profile copy_profile);
    
    my $reference_string = 'Some reference string';
    my $string = 'sample string';
    
    
    # Typical, single-line usage
    my $target_string = set_profile($string, get_profile($reference_string));
    
    # Alternatively, you can use the 'copy_profile' convenience function:
    my $target_string = copy_profile(
                                        from => $reference_string,
                                        to   => $string,
                                    );
    
    
    # Get the profile of a string and access the details
    my %ref_profile = get_profile($reference_string);
    
    my $string_type = $ref_profile{string_type};
    my $profile_str = $ref_profile{fold};             # 'fll'
    my $word        = $ref_profile{words}[2]->{word}; # third word
    my $word_type   = $ref_profile{words}[2]->{type};
    
    # See a profile report
    print "$ref_profile{report}";        # No need to add \n
    
    # Apply the profile to another string
    my $new_string  = set_profile($string, %ref_profile);
    
    
    # Use custom profiles
    my %profile1 = ( string_type => '1st_uc' );
    $new_string  = set_profile($string, %profile1);
    
    my %profile2 = ( string_type => 'all_lc', force_change => 1 );
    $new_string  = set_profile($string, %profile2);
    
    my %profile3 = (
                    custom => {
                                default => 'all_lc',
                                all_uc  => '1st_uc',
                                index   => {
                                            3 => '1st_uc',
                                            5 => 'all_lc',
                                           },
                               }
                    );
    $new_string  = set_profile($string, %profile3);



=head1 DESCRIPTION

This module provides a convenient way of handling the recasing (letter case
conversion) of sentences/phrases/chunks in machine translation, case-sensitive
search and replace, and other text processing applications.

String::CaseProfile includes three functions:

B<get_profile> determines the letter case profile of a string.

B<set_profile> applies a letter case profile to a string; you can apply a
profile determined by get_profile, or you can create your own custom profile.

B<copy_profile> gets the profile of a string and applies it to another string
in a single step.

These functions are Unicode-aware and support text in languages based on alphabets
which feature lowercase and uppercase letter forms (Roman, Greek, Cyrillic and
Armenian).
You must feed them utf8-encoded strings.

B<get_profile> and B<set_profile> use the following identifiers to classify
word and string types according to their case:

=over 4

=item * C<all_lc>

In word context, it means that all the letters are lowercase.
In string context, it means that every word is of C<all_lc> type.

=item * C<all_uc>

In word context, it means that all the letters are uppercase.
In string context, it means that every word is of C<all_uc> type.

=item * C<1st_uc>

In word context, it means that the first letter is uppercase,
and the other letters are lowercase.
In string context, it means that the type of the first word is C<1st_uc>,
and the type of the other words is C<all_lc>.

=item * C<other>

Undefined type (e.g. a CamelCase code identifier in word context, or a
string containing several alternate types in string context.)

=back


=head1 FUNCTIONS


B<NOTE:> The syntax of the B<get_profile> function changed slightly in v0.16.
The old syntax (see L<http://search.cpan.org/~enell/String-CaseProfile-0.15/lib/String/CaseProfile.pm>)
still works, but eventually it will be deprecated. 


=over 4

=item C<get_profile( $string, { exclude =E<gt> $excluded, strict =E<gt> $strict } )>

Returns a hash containing the profile details for $string.

The string provided must be encoded as B<utf8>. This is the only required parameter.

You can also specify a hash reference containing any of the following optional
parameters:

=over 4

=item * C<exclude>

A reference to a list of terms that should not be considered when determining
the profile of $string (e.g., the word "Internet" in some cases, or
the first person personal pronoun in English, "I").

=item * C<strict>

A parameter that you can set to to a true value if you want to consider
'Other'-type words when determining the string type.
By default, this parameter is set to false.

=back

The keys of the returned hash are the following:

=over 4

=item * C<string_type>

Scalar containing the string type, if it can be determined; otherwise,
its value is 'other'.

=item * C<fold>

Pattern string created by mapping each word type to a single-letter code:

    1st_uc => 'f'
    all_uc => 'u'
    all_lc => 'l'
    other  => 'o'


For instance, the patterns of the common types are:

    1st_uc:  ^fl*$
    all_uc:  ^u+$
    all_lc:  ^l+$

This feature can be useful to process 'other' string types using regular expressions.
E.g., you can use it to detect (probable) title case strings:

    if ( $profile{fold} =~ /^f[fl]*f$/ ) {
        # some code here
    }

=item * C<words>

Reference to an array containing a hash for every word in the string.
Each hash has two keys: B<word> and B<type>.

=item * C<report>

Returns a string containing a summary of the string profile.

=back

=back

=over 4

=item C<set_profile( $string, %profile )>

Applies %profile to $string and returns a new string. $string must be encoded
as B<utf8>. The profile configuration parameters (hash keys) are the following:

=over 4

=item * C<string_type>

You can specify one of the string types mentioned above (except 'other') as the
type that should be applied to the string.

=item * C<custom>

As an alternative, you can define a custom profile as a reference to a hash in
which you can specify types for specific word (zero-based) positions, conversions
for the types mentioned above, and you can define a 'default' type for the words
for which none of the preceding rules apply. The order of evaluation is 1) index,
2) type conversion, 3) default type. For more information, see the examples below.

=item * C<exclude>

Optionally, you can specify a list of words that should not be affected by the
B<get_profile> function. The value of the C<exclude> key should be an array
reference. The case profile of these words won't change unless the target
string type is 'all_uc'.

=item * C<force_change>

By default, set_profile will ignore words with type 'other' when applying
the profile. You can use this boolean parameter to enable changing this
kind of words.

=back

=back

=over 4

=item C<copy_profile(from =E<gt> $source, to =E<gt> $target, [ exclude =E<gt> $array_ref ])>

Gets the profile of C<$source>, applies it to C<$target>, and returns
the resulting string.

You can also specify words that should be excluded both in the input string
and the target string:

    copy_profile(
                    from    => $source,
                    to      => $target,
                    exclude => $array_ref,
                    strict  => $strict,
                );

This is just a convenience function. If C<copy_profile> cannot determine
the profile of the source string, it will leave unchanged the target string.
If you need more control, you should use the C<get_profile> and C<set_profile>
functions.

=back

B<NOTES:>

When these functions process excluded words, they also consider compound
words that include them, like "Internet-based" or "I've".

The list of excluded words is case-sensitive (i.e., if you exclude the word 'MP3',
its lowercase version, 'mp3', won't be excluded unless you add it to the list).



=head1 EXAMPLES

    use String::CaseProfile qw(
                                get_profile
                                set_profile
                                copy_profile
                               );
    use Encode;
    
    my @strings = (
                    'Entorno de tiempo de ejecución',
                    'è un linguaggio dinamico',
                    'langages dérivés du C',
                  );


    # Encode strings as utf-8, if necessary
    my @samples = map { decode('iso-8859-1', $_) } @strings;

    my $new_string;


    # EXAMPLE 1: Get the profile of a string
    
    my %profile = get_profile( $samples[0] );

    print "$profile{string_type}\n";   # prints '1st_uc'
    my @types = $profile{string_type}; # 1st_uc all_lc all_lc all_lc all_lc
    my @words = $profile{words};       # returns an array of hashes



    # EXAMPLE 2: Get the profile of a string and apply it to another string
    
    my $ref_string1 = 'REFERENCE STRING';
    my $ref_string2 = 'Another reference string';

    $new_string = set_profile( $samples[1], get_profile( $ref_string1 ) );
    # The current value of $new_string is 'È UN LINGUAGGIO DINAMICO'

    $new_string = set_profile( $samples[1], get_profile( $ref_string2 ) );
    # Now it's 'È un linguaggio dinamico'
    
    # Alternative, using copy_profile
    $new_string = copy_profile( from => $ref_string1, to => $samples[1] );
    $new_string = copy_profile( from => $ref_string2, to => $samples[1] );



    # EXAMPLE 3: Change a string using several custom profiles

    my %profile1 = ( string_type  => 'all_uc' );
    
    $new_string = set_profile( $samples[2], %profile1 );
    # $new_string is 'LANGAGES DÉRIVÉS DU C'
    
    my %profile2 = ( string_type => 'all_lc', force_change => 1 );
    
    $new_string = set_profile( $samples[2], %profile2 );
    # $new_string is 'langages dérivés du c'
    
    my %profile3 = (
                    custom  => {
                                default => 'all_lc',
                                index   => { '1'  => 'all_uc' }, # 2nd word
                               }
                   );
    
    $new_string = set_profile( $samples[2], %profile3 );
    # $new_string is 'langages DÉRIVÉS du C'

    my %profile4 = ( custom => { all_lc => '1st_uc' } );
    
    $new_string = set_profile( $samples[2], %profile4 );
    # $new_string is 'Langages Dérivés Du C'



More examples, this time excluding words:


    # A second batch of sample strings
    @strings = (
                'conexión a Internet',
                'An Internet-based application',
                'THE ABS MODULE',
                'Yes, I think so',
                "this is what I'm used to",
               );
               
    # Encode strings as utf-8, if necessary
    my @samples = map { decode('iso-8859-1', $_) } @strings;



    # EXAMPLE 4: Get the profile of a string excluding the word 'Internet'
    #            and apply it to another string

    my %profile = get_profile( $samples[0], { exclude => ['Internet'], } );

    print "$profile{string_type}\n";      # prints  'all_lc'
    print "$profile{words}[2]->{word}\n"; # prints 'Internet'
    print "$profile{words}[2]->{type}\n"; # prints 'excluded'

    # Set this profile to $samples[1], excluding the word 'Internet'
    $profile{exclude} = ['Internet'];
    
    $new_string = set_profile( $samples[1], %profile );

    print "$new_string\n"; # prints "an Internet-based application", preserving
                           # the case of the 'Internet-based' compound word



    # EXAMPLE 5: Set the profile of a string containing a '1st_uc' excluded word
    #            to 'all_uc'

    %profile = ( string_type => 'all_uc', exclude => ['Internet'] );
    
    $new_string = set_profile( $samples[0], %profile );
    
    print "$new_string\n";   # prints 'CONEXIÓN A INTERNET', as expected, since
                             # the case profile of a excluded word is not preserved
                             # if the target string type is 'all_uc'



    # EXAMPLE 6: Set the profile of a string containing an 'all_uc'
    #            excluded word to 'all_lc'
    
    %profile = ( string_type => 'all_lc', exclude => ['ABS'] );
    
    $new_string = set_profile( $samples[2], %profile );

    print "$new_string\n";   # prints 'the ABS module', preserving the 
                             # excluded word case profile


    # EXAMPLE 7: Get the profile of a string containing the word 'I' and
    #            apply it to a string containing the compound word 'I'm'
    #            using the copy_profile function

    $new_string = copy_profile(
                                from    => $samples[3],
                                to      => $samples[4],
                                exclude => ['I'],
                              );

    print "$new_string\n";   # prints "This is what I'm used to"



    # EXAMPLE 8: Change a string using a custom profile
    
    %profile = (
                    custom  => {
                                default => '1st_uc',
                                index   => { '1'  => 'all_lc' }, # 2nd word
                               },
                    exclude => ['ABS'],
               );

    $new_string = set_profile( $samples[2], %profile );
    print "$new_string\n";  # prints 'The ABS Module'



Yet more examples using other alphabets:


    use utf8;
    
    binmode STDOUT, ':utf8';

    # Samples using other alphabets
    my @samples = ( 
                    'Ծրագրի հեղինակների ցանկը',              # Armenian
                    'Λίστα των συγγραφέων του προγράμματος', # Greek
                    'Список авторов программы',              # Cyrillic
                  );
    
    my $new_string;

    
    # EXAMPLE 9: Get the profile of a string
    
    my %profile = get_profile( $samples[0] );

    print "$profile{string_type}\n";   # prints '1st_uc'
    
    
    # EXAMPLE 10: Change a string using a custom profile
    
    %profile = ( string_type  => 'all_uc');
    
    $new_string = set_profile($samples[0], %profile);
    
    print "$new_string\n"; # prints 'ԾՐԱԳՐԻ ՀԵՂԻՆԱԿՆԵՐԻ ՑԱՆԿԸ'
    
    
    # EXAMPLE 11: Get the profile of a string and apply it to another string
    
    print set_profile($samples[1], get_profile($new_string)); # prints 'ΛΊΣΤΑ ΤΩΝ ΣΥΓΓΡΑΦΈΩΝ ΤΟΥ ΠΡΟΓΡΆΜΜΑΤΟΣ'
    print "\n";
    
    
    # EXAMPLE 12: More custom profiles
    
    my %profile1 = (
                    custom  => {
                                default => 'all_lc',
                                index   => { '1'  => 'all_uc' }, # 2nd word
                               }
                   );
                
    my %profile2 = ( custom => { 'all_lc' => '1st_uc' } );
    
    print set_profile($samples[2], %profile1); # prints 'список АВТОРОВ программы'
    print "\n";
    
    print set_profile($samples[2], %profile2); # prints 'Список Авторов Программы'
    print "\n";




=head1 EXPORT

None by default.

=head1 LIMITATIONS

Since String::CaseProfile is a multilanguage module and title case is a
language-dependent feature, the functions provided don't handle title
case capitalization (in the See Also section you will find further
information on modules you can use for this task). Anyway, you can use
the profile information provided by get_profile to implement a solution
for your particular case.

For the German language, which has a peculiar letter case rule consisting in
capitalizing every noun, these functions may have a limited utility, but you
can still use the profile information to create and apply customs profiles.


=head1 SEE ALSO

Lingua::EN::Titlecase

Text::Capitalize

L<http://en.wikipedia.org/wiki/Capitalization>

=head1 ACKNOWLEDGEMENTS

Many thanks to Xavier Noria and Joaquín Ferrero for wise suggestions.

=head1 AUTHOR

Enrique Nell, E<lt>blas.gordon@gmail.comE<gt>


=head1 BUGS

Please report any bugs or feature requests to C<bug-string-caseprofile at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=String-CaseProfile>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc String::CaseProfile


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=String-CaseProfile>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/String-CaseProfile>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/String-CaseProfile>

=item * Search CPAN

L<http://search.cpan.org/dist/String-CaseProfile/>

=back


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2010 by Enrique Nell, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
