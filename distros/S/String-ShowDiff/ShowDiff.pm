package String::ShowDiff;

use strict;

require Exporter;

use vars qw/@ISA %EXPORT_TAGS @EXPORT_OK @EXPORT $VERSION/;

@ISA = qw(Exporter);

%EXPORT_TAGS = ( 'all' => [ qw(
    ansi_colored_diff
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw(
	
);

$VERSION = '0.03';

use Algorithm::Diff qw/sdiff/;
use Term::ANSIColor qw/colored/;

sub ansi_colored_diff {
    my ($string, $changed_string, $options) = @_;
    $options ||= {};
    my %colors = (
        '-' => $options->{'-'} || 'on_red',
        '+' => $options->{'+'} || 'on_green',
        'u' => $options->{'u'} || 'reset',
    );
    my $context_re = $options->{context} || qr/.*/;
    my $gap        = $options->{gap}     || '';
    
    my @sdiff = sdiff(map {[split //, $_]} $string, $changed_string);
    my @ansi;
    my $first_while_loop = 1;
    while (@sdiff and my ($mod, $s1, $s2) = @{shift @sdiff}) {
        if ($mod =~ /[+-]/) { 
            push @ansi, colored($s1 || $s2, $colors{$mod});
        } else {  # Must be either a change or a part of unchanged characters
                  # So take a look, whether there are more chars that should be
                  # handled in a row
            while (@sdiff && $sdiff[0]->[0] eq $mod) {
                $s1 .= $sdiff[0]->[1];          # if so, join all chars from the old
                                                # string to $s1
                $s2 .= $sdiff[0]->[2];          # and from the new to $s2
                shift @sdiff;                   # The information of this element
                                                # is already in $s1, $s2 and $mod
                                                # and thus unnecessary now
            }
            if ($mod eq 'u') {
                my $unchanged_part = _construct_glue(
                    $s1, $context_re, $gap, $first_while_loop, @sdiff==0
                );
                push @ansi, _colorize_string($unchanged_part, $colors{'u'});
            } else {
                push @ansi,
                    _colorize_string($s1, $colors{'-'}), 
                    _colorize_string($s2, $colors{'+'}); 
            }		     
        }
        $first_while_loop = 0;
    }
    return join "", @ansi;
}

# call with _colorize_string($string, $color)
sub _colorize_string { join "", map {colored($_,$_[1])} split //, $_[0] }

sub _construct_glue {
    my ($full_string, $context_re, $gap, $at_beginning, $at_end) = @_;
    my ($start) = $full_string =~ /^($context_re)/;
    my ($end)   = $full_string =~ /($context_re)$/;
    $_ ||= "" for ($start, $end);

    # Return now the shorter string of either a constructed context with a gap
    # string or the normal string between the two differences                          
    my $start_gap_end = $start . $gap . $end;
    return length($start_gap_end) < length($full_string)
        ? $start_gap_end
        : $full_string;
}

1;
__END__

=head1 NAME

String::ShowDiff - Perl extension to help visualize differences between strings

=head1 SYNOPSIS

  use String::ShowDiff qw/ansi_colored_diff/;
  print ansi_colored_diff("abcehjlmnp", "bcdefjklmrst");

  # or a bit more detailed:
  my %options = ('u' => 'reset',
                 '+' => 'on_green',
        		 '-' => 'on_red');
  print ansi_colored_diff($oldstring, $newstring, \%options);

  # or let's see only the changed words 
  print ansi_colored_diff($old, $new, {context => qr/\w*/, gap => ' '});

=head1 DESCRIPTION

This module is a wrapper around the diff algorithm from the module
C<Algorithm::Diff>. It's job is to simplify a visualization of the differences of each strings.

Compared to the many other Diff modules,
the output is neither in C<diff>-style nor are the recognised differences on line or word boundaries,
they are at character level.

=head2 FUNCTIONS

=over 1

=item ansi_colored_diff $string, $changed_string, $options_hash;

This method compares C<$string> with C<$changed_string> 
and returns a string for an output on an ANSI terminal.
Removed characters from C<$string> are shown by default with a red background,
while added characters to C<$changed_string> are shown by default with a green background
(the unchanged characters are shown with the default values for the terminal).

The C<$options_hash> allows you to set the colors for the output and
the context to be shown.
The variable is a reference to a hash 
with the optional keys: 'u' for the color of the unchanged parts,
'-', '+' for the color of the removed and the added parts,
'context' for a regexp specifying the context that shall be shown
before and after a changed part and
'gap' for the string that shall be shown between the contexts of two changings.
The default values for the options are:

    my $default_options = {
	'u'       => 'reset',
	'-'       => 'on_red',
	'+'       => 'on_green',
    'context' => qr/.*/,
    'gap'     => '',
    };

The specified colors must follow the conventions for the
C<colored> method of L<Term::ANSIColor>.
Please read its documentation for details.

The specified context must be a valid regexp, constructed with the 
C<qr/.../> operator (or alternatively a string defining a valid regexp). 
Internal the context around a changing is created with 
matching the preceding substring with C</($context_re)$> and the succeeding
substring with C<^($context_re)>. That is important to know if you want to work
with backreferences. As an additional group encloses your regexp pattern, the
first of your own defined subgroup is in C<$2> instead of C<$1>. (That's not
very nice, but still better than paying the price of using C<$&>).

The C<gap> parameter describes how to fill the gap between two shown changings
in their context. Here are some examples of these parameters:

    print ansi_colored_diff($s1, $s2, {context => qr/.*/, gap => ''}); # default
    # will print the complete combined string with the marked removings and
    # additions

    print ansi_colored_diff($s1, $s2, {context => qr/.{0,3}/, gap => ' ... '});
    # will print all changings with a context of the left and right 3 chars
    # and will join each of them with a space, 3 dots and a space
    # Note that it is important to use qr/.{0,3}/ instead of qr/.../ to also
    # show only a context of 0,1 or 2 chars at the beginning or end of the
    # strings

    print ansi_colored_diff($s1, $s2, {context => qr/\w*/, gap => ' '})
    # will print all changed words and seperates them with a blank
    
=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<Term::ANSIColor>

L<Algorithm::Diff>,
L<Text::Diff>,
L<Text::ParagraphDiff>,
L<Test::Differences>

=head1 AUTHOR

Janek Schleicher, E<lt>bigj@kamelfreund.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Janek Schleicher

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
