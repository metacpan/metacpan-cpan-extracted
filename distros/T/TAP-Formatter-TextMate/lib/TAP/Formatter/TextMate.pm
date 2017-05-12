package TAP::Formatter::TextMate;

use warnings;
use strict;
use Carp;
use TAP::Formatter::TextMate::Session;

our $VERSION = '0.1';
use base 'TAP::Formatter::Console';

=head1 NAME

TAP::Formatter::TextMate - Generate TextMate compatible test output

=head1 VERSION

This document describes TAP::Formatter::TextMate version 0.1

=head1 SYNOPSIS

Create a TextMate command that looks something like this:

    test=''
    opts='-rb'
    if [ ${TM_FILEPATH:(-2)} == '.t' ] ; then
        test=`echo $TM_FILEPATH | perl -pe "s{^$TM_PROJECT_DIRECTORY/+}{}"`
        opts='-b'
    fi
    cd $TM_PROJECT_DIRECTORY && prove --merge --formatter TAP::Formatter::TextMate $opts $test
  
=head1 DESCRIPTION

Generates TextMate compatible HTML test output.

=head1 INTERFACE 

=head2 C<prepare>

Called by Test::Harness before any test output is generated. 

=cut

sub prepare {
    my ( $self, @tests ) = @_;

    my $html = $self->_html;

    $self->_raw_output(
        $html->open( 'html' ),
        $html->head( [ \'style', $self->_stylesheet ] ),
        $html->open( 'body' ), "\n"
    );

    $self->SUPER::prepare( @tests );
}

=head3 C<open_test>

Called to create a new test session.

=cut

sub open_test {
    my ( $self, $test, $parser ) = @_;

    my $session = TAP::Formatter::TextMate::Session->new(
        {
            name      => $test,
            formatter => $self,
            parser    => $parser
        }
    );

    $session->header;

    return $session;
}

=head3 C<summary>

  $harness->summary( $aggregate );

C<summary> prints the summary report after all tests are run.  The argument is
an aggregate.

=cut

sub summary {
    my ( $self, $aggregate ) = @_;
    my $html = $self->_html;
    $self->SUPER::summary( $aggregate );
    $self->_raw_output( $html->close( 'body' ), $html->close( 'html' ), "\n" );
}

sub _html {
    my $self = shift;
    return $self->{_html} ||= HTML::Tiny->new;
}

sub _set_colors {
    my $self = shift;
    # red white on_blue reset
    for my $col ( @_ ) {
        if ( $col =~ /on_(\w+)/ ) {
            $self->{_bg} = $1;
        }
        elsif ( $col eq 'reset' ) {
            $self->{_fg} = $self->{_bg} = undef;
        }
        else {
            $self->{_fg} = $col;
        }
    }
}

sub _newline {
    my $self = shift;
    $self->_output( "\n" ) if $self->{_nl};
}

sub _output {
    my $self = shift;
    my $out  = join( '', @_ );
    my $html = $self->_html;
    my $br   = $html->br;
    my $hr   = $html->hr;
    $self->{_nl} = substr( $out, -1 ) ne "\n";
    $out =~ s/\r//g;
    if ( $out =~ /^[\s-]+$/ ) {
        $out =~ s/-{5,}\s*/$hr/g;
    }
    else {
        $out = $html->entity_encode( $out );
    }
    $out =~ s/\n/$br\n/g;
    my ( $bg, $fg ) = ( $self->{_bg}, $self->{_fg} );

    if ( $bg || $fg ) {
        my @style = ();
        push @style, 'color: ' . $fg            if $fg;
        push @style, 'background-color: ' . $bg if $bg;
        $out = $html->span( { style => join( ';', @style ) }, $out );
    }
    $self->_raw_output( $out );
}

sub _raw_output {
    my $self = shift;
    print join '', @_;
}

sub _stylesheet {
    return <<CSS;

body, html {
    color: green;
    background-color: black;
    font-family: monospace;
}

.fail {
    color: red;
    background: #222;
}

CSS
}

1;
__END__

=head1 CONFIGURATION AND ENVIRONMENT
  
TAP::Formatter::TextMate requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-tap-formatter-textmate@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Andy Armstrong C<< <andy@hexten.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
