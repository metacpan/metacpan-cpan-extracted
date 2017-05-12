# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Rinchi-CPlusPlus-Preprocessor.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
BEGIN { use_ok('Rinchi::CPlusPlus::Preprocessor') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my @args = (
  'macro_test_1.pl',
  '-Uaaa',
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
  } elsif ($tag eq 'oct_lit') {
    $text .= $attrs{'value'};
  } elsif ($tag eq 'paren') {
    $text .= '(';
  } elsif ($tag eq 'plus') {
    $text .= '+';
  } elsif ($tag eq 'str_lit') {
    $text .= "\"$attrs{'value'}\"" unless ($comparing == 1);
    $comparing = 0;
  } elsif ($tag eq 'xor') {
    $text .= '^';
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
#        print "$text eq $pr_str\n";
        ok($text eq $pr_str, "  macro expansion $pr_str");
      }
    } elsif ($pr_id eq 'start') {
      $text = '';
    }
  }
}

sub characterDataHandler() {
}

sub processingInstructionHandler() {
}

sub commentHandler() {
}

sub startCdataHandler() {
}

sub endCdataHandler() {
}

sub xmlDeclHandler() {
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
$cpp->process_file('test_src/macro_expansion.cpp',\@args);


