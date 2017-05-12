######################################################################

use vars qw( %Printable );
%Printable = ( ( map { chr($_), unpack('H2', chr($_)) } (0..255) ),
	      "\\"=>'\\', "\r"=>'r', "\n"=>'n', "\t"=>'t', "\""=>'"' );

# $special_characters_escaped = printable( $source_string );
sub printable ($) {
  local $_ = ( defined $_[0] ? $_[0] : '' );
  s/([\r\n\t\"\\\x00-\x1f\x7F-\xFF])/\\$Printable{$1}/g;
  return $_;
}

sub quote_non_words ($) {
  ( ! length $_[0] or $_[0] =~ /[^\w\_\-\/\.\:\#]/ ) ? '"'.$_[0].'"' : $_[0]
}

# quoted_and_escaped = qprintable( $source_string );
sub qprintable ($) { quote_non_words printable $_[0] }

sub list2string {
  join ( ' ', map qprintable($_), @_ );
}

######################################################################

sub shell_cmd_eval {
  my $shell = shift;
  my $command = shift;

  $command =~ s/\s+/ /mg;
  if ( length $command > 32 ) { $command = substr($command, 0, 30) . "..." }
  print "$command: " . join(', ', map { defined $_ ? $_ : '(undef)' } scalar @results ? @results : "Completed.") );
  
  return 1;
}

######################################################################

sub shell_prompt_continuation {
  my $shell = shift;
  my $d_prompt = $shell->shell_prompt;
  (my $c_prompt = $d_prompt) =~ s/[\w\:\-]/ /g;
  $c_prompt;
}

use vars qw( $ShellInput );

sub io_get_command {
  my $continuation = "";
  LINE: while () {
    local $_ = &$ShellInput( length($continuation) ? $shell->shell_prompt_continuation : $shell->shell_prompt );
    last LINE unless defined (  $_ );
    
    if (s/\\$//s) {
      chomp;
      $continuation .= $_;
      next LINE ;
    } else {
      $_ = "$continuation$_" if ( length $continuation );
      $continuation = "";
    }
    
    if ( /^<<$/ ) {
      my $line = '';
      while ( <> ) {
	$line .= $_
      }      
      $_ = $line;
    }
    
    s/^\s+//;
    s/\s+$//;
    
    $continuation = "";
    return $_;
  }
}

######################################################################

sub shell_err {
  my $shell = shift;
  warn "$shell: " . join(' ', @_, "\n" );
}

######################################################################

use vars qw( @CommandHandlers );

sub shell {
  my $shell = shift;
  $shell = $shell->shell_require( shift ) if ( scalar @_ );
  $ShellInput ||= \&io_get_command();
  
  $shell->shell_start;
  local %Alias = ( $shell->shell_aliases );
  COMMAND: while () {
    local $_ = &$ShellInput( );
    last COMMAND unless defined (  $_ );
    
    if ( defined $Alias{$_} ) {
      $shell->io_print_lines($shell->shell_prompt_continuation() . $Alias{$_});
      $_ = $Alias{$_};
    }
    
    my $cmd = ( $_ =~ /^(\S+)\s/ )[0];
    if ( defined $cmd and defined $Alias{$cmd} ) {
      s/^\Q$cmd\E/$Alias{$cmd}/;
      $shell->io_print_lines( $shell->shell_prompt_continuation() . $_);
    }
    
    if ( ! length $_ ) {
      next COMMAND;
    }
    
    my @failures;
    foreach my $cmd_type ( @CommandHandlers ) {
      my ($status,$info) = $shell->$cmd_type( $_ );
      if ( $status ) {
        if ( $info ) {
	  push @failures, $cmd_type, $info;
	  last;
	}
	next COMMAND;
      } else {
	push @failures, $cmd_type, $info;
      }
    }
    my $excerpt = $_;
    $excerpt =~ s/\s+/ /mg;
    if ( length $excerpt > 32 ) { $excerpt = substr($excerpt, 0, 30) . "..." }
    
    $shell->io_print_lines( "$excerpt: Failed." );
    while ( scalar @failures ) {
      my $method = shift @failures;
      my $message = shift @failures;
      next unless $message;
      $message =~ s/\n/\n    /g;
      $shell->io_print_lines( "  $method: $message" );
    }
  }
}

sub shell_auto_command {
  my $shell = shift;
  my $command = shift;
  $shell->io_print_lines( $shell->shell_prompt_continuation() . 
list2string($command, @_) );
  $shell->$command( @_ );
}

######################################################################

use vars qw( @CommandHandlers );

sub shell {
  my $shell = shift;
  $shell = $shell->shell_require( shift ) if ( scalar @_ );
  $ShellInput ||= $shell->shell_input();
  
  my $continuation = "";
  
  $shell->shell_start;
  local %Alias = ( $shell->shell_aliases );
  COMMAND: while () {
    local $_ = &$ShellInput( length($continuation) ? $shell->shell_prompt_continuation : $shell->shell_prompt );
    last COMMAND unless defined (  $_ );
    
    if (s/\\$//s) {
      chomp;
      $continuation .= $_;
      next COMMAND ;
    } else {
      $_ = "$continuation$_" if ( length $continuation );
      $continuation = "";
    }
    
    if ( /^<<$/ ) {
      my $line = '';
      while ( <> ) {
	$line .= $_
      }      
      $_ = $line;
    }
    
    s/^\s+//;
    s/\s+$//;
    
    if ( defined $Alias{$_} ) {
      $shell->shell_out_lines($shell->shell_prompt_continuation() . $Alias{$_});
      $_ = $Alias{$_};
    }
    
    my $cmd = ( $_ =~ /^(\S+)\s/ )[0];
    if ( defined $cmd and defined $Alias{$cmd} ) {
      s/^\Q$cmd\E/$Alias{$cmd}/;
      $shell->shell_out_lines( $shell->shell_prompt_continuation() . $_);
    }
    
    if ( ! length $_ ) {
      next COMMAND;
    }
    
    my @failures;
    foreach my $cmd_type ( @CommandHandlers ) {
      my ($status,$info) = $shell->$cmd_type( $_ );
      if ( $status ) {
        $continuation = "";
        if ( $info ) {
	  push @failures, $cmd_type, $info;
	  last;
	}
	next COMMAND;
      } else {
	push @failures, $cmd_type, $info;
      }
    }
    my $excerpt = $_;
    $excerpt =~ s/\s+/ /mg;
    if ( length $excerpt > 32 ) { $excerpt = substr($excerpt, 0, 30) . "..." }
    
    $shell->shell_out_lines( "$excerpt: Failed." );
    while ( scalar @failures ) {
      my $method = shift @failures;
      my $message = shift @failures;
      next unless $message;
      $message =~ s/\n/\n    /g;
      $shell->shell_out_lines( "  $method: $message" );
    }
  }
}

sub shell_auto_command {
  my $shell = shift;
  my $command = shift;
  $shell->shell_out_lines( $shell->shell_prompt_continuation() . 
list2string($command, @_) );
  $shell->$command( @_ );
}

######################################################################


To enter commands, you can:

=over 4

=item *

Use standard line-editing control keys, including filename tab-completion and a command history (curtesy of Term::Readline).

=item *

End a line with a backslash character to continue it on another line.

=item *

Enter "<<" followed by return, then several lines of text, followed by return and control-d.

=back





=head1 EXAMPLES

=head2 Declaring a subroutine

In the below, I use the << notation to enter a multi-line block of Perl, terminated by a control-D.

You can then call any subroutines you've defined on the shell prompt line.
  
  ~> perl lib/Shell/Shell.pm
  Term::ShellKit: Starting interactive shell
  Term::ShellKit> <<
  
  sub count {
    my $count = shift;
    join(', ', ( 0 .. $count ) )
  }
  ^D
  
  Term::ShellKit> count(3)
  count(3): 0, 1, 2, 3
  Term::ShellKit> count(5)
  count(5): 0, 1, 2, 3, 4, 5


=head2 Declaring a shell command

To create a new shell command, define a function using the above << syntax. 

You can then call those functions with space-separated arguments on the shell prompt line. These commands can use existing shell methods for further interaction with the user.

  ~> perl lib/Shell/Shell.pm
  Term::ShellKit: Starting interactive shell
  Term::ShellKit> <<
  
  sub do_count {
    my $count = shift || $Term::ShellKitInput->( 'do_count to: ' );
    $shell->shell_out_lines( join(', ', ( 0 .. $count ) ) );
  }
  ^D
  
  Term::ShellKit> do_count 3
  0, 1, 2, 3

  Term::ShellKit> do_count  
  do_count to: 3
  0, 1, 2, 3


