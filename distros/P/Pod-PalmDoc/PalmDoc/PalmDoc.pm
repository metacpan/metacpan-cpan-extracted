package Pod::PalmDoc;

use strict;
use vars qw($text $doc $doc_text @ISA $VERSION @EXPORT);

require Exporter;

use Pod::Parser;
use Palm::PalmDoc '0.0.6';
@ISA = qw(Exporter Pod::Parser);

@EXPORT = qw();

$VERSION = '0.0.2';

$doc = Palm::PalmDoc->new();

sub command {
    my ($parser, $command, $paragraph, $line_num) = @_;
    $paragraph .= "\n" unless substr($paragraph, -1) eq "\n";
    $paragraph .= "\n" unless substr($paragraph, -2) eq "\n\n";
    $text .= $paragraph;
}

sub verbatim {
    my ($parser, $paragraph, $line_num) = @_;
    $text .= $paragraph;
}

sub textblock {
    my ($parser, $paragraph, $line_num) = @_;
    $text .= $paragraph;
}

sub interior_sequence {
    my ($parser, $seq_command, $seq_argument) = @_;
    return "$seq_command<$seq_argument>";
}

sub title {
    my $parser = shift;
    if (@_)
    { $doc->title(shift); }
}

sub compress {
    my $parser = shift;
    if (@_)
    { $doc->compression(shift); }
}

sub begin_pod {
    my $parser = shift;
    $doc->outfile($parser->output_file()) if $parser->output_file();
}

sub end_pod {
    my $parser = shift;
    $doc->body($text) if $text;
    $doc->write_text if $doc->outfile;
    my $fhandle = $parser->output_handle();
    print $fhandle $doc->pdb_header, $doc->body if $fhandle;
}

1;
__END__

=head1 NAME

Pod::PalmDoc - Convert POD Data to PalmDoc

=head1 SYNOPSIS

  use Pod::PalmDoc;

  my $parser = Pod::PalmDoc->new();
  $parser->compress(1);
  $parser->title("POD Foo");
  $parser->parse_from_file($ARGV[0],"foo.pdb");

  -or-

  use Pod::PalmDoc;

  my $parser = Pod::PalmDoc->new();
  $parser->compress(1);
  $parser->title("POD Foo");
  open(FOO,">foo.pdb") || die $!;
  $parser->parse_from_filehandle(\*STDIN, \*FOO); 
  close(FOO);

  -or-

  use Pod::PalmDoc;

  my $parser = Pod::PalmDoc->new();
  $parser->compress(1);
  $parser->title("POD Foo");
  open(FOO,"<Pod/PalmDoc.pm") || die $!;
  open(BAR,">foo.pdb") || die $!;
  $parser->parse_from_filehandle(\*FOO, \*BAR); 
  close(FOO);
  close(BAR);

=head1 DESCRIPTION

This module converts POD (Plain Old Documentation) to PalmDoc format.
It uses Palm::PalmDoc and inherits most of its methods from Pod::Parser.

=head1 TODO

Future releases probably will inherit from Pod::Select instead of Pod::Parser.

=head1 DISCLAIMER

This code is released under GPL (GNU Public License). More information can be 
found on http://www.gnu.org/copyleft/gpl.html

=head1 VERSION

This is Pod::PalmDoc 0.0.2.

=head1 AUTHOR

Hendrik Van Belleghem (beatnik@quickndirty.org)

=head1 SEE ALSO

GNU & GPL - http://www.gnu.org/copyleft/gpl.html

=cut