package String::ShowHTMLDiff;

use strict;

require Exporter;

use vars qw/@ISA %EXPORT_TAGS @EXPORT_OK @EXPORT $VERSION/;

@ISA = qw(Exporter);

%EXPORT_TAGS = ( 'all' => [ qw(
    html_colored_diff
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw(
	
);

$VERSION = '0.01';

use Algorithm::Diff qw/sdiff/;

sub html_colored_diff {
    my ($string, $changed_string, $options) = @_;
    $options ||= {};
    my %colors = (
        '-' => $options->{'-'} || 'diff_minus',
        '+' => $options->{'+'} || 'diff_plus',
        'u' => $options->{'u'} || 'diff_unchanged',
    );
    my $context_re = $options->{context} || qr/.*/;
    my $gap        = $options->{gap}     || '';
    
    my @sdiff = sdiff(map {[split //, $_]} $string, $changed_string);
    my @html;
    my $first_while_loop = 1;
    while (@sdiff and my ($mod, $s1, $s2) = @{shift @sdiff}) {
        if ($mod =~ /[+-]/) { 
            push @html, _colored($s1 || $s2, $colors{$mod});
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
                push @html, _colorize_string($unchanged_part, $colors{'u'});
            } else {
                push @html,
                    _colorize_string($s1, $colors{'-'}), 
                    _colorize_string($s2, $colors{'+'}); 
            }		     
        }
        $first_while_loop = 0;
    }
    return join "", @html;
}

sub _colored {
	my($text, $style) = @_;
	return "<span class='$style'>$text</span>";
}

# call with _colorize_string($string, $color)
sub _colorize_string { join "", map {_colored($_,$_[1])} split //, $_[0] }

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

String::ShowHTMLDiff - Perl extension to help visualize (in a browser) differences between strings.

=head1 SYNOPSIS

  use String::ShowDiff qw/html_colored_diff/;
  print html_colored_diff("abcehjlmnp", "bcdefjklmrst");

  # or a bit more detailed:
  my %options = ('u' => 'reset',
                 '+' => 'on_green',
        		 '-' => 'on_red');
  print html_colored_diff($oldstring, $newstring, \%options);

  # or let's see only the changed words 
  print html_colored_diff($old, $new, {context => qr/\w*/, gap => ' '});

=head1 DESCRIPTION

This module is a slight spin on the String::ShowASCIIDiff module.  It marks up a diff between two strings
using HTML.  YOU supply the style sheet and make it look cool.  A sample style sheet is included.  Basically,
you just have to define the style for the <SPAN> tags that are in the output.  The classes are
  
  unchanged
  diff_minus
  diff_plus
 
See a CSS tutorial if you still don't know what's going on.

This module is a wrapper around the diff algorithm from the module
C<Algorithm::Diff>. 

Compared to the many other Diff modules,
the output is neither in C<diff>-style nor are the recognised differences on line or word boundaries,
they are at character level.

=head2 FUNCTIONS

=over 1

=item html_colored_diff $string, $changed_string, $options_hash;

This method compares C<$string> with C<$changed_string> 
and returns an HTML encoded string.

    print html_colored_diff($s1, $s2, {context => qr/.*/, gap => ''}); # default
    # will print the complete combined string with the marked removings and
    # additions

    print html_colored_diff($s1, $s2, {context => qr/.{0,3}/, gap => ' ... '});
    # will print all changings with a context of the left and right 3 chars
    # and will join each of them with a space, 3 dots and a space
    # Note that it is important to use qr/.{0,3}/ instead of qr/.../ to also
    # show only a context of 0,1 or 2 chars at the beginning or end of the
    # strings

    print html_colored_diff($s1, $s2, {context => qr/\w*/, gap => ' '})
    # will print all changed words and seperates them with a blank
    
=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<Algorithm::Diff>,
L<String::ShowASCIIDiff>,
L<Text::Diff>,
L<Text::ParagraphDiff>,
L<Test::Differences>

=head1 ORIGINAL AUTHOR WHO DID ALL THE WORK

Janek Schleicher, E<lt>bigj@kamelfreund.deE<gt>

=head1 GUY WHO ADDED THE HTML CRAP

Jim Garvin	 E<lt>jg.perl@thegarvin.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Jim Garvin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
