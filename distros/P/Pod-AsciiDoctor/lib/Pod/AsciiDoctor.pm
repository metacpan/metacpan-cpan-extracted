package Pod::AsciiDoctor;
$Pod::AsciiDoctor::VERSION = '0.102000';
use 5.014;
use strict;
use warnings FATAL => 'all';

use Pod::Parser 1.65 ();
use parent 'Pod::Parser';


sub initialize
{
    my $self = shift;
    $self->SUPER::initialize(@_);
    $self->_prop;
    return $self;
}


sub adoc
{
    my $self = shift;
    my $data = $self->_prop;
    return join "\n", @{ $data->{text} };
}


sub _prop
{
    my $self = shift;
    return $self->{prop} //= {
        'text'       => [],
        'headers'    => "",
        'topheaders' => {},
        'command'    => '',
        'indent'     => 0
    };
}


sub _sanitise
{
    my $self = shift;
    my $p    = shift;
    chomp($p);
    return $p;
}


sub append
{
    my ( $self, $doc ) = @_;
    my $data = $self->_prop;
    push @{ $data->{text} }, $doc;
}


sub command
{
    my ( $self, $command, $paragraph, $lineno ) = @_;
    my $data = $self->_prop;
    $data->{command} = $command;

    # _sanitise: Escape AsciiDoctor syntax chars that appear in the paragraph.
    $paragraph = $self->_sanitise($paragraph);

    if ( my ($input_level) = $command =~ /head([0-9])/ )
    {
        my $level = $input_level;
        $level //= 2;
        $data->{command} = 'head';
        $data->{topheaders}{$input_level} =
            defined( $data->{topheaders}{$input_level} )
            ? $data->{topheaders}{$input_level}++
            : 1;
        $paragraph = $self->set_formatting($paragraph);
        $self->append( $self->make_header( $command, $level, $paragraph ) );
    }

    if ( $command =~ /over/ )
    {
        $data->{indent}++;
    }
    if ( $command =~ /back/ )
    {
        $data->{indent}--;
    }
    if ( $command =~ /item/ )
    {
        $self->append( $self->make_text( $paragraph, 1 ) );
    }
    return;
}


sub verbatim
{
    my $self      = shift;
    my $paragraph = shift;
    chomp($paragraph);
    $self->append($paragraph);
    return;
}


sub textblock
{
    my $self = shift;
    my ( $paragraph, $lineno ) = @_;
    chomp($paragraph);
    $paragraph = $self->interpolate($paragraph);
    $self->append($paragraph);
}


sub interior_sequence
{
    my ( $parser, $seq_command, $seq_argument ) = @_;
    ## Expand an interior sequence; sample actions might be:
    return "*$seq_argument*" if ( $seq_command eq 'B' );
    return "`$seq_argument`" if ( $seq_command eq 'C' );
    return "_${seq_argument}_'"
        if ( $seq_command eq 'I' || $seq_command eq 'F' );
    if ( $seq_command eq 'L' )
    {
        my $ret = "";
        my $text;
        my $link;
        if ( $seq_argument =~ /(.+)\|(.+)/ )
        {
            $text = $1;
            $link = $2;
        }
        elsif ( $seq_argument =~ /(.+)/ )
        {
            $text = "";
            $link = $1;
        }
        if ( $link =~ /(.+?\:\/\/)(.+)/ )
        {
            $ret .= "$link";
            $ret .= " [$text]" if ( length($text) );
        }
        elsif ( length($link) )
        {
            # Internal link
            if ( my ( $s, $e ) = $link =~ /(.+)\/(.+)/ )
            {
                $ret = "<< $s#$e >>";
                $ret = "<< $s#$e,$text >>" if ($text);
            }
            else
            {
                $ret = "<< $link >>";
                $ret = "<< $link,$text >>" if ($text);
            }
        }
        return $ret;
    }
}


sub make_header
{
    my ( $self, $command, $level, $paragraph ) = @_;
    if ( $command =~ /head/ )
    {
        my $h = sprintf( "%s %s", "=" x ( $level + 1 ), $paragraph );
        return $h;
    }
    elsif ( $command =~ /item/ )
    {
        return "* $paragraph";
    }
    die "unimplemented";
}


sub make_text
{
    my ( $self, $paragraph, $list ) = @_;
    my @lines = split "\n", $paragraph;
    my $data  = $self->_prop;
    my @i_paragraph;
    my $pnt = $list ? "*" : "";
    for my $line (@lines)
    {
        push @i_paragraph, $pnt x $data->{indent} . " " . $line . "\n";
    }
    return join "\n", @i_paragraph;
}


sub set_formatting
{
    my $self      = shift;
    my $paragraph = shift;
    $paragraph =~ s/I<(.*)>/_$1_/;
    $paragraph =~ s/B<(.*)>/*$1*/;

    # $paragraph =~ s/B<(.*)>/*$1*/;
    $paragraph =~ s/C<(.*)>/\`$1\`/xms;
    return $paragraph;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::AsciiDoctor - Convert from POD to AsciiDoc

=head1 VERSION

version 0.102000

=head1 SYNOPSIS

Converts the POD of a Perl module to AsciiDoc format.

    use Pod::AsciiDoctor;

    my $adoc = Pod::AsciiDoctor->new();
    $adoc->parse_from_filehandle($fh);
    print $adoc->adoc();

=head1 SUBROUTINES/METHODS

=head2 initialize

=head2 adoc

=head2 _prop

=head2 sanitise

=head2 append

=head2 command

    Overrides Pod::Parser::command

=head2 verbatim

    Overrides Pod::Parser::verbatim

=head2 textblock

    Overrides Pod::Parser::textblock

=head2 interior_sequence

    Overrides Pod::Parser::interior_sequence (Copied from the Pod::Parser)

=head2 make_header

=head2 make_text

=head2 set_formatting

=head1 AUTHOR

Balachandran Sivakumar, C<< <balachandran at balachandran.org> >>
Abhisek Kumar Rout, C<< <akr.optimus at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pod-asciidoctor at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Pod-AsciiDoctor>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Pod::AsciiDoctor

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Pod-AsciiDoctor>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Pod-AsciiDoctor>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Pod-AsciiDoctor>

=item * Search CPAN

L<http://search.cpan.org/dist/Pod-AsciiDoctor/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Balachandran Sivakumar, Abhisek Kumar Rout.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Apache License (2.0). You can get a copy of
the license at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied.  See the License for the
specific language governing permissions and limitations
under the License.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Pod-AsciiDoctor>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-AsciiDoctor>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Pod-AsciiDoctor>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/P/Pod-AsciiDoctor>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Pod-AsciiDoctor>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Pod::AsciiDoctor>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-pod-asciidoctor at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Pod-AsciiDoctor>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/Pod-AsciiDoctor>

  git clone git://github.com/shlomif/Pod-AsciiDoctor.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/Pod-AsciiDoctor/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Balachandran Sivakumar <balachandran@balachandran.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
