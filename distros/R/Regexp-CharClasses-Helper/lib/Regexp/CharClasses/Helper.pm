use strict;
use warnings;
use v5.15.7;
package Regexp::CharClasses::Helper;

# ABSTRACT: Helper for creating user defined character class strings
our $VERSION = '0.005'; # VERSION

use Carp;
use charnames ':full';
use utf8;

=pod

=encoding utf8

=head1 NAME

Regexp::CharClasses::Helper - User defined character class strings by unicode name or literals


=head1 SYNOPSIS

    use Regexp::CharClasses::Helper;

    sub IsAorPlus {
        return Regexp::CharClasses::Helper::fmt(
            'A',
            'LATIN SMALL LETTER A'
            '+',
        );
    }
    say 'matches' if 'A+' =~ /^\p{IsAorPlus}+$/;

    sub InCapitalsButNot42 {
        return Regexp::CharClasses::Helper::fmt(
            "+A\tZ", # from A till Z
            "-\x42"  # except \x42
        );
    }
    say "doesn't" if 'ABC' =~ /\p{InCapitalsButNot42}+/;
        

=head1 METHODS AND ARGUMENTS

=over 4

=cut

sub _parse {
    my $in = $_[0] || $_;
    croak "Unknown charname '$in'" if $in =~ /^U\+/i;
    return $in if $in =~ /In|Is|::/;
    my $code = length $in == 1 ? ord $in
                               : charnames::vianame $in;
    croak "Unknown charname '$in'" unless defined $code;
    return sprintf '%04x', $code;
}

=item fmt()

Takes in a list and turns it into the format specified by L<User-Defined Character Properties|http://perldoc.perl.org/perlunicode.html#User-Defined-Character-Properties>

=cut

sub fmt {
    return join '', map {
        croak 'undef unexpected' unless defined $_;
        my ($prefix, @out) = ('', $_);
        if (/^[-+!&]/ && !/^[-+!&]($|\t[^\t]|\t\t$)/) {
            $out[0] =~ s/^([-+!&])//;
            $prefix = $1;
        }
        @out = ($1, $2) if $out[0] =~ /^(.+)\t(.+)$/;
        $prefix . join("\t", map {_parse $_} @out) . "\n";
    } @_;
}

1;
__END__

=back

=head1 GIT REPOSITORY

L<http://github.com/athreef/Regexp-CharClasses-Helper>

=head1 SEE ALSO

L<Regexp::CharClasses|Regexp::CharClasses> for a collection of user supplied character classes.
L<Sub::CharacterProperties|Sub::CharacterProperties> generates the subs themselves, but isn't usable at compile time.

L<User-Defined Character Properties|http://perldoc.perl.org/perlunicode.html#User-Defined-Character-Properties> perldoc.

=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
