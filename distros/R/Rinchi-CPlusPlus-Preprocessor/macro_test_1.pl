use strict;
use Rinchi::CPlusPlus::Preprocessor;

my @args = (
  'macro_test_1.pl',
  '-Uaaa',
#  '--debug',
);

my @elems;
my $text;
my $comparing;

sub startElementHandler() {
  my ($tag, $hasChild, %attrs) = @_;

  my $elem = [$tag, $hasChild, \%attrs, []];
  push @{$elems[-1]->[3]},$elem if(@elems);
  push @elems,$elem;
  if ($tag eq 'amp') {
    $text .= '&';
  } elsif ($tag eq 'ast') {
    $text .= '*';
  } elsif ($tag eq 'bitor') {
    $text .= '|';
  } elsif ($tag eq 'brace') {
    $text .= '{';
  } elsif ($tag eq 'bracket') {
    $text .= '[';
  } elsif ($tag eq 'char') {
    $text .= 'char ';
  } elsif ($tag eq 'comma') {
    $text .= ',';
  } elsif ($tag eq 'compl') {
    $text .= '~';
  } elsif ($tag eq 'dec_lit') {
    $text .= $attrs{'value'};
  } elsif ($tag eq 'eos') {
    $text .= ';';
  } elsif ($tag eq 'eq') {
    $text .= '=';
  } elsif ($tag eq 'identifier') {
    if ($attrs{'identifier'} eq 'compare') {
      $comparing = 1; 
    } else {
      $text .= $attrs{'identifier'} ;
    }
  } elsif ($tag eq 'int') {
    $text .= 'int ';
  } elsif ($tag eq 'minus') {
    $text .= '-';
  } elsif ($tag eq 'mod') {
    $text .= '%';
  } elsif ($tag eq 'ppd_pragma') {
  } elsif ($tag eq 'oct_lit') {
    $text .= $attrs{'value'};
  } elsif ($tag eq 'paren') {
    $text .= '(';
  } elsif ($tag eq 'plus') {
    $text .= '+';
  } elsif ($tag eq 'replaced_identifier') {
  } elsif ($tag eq 'str_lit') {
    $text .= "\"$attrs{'value'}\"" unless ($comparing == 1);
    $comparing = 0;
  } elsif ($tag eq 'xor') {
    $text .= '^';
  } else {
    print "<$tag/>\n";
  }
}

sub endElementHandler() {
  my ($tag) = @_;

  my $elem = pop @elems;
  my $content = $elem->[3];
  my $pr_id;
  my $pr_str;
  if ($tag eq 'brace') {
    $text .= '}';
  } elsif ($tag eq 'bracket') {
    $text .= ']';
  } elsif ($tag eq 'paren') {
    $text .= ')';
  } elsif($tag eq 'ppd_pragma') {
    if(defined($content->[0])) {
      $pr_id = $content->[0][2]{'identifier'};
    }
    if($pr_id eq 'compare') {
      if(defined($content->[1])) {
        $pr_str = $content->[1][2]{'value'};
        print "                   $text\n";
      }
    } elsif ($pr_id eq 'start') {
      $text = '';
    }
    print "ppd_pragma $pr_id $pr_str\n";
  }
}

sub characterDataHandler() {
  my ($cdata) = @_;
#  print $cdata;
}

sub processingInstructionHandler() {
  my ($target,$data) = @_;
#  print "<?$target $data?>\n";
}

sub commentHandler() {
  my ($string) = @_;
#  print "<!-- $string -->\n";
}

sub startCdataHandler() {
#  print "<![CDATA[";
}

sub endCdataHandler() {
#   print "]]>";
}

sub xmlDeclHandler() {
#  print 'xmlDeclHandler',@_,"\n";
  my ($version, $encoding, $standalone) = @_;
#  print "<?xml version=\"$version\" encoding=\"$encoding\" standalone=\"$standalone\"?>\n";
}

my $cpp = new Rinchi::CPlusPlus::Preprocessor;
$cpp->setHandlers('Start'      => \&startElementHandler,
                  'End'        => \&endElementHandler,
                  'Char'       => \&characterDataHandler,
                  'Proc'       => \&processingInstructionHandler,
                  'Comment'    => \&commentHandler,
                  'CdataStart' => \&startCdataHandler,
                  'CdataEnd'   => \&endCdataHandler,
                  'XMLDecl'    => \&xmlDeclHandler,
                  );
#$cpp->process_file('test_src/example_16_3_5_5.cpp',\@args);
$cpp->process_file('test_src/macro_expansion.cpp',\@args);

