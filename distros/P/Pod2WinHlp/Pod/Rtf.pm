
package Pod::Rtf;

use Pod::Parser;
require Pod::PlainText;
use strict;

use vars qw(@ISA $VERSION);
$VERSION = '0.02';

use base qw(Pod::Parser);


BEGIN {
    $li = "";
}

sub begin_input {
    my $parser = shift;
    my $header = <<"EOHEADER";
{\\rtf1\\ansi \\deff0\\deflang1024

{\\fonttbl
{\\f0\\froman Times New Roman;}
{\\f1\\fmodern Fixedsys;}
}

{\\colortbl;
\\red0\\green0\\blue0;
\\red0\\green0\\blue255;
\\red0\\green255\\blue0;
\\red255\\green0\\blue0;
\\red255\\green255\\blue255;
}
EOHEADER

    if ($pound_note) {
        $pound_note = context_string($pound_note);
        $header .= "#{\\footnote $pound_note}\n";
        push(@pound_pages,$pound_note);
    }
    if ($dollar_note) {
        $header .= "\${\\footnote $dollar_note}\n";
        push(@index_pages,$dollar_note);
    }
    if ($K_note) {
        $header .= "K{\\footnote $K_note}\n";
        push(@K_pages,$dollar_note);
    }
    $header .= "\n{\\pard}\n";

    my $out_fh = $parser->output_handle();
    print $out_fh $header;
}

sub command { 
    my ($parser, $command, $paragraph, $line_num) = @_;
    my $cmd_open = "{";
    my $cmd_close = "}\n";
    if ($command eq 'head1') { 
        my $line = $paragraph;
        $line = context_string("$pound_note$line");
        if (length($line) > 0) {
            push(@pound_topics,$line);
            $cmd_open = "#{\\footnote $line}\n$cmd_open\\f0\\fs36 "; 
        }
        $cmd_close .= "{\\par}{\\pard}\n";
        $li = "";
    }
    elsif ($command eq 'head2') {
        my $line = $paragraph;
        $line = context_string("$pound_note$line");
        if (length($line) > 0) {
            push(@pound_topics,$line);
            $cmd_open = "#{\\footnote $line}\n$cmd_open\\f0\\fs28 ";
        }
        $cmd_close .= "{\\par}{\\pard}\n";
        $li = "";
    }
    elsif ($command =~ /head[3-9]/) {
        my $line = $paragraph;
        $line = context_string("$pound_note$line");
        if (length($line) > 0) {
            push(@pound_topics,$line);
            $cmd_open = "#{\\footnote $line}\n$cmd_open\\f0\\fs24 ";
        }
        $cmd_close .= "{\\par}{\\pard}\n";
        $li = "";
    }
    elsif ($command eq 'item') {
        my $non_space = $paragraph;
        $non_space =~ s/\s+//g;
        if ($non_space eq '*') { $paragraph =~ s/\*/\\bullet/; }
        # HCW on NT seems to have difficulty w/ RTF, we hack around:
        if ($is_first_item eq "yes") {
            $cmd_open =~ s/\{//; 
            $is_first_item = "";
        }
    }
    elsif ($command eq 'over') {
        my $amount = $paragraph;
        if ($amount !~ s/(\d+)/$1/) { $amount = 4 }
        # @10 pt fontw/ 2:1 aspect: 5 pts/space * 20 twips/point
        $amount *= 100; 
        $paragraph = "";
        $li = "\\li$amount";
        $cmd_open = "$cmd_open$li\\f0\\fs20";
        # HCW on NT seems to have difficulty w/ RTF, we hack around:
        $cmd_close =~ s/\}//; 
        $is_first_item = "yes";
    }
    elsif ($command eq 'back') {
        $li = "";
        $cmd_close = "{\\par}{\\pard}$cmd_close";
    }
    elsif ($command eq 'cut') {
        $li = "";
    }
    elsif ($command eq 'pod') {
        $li = "";
    }
    # perhaps for and begin ought to be handled as verbatim(?)
    elsif ($command eq 'for') {
        $li = "";
    }
    elsif ($command eq 'begin') {
    }
    elsif ($command eq 'end') {
    }
    ## ... other commands and their actions
    else {
        warn "Unrecognized command '$command'\n" if $VERBOSE;
    }
    my $expansion = $parser->interpolate($paragraph, $line_num);
    $expansion = "$cmd_open$expansion$cmd_close";

    my $out_fh = $parser->output_handle();
    print $out_fh $expansion;
}

sub verbatim { 
    my ($parser, $paragraph, $line_num) = @_;
    ## Format verbatim paragraph; sample actions might be:
    my @lines = split(/\n/,$paragraph);
    my $out_fh = $parser->output_handle();
    foreach my $line (@lines) {
        chomp($line);
        $line = rtf_escape($line);
        $line = "{{\\keep}\\f1\\fs20 $line {\\line}}\n";
        print $out_fh $line;
    }
    $line="{\\par}{\\pard}\n";
    print $out_fh $line;
}

sub textblock { 
    my ($parser, $paragraph, $line_num) = @_;
    ## Translate/Format this block of text; sample actions might be:
    # Because we do the rtf escape here it is not necessary to do it
    # for the interior sequences individually.
    my $rtf_paragraph = rtf_escape($paragraph);
    my $expansion = $parser->interpolate($rtf_paragraph, $line_num);
    my $rtf_par = "{$li\\f0\\fs20\n$expansion\{\\par}}\n{\\par}{\\pard}\n";
    my $out_fh = $parser->output_handle();
    print $out_fh $rtf_par;
}

sub interior_sequence { 
    my ($parser, $seq_command, $argument) = @_;
    my $cfont  = '\\f1';
    my $cfonts = '\\fs20';
    # rtf escape has already been done by textblock
    # my $argument = rtf_escape($seq_argument);
    ## Expand an interior sequence; sample actions might be:
    return "{\\i $argument}"            if ($seq_command eq 'I');
    return "{\\b $argument}"            if ($seq_command eq 'B');
    return "{{\\keep} $argument{\\pard}}"
                                        if ($seq_command eq 'S');
    return "{$cfont$cfonts $argument}{\\pard}"
                                        if ($seq_command eq 'C');
    if ($seq_command eq 'L') {
        my @links = split(/\|/,$argument);
        my $show = $argument;
        if ($#links >= 1) {
            $show = $links[0];
            $argument = join('|',@links[1..$#links]);
        }
        if ($argument =~ /\/?\"[^\"\|\/]+\"/) { # an L<"sec"> or L</"sec">
            my $vlink = context_string("$pound_note$argument");
            return "{\\strike $show}{\\v $vlink}"
        }
        if ($argument =~ /[^\"\|\/]+/) { # an L<name> or L<sec>
            my $vlink = context_string($argument);
            # *if* we have seen it before:
            if (scalar(grep(/$vlink/,@pound_topics))) {
                $vlink = context_string("$pound_note$vlink");
            }
            elsif (scalar(grep(/$vlink/,@pound_pages))) {
                if ($vlink !~ /\./) { $vlink .= ".pod"; }
            }
            else {
                if ($vlink !~ /\./) {
                    if ($vlink =~ /perl/) { 
                        $vlink .= ".pod"; 
                    }
                    elsif ($argument =~ /::/) {
                        $vlink .= ".pm"; 
                    }
                }
            }
            return "{\\strike $show}{\\v $vlink}"
        }
        # if (($argument !~ /\//) ||
        #     ($argument !~ /\|/));
        #if ( m{^ ([a-zA-Z][^\s\/]+) (\([^\)]+\))? $}x ) {
        #    ## LREF: a manpage(3f)
        #    $_ = "the $1$2 manpage";
        #}
        #elsif ( m{^ ([^/]+) / ([:\w]+(\(\))?) $}x ) {
        #    ## LREF: an =item on another manpage
        #    $_ = "the \"$2\" entry in the $1 manpage";
        #}
        #elsif ( m{^ / ([:\w]+(\(\))?) $}x ) {
        #    ## LREF: an =item on this manpage
        #    $_ = $self->internal_lrefs($1);
        #}
        #elsif ( m{^ (?: ([a-zA-Z]\S+?) / )? "?(.*?)"? $}x ) {
        #    ## LREF: a =head2 (head1?), maybe on a manpage, maybe right here
        #    ## the "func" can disambiguate
        #    $_ = ((defined $1) && $1)
        #            ? "the section on \"$2\" in the $1 manpage"
        #            : "the section on \"$2\"";
        #}
    }
    return "$argument"                  if ($seq_command eq 'F');
    if ($seq_command eq 'X') {
        return "{\\strike $argument}{\\v $argument}";
    }
    return "$argument"                  if ($seq_command eq 'Z');
    if ($seq_command eq 'E') {
        if (defined($Pod::PlainText::HTML_Escapes{$argument})) {
            return "$Pod::PlainText::HTML_Escapes{$argument}";
        }
        else {
            warn "Unrecognized escape sequence '$seq_command<$argument>'\n" if $VERBOSE;
            return "$argument";
        }
    }
    ## ... other sequence commands and their resulting text
    warn "Unrecognized interior sequence '$seq_command<$argument>'\n" if $VERBOSE;
    return "$argument";
}

sub end_input {
    my $parser = shift;
    my $footer = <<"EOFOOTER";
}
EOFOOTER
    my $out_fh = $parser->output_handle();
    print $out_fh $footer;
}

sub rtf_escape { 
    my $text = shift;
    #
    # According to Keith Bugg we need to \ escape \ {} [] # $
    # Experience with HCW on NT 4 shows that only \ {} need be escaped.
    #
    $text =~ s/(\\)/\\$1/g;
    $text =~ s/(\{)/\\$1/g;
    $text =~ s/(\})/\\$1/g;
    return($text);
}

sub context_string { 
    my $text = shift;
    $text =~ s/[^A-Za-z0-9_\.]//g;
    if (length($text) > 255) {
        return(substr($text,0,255));
    }
    return($text);
}

1; # happy package


=head1 NAME

Pod::Rtf

=head1 SYNOPSIS

    $parser = new Pod::Rtf();
    $parser->parse_from_filehandle(\*STDIN)  if (@ARGV == 0);
    for (@ARGV) {
       my $file = $_;
       $file =~ s/\..*$//;
       $Pod::Rtf::pound_note = $_;
       $Pod::Rtf::dollar_note = $file;
       $Pod::Rtf::K_note = $file;
       $parser->parse_from_file($_);
    }

=head1 DESCRIPTION

Uses Pod::Parser to convert pod documentation to Rich Text Format (rtf)
suitable for compilation by a Windows Help compiler.


=head1 SEE ALSO

L<perl>.  L<Pod::Rtf>,  L<Pod::Parser>.

=head1 AUTHOR

Peter Prymmer.

=cut


