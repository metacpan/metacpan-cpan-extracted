#===============================================================================
#
#  DESCRIPTION:  Implement E (Entities)
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
package Perl6::Pod::FormattingCode::E;
use warnings;
use strict;
use Data::Dumper;
use Perl6::Pod::FormattingCode;
use base 'Perl6::Pod::FormattingCode';
our $VERSION = '0.01';

=pod

=head1 NAME

Perl6::Pod::FormattingCode::E - include named Unicode or XHTML entities

=head1 SYNOPSIS

        Perl 6 makes considerable use of E<171> and E<187>.
    
        C<1E<VERTICAL LINE>2>
   
        my $label-area-width = 1 + [max] @scoresE<raquo>.keyE<raquo>.chars;


=head1 DESCRIPTION

If the contents of the C<EE<lt>E<gt>> are a number, that number is treated as the decimal Unicode value for the desired codepoint. For example:

    Perl 6 makes considerable use of E<171> and E<187>.

You can also use explicit binary, octal, decimal, or hexadecimal numbers (using the Perl 6 notations for explicitly based numbers):

    Perl 6 makes considerable use of E<0b10101011> and E<0b10111011>.
    Perl 6 makes considerable use of E<0o253> and E<0o273>.
    Perl 6 makes considerable use of E<0d171> and E<0d187>.
    Perl 6 makes considerable use of E<0xAB> and E<0xBB>.

If the contents are not a number, they are interpreted as a Unicode character name (which is always upper-case), or else as an XHTML entity. For example:

    Perl 6 makes considerable use of E<LEFT DOUBLE ANGLE BRACKET>
    and E<RIGHT DOUBLE ANGLE BRACKET>.

or, equivalently:

    Perl 6 makes considerable use of E<laquo> and E<raquo>.

Multiple consecutive entities can be specified in a single C<EE<lt>E<gt>> code, separated by semicolons:

    Perl 6 makes considerable use of E<laquo;hellip;raquo>.

=cut

=head2 to_xhtml

    E<lt>

Render to

   &lt;
    
=cut
my %line_break = (NEL=>1);

sub to_xhtml {
    my ( $self, $to ) = @_;
    my $line = $self->childs->[0];
    #split by ;
    [
        map {
            s/^\s+//;
            s/\s+$//;
            if ( exists $line_break{$_} ) {
                $to->w->raw('<br/>')
            } else {
            $to->w->raw( _to_xhtml_entity($_) )
            }
          }
          split( /\s*;\s*/, $line )
    ];
}
sub _to_xhtml_entity {
    my $str = shift;
    if ( $str !~ /^\d/ ) {
        use charnames ':full';
        my $ord = charnames::vianame($str);
        return sprintf( '&#%d;', $ord ) if defined $ord;
        return qq{&$str;};
    }
    # Otherwise, it's the numeric codepoint in some base...
    else {
        # Convert Perl 6 octals and decimals to Perl 5 notation...
        if ($str !~ s{\A 0o}{0}xms) {       # Convert octal
            $str =~ s{\A 0d}{}xms;          # Convert explicit decimal
            $str =~ s{\A 0+ (?=\d)}{}xms;   # Convert implicit decimal
        }

        # Then return the XHTML numeric code...
        return sprintf '&#%d;', eval $str;
    }

    die "Unsupported identity $_ in E<>";
}

=head2 to_docbook

    E<lt>

Render to

   &lt;

=cut

sub to_docbook {
    my ( $self, $to ) = @_;
    my $line = $self->childs->[0];
    #split by ;
    [
        map {
            s/^\s+//;
            s/\s+$//;
            # <br/> not exists in docbook
            if (exists $line_break{$_} ) {()} else {
            $to->w->raw( _to_xhtml_entity($_) )
            }
          }
          split( /\s*;\s*/, $line )
    ];
}

1;
__END__

=head1 SEE ALSO

L<http://zag.ru/perl6-pod/S26.html>,
Perldoc Pod to HTML converter: L<http://zag.ru/perl6-pod/>,
Perl6::Pod::Lib

=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2015 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut




