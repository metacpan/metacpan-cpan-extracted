package Parse::SSA;
{
    $Parse::SSA::VERSION = '1.0';
}

=pod
=head NAME
Parse::SSA = ASS/SSA subtitle parser

=head1 VERSION

version 1.0

=head1 SYNOPSIS

    # Simple parsing all texts subtitle
    my $sub = Parse::SSA->new("./sub.ass");
    my $row = $sub->subrow();
    print($row->[5]->{'subtitle'});
    # subtitle text on 5 line.

=head1 DESCRIPTION

This module can parse text, time, comments, names from SSA/ASS subtitle fromat.

=head1 AUTHOR
Konstantin Gromyko E<lt>disinterpreter@protonmail.ch<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<https://en.wikipedia.org/wiki/SubStation_Alpha> L<https://www.matroska.org/technical/specs/subtitles/ssa.html>


=cut
#use `5.020_000`;
use warnings FATAL => 'all';

my @lines;
sub new {
    my ($pkg, $filename) = @_;
    my $lineNum = 0;
    my $self = {};

    my @assfile = ();
    open( ASSFILE, "<", $filename )
        or die 'Can not open ".ass" source file:' . $filename . ", please check it!!\n";
    while (<ASSFILE>) {
        chomp;
        if (m/^Dialogue:/) {
            $lineNum = extractLine( $lineNum, $_ );
        }
        elsif (m/^(Title:|Original)/) {
            # If a line begins with 'Title' or 'Original', it is the source for the subtitles

        }

    }
    $self->{'fname'} = $filename;
    $self->{'assall'} = \@lines;
    bless($self, $pkg);

    return $self;
}

=head2 subrow

  # Get all parsed data from subtitle
  my $row = $sub->subrow();

The C<subrow> method gets the data which are present in a Dialogue section: begin time, end time, comment flag, character name, subtitles.
=cut

sub subrow {
    my ($self) = @_;
    return $self->{'assall'};
}

sub extractLine {
    my ($lineNumber, $content) = @_;

    my $begin;
    my $end;
    my $subtitle;
    my $name;
    my $currentTime;

    if ( $content
        =~ m/Dialogue: [^,]*,([^,]*),([^,]*),([^,]*),([^,]*),[^,]*,[^,]*,[^,]*,[^,]*,(.*)$/
    )
    {
        $begin    = $1;
        $end      = $2;
        $name     = $4;
        $subtitle = $5;

        my $isComment = $3;
        $begin =~ s/\./,/g;
        $end   =~ s/\./,/g;
        if ( $begin =~ m/^\d{1}:/ ) {
            $begin = "0" . $begin;
        }

        if ( $end =~ m/^\d{1}:/ ) {
            $end = "0" . $end;
        }
        $subtitle =~ s/\r$//g;
        $subtitle =~ s/\\N/ /g;
        $subtitle =~ s/^m\s+\d+.+//g;
        $subtitle =~ s/{[^}]*}//g;

        if ( $isComment eq 'comment' ) {
            $subtitle = '(' . $subtitle . ')';
        }
        my %line = ( begin => $begin, end => $end, isComment => $isComment, name=>$name, subtitle => $subtitle );
        push @lines, \%line;

        return $lineNumber;
    }
}

1;
