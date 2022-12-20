
package Term::Shell::MultiCmd;

use warnings;
use strict;
use Carp ;

=head1 NAME

Term::Shell::MultiCmd -  Nested Commands Tree in Shell Interface

=cut

our $VERSION = '3.02';

=head1 SYNOPSIS

    # Examples are available with the distribution, under directory 'examples/'
    # This one is named examples/synopsis.pl

    use Term::Shell::MultiCmd;
    my @command_tree =
     ( 'multi word command' =>
             { help => "Help title.",
               opts => 'force repeat=i',
               exec => sub {
                   my ($o, %p) = @_ ;
                   print "$p{ARG0} was called with force=$p{force} and repeat=$p{repeat}\n"
               },
             },
       'multi word another command' =>
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
       'multi word third command' =>
             { help => 'same idea',
               comp => [qw/a list of words/], # this is also possible
               exec => sub { my ($o, %p) = @_ ; print "$p{ARG0} was called. Isn't that fun?\n"},
             },
       'multi word' => 'You can add general help title to a path',
     ) ;

     Term::Shell::MultiCmd
      -> new()
      -> populate( @command_tree )
      -> loop ;

    print "All done, see you later\n" ;

=head1 TIPS

To get the most from a command line, it might be a good idea to get the latest versions of
Term::ReadLine and Term::ReadKey.
There are numberless ways of doing it, one of them is running 'cpan update Bundle::CPAN' (with a proper write permission).

If you use MacOS, and the completion tab converts newlines to literal '\n' chars, you can try using Term::ReadLine::Perl5
instead of Term::ReadLine::Gnu. One way of doing it is with the code below:
BEGIN{ $ENV{PERL_RL} = "Perl o=0" }

=cut
# some of my common utility functions:
sub _params($@) {

    # convert parameter to hash table, at this point,
    # I wish perl would have followed python's function
    # parameters scheme, or made Params::Smart standard.
    # (Had anybody mentioned perl6?)

    # Note 1: this parameter processing takes time, and wouldn't
    # be a good choise for frequently called functions.

    # Note 2: as parameters are suplied by developer, a bad
    # would terminate the program - this is not a sandbox.

    my %ret ;
    my $str = shift ;
    for (split ' ', $str) {
        /(\w+)([\=\:](.*))?/ or confess "_params can only take simple instructions
like key (must be provided), or key=value (value becomes default), or key= (default empty string)
" ;
        $ret{$1} = $2 ? $3 : undef ;
    }
    # when called as OO, itemize self
    # Note: this one wouldn't work with classes (as in Term::Shell::MultiCmd -> new )
    $ret{self} = shift if $_[0] and ref $_[0] ;
    while (@_) {
        my ($k, $v) = (shift, shift) ;
        $k =~ s/^\-?\-?// unless ref $k ;
        croak "unknown parameter: '$k'\n expected params: $str\n" unless exists $ret{$k} ;
        $ret{$k} = $v ;
    } ;
    while (my ($k, $v) = each %ret) {
        croak "missing parameter: '$k'\n expected params: $str\n" unless defined $v ;
    }
    %ret
}

sub _options {
    # Parsing user's options, this function is more forgiving than _params
    my $p = shift ;
    my @p = ref $p ? @$p : split ' ', $p ;
    my %p ; # now we have a complete set

    # use Getopt::Long 'GetOptionsFromArray' ; -- didn't work as I expected ..
    use Getopt::Long ;
    local @ARGV = @_ ;
    if (@p and not eval { GetOptions( \%p, @p ) }) {
        $p{_ERR_} = "$@ Expected " . join ', ', map {/(\w+)/ ; '-' . ($1 || $_)} sort @p ;
        $p{_ERR_} .= "\n" ;
    }
    $p{ARGV} ||= [@ARGV] ; # all the leftover, in order
    %p
}

# we can't limit ourselves by 'use :5.10', not yet.
sub _say(@) { print join ('', @_) =~ /^\n*(.*?)\s*$/s, "\n" }


# module specific functions

# Important Note:
# Do manipulate $o->{delimiter} and $o->{delimiterRE} ONLY if you know what you're doing ...

sub _split($$) {
    my ($o, $l) = @_ ;
    use Text::ParseWords 'quotewords';
    # grep {defined $_ and $_ ne ''} quotewords $o->{delimiterRE} || '\s+', 0, $l
    grep {defined and length } quotewords $o->{delimiterRE} || '\s+', 0, $l
}

sub _join($@) {
    my $o = shift ;
    join $o->{delimiter} || ' ', @_
}

sub _travela($@) {              # explicit array
    my ($o) = shift ;
    my ($c, $d, @w, @path) = ($o->{root} || $o->{cmds}, $o->{delimiter} || ' ', @_ );
    while ( @w and 'HASH' eq ref $c ) {
        my $w = shift @w ;
        if (exists $c->{$w}) {
            $c = $c->{$w} ;
            push @path , $w ;# $path .= "$w ";
            next ;
        }
        my @c = grep /^\Q$w/, keys %$c ;
        if(@c == 1) {
            $c = $c->{$c[0]} ;
            push @path, $c[0] ; # $path .= "$c[0] " ;
            next ;
        }
        if (@c > 1 ) {
            my $cmd = join $d, @path, $w ;
            return "Ambiguous command: '$cmd'\n $w could mean: @c\n" ;
        }

        # if @c == 0 : should I state the obvious? well, not with perl
        unshift @w, $w ;
        last ;
    }
    ($c, join ($d, @path), @w)
}

sub _travel($$) {
    my ($o, $c) = &_check_pager ; # clear $c pager sign, let cmd know about it.
    ($o, $c) = &_check_sh_pipe if $o->{enable_sh_pipe} and not $o->{piper};
    $c = _check_silent_aliases($o, $c);
    _travela( $o, _split $o, $c )
}

sub _expect_param_comp {
    my($o, $word, $line, $pos, $op, $opt) = @_;
    # This is ugly, Getopt::Long has many options, and
    # caller can use any of them. However, my parsing would
    # be limited.
    # print "$opt\n" ;
    my ($eq, $t) = $opt =~ /([\=\:])(\w)\W*$/ ;
    my $type = ($t ?
                $t eq 'i' ? 'Integer':
                $t eq 'o' ? 'Extended Integer':
                $t eq 's' ? 'String' :
                $t eq 'f' ? 'Real Number' :
                $t : $t ) ;
    $type = "(optional) $type" if $eq eq ':' ;
    ("$opt\nParameter Expected for -$op, type '$type'", $word)
}

my $dlm = $; ; # cache this value, in case the developer changes it on the fly.
               # Should I make it explicit '\034' value?

sub _filter($@) {
    my $w = shift ;
    my $qr = qr/^\Q$w/ ;
    grep /$qr/, sort grep {$_ ne $dlm}
      'ARRAY'  eq ref $_[0] ? @{$_[0]} :
        'HASH' eq ref $_[0] ? (keys %{$_[0]}) :
          @_   ;
}

=head1 SUBROUTINES/METHODS

=head2 new

    my $cli = new Term::Shell::MultiCmd ;
   - or -
    my $cli = Term::Shell::MultiCmd->new( [optional parameters ...] ) ;

The parameters to the constructor are passed in hash form, preceding dash is optional.

Optional Parameters for the new command:

=over 4

=item * -prompt

    my $cli = new Term::Shell::MultiCmd ( -prompt => 'myprompt') ;
- or -
    my $cli = mew Term::Shell::MultiCmd ( -prompt => \&myprompt) ;

Overwrite the default prompt 'shell'.
Rules are:

 If prompt is a CODE reference, call it in each loop cycle and display the results.
 if it ends with a non-word character, display it as is.
 Else, display it with the root-path (if exists) and '> ' characters.

=item * -help_cmd

Overwrite the default 'help' command, empty string would disable this command.

=item * -quit_cmd

Overwrite the default 'quit' command, empty string would disable this command.

=item * -root_cmd

    my $cli = new Term::Shell::MultiCmd ( -root_cmd => 'root' ) ;

This would enable the root command and set it to root.

Unlike 'quit' and 'help', the 'root' command is a little unexpected. Therefore it is disabled by default. I
strongly recommend enabling this command when implementing a big, deep command tree. This allows the user rooting
in a node, then referring to this node thereafter. After enabling, use 'help root' (or whatever names you've chosen)
for usage manual.

=item * -history_file

    my $cli = new Term::Shell::MultiCmd ( -history_file => "$ENV{HOME}/.my_progarms_data" ) ;

This is the history file name. If present, try to load history from this file just
before the loop command, and try saving history in this file after the loop command.
Default is an empty string (i.e. no history preserved between sessions). Please note that
things might get tricky if that if multiple sessions are running at the same time.

=item * -history_size

Overwrite the default 100 history entries to save in hisotry_file (if exists).

=item * -history_more

If the history_file exists, try to load this data from the file during initialization, and save it at loop end.
For Example:

   my %user_defaults ;
   my $cli = new Term::Shell::MultiCmd ( -history_file => "$ENV{HOME}/.my_saved_data",
                                         -history_size => 200,
                                         -history_more => \%user_defaults,
                                        ) ;
   # ....
   $cli -> loop ;

This would load shell's history and %user_defaults from the file .my_saved_data before the loop, and
store 200 history entries and %user_defaults in the file after the loop.

Note that the value of history_more must be a reference for HASH, ARRAY, or SCALAR. And
no warnings would be provided if any of the operations fail. It wouldn't be a good idea
to use it for sensitive data.

=item * -history_flash_file

This is a newer feature, somehow replacing -history_file:
If -history_flash_file exists, then use it for commands history - but write each command to the EOF immediatly after execution. This is
helpful in two cases - when using multiple sessions and when the process exits ungracefully. Note that in this case,  -history_file will
be used as a container for -history_more only.
Example:

   my %config ;
   my $cli = new Term::Shell::MultiCmd ( -history_file => "$ENV{HOME}/.my_saved_config",       # keep \%config only
                                         -history_size => 200,
                                         -history_more => \%config,
                                         -history_flash_file => "$ENV{HOME}/.my_saved_hisotry" # keep all history
                                         ) ;
   

=item * -pager

As pager's value, this module would expect a string or a sub that returns a FileHandle. If the value is a string,
it would be converted to:

   sub { use FileHandle ; new FileHandle "| $value_of_pager" }

When appropriate, the returned file handle would be selected before user's command execution, the old
one would be restored afterward. The next example should work on most posix system:

   my $cli = new Term::Shell::MultiCmd ( -pager => 'less -rX',
                                         ...

The default pager's value is empty string, which means no pager manipulations.

=item * -pager_re

Taking after perldb, the default value is '^\|' (i.e. a regular expression that matches '|' prefix, as in
the user's command "| help"). If the value is set to an empty string, every command would trigger
the pager.

The next example would print any output to a given filehandle:

   my $ret_value ;
   my $cli = new Term::Shell::MultiCmd ( -pager => sub {
                                               open my $fh, '>', \$ret_value or die "can't open FileHandle to string (no PerlIO?)\n" ;
                                               $fh
                                          },
                                         -pager_re => '',
                                       ) ;
  # ...
  $cli -> cmd ('help -t') ;
  print "ret_value is:\n $ret_value" ;

=item * -record_cmd

If it's a function ref, call it with an echo of the user's command


   my $cli = new Term::Shell::MultiCmd ( -record_cmd => sub {
                                            my $user_cmd = shift;
                                            system "echo '$user_cmd' >> /tmp/history"
                                          }
                                       ) ;


=item * -empty_cmd

Function ref only, call it when user hits 'Return' with no command or args (not even spaces)

   my $cli = new Term::Shell::MultiCmd ( -empty_cmd => sub {
                                                # Assuming some commands are recorded in $last_repeatable_cmd
                                                if ( $last_repeatable_cmd ) {
                                                    # repeat it
                                                }
                                          }
                                       ) ;


=item * -query_cmd

If exeuting a node, and node contains the query cmd, it would be executed instead of the help command (on the node)
Default: 'query'
For exmaple, with this feature, if "my cmd query" exists, it would also be exeuted at "my cmd'

   my $cli = new Term::Shell::MultiCmd ( -query_cmd => 'query',
                                       ) ;
=item * -enable_sh_pipe

If true, allow redirect output to a shell command by the suffix ' | <chell cmd>'. Example:
Shell> my multy path cmd | grep -w 42
Default is value is 1, To disable, set it to false (0 or '' or undef)

   my $cli = new Term::Shell::MultiCmd ( -enable_sh_pipe => '',
                                       ) ;

Note: If both pager and this pipe are used, the pipe will be ingored and the command will get whole line
as argument.

=back

=cut

sub _new_readline($) {
    my $o = shift ;
    use Term::ReadLine;
    my $t = eval { local $SIG{__WARN__} = 'IGNORE' ;
                   Term::ReadLine->new($o->prompt)} ;
    if (not $t ) {
        die "Can't create Term::ReadLine: $@\n" if -t select ;
    }
    elsif (defined $readline::rl_completion_function) {
        $readline::rl_completion_function =
          sub { $o -> _complete_cli(@_)} ;
    }
    elsif ( defined (my $attr = $t -> Attribs())) {
        $attr->{attempted_completion_function} =
          $attr->{completion_function} =
            sub { $o -> _complete_gnu(@_) } ;
    }
    else {
        warn __PACKAGE__ . ": no tab completion support for this system. Sorry.\n" ;
    }
    $t
}

sub new {
    my $class = shift ;
    my $params = 'help_cmd=help quit_cmd=quit root_cmd= prompt=shell>
                  history_file= history_size=10000 history_more= pager= pager_re=^\|
                  query_cmd=query enable_sh_pipe=1
                  record_cmd= empty_cmd= history_flash_file=
                  ';
    my %p = _params $params, @_ ;

    # structure rules:
    # hash ref is a path, keys are items (commands or paths) special item $dlm is one liner help
    # array ref is command's data as [help, command, options, completion]
    #  where: first help line is the one liner, default completion might be good enough

    my $o = bless { cmds => { },
                    map {($_, $p{$_})} map { /^(\w+)/ } split ' ', $params
                  }, ref ( $class ) || $class ;

    $o -> {delimiter  } = ' '   ; # now, programmers can manipulate the next two values after creating the object,
    $o -> {delimiterRE} = '\s+' ; # but they must be smart enough to read this code. - jezra
    $o -> _root_cmds_set() ;
    # _new_readline $o unless $DB::VERSION ; # Should I add parameter to prevent it?
    #                                        # it could be useful when coder doesn't plan to use the loop
    #   - on second thought, create it when you have to.
    _last_setting_load $o ;
    _last_history_flash_load $o ;
    $o
}

sub _root_cmds_clr($) {
    my $o = shift ;
    my $root = $o->{root};
    return unless $root and $o->{cmds} != $root ;
    for ([$o->{help_cmd}, \&_help_command],
         [$o->{quit_cmd}, \&_quit_command],
         [$o->{root_cmd}, \&_root_command],
        ) {
        delete $root->{$_->[0]} if exists $root->{$_->[0]} and $root->{$_->[0]}[1] eq $_->[1]
    }
    delete $o->{root} ;
    delete $o->{root_path} ;
}

sub _root_cmds_set($;$$) {
    my ($o, $root, $path) = @_ ;
    ($root, $o->{cmds}) = ($o->{cmds}, $root) if $root ;
    $o -> add_exec ( path => $o->{help_cmd},
                     exec => \&_help_command,
                     comp => \&_help_command_comp,
                     opts => 'recursive tree',
                     help => 'help [command or prefix]
Options:
$PATH -t --tree      : Show commands tree
$PATH -r --recursive : Show full help instead of title, recursively'
                   ) if $o->{help_cmd};

    $o -> add_exec ( path => $o->{quit_cmd},
                     exec => \&_quit_command,
                     help => 'Exit this shell',
                   ) if $o->{quit_cmd};

    $o -> add_exec ( path => $o->{root_cmd},
                     exec => \&_root_command,
                     comp => \&_root_command_comp,
                     # opts => 'set display clear', - use its own completion
                     help => 'Execute from, or Set, the root node
Usage:
$PATH -set a path to node: set the current root at \'a path to node\'
$PATH -clear             : set the root to real root (alias to -set without parameters)
$PATH -display           : display the current root (if any)
$PATH a path to command -with options
                         : execute command from real root, options would be forwarded
                         : to the command.
'
                   ) if $o->{root_cmd};
    ($o->{root}, $o->{cmds}, $o->{root_path}) = ($o->{cmds}, $root, $path) if $root ;
}

=head2 add_exec

   $cli -> add_exec ( -path => 'full command path',
                      -exec => \&my_command,
                      -help => 'some help',
                      -opts => 'options',
                      -comp => \&my_completion_function,
                    ) ;

This function adds an command item to the command tree. It is a little complicated, but useful (or so I hope).

=over

=item * -path

B<Mandatory. Expecting a string.>
This string would be parsed as multi-words command.

Note: by default, this module expects whitespaces delimiter. If you'll read the module's code, you can find
an easy way to change it - in unlikely case you'll find it useful.

=item * -exec

B<Mandatory. Expecting a function ref.>
This code would be called when the user types a unique path for this command (with optional
options and arguments). Parameters sent to this code are:

   my ($cli, %p) = @_ ;
   #  where:
   # $cli     - self object.
   # $p{ARG0} - the command's full path (user might have used partial but unique path. This is the explicit path)
   # $p{ARGV} - all user arguments, in order (ARRAY ref)
   # %p       - contains other options (see 'opts' below)

=item * -help

B<Expecting a multi line string.>
The top line would be presented when a one line title is needed (for example, when 'help -tree'
is called), the whole string would be presented as the full help for this item.

=item * -comp

B<Expecting CODE, or ARRAY ref, or HASH ref.>
If Array, when the user hits tab completion for this command, try to complete his input with words
from this list.
If Hash, using the hash keys as array, following the rule above.
If Code, call this function with the next parameters:

   my ($cli, $word, $line, $start) = @_ ;
   #  where:
   # $cli is the Term::Shell::MultiCmd object.
   # $word is the curent word
   # $line is the whole line
   # $start is the current location

This code should return a list of strings. Term::ReadLine would complete user's line to the longest
common part, and display the list (unless unique). In other words - it would do what you expect.

For more information, see Term::ReadLine.

=item * -opts

B<Expecting a string, or ARRAY ref.>
If a string, split it to words by whitespaces. Those words are parsed as
standard Getopt::Long options. For example:

     -opts => 'force name=s flag=i@'

This would populating the previously described %p hash, correspond to user command:

     shell> user command -name="Some String" -flag 2 -flag 3 -flag 4 -force


For more information, see Getopt::Long. Also see examples/multi_option.pl in distribution.

As ARRAY ref, caller can also add a complete 'instruction' after each non-flag option (i.e. an option that
expects parameters). Like the 'comp' above, this 'instruction' must be an ARRAY or CODE ref, and follow
the same roles. When omitted, a default function would be called and ask the user for input.
For example:

    -opts => [ 'verbose' =>
               'file=s'  => \&my_filename_completion,
               'level=i' => [qw/1 2 3 4/],
               'type=s'  => \%my_hash_of_types,
             ],

=back

=cut

sub add_exec {
    my $o = shift ;
    my %p = _params 'path exec help= comp= opts=', @_ ;
    return unless $p{path};     # let user's empty string prevent this command
    my $r = $o ->{cmds} ;
    my $p = '' ;
    die "command must be CODE refferance\n" unless 'CODE' eq ref $p{exec} ;
    my @w = _split $o, $p{path} ;
    my $new = pop @w or return ;
    for my $w (@w) {
        $p .= _join $o, $p, $w ;
        if ('ARRAY' eq ref $r ->{$w} ) {
            carp "Overwrite command '$p'\n" ;
            delete $r -> {$w} ;
        }
        $r = ($r->{$w} ||= {}) ;
    }
    my ($opts, %opts) = '' ;    # now calculate options
    if ($p{opts}) {
        my @opts = ref $p{opts} ? @{$p{opts}} : split ' ', $p{opts} ;
        # croak "options -opts must be ARRAY ref\n" unless 'ARRAY' eq ref $p{opts} ;
        while (@opts) {
            my $op = shift @opts ;
            croak "unexpected option completion\n" if ref $op ;
            $opts .= "$op " ;
            my $expecting = $op =~ s/[\=\:].*$// ;
            $opts{$op} = ( $expecting  ?
                           ref $opts[0] ?
                           shift @opts :
                           \&_expect_param_comp :
                           '' ) ;
        }
    }
    #                   0    1    2       3      4..
    $r->{$new} = [@p{qw/help exec comp/}, $opts, %opts]
}


=head2 add_help

Although help string can set in add_exec, this command is useful when he wishes to
add title (or hint) to a part of the command path. For example:

   # assume $cli with commands 'feature set', 'feature get', etc.
   $cli -> add_help ( -path => 'feature' ,
                      -help => 'This feature is about something') ;

=cut

sub add_help {
    my $o = shift ;
    my %p = _params "path help", @_ ;
    my ($cmd, $path, @args, $ret) = _travel $o, $p{path} ; # _split $o, $p{path} ;
    if ('HASH' eq ref $cmd) {
        for my $w (@args) {
            $cmd = ($cmd->{$w} = {});
        }
        ($ret, $cmd->{$dlm}) = ($cmd->{$dlm}, $p{help})
    }
    else {
        croak "command '$p{path}' does not exists.\n For sanity reasons, will not add help to non-existing commands\n" if @args;
        ($ret, $cmd->[0 ]) = ($cmd->[0 ], $p{help})
    }
    $ret # Was it worth the trouble?
}

=head2 populate

A convenient way to define a chain of add_exec and add_help commands. This function expects hash, where
the key is the command path and the value might be HASH ref (calling add_exec), or a string (calling add_help).
For example:

    $cli -> populate
       ( 'feature' => 'This feature is a secret',
         'feature set' => { help => 'help for feature set',
                            exec => \&my_feature_set,
                            opts => 'level=i',
                            comp => \&my_feature_set_completion_function,
                          },
         'feature get' => { help => 'help for feature get',
                            exec => \&my_feature_get
                          },
       ) ;

    # Note:
    # - Since the key is the path, '-path' is omitted from parameters.
    # - This function returns the self object, for easy chaining (as the synopsis demonstrates).

=cut

sub populate {
    my ($o, %p) = @_ ;
    while (my ($k, $v) = each %p) {
        if (not ref $v) {
            $o->add_help(-path => $k, -help => $v) ;
        }
        elsif ('HASH' eq ref $v) {
            $o->add_exec(-path => $k, %$v)
        }
        else {
            croak "unknow item for '$k': $v\n" ;
        }
    }
    $o
}

sub _last_setting_load($) {
    my $o = shift ;
    my $f = $o->{history_file} or return ;
    return unless -f $f ;
    my $d = $o->{history_more} ;
    eval {
        my $setting = eval { use Storable ; retrieve $f } ;
        return print "Failed to load configuration from $f: $@\n" if $@ ;
        my ($hist, $more) = @$setting ;
        $o->{history_data} = $hist if 'ARRAY' eq ref $hist and @$hist ;
        return unless ref $d and ref $more and ref($d) eq ref($more) ;
        %$d = %$more if 'HASH'   eq ref $d ;
        @$d = @$more if 'ARRAY'  eq ref $d ;
        $$d = $$more if 'SCALAR' eq ref $d ;
    } ;
}

sub _last_history_flash_load($) {
    my $o = shift ;
    my $f = $o->{history_flash_file} or return ;
    return unless -f $f ;
    my $max = $o->{history_size};
    eval {
        open F, '<', $f or return;
        my @A = <F>;
        splice @A, 0, @A-$max if @A > $max;
        chomp @A;
        push @{$o->{history_data}}, @A;
        close F;
    }
}

sub _last_setting_save($) {
    my $o = shift ;
    my $f = $o->{history_file} or return ;
    my @his ;
    unless ($o->{history_flash_file}) {
        @his = $o -> history();
        splice @his, 0,  @his - $o->{history_size} ;
    }
    print
      eval {use Storable ; store ([[@his], $o->{history_more}], $f)} ? # Note: For backward compatibly, this array can only grow
        "Configuration saved in $f\n" :
          "Failed to save configuration in $f: $@\n" ;
}

=head2 loop

  $cli -> loop ;

Prompt, parse, and invoke in an endless loop

('endless loop' should never be taken literally. Users quit, systems crash, universes collapse -
 and the loop reaches its last cycle)

=cut

sub loop {
    local $| = 1 ;
    my $o = shift ;

    $o-> {term} ||= _new_readline $o ;
    $o-> history($o->{history_data}) if $o->{history_data};
    while ( not $o -> {stop} and
            defined (my $line = $o->{term}->readline($o->prompt)) ) {
        $o->cmd( $line ) ;
    }
    _last_setting_save $o ;
}

sub _complete_gnu {
    my($o, $text, $line, $start, $end) = @_;
    $text, &_complete_cli       # apparently, this should work
}

sub _complete_cli {
    my($o, $word, $line, $start) = @_;
    #   1. complete command
    #   2. if current word starts with '-', complete option
    #   3. if previous word starts with '-', try arg completion
    #   4. try cmd completion (should it overwrite 3 for default _expect_param_comp?)
    #   5. show help, keep the line

    # my @w = _split $o ,        # should I ignore the rest of the line?
    #   substr $line, 0, $start ; # well, Term::ReadLine expects words list.

    my ($cmd, $path, @args) = _travel $o, substr $line, 0, $start ; # @w ;
    return ($cmd, $word) unless ref $cmd ;
    return (@args ? "\a" : _filter $word, $cmd) if 'HASH' eq ref $cmd ;

    my ($help, $exec, $comp, $opts, %opts) = @{ $cmd } ; # avoid confusion
    return &_root_command_comp if $comp and $comp == \&_root_command_comp ; # very special case: root 'imports' its options.
    return map {"$1$_"} _filter $2,\%opts if $word =~ /^(\-\-?)(.*)/ ;
    if ( @args and $args[-1] =~ /^\-\-?(.*)/) {
        my ($op, @op) = _filter $1, \%opts ;
        return ("Option $args[-1] is ambiguous: $op @op?", $word) if @op ;
        return ("Option $args[-1] is unknown", $word) unless $op ;
        my $cb = $opts{$op} ;
        return _filter $word, $cb if 'ARRAY' eq ref $cb or 'HASH' eq ref $cb ;
        return $cb->($o, $word, $line, $start, $op, $opts =~ /$op(\S*)/ ) if 'CODE' eq ref $cb ;
    }
    return _filter $word, $comp if 'ARRAY' eq ref $comp or 'HASH' eq ref $comp ;
    return $comp->($o, $word, $line, $start) if 'CODE' eq ref $comp ;
    return ($help, $word)       # so be it
}

sub _help_message_tree {        # inspired by Unix 'tree' command
                                # Should I add ANSI colors?
    my ($h, $cmd, $pre, $last) = @_ ;
    print $pre . ($last ? '`' : '|') if $pre ;
    return _say "- $cmd : ", $h->[0] =~ /^(.*)/m if 'ARRAY' eq ref $h ;
    _say "-- $cmd" ;
    my @c = sort keys %$h ;
    for my $c (grep {defined} @c) {
        _help_message_tree( $h->{$c},
                            $c,
                            $pre ? $pre . ($last ? '    ' : '|   ') : ' ' ,
                            $c eq ($c[-1]||'')
                          ) unless $c eq $dlm ;
    }
}

sub _help_message {
    my $o = shift ;
    my %p = _params "node path full= recursive= tree= ARGV= ARG0=", @_ ;
    my ($h, $p) = @p{'node', 'path'} ;
    $p =~ s/^\s*(.*?)\s*$/$1/ ;
    sub _align2($$) {
        my ($a, $b) = @_;
        _say $a, (' ' x (20 - length $a)), ': ', $b
    }

    if ('ARRAY' eq ref $h) {    # simple command, full help
        my $help = $h->[0] ;
        $help =~ s/\$PATH/$p{path}/g ;
        _say "$p:\n $help" ;
        $help
    }
    elsif ('HASH' ne ref $h) {  # this one shouldn't happen
        confess "bad item in help message: $h"
    }
    elsif ($p{recursive}) {     # show everything
        my $xxx = "----------------------\n" ;
        _say $xxx, $p, ":\t", $h->{$dlm} if exists $h->{$dlm};

        for my $k (sort keys %$h) {
            next if $k eq $dlm ;
            _say $xxx ;
            _help_message( $o, %p, -node => $h->{$k}, -path => _join $o, $p, $k) ;
        }
    }
    elsif ($p{tree}) {          # tree - one linear for each one
        _help_message_tree ($h, $p)
    }
    elsif ($p{full}) {          # prefix, full list

        _say "$p:\t", $h->{$dlm} if exists $h->{$dlm} ;

        for my $k (sort keys %$h) {
            next if $k eq $dlm ;
            my ($l) = (('ARRAY' eq ref $h->{$k}) ?
                       ($h->{$k}[0]    || 'a command') :
                       ($h->{$k}{$dlm} || 'a prefix' ) ) =~ /^(.*)$/m ;
            _align2 _join($o, $p, $k), $l;
        }
    }
    else {                      # just show the prefix with optional help
        _say "$p: \t", $h->{$dlm} || 'A command prefix' ;
    }
}

sub _help_command {
    my ($o, %p) = @_ ;
    my ($cmd, $path, @args) = _travela $o, @{$p{ARGV}} ;
    return _say $cmd unless ref $cmd ;
    return _say "No such command or prefix: " . _join $o, $path, @args if @args ;
    return _help_message($o, -node => $cmd, -path => $path, -full => 1, %p) ;
}

sub _help_command_comp {
    my($o, $word, $line, $start) = @_;
    my @w = _split $o , substr $line, 0, $start ;
    shift @w ;
    my ($cmd, $path, @args) = _travela $o, grep {!/\-\-?r(?:ecursive)?|\-\-?t(?:ree)?/} @w ;
                             # potential issue: 'help -r some path' wouldn't be a valid path, is DWIM the solution?
    return ($cmd, $word) unless ref $cmd ;
    return _filter $word, $cmd if 'HASH' eq ref $cmd ;
    ('', $word)
}

sub _quit_command { $_[0]->{stop} = 1 }

sub _root_command_comp {
    my($o, $word, $line, $start) = @_;
    $line =~ s/^(\s*\S+\s*(?:(\-\-?)(\w*))?)// ; # todo: delimiterRE
    my ($prolog, $par, $param) = ($1, $2, $3) ;
    return unless $prolog ;     # error, avoid recursion
    return map {"$par$_"} _filter $param, qw/clear set display/ if $par and not $line ;
    $line =~ s/^(\s*)// ;
    $prolog .= $1 ;
    my $root = delete $o -> {root} ;
    my @res = _complete_cli($o, $word, $line, $start - length $prolog) ;
    $o->{root} = $root if $root ;
    @res
}

sub _root_command {
    # root -display   : display current path
    # root -set  path : set path
    # root -clear     : alias to root -set  (without a path)
    # root path params: execute path <params> from real command root

    my ($o, %p) = @_ ;
    my @argv = @{$p{ARGV}} ;
    @argv  or return $o->cmd("help $p{ARG0}") ;
    # algo: can't parse those options automaticaly, as it would prevent user's options to optional root commnad
    $argv[0] =~ /^\-\-?d/ and return _say $o->{root} ? "root is set to '$o->{root_path}'" : "root is clear." ;
    $argv[0] =~ /^\-\-?c/ and @argv = ('-set') ;
    $argv[0] =~ /^\-\-?s/ or do {
        # just do it, do it!
        my $root = delete $o->{root} ;
        my @res = $o->cmd(_join $o, @argv) ;
        $o->{root} = $root if $root ;
        return @res ;
    } ;
    shift @argv ; # -set, it is
    my ($cmd, $path, @args) ;
    if (@argv) {
        my $root = delete $o->{root} ;
        ($cmd, $path, @args) = _travela $o, @argv ;
        $o->{root} = $root if $root ;
        return _say $cmd unless ref $cmd ;
        return _say "No such prefix: " . _join $o, $path, @args if @args ;
        return _say "$path: is a command. Only a node can be set as root." if 'ARRAY' eq ref $cmd ;
    }
    if ( $o->{root}) {
        _say "clear root '$o->{root_path}'" ;
        _root_cmds_clr $o ;
    }
    if ( $cmd ) {
        _root_cmds_set $o, $cmd, $path ;
        _say "set new root: '$path'" ;
    }
}

sub _check_sh_pipe {
    my ($o, $c) = @_ ;
    my $r = qr/(\|.*)$/;
    if ($c =~ s/$r//) {
        my $cmd = $1;
        $o->{piper} = 'c';
        $o->{shcmd} = sub { use FileHandle ; new FileHandle $cmd };
    }
    ($o, $c)
}

sub _check_pager {
    my ($o, $c) = @_ ;
    my $p = $o->{pager} or return (@_, $o->{piper}=undef); # just in case programmer delete {pager} during run
    my $r = $o->{pager_re};
    if ($r and not ref $r) {    # once
        my $d = "$r($o->{delimiterRE})*" ;
        $r =  $o->{pager_re} = qr/$d/;
    }
    if (!$r or
        $r && $c =~ s/$r//) {
        $o->{piper} = 'p';
        $o->{pager} = sub { use FileHandle ; new FileHandle "| $p" } unless ref $o->{pager};
    }
    ($o, $c)
}

sub _check_silent_aliases {
    my ($o, $cmd) = @_ ;
    return  $cmd unless $cmd;
    my $r = $o->{root} || $o->{cmds};
    my ($c, @a) = _split $o, $cmd || '';
    $c ||= '';

    return _join $o, $o->{root_cmd}, (@a ? (-set => @a ) : ('-clear'))
      if ( $c eq 'cd' and
           $o->{root_cmd} and
           not exists $r->{cd});

    return _join $o, $o->{help_cmd}, @a
      if $o->{help_cmd} and
        ( ($c eq 'ls'   and not exists $r->{ls}  ) or
          ($c eq 'help' and not exists $r->{help}) );

    $cmd
}

=head2 cmd

 $cli -> cmd ( "help -tree" ) ;

Execute the given string parameter, similarly to user input. This one might be useful to execute
commands in a script, or testing.

=cut

sub cmd {
    my ($o, $clt) = @_;
    $o->{record_cmd}->($clt) if 'CODE' eq ref $o->{record_cmd};

    if ($o->{history_flash_file}) {
        unless (_log_command($o->{history_flash_file}, $clt)) {
            print STDERR "Can't write to $o->{history_flash_file}: $!\n";
            $o->{history_flash_file} = undef;
        }
    }

    my ($cmd, $path, @args) = _travel $o, $clt or return ;
    local %SIG ;

    my $fh;
    $fh = $o->{pager}->() if 'p' eq ($o->{piper}||'');
    $fh = $o->{shcmd}->() if 'c' eq ($o->{piper}||'') and not $fh;
    if ($fh) {
        $o->{stdout} = select ;
        select $fh ;
        $SIG{PIPE} = sub {} ;
    }

    my $res = $o->_cmd ($cmd, $path, @args) ;

    if ($fh) {
        select $o->{stdout} ;
        $o->{piper} = $o->{shcmd} = undef;
    }
    $res
}

sub _cmd {
    my ($o, $cmd, $path, @args) = @_ ;
    return print $cmd unless ref $cmd ;
    return $o->{empty_cmd}->() if $o->{empty_cmd} and $cmd eq ($o -> {root} || $o->{cmds}) and 0 == length join '', @args;
    return _say "No such command or prefix: " . _join $o, @args if $cmd eq $o->{cmds} ;
    $cmd = $cmd->{$o->{query_cmd}} if 'HASH' eq ref $cmd and length($o->{query_cmd}) and exists $cmd->{$o->{query_cmd}};
    return _help_message($o, -node => $cmd, -path => $path) unless 'ARRAY' eq ref $cmd ; # help message
    my %p = _options $cmd->[3] || '', @args ;
    return print $p{_ERR_} if $p{_ERR_} ;
    return $cmd->[1]->($o, ARG0 => $path, %p) ;
}

my $_log_command_last = '';
sub _log_command {
    my ($file, $cmd) = @_;
    return unless defined $file and defined $cmd;
    $cmd =~ s/\n*$/\n/s;
    if ($_log_command_last ne $cmd) {
        $_log_command_last =  $cmd;
        open  F, '>>', $file or return undef;
        print F $cmd;
        close F;
    }
    1
}


=head2 command

 $cli -> command ( "help -tree") ;
Is the same as cmd, but echos the command before execution

=cut

sub command {
    my ($o, $cmd) = @_ ;
    print "$cmd ..\n" ;
    &cmd
}

=head2 complete

  my ($base_line, @word_list) = $cli -> complete ($a_line) ;

given a line, this function would return a base line (i.e. truncated to the beginning of the last word), and a list of potential
completions. Added to the 'cmd' command, this might be useful when module user implements his own 'loop' command in a non-terminal
application

=cut

sub complete {
    # line, pos ==> line, list of words
    my ($o, $line, $pos) = @_ ;
    my $lo = substr $line, $pos, -1, '' if defined $pos ;
    my $lu = $line ;
    my $qd = $o -> {delimiterRE} ;
    $lu =~ s/([^$qd]*)$// ;
    my $w = $1 ||  '' ;
    my (@list) = _complete_cli($o, $w, $line, $pos || length $lu) ;
    # if ($lu =~ /^(.*)($qd+)$/) {
    #     # this is duplicating what is done in _complete_cli, TODO: optimize
    #     my ($l, $s) = ($1, $2 ) ;
    #     my ($cmd, $path, @args) = _travel $o, $l ;
    #     $lu = "$path$s" if $path and not @args ;
    # }
    ($lu, @list)
}

=head2 prompt

  my $prompt = $cli -> prompt() ;

accepts no parameters, return current prompt.

=cut


sub prompt() {
    my $o = shift ;
    my $p = $o->{prompt} || 'shell' ;
    return $p->()  if 'CODE' eq ref $p ;
    return $p      if $p =~ /\W$/ ;
    $p .= ':' . $o->{root_path} if $o->{root_path} ;
    $p .  '> '
}

=head2 history

set/get history 

  my @hist = $cli -> history() ;            # get history
  $cli -> history( @alternative_history ) ; # set history
  $cli -> history([@alternative_history]) ; # the very same, by ptr
  $cli -> history([]) ;                     # clear history

=cut

sub history {
    my $o = shift ;
    return unless $o->{term} ;
    return $o->{term}->SetHistory(map {('ARRAY' eq ref $_) ? (@$_) : ($_)} @_ ) if @_ ;
    return $o->{term}->GetHistory
}


# =head2 pager

#     my $old_pager = $o->pager($new_pager);  # set new pager
#     my $old_pager = $o->pager('') ;         # clear pager
#     my $cur_pager = $o->pager() ;           # keep current pager

# =cut

# sub pager {
#     my ($o, $new) = @_ ;
#     my $old = $o->{pager} ;
#     $o->{pager} = $new if defined $new ;
#     $old
# }

=head1 ALSO SEE

Term::ReadLine, Term::ReadKey, Getopt::Long

=head1 AUTHOR

Josef Ezra, C<< <jezra at sign cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to me, or to C<bug-term-cli at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Term-CLI>.
I am grateful for your feedback.

=head2 TODO list

nImplement pager.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Term::Shell::MultiCmd

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Term-CLI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Term-CLI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Term-CLI>

=item * Search CPAN

L<http://search.cpan.org/dist/Term-CLI/>

=back


=head1 ACKNOWLEDGMENTS

This module was inspired by the excellent modules Term::Shell, CPAN, and CPANPLUS::Shell.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Josef Ezra.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

'end'

