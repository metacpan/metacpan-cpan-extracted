
# This example makes sure the synopsis part is actually working. This code would
# be copy and pasted to the module 'as is'.

    use lib 'lib', '../lib' ;
    use Term::Shell::MultiCmd;
    my @command_tree =
     ( 'multi node command' =>
             { help => "Help title.",
               opts => 'force repeat=i',
               exec => sub {
                   my ($o, %p) = @_ ;
                   print "$p{ARG0} was called with force=$p{force} and repeat=$p{repeat}\n"
               },
             },
       'multi node another command' =>
             { help => 'Another help title.
  Help my have multi lines, the top one
  would be used when one linear needed.',
               comp => sub {
                   # this function would be called when use hits tab completion at arguments
                   my ($o, $word, $line, $start, $op, $opts) = @_ ;
                   # .. do something, then
                   return qw/a list of completion words/ ;
               },
               exec => sub { my ($o, %p) = @_ ; print "$p{ARG0} was called\n"},
             },
       'multi node third command' =>
             { help => 'same idea',
               comp => [qw/a list of words/], # this is also possible
               exec => sub { my ($o, %p) = @_ ; print "$p{ARG0} was called. Isn't that fun?\n"},
               # comp and opts are optional
             },
       'multi node' => 'You can add general help title to a node',
     ) ;

     Term::Shell::MultiCmd
      -> new()
      -> populate( @command_tree )
      -> loop ;
