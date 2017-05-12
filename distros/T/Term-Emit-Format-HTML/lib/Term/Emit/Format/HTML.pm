# Term::Emit::Format::HTML - Formats Term::Emit output into HTML
#
# $Id: HTML.pm 23 2009-02-13 17:41:11Z steve $

package Term::Emit::Format::HTML;
use warnings;
use strict;
use 5.008;

our $VERSION = '0.0.2';
use Exporter;
use base qw/Exporter/;
our @EXPORT_OK = qw/format_html/;
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

sub format_html {
    my $opts = ref $_[0] eq 'HASH' ? shift : {};
    my $text = shift;
    my @lines = split(/\n/, $text);
    my %indent_index = ();
    my $prior_ix = 0;
    my $prior_he = 0;
    my $blob = q{};
    my @blobs = ();
    foreach my $line (@lines) {
        $line = _clean_line($line);
        next if length $line == 0;
        my $blip = _extract_blip($line);
        my $he = _has_ellipsis($line);
        my $st = _has_status($line);
        my $ix = _amount_of_indentation($line);
        $indent_index{$ix}++;

        # Level changed (with or without status): a blob transition
        if ($ix != $prior_ix) {
            # Close off prior blob
            push @blobs, {-indent => $prior_ix,
                          -status => undef,
                          -style  => $prior_he? 'h' : 'p',
                          -text   => $blob,
                         } if length $blob;

            # Start this blob
            $blob = $blip;
            $prior_ix = $ix;

            # Finish it now?
            if ($st) {
                # Look back to close the balancing open
                my $info = _find_rollback($blob, $ix, \@blobs);
                if ($info) {
                    $info->{-status} = $st;
                }
                else {
                    push @blobs, {-indent => $ix,
                                -status => $st,
                                -style  => 'h',
                                -text   => $blob,
                                } if length $blob;
                }
                $blob = q{};
            }
            elsif ($he) {
                push @blobs, {-indent => $ix,
                              -status => undef,
                              -style  => 'h',
                              -text   => $blob,
                             } if length $blob;
                $blob = q{};
            }
        }

        # Same level, has status - add to & finish a multiline wrap
        elsif ($st) {
            $blob .= q{ } if length $blob;
            $blob .= $blip;
            if (length $blob) {
                push @blobs, {-indent => $ix,
                              -status => $st,
                              -style  => 'h',
                              -text   => $blob,
                             };
                $blob = q{};
            }
        }

        # Same level, no status, just ellipsis - add to & finish the prior blob
        elsif ($he) {
            $blob .= q{ } if length $blob;
            $blob .= $blip;
            if (length $blob) {
                push @blobs, {-indent => $ix,
                              -status => undef,
                              -style  => 'h',
                              -text   => $blob,
                             };
                $blob = q{};
            }
        }

        # Same level, no status, no ellipsis - we are continuing the prior blob
        else {
            $blob .= q{ } if length $blob;
            $blob .= $blip;
        }

        $prior_he = $he;
    }

    # Anything left over?
    push @blobs, {-indent => $prior_ix,
                  -status => undef,
                  -style  => $prior_he? 'h' : 'p',
                  -text   => $blob,
                 } if length $blob;

    # Determine levels from indentation
    my $lev = 0;
    foreach my $ix (sort {$a <=> $b} keys %indent_index) {
        $indent_index{$ix} = ++$lev;
    }

    # Make the HTML
    my $html = q{};
    foreach my $b (@blobs) {
        my $level = $indent_index{$b->{-indent}} || 0;
        $html .= q{  } x $level;
        if ($b->{-style} eq 'h') {
            ### TODO: handle levels > 6
            $html .= qq{<h$level};
            if ($b->{-status}) {
                my $cls = lc $b->{-status};
                $html .= qq{ class="$cls"};
            }
            $html .= qq{>$b->{-text}};
            $html .= qq{</h$level>\n};
        }
        else {
            $html .= qq{<p>$b->{-text}</p>\n};
        }
    }

    return $html;
}

sub _amount_of_indentation {
    my $line = shift;
    return length $1 if $line =~ m{^(\s+)\S}sxm;
    return 0;
}

sub _clean_line {
    my $line = shift;

    # Remove bullets
    $line =~ s{^\s?[\#\@\*\+\-\.]}{}sxm;

    # Remove backspaced-over content
    while ($line =~ s{[^\010]\010}{}sxm) {};

    # Trim trailing only
    $line =~ s{\s+$}{}sxm;
    return $line;
}

sub _extract_blip {
    my $line = shift;   # presumes already cleaned line
    return q{}
        unless $line =~ m{\s*               # Skip leading space
                          (.+?)             # The blob we want
                          \s*               # Possible trailing space
                          (\.\.\.           # Maybe ellipsis
                            .*?             # Maybe anything else, like prog/over
                            (\s\[\S+\])?    # with  [STAT]
                          )?$               # to end of line
                         }sxm;
    return $1;
}

sub _find_rollback {
    my ($blob, $ix, $blobs) = @_;
    foreach my $b (reverse @{$blobs}) {
        if ($b->{-indent} == $ix) {
            return $b
                if $b->{-text} eq $blob;
            last;
        }
    }
    return 0;
}

sub _has_ellipsis {
    my $line = shift;
    return $line =~ m{[^\.]                 # Any non-dot
                        \.\.\.              # Then three dots in a row
                        (.+?                # Maybe anything else
                            (\s\[\S+\])?    # with  [STAT]
                        )?$                 # to end of line
                      }sxm;
}

sub _has_status {
    my $line = shift;
    return $line =~ m{\s\[(\S+)\]$}sxm? $1 : 0;
}

1;
__END__

=head1 NAME

Term::Emit::Format::HTML - Formats Term::Emit output into HTML


=head1 VERSION

This document describes Term::Emit::Format::HTML version 0.0.2


=head1 SYNOPSIS

    use Term::Emit::Format::HTML 'format_html';
    my $out = "some output from Term::Emit";
    my $html = format_html($out);


=head1 DESCRIPTION

This module reformats the output from an application that
uses L<Term::Emit|Term::Emit> into a chunk of HTML,
which you can embed in a web page.

This module is handy if you write Web UIs that wrap a command line
utility and show the output from that utility on a web page.

Suppose you have a utility that produces this output:

    Quobalating all frizzles...
        We operate on only the first and
        second frizzles in this step.
      Merfubbing primary frizzle.......... [OK]
      Xylokineting secondary frizzle...... [WARN]
    Quobalating all frizzles.............. [DONE]

This module can parse that output and convert it into this:

    <h1 class="done">Quobalating all frizzles</h1>
      <p>We operate on only the first and second frizzles in this step.</p>
      <h2 class="ok">Merfubbing primary frizzle</h2>
      <h2 class="warn">Xylokineting secondary frizzle</h2>

Note how the steps that have completed with a status, such as [OK] or [DONE],
get tagged in the resulting HTML with a class.  This simple hook allows you
to do some fancy CSS so you can associate images, colors, and so forth
with the output to really spiff up your web page.


=head1 SUBROUTINES/METHODS

=head2 format_html ( STRING )

This function parses the given STRING and returns an HTML string.
The input STRING is presumed to be the captured output of some
other application that uses L<Term::Emit|Term::Emit>.

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

Term::Emit::Format::HTML requires no configuration files or environment variables.


=head1 DEPENDENCIES

None.


=head1 INCOMPATIBILITIES


None reported.


=head1 BUGS AND LIMITATIONS

B<This is ALPHA code!>  It is not yet complete, but it's working well
enough for simple, non-demanding cases.  Use at your own risk!

The heuristic this module uses is rather simple-minded,
and relies upon indentation to figure out nesting depths.
If you set the indentation I<-step> to 0 in Term::Emit, then
this module will not be able to properly parse the string,
even with bullets enabled.  I hope to make it smarter in a
future release (so it can tell nesting depth from the bullets, too).


No bugs have been reported.

Please report any bugs or feature requests to
C<bug-term-emit-format-html@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Steve Roscio  C<< <roscio@cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, Steve Roscio C<< <roscio@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

Because this software is licensed free of charge, there is no warranty
for the software, to the extent permitted by applicable law.  Except when
otherwise stated in writing the copyright holders and/or other parties
provide the software "as is" without warranty of any kind, either
expressed or implied, including, but not limited to, the implied
warranties of merchantability and fitness for a particular purpose.  The
entire risk as to the quality and performance of the software is with
you.  Should the software prove defective, you assume the cost of all
necessary servicing, repair, or correction.

In no event unless required by applicable law or agreed to in writing
will any copyright holder, or any other party who may modify and/or
redistribute the software as permitted by the above licence, be
liable to you for damages, including any general, special, incidental,
or consequential damages arising out of the use or inability to use
the software (including but not limited to loss of data or data being
rendered inaccurate or losses sustained by you or third parties or a
failure of the software to operate with any other software), even if
such holder or other party has been advised of the possibility of
such damages.

=for me to do:
    * Provide an option to generate lists instead of head's.
