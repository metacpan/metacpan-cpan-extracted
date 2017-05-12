package Term::ShellKit::Commands;

require Term::ShellKit;

######################################################################

sub eval ($) {
  my $input = shift;
  my @results = eval "package $Term::ShellKit::CurrentPackage; no strict qw( refs vars subs ); $input";
  die $@ if $@;
  ! scalar( @results ) ? '' : 
  scalar( @results == 1 ) ? (
      ( ! defined $results[0] ) ? 'undef' : "$results[0]"
    ) : 
      join(', ', map { 
      ( ! defined ) ? 'undef' : ( ref $_ ) ? "$_" : "'$_'" 
    } @results );
}

sub package ($) {
  my $input = shift;
  $input =~ s/\;\s*$//;
  $Term::ShellKit::CurrentPackage = $input;
}

sub exit {
  exit;
}

sub kit { 
  die "No kit name provided" unless ( scalar @_ );
  map { Term::ShellKit::load_kit( $_ ) } @_; 
}

######################################################################

sub execute ($) {
  my $command = shift;
  qx{$command};
}

######################################################################

sub echo (;$) {
  shift;
}

######################################################################

use vars qw( $PODViewer );
$PODViewer ||= "Pod::Text" || "Pod::Text::TermCap";

sub help (;$) {
  my $topic = shift || 'Term::ShellKit::Commands';
  
  $topic =~ s/kit /Term::ShellKit::/;
  if ( $topic =~ /^[\w\:]+$/ ) {
    (my $lib = $topic . '.pm' ) =~ s|::|/|go;
    if ( ! $::INC{$lib} ) { eval { local $SIG{__DIE__}; require $lib } }
    $topic = $::INC{$lib} if ( $::INC{$lib} );
  }
  
  Term::ShellKit::require_package( $PODViewer );
  $PODViewer->new()->parse_from_file( $topic );
  return;
}

######################################################################

use vars qw( %CommandAliases );
%CommandAliases = (
  '"' => 'echo',
  '$' => 'eval',
  '!' => 'execute',
  'q' => 'exit',
  'quit' => 'exit',
  '?' => 'help',
);

sub alias {
  if ( scalar @_ ) {
    my $cmd = shift;
    if ( scalar @_ ) {
      $CommandAliases{ $cmd } = join ' ', @_;
      return;
    } else {
     $CommandAliases{ $cmd };
    }
  } else {
    map "$_: $CommandAliases{ $_ }", sort keys %CommandAliases;
  }
}

sub _shell_rewrite {
  my $input = shift;
  
  $input =~ s/\A\s+//;
  my ($command, $args) = split(' ', $input, 2);
  my $alias = $CommandAliases{ $command }
      or return;
  
  return $alias . ( length($args) ? " $args" : '' );
}

######################################################################

1;

__END__

=head1 NAME

Term::ShellKit::Commands - Basic shell functions


=head1 SYNOPSIS

  > perl -MTerm::ShellKit -eshell
  Term::ShellKit: Starting interactive shell
  
  Term::ShellKit> eval join ', ', 1 .. 10 
  1, 2, 3, 4, 5, 6, 7, 8, 9, 10
  
  Term::ShellKit> alias incr eval $i += 1
  Term::ShellKit> incr
  1
  Term::ShellKit> incr
  2
  
  Term::ShellKit> help
  NAME
      Term::ShellKit - Generic Perl command-line environment
  ...
  
  Term::ShellKit> exit


=head1 COMMANDS

The following commands are available.


=head2 alias

Manipulates Term::ShellKit aliases.

=over 4

=item *

alias: Shows all aliases.

=item *

alias I<name>: Shows the alias for I<name>.

=item *

alias I<name> I<command>: Sets I<name> as an alias for I<command>.

=back


=head2 echo (alias ")

Prints the provided argument.


=head2 eval (alias $)

Run some Perl using eval.

=over 4

=item *

eval I<perl statements...>

Runs the provided code (with Perl's eval operator) and prints the result.

=back


=head2 execute (alias !)

Run an external program with Perl's qx operator.

=over 4

=item *

execute I<program arguments...>

Runs the named external program (with Perl's qx operator) and waits for it to complete, then prints the program's output.

=back


=head2 exit (alias quit, or q)

Exit the shell.

=over 4

=item *

exit

=back


=head2 help (alias ?)

Uses the pod2text script to display documentation for a Perl module.

=over 4

=item *

help: Gets help for the current shell

=item *

help kit I<KitName>: Gets help for the named module

=item *

help I<module>: Gets help for the named module

=back


=head2 kit

Load a ShellKit package.

=over 4

=item *

kit I<KitName>, I<KitName>, ...

Load the named kits.

=back

Try "kit Dev" to load the Dev kit, or "help kit Dev" to learn more about it. 

Typing "kit AutoPager" will provide ShellKit with output buffered through /usr/bin/more or your prefered pager program.  


=head1 SEE ALSO

L<Term::ShellKit>

=cut
