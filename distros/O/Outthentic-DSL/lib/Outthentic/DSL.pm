package Outthentic::DSL;

use strict;

our $VERSION = '0.2.10';

use Carp;
use Data::Dumper;
use Outthentic::DSL::Context::Range;
use Outthentic::DSL::Context::Default;
use Outthentic::DSL::Context::TextBlock;
use File::Temp qw/ tempfile /;
use JSON;

$Data::Dumper::Terse=1;

sub results {

    my $self = shift;

    $self->{results};
}

sub add_result {

    my $self = shift;
    my $item = shift;

    push @{$self->results}, { %{$item}, type => 'check_expression' };
        
}

sub debug {

    my $self = shift;
    my $item = shift;

    push @{$self->results}, { message => $item , type => 'debug' };
        
}


sub new {

    my $class = shift;
    my $output = shift;
    my $opts = shift || {};

    bless {
        results => [],
        original_context => [],
        current_context => [],
        context_modificator => Outthentic::DSL::Context::Default->new(),
        has_context => 0,
        succeeded => [],
        captures => [],
        within_mode => 0,
        block_mode => 0,
        last_match_line => undef,
        last_check_status => undef,
        debug_mod => 0,
        output => $output||'',
        match_l => 40,
        stream => {},
        languages => {},
        %{$opts},
    }, __PACKAGE__;

}

sub create_context {

    my $self = shift;

    return if $self->{has_context};

    my $i = 0;

    my @original_context = ();

    for my $l ( split /\n/, $self->{output} ){
        chomp $l;
        $i++;
        $l=":blank_line" unless $l=~/\S/;
        push @original_context, [$l, $i];

        $self->debug("[oc] [$l, $i]") if $self->{debug_mod} >= 2;

    }

    $self->{original_context} = [@original_context];

    $self->{current_context} = [@original_context];

    $self->debug('context populated') if $self->{debug_mod} >= 2;


    $self->{has_context} = 1;


}


sub reset_context {

    my $self = shift;

    $self->{current_context} = $self->{original_context};

    $self->debug('reset search context') if $self->{debug_mod} >= 2;

    $self->{context_modificator} = Outthentic::DSL::Context::Default->new();

}

sub reset_captures {

    my $self = shift;
    $self->{captures} = [];
    unlink $self->{cache_dir}."/captures.json" if -f $self->{cache_dir}."/captures.json";
}

sub reset_succeeded {

    my $self = shift;
    $self->{succeeded} = [];

}


sub stream {

    my $self = shift;
    my @stream;
    my $i=0;

    for my $cid ( sort { $a <=> $b } keys  %{$self->{stream}} ){
        $stream[$i]=[];
        for my $c (@{$self->{stream}->{$cid}}){
            push @{$stream[$i]}, $c->[0];
            $self->debug("[stream {$cid}] $c->[0]") if $self->{debug_mod} >= 2;
        }
        $i++;
    }
    [@stream]
}

sub match_lines {

    my $self = shift;
    return $self->{succeeded};
}


sub check_line {

    my $self = shift;
    my $pattern = shift;
    my $check_type = shift;
    my $message = shift;

    my $status = 0;

    s/\s+$// for $pattern;

    $self->reset_captures;

    my @captures = ();

    $self->create_context;

    $self->debug("[lookup] $pattern ...") if $self->{debug_mod} >= 2;

    my @original_context   = @{$self->{original_context}};
    my @context_new        = ();

    # dynamic context 
    my $dc = $self->{context_modificator}->change_context(
        $self->{current_context},
        $self->{original_context},
        $self->{succeeded}
    );

    $self->debug("context modificator applied: ".(ref $self->{context_modificator})) 
        if $self->{debug_mod} >=2;
        
    if ( $self->{debug_mod} >= 2 ) {
        for my $dcl (@$dc){ 
            $self->debug("[dc] $dcl->[0]");
        } 

    };
    

    $self->reset_succeeded;

    if ($check_type eq 'default'){
        for my $c (@{$dc}){

            my $ln = $c->[0];

            next if $ln =~/#dsl_note:/; # skip debug entries

            if ( index($ln,$pattern) != -1){
                $status = 1;
                $self->{last_match_line} = $ln;
                push @{$self->{succeeded}}, $c;
            }
        }

    }elsif($check_type eq 'regexp'){


        for my $c (@{$dc}) {

            my $re = qr/$pattern/;

            my $ln = $c->[0];

            next if $ln eq ":blank_line";
            next if $ln =~/#dsl_note:/;

            my @foo = ($ln =~ /$re/g);

            if (scalar @foo){
                push @captures, [@foo];
                $status = 1;
                push @{$self->{succeeded}}, $c;
                push @context_new, $c if $self->{within_mode};
                $self->{last_match_line} = $ln;
            }

        }
    }else {
        confess "unknown check_type: $check_type";
    }



    $self->{last_check_status} = $status;

    if ( $self->{debug_mod} >= 2 ){

        my $i = 1;
        my $j = 1;
        for my $cpp (@captures){
            for my $cp (@{$cpp}){
                $self->debug("CAP[$i,$j]: $cp");
                $j++;
            }
            $i++;
            $j=1;
        }

        for my $s (@{$self->{succeeded}}){
            $self->debug("SUCC: $s->[0]");
        }
    }

    $self->{captures} = [ @captures ];

    if ($self->{cache_dir}){
      open CAPTURES, '>', $self->{cache_dir}.'/captures.json' 
        or confess "can't open ".($self->{cache_dir})."captures.json to write $!";
      print CAPTURES encode_json($self->{captures});
      $self->debug("CAPTURES saved at ".$self->{cache_dir}.'/captures.json')
        if $self->{debug_mod} >= 1;
      close CAPTURES;
    }

    # update context
    if ( $self->{within_mode} and $status ){
        $self->{current_context} = [@context_new];
        $self->debug("[WITH] within mode: modify search context to: $context_new[0][0]") 
          if $self->{debug_mod} >= 2 
    }elsif ( $self->{within_mode} and ! $status ){
        $self->{current_context} = []; # empty context if within expression has not passed 
        $self->debug('within mode: modify search context to: '.(Dumper([@context_new]))) if $self->{debug_mod} >= 2 
    }

    $self->add_result({ status => $status , message => $message });


    $self->{context_modificator}->update_stream(
        $self->{current_context},
        $self->{original_context},
        $self->{succeeded}, 
        \($self->{stream}),
    );

    return $status;

}

sub validate {

    my $self        = shift;
    my $check_list  = shift;

    my $block_type;
    my @multiline_block;
    my $here_str_mode = 0;
    my $here_str_marker;

    my @lines;
    if (  -f $check_list ){
      open my $ff, $check_list or die "can't open file check_list to read: $!";
      while (my $ii = <$ff>){
        push @lines, $ii;
      }
      close $ff;
    } else {
     @lines = ( ref $check_list  ) ? @{$check_list} : ( split "\n", $check_list ); 
    }

    LINE: for my $l ( @lines ) {

        chomp $l;

        $self->debug("[dsl::$block_type] $l") if $self->{debug_mod} >= 2;

        next LINE unless $l =~ /\S/; # skip blank lines

        next LINE if $l=~ /^\s*#(.*)/; # skip comments
        
        if ($here_str_mode && $l=~s/^$here_str_marker\s*$//) {

          $here_str_mode = 0;

          $self->debug("here string mode off") if $self->{debug_mod} >= 2;

          $self->debug("flushing $block_type block") if $self->{debug_mod} >= 2;

          no strict 'refs';

          my $name = "handle_"; 

          $name.=$block_type;

          &$name($self, [ @multiline_block ] );

          undef @multiline_block; undef $block_type;

          next LINE;

        } 

        if ( $block_type and $l!~/\\\s*$/ and ! $here_str_mode  ){

          no strict 'refs';

          my $name = "handle_"; 

          $name.=$block_type;

          $self->debug("flushing $block_type block") if $self->{debug_mod} >= 2;

          &$name($self, [ @multiline_block ] );

          undef @multiline_block; undef $block_type;


        }

        if ( $block_type and $l=~/^\s*(code|generator|validator):\s*(.*)/ and ! $here_str_mode  ){

          no strict 'refs';

          my $name = "handle_"; 

          $name.=$block_type;

          $self->debug("flushing $block_type block") if $self->{debug_mod} >= 2;

          &$name($self, [ @multiline_block ] );

          undef @multiline_block; undef $block_type;


        }

        if ( $block_type && ( $l=~s/\\\s*$// or $here_str_mode )) { # multiline block

           # this is multiline block or here string,
           # accumulate lines until meet line not ending with '\' ( for multiline blocks )
           # or here string end marker ( for here stings )

           push @multiline_block, $l;

           next LINE;

        } 



        if ( $l=~/^\s*begin:\s*$/) { # begining  of the text block

            do { undef @multiline_block; undef $block_type } if $block_type; 

            die "you can't switch to text block mode when within mode is enabled" if $self->{within_mode};

            $self->{context_modificator} = Outthentic::DSL::Context::TextBlock->new();

            $self->debug('text block start') if $self->{debug_mod} >= 2;

            $self->{block_mode} = 1;

            $self->reset_succeeded();

        } elsif ($l=~/^\s*end:\s*$/) { # end of the text block

            $self->{block_mode} = 0;

            $self->reset_context();

            $self->debug('text block end') if $self->{debug_mod} >= 2;

        } elsif ($l=~/^\s*reset_context:\s*$/) {

            do { undef @multiline_block; undef $block_type } if $block_type; 
            $self->reset_context();

        } elsif ($l=~/^\s*assert:\s+(\d+)\s+(.*)/) {

            my $status = $1; my $message = $2;

            do { undef @multiline_block; undef $block_type } if $block_type; 

            $self->debug("assert found: $status | $message") if $self->{debug_mod} >= 2;

            $status = 0 if $status eq 'false'; # ruby to perl5 conversion

            $status = 1 if $status eq 'true'; # ruby to perl5 conversion

            $self->add_result({ status => $status , message => $message });

        } elsif ($l=~/^\s*between:\s+(.*)/) { # range context


            die "you can't switch to range context mode when within mode is enabled"  if $self->{within_mode};
            die "you can't switch to range context mode when block mode is enabled"   if $self->{block_mode};

            my $pattern = $1;

            do { undef @multiline_block; undef $block_type } if $block_type; 

            $self->{context_modificator} = Outthentic::DSL::Context::Range->new($1);


        } elsif ($l=~/^\s*(code|generator|validator):\s*(.*)/)  {

            my $my_block_type = $1;

            my $code = $2;

            if ( $code=~s/(.*)\\\s*$// ) {

                 # this is multiline block, accumulate lines until meet '\' line
                 $block_type = $my_block_type;
                 my $first_line = $1; 
                 push @multiline_block, $first_line;

                 $self->debug("starting $block_type block") if $self->{debug_mod}  >= 2;
                 $self->debug("first line in block: <<<$first_line>>>") if $self->{debug_mod}  >= 2;

            } elsif ( $code=~s/<<(\S+)// ) {

                $block_type = $my_block_type;

                $here_str_mode = 1;

                $here_str_marker = $1;

                $self->debug("$block_type block start. heredoc marker: $here_str_marker") if $self->{debug_mod}  >= 2;


            } else {

                $self->debug("one-line $my_block_type found: $code") if $self->{debug_mod}  >= 2;

                no strict 'refs';

                my $name = "handle_"; 

                $name.=$my_block_type;

                $self->debug("flushing one-line $block_type block") if $self->{debug_mod} >= 2;

                &$name($self,$code);


            }

        } elsif ($l=~/^\s*regexp:\s*(.*)/) { # `regexp' line

            my $re = $1;

            $re=~s/\s+#.*//;

            $re=~s/^\s+//;

            $self->handle_regexp($re);

        } elsif ($l=~/^\s*within:\s*(.*)/) {

            die "you can't switch to within mode when text block mode is enabled" if $self->{block_mode};

            my $re = $1;

            $re=~s/\s+#.*//;

            $re=~s/^\s+//;

            $self->handle_within($re);

        } else { # `plain string' line

            $l=~s/\s+#.*//;

            $l=~s/^\s+//;

            $self->handle_plain($l);

        }
    }

    if ( $block_type ){

      no strict 'refs';

      my $name = "handle_"; 

      $self->debug("flushing $block_type block") if $self->{debug_mod} >= 2;

      $name.=$block_type;

      &$name($self, [ @multiline_block ] );

      undef @multiline_block; undef $block_type;


    }

}


sub handle_code {

    my $self = shift;
    my $code = shift;
    my $results;

    if (! ref $code) {

        $results = eval "package main; $code;";
        confess "eval error; sub:handle_code; code:$code\nerror: $@" if $@;
        $self->debug("code OK. single line. code: $code") if $self->{debug_mod} >= 3;

    } else {

        my $i = 0;

        my $code_to_print = join "\n", map { my $v=$_; $i++; "[$i] $v" }  @$code;

        if ($code->[0]=~s/^\!(.*)//) {

          my $ext_runner = $1;

          my $language = (split /\\/, $ext_runner)[-1];

          if ($language eq 'perl') {

              shift @$code;
              my $code_to_eval = join "\n", @$code;
              $results = eval "package main; $code_to_eval";
              confess "eval error; sub:handle_code; code:\n$code_to_print\nerror: $@" if $@;
              $self->debug("code OK. inline(perl). $code_to_eval") if $self->{debug_mod} >= 3;

          } else {

            my $source_file = File::Temp->new( DIR => $self->{cache_dir} , UNLINK => 0 );

            shift @$code;

            my $code_to_eval = join "\n", @$code;

            open SOURCE_CODE, '>', $source_file or die "can't open source code file $source_file to write: $!";

            print SOURCE_CODE $code_to_eval;

            close SOURCE_CODE;

            if ($language eq 'bash'){

              if ($self->{languages}->{$language}){
                $ext_runner = "bash -c '".($self->{languages}->{$language})." && source $source_file'";
              }else{
                  $ext_runner = "bash -c 'source $source_file'";
              }

            } else {
              $ext_runner = $self->{languages}->{$language} if $self->{languages}->{$language};
              $ext_runner.=' '.$source_file;
            }


            my $st = system("$ext_runner 2>$source_file.err 1>$source_file.out");  

            if ($st != 0){
              confess "$ext_runner failed, see $source_file.err for details";
            }

            $self->debug("code OK. inline. $ext_runner") if $self->{debug_mod} >= 2;

            open EXT_OUT, "$source_file.out" or die "can't open file $source_file.out to read: $!";
            $results = join "", <EXT_OUT>;
            close EXT_OUT;

            unless ($ENV{OTX_KEEP_SOURCE_FILES}) {
              unlink("$source_file.out");
              unlink("$source_file.err");
              unlink("$source_file");
            }
        } 



      } else {

        my $code_to_eval = join "\n", @$code;
        $results = eval "package main; $code_to_eval";
        confess "eval error; sub:handle_code; code:\n$code_to_print\nerror: $@" if $@;
        $self->debug("code OK. multiline. $code_to_eval") if $self->{debug_mod} >= 3;

      }


  }

  return $results;

}

sub handle_validator {

    my $self = shift;
    my $code = shift;

    if (! defined ($self->{last_check_status}) or $self->{last_check_status}){
      my $r = $self->handle_code($code);
      $self->add_result({ status => $r->[0] , message => $r->[1] });
    } else {
      $self->debug("skip validator step because last check has been failed") if $self->{debug_mod} >= 1;
    }


}

sub handle_generator {

    my $self = shift;
    my $code = shift;

    if (! defined ($self->{last_check_status}) or $self->{last_check_status}){
      $self->validate(
        $self->handle_code($code)
      )
    } else {
      $self->debug("skip generator step because last check has been failed") if $self->{debug_mod} >= 1;
    }


}

sub handle_simple {

  my $self    = shift;
  my $pattern = shift;
  my $check_type = shift;  

  my $msg;

  my $lshort =  $self->_short_string($pattern);

  my $reset_context = 0;

  if ($self->{within_mode}) {

      $self->{within_mode} = 0;

      $reset_context = 1;

      if ($self->{last_check_status}){
        if ($check_type eq 'regexp'){
          $msg = "'".($self->_short_string($self->{last_match_line}))."' match /$lshort/"
        } else {
          $msg = "'".($self->_short_string($self->{last_match_line}))."' has '".$lshort."'"
        }
      } else {
        if ($check_type eq 'regexp'){
          $msg = "text match /$lshort/"
        } else {
          $msg = "text has '".$lshort."'"
        }
      }


  } else {

      if ($self->{block_mode}){
        if ($check_type eq 'regexp'){
          $msg = "[b] text match /$lshort/";
        } else {
          $msg = "[b] text has '".$lshort."'";
        }
      } else {
        if ($check_type eq 'regexp'){
          $msg = "text match /$lshort/";
        } else {
          $msg = "text has '".$lshort."'";
        }
      }
  }


  $self->check_line($pattern,$check_type, $msg);

  $self->reset_context if $reset_context; 

  $self->debug("$check_type check DONE. >>> <<<$pattern>>>") if $self->{debug_mode} >= 3;

}

sub handle_regexp {

    my $self  = shift;
    my $re    = shift;
    
    $self->handle_simple($re, 'regexp');

}

sub handle_within {

    my $self    = shift;
    my $pattern = shift;

    my $msg;

    if ($self->{within_mode}) {
      if ($self->{last_check_status}){
        $msg = "'".($self->_short_string($self->{last_match_line}))."' match  /$pattern/"
      } else {
        $msg = "text match /$pattern/"
      }

    }else{
        $msg = "text match /$pattern/";
    }

    $self->{within_mode} = 1;

    $self->check_line($pattern,'regexp', $msg);

    $self->debug("within check DONE. >>> <<<$pattern>>>") if $self->{debug_mode} >= 3;
    
}

sub handle_plain {

    my $self = shift;
    my $l = shift;

    $self->handle_simple($l, 'default');

}


sub _short_string {

    my $self = shift;
    my $str = shift;
    my $sstr = substr( $str, 0, $self->{match_l} );

    s{\r}[]g for $str;
    s{\r}[]g for $sstr;

    s/\s+$// for $sstr;
    s/\s+$// for $str;
    
    return $sstr < $str ? "$sstr ..." : $sstr; 

}

1;

__END__

=pod


=encoding utf8


=head1 NAME

Outthentic::DSL


=head1 SYNOPSIS

Outthentic::DSL - language to verify (un)structured text.


=head1 Install

    $ cpanm Outthentic::DSL


=head1 Developing

    $ git clone https://github.com/melezhik/outthentic-dsl.git 
    $ cd outthentic-dsl
    $ perl Makefile.PL && make && make install


=head1 Glossary


=head2 Input text

An arbitrary, often unstructured text being verified. It could be any text.

Examples:

=over

=item *

html code


=item *

xml code


=item *

json 


=item *

plain text


=item *

emails :-)


=item *

http headers


=item *

another program languages code


=back


=head2 Outthentic DSL

=over

=item *

Is a language to verify I<arbitrary> text



=item *

Outthentic DSL is both imperative and declarative language



=back


=head3 Declarative way

You define rules ( check expressions ) to describe expected content.


=head3 Imperative way

You I<extend> a process of verification using regular programming languages - like Perl, Bash and Ruby, see examples below.


=head2 DSL code

A program code written on Outthentic DSL language to verify text input.


=head2 Search context

Verification process is taken in a  I<context>.

By default search context I<is equal> to an original text input stream.

However a search context might be changed in some situations ( see within, text blocks and ranges expressions ).


=head2 DSL parser

DSL parser is the program which:

=over

=item *

parses DSL code



=item *

parses text input



=item *

verifies text input ( line by line ) against a check expressions ( line by line )



=back


=head2 Verification process

Verification process consists of matching lines of text input against check expressions.

This is schematic description of the process:

    For every check expression in a check expressions list:
        * Mark this check step in `unknown' state.
        * For every line in input text:
            * Verify if it matches check expression. If line matches then mark step in `succeeded' state.
            * Next line.
        End of lines loop.
        * If the check step marked in `unknown' state, then mark it in `failed' state.  
        * Next check expression.
    End of expressions loop.
    
    Check if all check steps are succeeded. If so then input text is considered verified, else - not verified.

A final I<presentation> of verification results should be implemented in a certain L<client|#clients> I<using> L<parser api|#parser-api> and not being defined at this scope.



=head2 Parser API

Outthentic::DSL provides program API for I<client applications>. 

This is example of verification some text against 2 lines;

    use Outthentic::DSL;
    
    my $otx = Outthentic::DSL->new(<<HERE, { debug_mod => 0 });
        Hello
        My name is Outthentic!
    HERE
    
    $otx->validate(<<'CHECK');
        Hello
        regexp: My\s+name\s+is\s+\S+
    CHECK
    
    print "status\tcheck\n";
    print "==========================\n";
    
    for my $r (@{$otx->results}) {
        print $r->{status} ? 'true' : 'false', "\t", $r->{message}, "\n";
    }

Output:

    status  check
    ==========================
    true    text has 'Hello'
    true    text match /My\s+name\s+is\s+\S+/

Methods list:


=head3 new

This is constructor to create an Outthentic::DSL instance. 

Obligatory parameters are:

=over

=item *

text


=back

input text to get verified

    Outthentic::DSL->new("Hi! Welcome to my birthday party.\nLet's have a fun" );

Optional parameters are passed as hash:

=over

=item *

match_l - truncate check expressions to a C<match_l> bytes when generating results


=back

This is useful when debugging long check expressions:

    use Outthentic::DSL;
    
    my $otx = Outthentic::DSL->new( 'A'x99 , { match_l  => 9 });
    
    $otx->validate('A'x99);
    
    print "status\tcheck\n";
    print "==========================\n";
    
    for my $r (@{$otx->results}) {
        print $r->{status} ? 'true' : 'false', "\t", $r->{message}, "\n";
    }

Output:

    status  check
    ==========================
    true    text has 'AAAAAAAAA'

Default value is C<40>.

=over

=item *

debug_mod - enable debug mode

=over

=item *

Possible values is one of: C<0,1,2,3,4>



=item *

Set to 1 or 2 or 3 or 4 if you want to see some debug information appeared at console.



=item *

Increasing debug_mod value results in more low level information appeared.



=item *

Default value is C<0> - means do not emit debug messages.



=back



=back


=head3 validate

Perform verification process. 

Obligatory parameter is:

=over

=item *

a string with DSL code


=back

Example:

    $otx->validate(<<'CHECK');
    
      # there should be digits
      regexp: \d
      # and greetings
      regexp: hello \s+ \w+
    
    CHECK


=head3 results


Returns validation results as array containing { type, status, message } hashes.


=head2 Outthentic clients

Client is a external program using DSL API. Existed Outthentic clients:

=over

=item *

L<Swat|https://github.com/melezhik/swat> - web application testing tool



=item *

L<Outthentic|https://github.com/melezhik/outthentic> -  multipurpose scenarios framework



=back


=head1 DSL code syntax

Outthentic DSL code comprises following entities:

=over

=item *

Comments



=item *

Blank lines



=item *

Check expressions:

=over

=item *

plain     strings


=item *

regular   expressions


=item *

text      blocks


=item *

within    expressions


=item *

asserts   expressions


=item *

validator expressions


=item *

range     expressions


=back



=item *

Code expressions



=item *

Generator expressions



=back


=head1 Check expressions

Check expressions define patterns to match against an input text stream. 

Here is a simple example:

    use Outthentic::DSL;
    
    my $otx = Outthentic::DSL->new(<<'HERE');
      HELLO
      HELLO WORLD
      My birth day is: 1977-04-16
    HERE
    
    $otx->validate(<<'CHECK');
      HELLO
      regexp: \d\d\d\d-\d\d-\d\d
    CHECK
    
    print "status\tcheck\n";
    print "==========================\n";
    
    for my $r (@{$otx->results}) {
        print $r->{status} ? 'true' : 'false', "\t", $r->{message}, "\n";
    }

Output:

    status  check
    ==========================
    true    text has 'HELLO'
    true    text match /\d\d\d\d-\d\d-\d\d/

There are two basic types of check expressions:

=over

=item *

L<plain text expressions|#plain-text-expressions> 



=item *

L<regular expressions|#regular-expressions>.



=back


=head1 Plain text expressions 

Plain text expressions define a lines an input text to contain.

    use Outthentic::DSL;
    
    my $otx = Outthentic::DSL->new(<<'HERE');
      I am ok, really
      HELLO Outthentic !!!
    HERE
    
    $otx->validate(<<'CHECK');
      I am ok
      HELLO Outthentic
    CHECK
    
    print "status\tcheck\n";
    print "==========================\n";
    
    for my $r (@{$otx->results}) {
        print $r->{status} ? 'true' : 'false', "\t", $r->{message}, "\n";
    }

Output:

    status  check
    ==========================
    true    text has 'I am ok'
    true    text has 'HELLO Outthentic'

Plain text expressions are case sensitive:

    use Outthentic::DSL;
    
    my $otx = Outthentic::DSL->new(<<'HERE');
      I am ok
    HERE
    
    $otx->validate(<<'CHECK');
      I am OK
    CHECK
    
    print "status\tcheck\n";
    print "==========================\n";
    
    for my $r (@{$otx->results}) {
        print $r->{status} ? 'true' : 'false', "\t", $r->{message}, "\n";
    }

Output:

    status  check
    ==========================
    false   text has 'I am OK'


=head1 Regular expressions

Similarly to plain text matching, you may require that input lines match some regular expressions.

This should be L<Perl Regular Expressions|http://perldoc.perl.org/perlre.html>.

Example:

    use Outthentic::DSL;
    
    my $otx = Outthentic::DSL->new(<<'HERE');
      2001-01-02
      Name: Outthentic
      App Version Number: 1.1.10
    HERE
    
    $otx->validate(<<'CHECK');
      regexp: \d\d\d\d-\d\d-\d\d # date in format of YYYY-MM-DD
      regexp: Name:\s+\w+ # name
      regexp: App Version Number:\s+\d+\.\d+\.\d+ # version number
    CHECK
    
    for my $r (@{$otx->results}) {
        print $r->{status} ? 'true' : 'false', "\t", $r->{message}, "\n";
    }

Output:

    true    text match /\d\d\d\d-\d\d-\d\d/
    true    text match /Name:\s+\w+/
    true    text match /App Version Number:\s+\d+\.\d+\.\d+/


=head1 One or many?

=over

=item *

Parser does not care about I<how many times> check expression matches an input text.



=item *

If at least I<one line> in a text matches the check expression - I<this check> is considered as successful.



=item *

If you use I<capturing> regex expressions, parser  I<accumulates> all captured data to make it possible further processing.



=back

Example:

    use Outthentic::DSL;
    use Data::Dumper;
    
    my $otx = Outthentic::DSL->new(<<'HERE');
        1 - for one
        2 - for two
        3 - for three
    HERE
    
    $otx->validate(<<'CHECK');
    
    regexp: (\d+)\s+-\s+for\s+(\w+)
    
    CHECK
    
    print Dumper($otx->{captures});

Output:

    [
      [
        '1',
        'one'
      ],
      [
        '2',
        'two'
      ],
      [
        '3',
        'three'
      ]
    ]

See L<"captures"|#captures> section for full explanation of a captures mechanism.


=head1 Comments, blank lines and text blocks

Comments and blank lines don't impact verification process but you may use them for the sake of DSL code readability.


=head1 Comments

Comment lines start with C<#> symbol, comments are ignored by parser.

DSL code:

    # comments could be represented at a distinct line, like here
    The beginning of story
    Hello World # or could be added for the existed expression to the right, like here


=head1 Blank lines

Blank lines are ignored as well.

DSL code:

    # every story has the beginning
    The beginning of a story
    # then 2 blank lines
    
    
    # end has the end
    The end of a story

But you B<can't ignore> blank lines in a I<text blocks>, see L<text blocks|#text-blocks> subsection for details.

Use C<:blank_line> marker to match blank lines inside text blocks.

DSL code:

    # :blank_line marker matches blank lines
    # this is especially useful
    # when match in text blocks context:
    
    begin:
        this line followed by 2 blank lines
        :blank_line
        :blank_line
    end:


=head1 Text blocks

Sometimes you need to match a text against a I<sequence of lines> like in code below.

    use Outthentic::DSL;
    
    my $otx = Outthentic::DSL->new(<<'HERE');
      this string followed by
      that string followed by
      another one string
      with that string
      at the very end.
    HERE
    
    $otx->validate(<<'CHECK');
    
      # this text block
      # consists of 5 strings
      # going consecutive
      
      begin:
          # plain strings
          this string followed by
          that string followed by
          another one
          # regexp patterns:
          regexp: with\s+(this|that)
          # and the last one in a block
          at the very end
      end:
      
    CHECK
    
    for my $r (@{$otx->results}) {
        print $r->{status} ? 'true' : 'false', "\t", $r->{message}, "\n";
    }

Output:

    true    [b] text has 'this string followed by'
    true    [b] text has 'that string followed by'
    true    [b] text has 'another one'
    true    [b] text match /with\s+(this|that)/
    true    [b] text has 'at the very end'

A negative example:

    my $otx = Outthentic::DSL->new(<<'HERE');
        that string followed by
        this string followed by
        another one string
        with that string
        at the very end.
    HERE
    
    $otx->validate(<<'CHECK');
    
      # this text block
      # consists of 5 strings
      # going consecutive
      
      begin:
          # plain strings
          this string followed by
          that string followed by
          another one
          # regex patterns:
          regexp: with\s+(this|that)
          # and the last one in a block
          at the very end
      end:
      
    CHECK
    
    for my $r (@{$otx->results}) {
        print $r->{status} ? 'true' : 'false', "\t", $r->{message}, "\n";
    }

Output:

    true    [b] text has 'this string followed by'
    false   [b] text has 'that string followed by'
    true    [b] text has 'another one'
    true    [b] text match /with\s+(this|that)/
    true    [b] text has 'at the very end'

C<begin:>, C<end:> markers decorate text blocks content. 

Markers should not be followed by any text at the same line.


=head2 Don't forget to close the block ...

Be aware if you leave "dangling" C<begin:> marker without closing C<end:> parser will remain in a I<text block> mode 
till the end of the file, which is probably not you want:

DSL code:

    begin:
        here we begin
        and till the very end 
        of this text
        we remain in `text block` mode


=head1 Code expressions

Code expressions are just a pieces of 'some language code' you may inline and execute B<during parsing> process.

By default, if I<language> is no set Perl language is assumed. Here is example:

    use Outthentic::DSL;
    
    my $otx = Outthentic::DSL->new('hello');
    
    $otx->validate(<<'CHECK');
      hello
      code: print "hi there!\n";
    CHECK
    
    for my $r (@{$otx->results}) {
        print $r->{status} ? 'true' : 'false', "\t", $r->{message}, "\n";
    }

Output:

    hi there!
    true    text has 'hello'

As you may notice code expression here has no impact on verification process, this trivial example just shows
that you may inline some programming languages code into Outthentic DSL. See L<generators|#generators> section on
how dynamically create new check expressions using common programming languages.

You may use other languages in code expressions, not only Perl. 

Use C<here> document style ( see L<multiline expressions|#Multiline> section ) and proper shebang to
insert code written in other languages. Here are some examples:


=head2 perl5

    code:  <<HERE
    !perl
    
    print 'hi there!'
    HERE


=head2 bash 

    code:  <<HERE
    !bash
    
    echo 'hi there!'
    HERE


=head2 ruby

    code: <<CODE
    !ruby
    
    puts 'hi there!'
    CODE


=head1 Asserts

Asserts expressions consists of assert value, and description - a short string to describe assert.

Assert value should be I<something> to be treated as false or true in Perl, here is examples:

DSL code

    # you may have assert expressions as is
    # then assert value should be Perl value to be treated as true or false
    # 
    assert: 0     this is not true in Perl
    assert: 1     this is true in Perl
    assert: "OK"  none empty string is for true in Perl
    assert: ""    empty string is for false in Perl

Asserts almost always to be created dynamically with generators. See the next section.


=head1 Generators

=over

=item *

Generators is the way to I<generate new Outthentic entities on the fly>.



=item *

Generator expressions like code expressions are just a piece of code to be executed.



=item *

The only requirement for generator code - it should return I<new Outthentic entities>.



=back

If you use Perl in generator expressions ( which is by default ) - last statement in your
code should be one of three:

=over

=item 1.

reference to array of strings where every string should I<represent> a I<new> Outthentic entity


=item 2.

string to represent a I<new> Outthentic entities, this could be multiline string


=item 3.

path to file with check expressions - new outthentic entities 


=back

Usually first two options most convenient way.

If you use languages I<other than Perl> to produce new Outthentic entities you should print them 
into B<stdout>. See examples below.

A new Outthentic entities are passed back to parser and executed immediately.

Generators expressions start with C<generator:> marker.

Here is simple example.

    use Outthentic::DSL;
    
    my $otx = Outthentic::DSL->new('HELLO');
    
    $otx->validate(<<'CHECK');
      generator: [ 'H', 'E', 'L', 'O' ];
    CHECK
    
    for my $r (@{$otx->results}) {
        print $r->{status} ? 'true' : 'false', "\t", $r->{message}, "\n";
    }

Output:

    true    text has 'H'
    true    text has 'E'
    true    text has 'L'
    true    text has 'O'

If you use other languages to generate expressions, 
you just need to print entries into stdout. Here are some generators examples for other languages:

Original check expressions list:

    Say
    HELLO

This generator creates 3 new check expressions:

    generator: <<CODE
    !bash
      echo say
      echo hello
      echo again
    CODE

Or if you prefer Ruby:

    generator: <<CODE
    !ruby
      puts 'say'
      puts 'hello'
      puts 'again'
    CODE

Updated check list:

    Say
    HELLO
    say
    hello
    again

Here is more complicated example using Perl language.

    # this generator creates
    # comments
    # and plain string check expressions:
    
    use Outthentic::DSL;
    
    my $otx = Outthentic::DSL->new(<<'HERE');
      foo value
      bar value
    HERE
    
    $otx->validate(<<'CHECK');
    
        generator: <<CODE
    
          my %d = ( 'foo' => 'foo value', 'bar' => 'bar value' );
          join "\n", map { ( "# $_" , $d{$_} ) } keys %d;
    
        CODE
    
    CHECK
    
    for my $r (@{$otx->results}) {
        print $r->{status} ? 'true' : 'false', "\t", $r->{message}, "\n";
    }

A check list being generated:

    # foo
    foo value
    # bar
    bar value

Output:

    true    text has 'foo value'
    true    text has 'bar value'

Generators could produce not only check expressions but code expressions and ... another generators.

So ... use your imagination power! ...

This is fictional example.

Input Text:

    A
    AA
    AAA
    AAAA
    AAAAA

DSL code:

    generator:  <<CODE
    
    sub next_number {                       
        my $i = shift;                       
        $i++;                               
        return if $i>=5;                 
        [
          'regexp: ^'.('A' x $i).'$',      
          "generator: next_number(".$i.")"
        ]
    }
    CODE

Generators are commonly used to create an asserts. 

This is short example for Ruby language:

    number: (\d+)
    
    generator: <<CODE
    !ruby
        puts "assert: #{capture()[0] == 10}, you've got 10!"  
    CODE


=head1 Validators

WARNING!!! You should prefer asserts over validators. Validators feature will be deprecated soon!

Validator expressions are perl code expressions used for dynamic verification.

Validator expressions start with C<validator:> marker.

A Perl code inside validator block should I<return> array reference. 

=over

=item *

Once code is executed a returned array structure treated as:



=item *

first element - is a status number ( Perl true or false )



=item *

second element - is a helpful message 



=back

Validators a kind of check expressions with check logic I<expressed> in program code. Here is examples:

    # this is always true
    validator: [ 10>1 , 'ten is bigger then one' ]
    
    # and this is not
    validator: [ 1>10, 'one is bigger then ten'  ]
    
    # this one depends on previous check
    regexp: credit card number: (\d+)
    validator: [ captures()[0][0] == '0101010101', 'I know your secrets!'  ]
    
    
    # and this could be any
    validator: [ int(rand(2)) > 1, 'I am lucky!'  ]

Validators are often used in conjunction with the L<captures expressions|#captures>. This is another example.

Input text:

    # my family ages list
    alex    38
    julia   32
    jan     2

DSL code:

    # let's capture name and age chunks
    regexp: /(\w+)\s+(\d+)/
    
    validator: <<CODE
    my $total=0;                        
    for my $c (@{captures()}) {         
        $total+=$c->[0];                
    }                                   
    [ ( $total == 72 ), "total age" ] 
    
    CODE


=head1 Multiline expressions


=head2 Multilines in check expressions

When parser parses check expressions it does it in a I<single line mode> :

=over

=item *

check expression is always single line string



=item *

input text is parsed in line by line mode, thus every line is validated against a single line check expression



=back

Here is example.

Input text:

    Multiline
    string
    here

DSL code:

    # check list
    # always
    # consists of
    # single line expressions
    
    Multiline
    string
    here
    regexp: Multiline \n string \n here

Results:

    +--------+---------------------------------------+
    | status | message                               |
    +--------+---------------------------------------+
    | OK     | matches "Multiline"                   |
    | OK     | matches "string"                      |
    | OK     | matches "here"                        |
    | FAIL   | matches /Multiline \n string \n here/ |
    +--------+---------------------------------------+

Use text blocks if you want to I<represent> multiline checks.


=head2 Multilines in code expressions, generators and validators

Perl expressions, validators and generators could contain multilines expressions

There are two ways to write multiline expressions:

=over

=item *

using back slash delimiters to split multiline string to many chunks



=item *

using HERE documents expressions 



=back


=head3 Back slash delimiters

C<\> delimiters breaks a single line text on a multi lines.

Example:

    # What about to validate stdout
    # With sqlite database entries?
    
    generator:                                                          \
    
    use DBI;                                                            \
    my $dbh = DBI->connect("dbi:SQLite:dbname=t/data/test.db","","");   \
    my $sth = $dbh->prepare("SELECT name from users");                  \
    $sth->execute();                                                    \
    my $results = $sth->fetchall_arrayref;                              \
    
    [ map { $_->[0] } @${results} ]                                     \


=head3 HERE documents expressions 

Is alternative to make your multiline code more readable:

    # What about to validate stdout
    # With sqlite database entries?
    
    generator: <<CODE
    
      use DBI;                                                            
      my $dbh = DBI->connect("dbi:SQLite:dbname=t/data/test.db","","");   
      my $sth = $dbh->prepare("SELECT name from users");                  
      $sth->execute();                                                    
      my $results = $sth->fetchall_arrayref;                              
      
      [ map { $_->[0] } @${results} ]
      
    CODE


=head1 Captures

Captures are pieces of data get captured when parser validate lines against a regular expressions:

Input text:

    # my family ages list.
    alex    38
    julia   32
    jan     2
    
    
    # let's capture name and age chunks
    regexp: /(\w+)\s+(\d+)/
    code: << CODE                                 
        for my $c (@{captures}){            
            print "name:", $c->[0], "\n";   
            print "age:", $c->[1], "\n";    
        }
    CODE

Data accessible via captures():

    [
        ['alex',    38 ]
        ['julia',   32 ]
        ['jan',     2  ]
    ]

Usually captured data is good candidates for assert checks.

DSL code:

    generator: << CODE
    !ruby
      total=0                 
      captures().each do |c|
        total+=c[0]
      end           
      puts "assert: #{total == 72} 'total age of my family'"
    CODE


=head2 captures() function

captures() function returns an array reference holding all the chunks captured during I<latest regular expression check>.

Here is another example:

    # check if stdout contains lines
    # with date formatted as date: YYYY-MM-DD
    # and then check if first date found is yesterday
    
    regexp: date: (\d\d\d\d)-(\d\d)-(\d\d)
    
    generator:  <<CODE
      use DateTime;                       
      my $c = captures()->[0];            
      my $dt = DateTime->new( year => $c->[0], month => $c->[1], day => $c->[2]  ); 
      my $yesterday = DateTime->now->subtract( days =>  1 );                        
      my $true_or_false = (DateTime->compare($dt, $yesterday) == 0);
      [ 
        "assert: $true_or_false first day found is - $dt and this is a yesterday"
      ];
    CODE


=head2 capture() function

capture() function returns a I<first element> of captures array. 

it is useful when you need data I<related> only  I<first> successfully matched line.

DSL code:

    # check if  text contains numbers
    # a first number should be greater then ten
    
    regexp: (\d+)
    generator: [ "assert: ".( capture()->[0] >  10 )." first number is greater than 10 " ]


=head1 Search context modificators

Search context modificators are special check expressions which not only validate text but modify search context.

By default search context is equal to original input text stream. 

That means parser executes validation use all the lines when performing checks 

However there are two search context modificators to change this behavior:

=over

=item *

within expressions



=item *

range expressions



=back


=head2 Within expressions

Within expression acts like regular expression - checks text against given patterns 

Text input:

    These are my colors
    
    color: red
    color: green
    color: blue
    color: brown
    color: back
    
    That is it!

DSL code:

    # I need one of 3 colors:
    
    within: color: (red|green|blue)

Then if checks given by within statement succeed I<next> checks will be executed I<in a context of> succeeded lines:

    # but I really need a green one
    green

The code above does follows:

=over

=item *

try to validate input text against regular expression "color: (red|green|blue)"



=item *

if validation is successful new search context is set to all I<matching> lines



=back

These are:

    color: red
    color: green
    color: blue

=over

=item *

thus next plain string checks expression will be executed against new search context


=back

Results:

    +--------+------------------------------------------------+
    | status | message                                        |
    +--------+------------------------------------------------+
    | OK     | matches /color: (red|green|blue)/              |
    | OK     | /color: (red|green|blue)/ matches green        |
    +--------+------------------------------------------------+

Here more examples:

    # try to find a date string in following format
    within: date: \d\d\d\d-\d\d-\d\d
    
    # we only need a dates in 2000 year
    2000-

Within expressions could be sequential, which effectively means using C<&&> logical operators for within expressions:

    # try to find a date string in following format
    within: date: \d\d\d\d-\d\d-\d\d
    
    # and try to find year of 2000 in a date string
    within: 2000-\d\d-\d\d
    
    # and try to find month 04 in a date string
    within: \d\d\d\d-04-\d\d

Speaking in human language chained within expressions acts like I<specifications>. 

When you may start with some generic assumptions and then make your requirements more specific. A failure on any step of chain results in
immediate break. 


=head1 Range expressions

Range expressions also act like I<search context modificators> - they change search area to one included
I<between> lines matching right and left regular expression of between statement.

It is very similar to what Perl L<range operator|http://perldoc.perl.org/perlop.html#Range-Operators> does 
when extracting pieces of lines inside stream:

    while (<STDOUT>){
        if /foo/ ... /bar/
    }

Outthentic analogy for this is range expression:

    between: foo bar

Between statement takes 2 arguments - left and right regular expression to setup search area boundaries.

A search context will be all the lines included between line matching left expression and line matching right expression.

A matching (boundary) lines are not included in range. 

These are few examples:

Parsing html output

Input text:

    <table cols=10 rows=10>
        <tr>
            <td>one</td>
        </tr>
        <tr>
            <td>two</td>
        </tr>
        <tr>
            <td>the</td>
        </tr>
    </table>

DSL code:

    # between expression:
    between: <table.*> <\/table>
    regexp: <td>(\S+)<\/td>
    
    # or even so
    between: <tr.*> <\/tr>
    regexp: <td>(\S+)<\/td>


=head2 Multiple range expressions

Multiple range expressions could not be nested, every new between statement discards old search context and setup new one:

Input text:

    foo
    
        1
        2
        3
    
        FOO
            100
        BAR
    
    bar
    
    FOO
    
        10
        20
        30
    
    BAR

DSL code:

    between: foo bar
    
    code: print "# foo/bar start"
    
    # here will be everything
    # between foo and bar lines
    
    regexp: \d+
    
    code: <<CODE                           
    for my $i (@{captures()}) {     
        print "# ", $i->[0], "\n"   
    }                               
    print "# foo/bar end"
    
    CODE
    
    between: FOO BAR
    
    code: print "# FOO/BAR start"
    
    # here will be everything
    # between FOO and BAR lines
    # NOT necessarily inside foo bar block
    
    regexp: \d+
    
    code:  <<CODE
    for my $i (@{captures()}) {     
        print "#", $i->[0], "\n";   
    }                               
    print "# FOO/BAR end"
    
    CODE

Output:

    # foo/bar start
    # 1
    # 2
    # 3
    # 100
    # foo/bar end
    
    # FOO/BAR start
    # 100
    # 10
    # 20
    # 30
    # FOO/BAR end


=head2 Restoring search context

And finally to restore search context use C<reset\_context:> statement.

Input text:

    hello
    foo
        hello
        hello
    bar

DSL code:

    between foo bar
    
    # all check expressions here
    # will be applied to the chunks
    # between /foo/ ... /bar/
    
    hello       # should match 2 times
    
    # if you want to get back to an original search context
    # just say reset_context:
    
    reset_context:
    hello       # should match three times


=head2 Range expressions caveats

Range expressions can't verify continuous lists.

That means range expression only verifies that there are I<some set> of lines inside some range.
It is not necessary should be continuous.

Example.

Input text:

    foo
        1
        a
        2
        b
        3
        c
    bar

DSL code:

    between: foo bar
        1
        code: print capture()->[0], "\n"
        2
        code: print capture()->[0], "\n"
        3
        code: print capture()->[0], "\n"

Output:

        1 
        2 
        3 

If you need check continuous sequences checks use text blocks.


=head1 Experimental features

Below is highly experimental features purely tested. You may use it on your own risk! ;)


=head2 Streams

Streams are alternative for captures. Consider following example.

Input text:

    foo
        a
        b
        c
    bar
    
    foo
        1
        2
        3
    bar
    
    foo
        0
        00
        000
    bar

DSL code:

    begin:
    
        foo
    
            regexp: (\S+)
            code: print '#', ( join ' ', map {$_->[0]} @{captures()} ), "\n"
    
            regexp: (\S+)
            code: print '#', ( join ' ', map {$_->[0]} @{captures()} ), "\n"
    
            regexp: (\S+)
            code: print '#', ( join ' ', map {$_->[0]} @{captures()} ), "\n"
    
    
        bar
    
    end:

Output:

    # a 1 0
    # b 2 00
    # c 3 000

Notice something interesting? Output direction has been inverted.

The reason for this is Outthentic check expression works in "line by line scanning" mode 
when text input gets verified line by line against given check expression. 

Once all lines are matched they get dropped into one heap without preserving original "group context". 

What if we would like to print all matching lines grouped by text blocks they belong to?

As it's more convenient way ...

This is where streams feature comes to rescue.

Streams - are all the data successfully matched for given I<group context>. 

Streams are I<applicable> for text blocks and range expressions.

Let's rewrite last example.

DSL code:

    begin:
    
        foo
            regexp: \S+
            regexp: \S+
            regexp: \S+
        bar
    
        code:  <<CODE
            for my $s (@{stream()}) {           
                print "# ";                     
                for my $i (@{$s}){              
                    print $i;                   
                }                               
                print "\n";                     
            }
    
    CODE
    
    end:

Stream function returns an arrays of I<streams>. Every stream holds all the matched lines for given I<logical block>.

Streams preserve group context. Number of streams relates to the number of successfully matched groups.

Streams data presentation is much closer to what was originally given in text input:

Output:

    # foo a b  c    bar
    # foo 1 2  3    bar
    # foo 0 00 000  bar

Stream could be specially useful when combined with range expressions of I<various> ranges lengths.

For example.

Input text:

    foo
        2
        4
        6
        8
    bar
    
    foo
        1
        3
    bar
    
    foo
        0
        0
        0
    bar

DSL code:

    between: foo bar
    
    regexp: \d+
    
    code:  <<CODE
        for my $s (@{stream()}) {           
            print "# ";                     
            for my $i (@{$s}){              
                print $i;                   
            }                               
            print "\n";                     
        }
    
    CODE

Output:

    # 2 4 6 8
    # 1 3
    # 0 0 0


=head1 Examples

=over

=item *

Some code examples mostly mentioned at this documentation could be found at C<examples/> directory


=item *

A plenty of other L<examples|https://github.com/melezhik/outthentic/tree/master/examples> could be found at Outthentic module


=back


=head1 Environment variables

I'll document these variables later. Here is just a list:

=over

=item *

OUT_KEEP_SOURCE_FILES


=item *

OTX_DEBUG


=back


=head1 Author

L<Aleksei Melezhik|mailto:melezhik@gmail.com>


=head1 Home page

https://github.com/melezhik/Outthentic-dsl


=head1 COPYRIGHT

Copyright 2016 Alexey Melezhik.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


=head1 See also

Alternative Outthentic DSL introduction could be found here - L<intro.md|https://github.com/melezhik/Outthentic-dsl/blob/master/intro.md>


=head1 Thanks

=over

=item *

To God as the One Who inspires me to do my job!


=back
