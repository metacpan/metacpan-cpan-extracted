package VCP::Filter::map;

=head1 NAME

VCP::Filter::map - rewrite name, branch_id or delete revisions

=head1 SYNOPSIS

  ## From the command line:
   vcp <source> map: p1 r1   p2 r2 -- <dest>

  ## In a .vcp file:

    Map:
            name_glob_1<branch_1> name_out_1<branch_result_1>
            name_glob_2<branch_2> name_out_2<branch_result_2>
            # ... etc ...

=head1 DESCRIPTION

Maps source files, revisions, and branches to destination files and
branches while copying a repository.  This is done by rewriting the
C<name> and C<branch_id> of revisions according to a list of rules.

=head2 Rules

A rule is a pair of expressions specifying a pattern to match against
the each incoming revision's name and branch_id and a result to use to
replace the revision's name and branch_id.

The list of rules is evaluated top down; the first rule in the list that
matches is used to generate the new name and branch_id.  There is a
default rule that applies to all files and copies them.

Note that sorting is performed in the destination, so the map will
affect the sort order and the original file name and branch_id are lost.

=head2 Patterns and Rule Expressions

Patterns and rules are composed of two subexpressions, the
C<name_expr> and the C<branch_id_expr> like so:

    name_expr<branch_id_expr>

The C<< <branch_id_expr> >> (including angle brackets) is optional and may
be forbidden by some sources or destinations that embed the concept of a
branch in the name_expr.  (See L<VCP::Dest::p4|VCP::Dest::p4> for an
example, though this may be changed in the future).

For now, the symbols C<#> and C<@> are reserved for future used in all
expressions and must be escaped using C<\>, and various shell-like
wildcards are implemented in pattern expressions.

=head2 Pattern Expressions

Both the C<name_expr> and C<branch_id_expr> specify patterns using shell
regular expression syntax with the extension that parenthesese are used
to extract portions of the match in to numbered variables which may be
used in the result construction, like Perl regular expressions:

   ?      Matches one character other than "/"
   *      Matches zero or more characters other than "/"
   ...    Matches zero or more characters, including "/"
   (foo)  Matches "foo" and stores it in the $1, $2, etc

Some example pattern C<name_expr>s are:

   Pattern
   name_expr  Matches
   =========  =======
   foo        the top level file "foo"
   foo/bar    the file "foo/bar"
   ...        all files (like a missing name_expr)
   foo/...    all files under "foo/"
   .../bar    all files named "bar" anywhere
   */bar      all files named "bar" one dir down
   ....pm     all files ending in ".pm"
   ?.pm       all top level 4 char files ending in ".pm"
   \?.pm      the top level file "?.pm"
   (*)/...    all files in subdirs, puts the top level dirname in $1

Unix-style slashes are used, even on operating systems where that may
not be the preferred local custom.  A pattern consisting of the empty
string is legal and matches everything (NOTE: currently there is no way
to take advantage of this; quoting is not implemented in the forms
parser yet.  use "..." instead).

Relative paths are taken relative to the rev_root indicated in the
source specification for pattern C<name_expr>s (or in the destination
specification for result C<name_expr>s).  For now, a relative path is a
path that does not begin with the character C</>, so be aware that the
pattern C<(/)> is relative.  This is a limitation of the implementation
and may change, until it does, don't rely on a leading "(" making a path
relative and use multiple rules to match multiple absolute paths.

If no C<name_expr> is provided, C<...> is assumed and the pattern will
match on all filenames.

Some example pattern C<branch_id_expr>s are:

    Pattern
    branch_id_expr  Matches files on
    ===========  ================
    <>           no branch label
    <...>        all branches (like a missing <branch_id_expr>)
    <foo>        branch "foo"
    <R...>       branches beginning with "R"
    <R(...)>     branches beginning with "R", the other chars in $1

If no C<branch_id_expr> is provided, files on all branches are matched.
C<*> and C<...> still match differently in pattern C<branch_id_expr>s, as
in <name_expr> patterns, but this is likely to make no difference, as
I've not yet seen a branch label with a "/" in it.  Still, it is wise
to avoid "*" in C<branch_id_expr> patterns.

Some example composite patterns are (any $ variables set
are given in parenthesis):

    Pattern            Matches
    =======            =======
    foo<>              top level files named "foo" not on a branch
    (...)<>            all files not on a branch ($1)
    (...)/(...)<>      all files not on a branch ($1,$2)
    ...<R1>            all files on branch "R1"
    .../foo<R...>      all files "foo" on branches beginning with "R"
    (...)/foo<R(...)>  all files "foo" on branches beginning with "R" ($1, $2)

=head2 Escaping

Null characters and newlines are forbidden in all expressions.

The characters C<#>, C<@>, C<[>, C<]>, C<{>, C<}>, C<E<gt>>, C<E<lt>>
and C<$> must be escaped using a C<\>, as must any wildcard characters
meant to be taken literally.

In result expressions, the wildcard characters C<*>, C<?>, the wildcard
trigraph C<...> and parentheses must each be escaped with single C<\> as
well.

No other characters are to be escaped.

=head2 Case sensitivity

By default, all patterns are case sensitive.  There is no way to
override this at present; one will be added.

=head2 Result Expressions

Result expressions look a lot like patthern expressions except that
wildcards are not allowed and C<$1> and C<${1}> style variable
interpolation is.

To explore result expressions, let's look at converting set of example
files between cvs and p4 repositories.  The difficulty here is that cvs
and p4 have differing branching implementations.

Let's assume our CVS repository has a module named C<flibble> with a
file named C<foo/bar> in it.  Here is a branch diagram, with the main
development trunk shown down the left (C<1.1> through C<1.6>, etc) and a
single branch, tagged in CVS with a branch tag of C<beta_1>, is shown
forking off version C<1.5>:

     flibble/foo/bar:

         1.1
          |
         ...
          |
         1.5
          | \
          |  \ beta_1
          |   \
         1.6   \
          |    1.5.2.1
         ...    |
                |
               1.5.2.2
                |
               ...

    NOTE 1: You can use C<vcp> to extract graphical branch diagrams by
    installing AT&T's GraphViz package and the Perl CPAN module
    GraphViz.pm.  Then you can use a command like:

        $ vcp cvs:/var/cvsroot:flibble/foo/bar \
            branch_diagram:foo_bar.png

    to generate a .png file showing something like the above diagram.

On the other hand, p4 users typically branch files using directory
names.  Here's file C<foo/bar> again, with the main trunk held in the main
depot's //depot/main directory, again with a branch after the 5th
version of the file, but this time, the branch is represented by taking
a copy 

    //depot/main/foo/bar

         #1
          |
         ...
          |
         #5
          |\
          | \ //depot/beta_1/foo/bar
          |  \
         #6   \
          |   #1
         ...   |
               |
              #2
               |
              ...
          
    NOTE 2: the p4 command allows users to branch in very crafty and
    creative ways; it does not enforce the semantic of 1 branch per
    directory, and this gives p4 users a lot of power and flexibility.
    It also means that you might need some pretty crafty and creative
    branch maps when converting from p4 to other repositories.

    NOTE 3: that branch looks like a copy, but is actually just a
    metadata entry in the perforce repository, so it's very low
    overhead in terms of server effort and disk space, usually
    even more so than CVS branches.

    NOTE 4: Using GraphViz (as described in NOTE 1 above), you can
    build a diagram like this using vcp:

        $ vcp p4:perforce.our.com:1666://depot/flibble/foo/bar \
            branch_diagram:foo_bar.png

A user may or may not choose to label a branch in p4 with something
called a "branch specification" (see "p4 help branch" for details).  For
this discussion, we'll assume they didn't.

First, let's look at cvs -> p4 conversion.  To do this, we need to
match the branch tags in the CVS repository and use them to map branched
files in to a p4 subdirectory.  Here's .vcp file for this:

   ## cvs2p4.vcp

   Source:
   # get all files in the flibble module from cvs
       cvs:/var/cvsroot:flibble/...

   Destination:
   # Put the files in the flibble directory in the main depot of p4
       p4:perforce.our.com:1666://depot/flibble/...

   Map:
   #   Pattern       Result
   #   ============  =======
       (...)<>       main/$1   # main trunk => //depot/flibble/main/...
       (...)<(...)>  $2/$1     # branches   => //depot/flibble/$branch/...

The C<Source:> and C<Destination:> fields are just pieces of a normal
C<vcp> command line moved in to C<cvs2p4.vcp>.  The C<Map:> field is a
list of rules composed of pattern, result expression pairs.

In this example, all of the map expressions are relative paths.  The
patterns are relative to the C<Source:> cvs repositories' "C<flibble>"
module.  The results are relative to the C<Destination:> p4
repositories' "C<//depot/flibble/>" directory.

The first rule maps all files that have no branch tag in to the p4
directory C<//depot/flibble/main/>.  The C< (...)<> > pattern has two
parts: a C<name> part and a C<branch_id> part.  The C<name> part,
C<(...)>, matches all path names and copies them to the C<$1> variable.
The C<branch_id> part, C< <> >, matches empty / missing C<branch_id>s
(C<vcp>'s name for the CVS branch tag associated with a file on a
branch).  The C< main/$1 > result retrieves the C<name> part stored in
C<$1> and prefixes it with "C<main/>" to build the final C<name> value.

The second rule maps all files on branches to an appropriately named
subdirectory in the p4 destination.  The pattern is a lot like the first
rule's, but has a C<branch_id> part that matches all C<branch_id>s and
copies them in to C<$2>.  The rule merely uses this C<branch_id> from
C<$2> instead of the hardcoded "C<main/>" string to place the branches
in appropriate subdirectories.

Here's how our flibble/foo/bar file version fare when passed through
this mapping:

    CVS flibble/...              p4 //depot/flibble/...
    ========================     ======================

    foo/bar#1.1                  main/foo/bar#1
    foo/bar#1.2                  main/foo/bar#2
    ...                          ...
    foo/bar#1.5.2.1              beta_1/foo/bar#1
    foo/bar#1.5.2.2              beta_1/foo/bar#2
    ...                          ...

It's up to you to be sure there are no branches tagged "C<main>" in the
CVS repository.  Also, no branch specification will be created in the
target p4 repository (this is a limitation that should be fixed).

=head2 Result Actions: <delete>> and <<keep>>

The result expression C<< <<delete>> >> indicates to delete the revision,
while the result expression "<<keep>>" indicates to pass it through
unchanged:

    Map:
    #   Pattern            Result
    #   =================  ==========
        old_stuff/...      <<delete>>  # Delete all files in /old
        old_stuff/.../*.c  <<keep>>    # except these

C< <<delete>> > and C< <<keep>> > may not appear in results; they are
standalone tokens.

=head2 The default rule

There is a default rule

    ...  <<keep>>  ## Default rule: passes everything through as-is

that is evaluated after all the other rules.  Thus, if no other rule
matches a revision, it is passed through unchanged.

=head2 Command Line Parsing

For large maps or repeated use, the map is best specified in a .vcp
file.  For quick one-offs or scripted situations, however, the map:
scheme may be used on the command line.  In this case, each parameter
is a "word" and every pair of words is a ( pattern, result ) pair.

Because L<vcp|vcp> command line parsing is performed incrementally and
the next filter or destination specifications can look exactly like
a pattern or result, the special token "--" is used to terminate the
list of patterns if map: is from on the command line.  This may also
be the last word in the C<Map:> section of a .vcp file, but that is
superfluous.  It is an error to use "--" before the last word in a .vcp
file.

=for test_script t/61map.t

=cut

$VERSION = 1 ;

use strict ;
use VCP::Logger qw( lg );
use VCP::Debug qw( :debug );
use VCP::Utils qw( shell_quote );
use VCP::Filter;
use Regexp::Shellish qw( compile_shellish );
use base qw( VCP::Filter );

use fields (
   'MAP_SUB',   ## The rules to apply, compiled in to an anon sub
);

my @expr_order = qw( name branch_id );

sub _parse_expr {
   my ( $type, $v ) = @_;

   my %exprs;

   return () unless defined $v;

   if ( $type eq "result" ) {
      return ( delete      => 1, %exprs ) if $v eq "<<delete>>";
      return ( keep        => 1, %exprs ) if $v eq "<<keep>>";
   }

   @exprs{@expr_order} = 
      $v =~ m{
         \A
         (?:(
            (?: \\. | [^<\\] )+ ## name
         ))?
         (?:
            <(
              .*                                        ## branch_id
            )>
         )?
         \z
      }x;
   die "unable to parse map $type '$v'\n"
      unless grep defined, values %exprs;

   for ( @expr_order ) {
      next unless defined $exprs{$_};

      die "newline in the $_ expression '$exprs{$_}' of map $type '$v'\n"
         if $exprs{$_} =~ tr/\n//;

      die "unescaped '$1' in the $_ expression '$exprs{$_}' of map $type '$v'\n"
         if $exprs{$_} =~ 
            ( $type eq "pattern"
                ? qr{(?<!\\)(?:\\\\)*([\@#<>\[\]{}\$])}
                : qr{(?<!\\)(?:\\\\)*([\@#<>\[\]*?()]|\.\.\.)|(?<!\$)\{}
            );

      die "illegal escape sequence '$1' in the $_ expression '$exprs{$_}' of map $type '$v'\n"
         if $exprs{$_} =~ qr{(?<!\\)(?:\\\\)*(\\(?!=\.\.\.)[^\@#<>\[\]{}*?()])};
   }

   return %exprs;
}


sub _compile_rule {
   my $self = shift;
   my ( $name, $pattern, $result ) = @_;

   my %pattern_exprs = _parse_expr pattern => $pattern;
   my %result_exprs  = _parse_expr result  => $result;

   ## The test expression is a single regexp that matches a string
   ## built up from some pieces of the rev metadata.  Right now, only
   ## the name and the branch_id are tested, by someday the labels,
   ## change_id, rev_id, and comment could be tested.  If so, the
   ## comment field would need to come last due to newline issues.

   my $test_expr = 
      ! keys %pattern_exprs
         ? 1  ## This happens iff the pattern was undef (which
              ## should only happen for the default rule).
         : join(
            "",
            "m'\\A",   ## Note the single-quotish context
            join(
               "\\n",  ## Newlines are forbidden in all expressions.
               map defined $_
                  ? do {
                     my $re = compile_shellish( $_, { anchors => 0 } );
                     $re =~ s{(')}{\\`}g;
                     $re =~ s{\A\(\?[\w-]*: (.*) \)}{$1}gx; # for readability 
                                                            # of dumped code
                     $re;
                  }
                  : ".*",
               @pattern_exprs{@expr_order}
            ),
            "\\z'",
         );

   $pattern = defined $pattern ? qq{"$pattern"} : "match all";

   my $result_statement = join(
      "",
      debugging()
         ?  qq{lg( '    matched $name ($pattern)' );\n}
         : (),
      $result_exprs{keep}
         ? (
            debugging()
               ?  qq{lg( "    <<keep>>ing" );\n}
               : (),
            "return \$self->dest->handle_rev( \$rev );\n"
         )
      : $result_exprs{delete}
         ? (
            debugging()
               ?  qq{lg( "   <<delete>>ing" );\n}
               : (),
            "return; ## Deleted!\n"
         )
         : (
            map(
               defined $result_exprs{$_}
                  ? do {
                     my $expr = $result_exprs{$_};
                     $expr =~ s{([\\"])}{\\$1}g;
                     $expr =~ s{\n}{\\n}g;
                     (
                        debugging()
                           ?  qq{lg( "   rewriting $_ to '$expr'" );\n}
                           : (),
                        qq{\$rev->$_( "$expr" );\n}
                     )
                  }
                  : (
                        debugging()
                           ?  qq{lg( "   not rewriting $_" );\n}
                           : (),
                  ),
               @expr_order
            ),
            "return \$self->dest->handle_rev( \$rev );\n"
         )
   );

   $result_statement =~ s/^/   /gm;

   "if ( $test_expr ) {\n$result_statement}\n";
}

sub _compile_rules {
   my VCP::Filter::map $self = shift;
   my ( $rules ) = @_;

   my $field_get_exprs = join ", ", map qq{\$rev->$_ || ""}, @expr_order;

   ## NOTE: making this a closure causes spurious warnings at exit so
   ## we pass $self explicitly.
   my $preamble = <<END_PREAMBLE;
my ( \$self, \$rev ) = \@_;

local \$_ = join "\\n", $field_get_exprs;

END_PREAMBLE

   $preamble .= qq{my \$s = \$_; \$s =~ s/\\n/\\\\n/g; lg( "map testing '\$s' (", \$rev->as_string, ")" );\n\n}
      if debugging;

   my $rule_number;
   my $code = join "",
      $preamble,
      map $self->_compile_rule(  @$_ ),
         map( [ "Rule " . ++$rule_number, @$_               ], @$rules ),
              [ "Default Rule",           undef, "<<keep>>" ];

   $code =~ s/^/   /mg;
   $code = "#line 1 VCP::Filter::map::map_function\n$code";

   $code = "sub {\n$code}";
   debug "map code:\n$code" if debugging;

   return( eval $code
      or die "$@ compiling\n",
         do {
            my $w = length( $code =~ tr/\n// + 1 ) ;
            my $ln;
            1 while chomp $code;
            $code =~ s{^}[sprintf "%${w}d|",++$ln]gme;
            "$code\n";
         },
   );
}


sub new {
   my $class = shift ;
   $class = ref $class || $class ;

   my $self = $class->SUPER::new( @_ ) ;

   my ( $spec, $options ) = @_ ;

   $self->{MAP_SUB} = $self->_compile_rules(
      $self->parse_rules_list( $options, "Pattern", "Replacement" )
   );

   return $self ;
}


sub handle_rev {
   my VCP::Filter::map $self = shift;

   $self->{MAP_SUB}->( $self, @_ );
}

=head1 LIMITATIONS

There is no way (yet) of telling the mapper to continue processing the
rules list.  We could implement labels like C< <<I<label>>> > to be
allowed before pattern expressions (but not between pattern and result),
and we could then impelement C< <<goto I<label>>> >.  And a C< <<next>>
> could be used to fall through to the next label.  All of which is
wonderful, but I want to gain some real world experience with the
current system and find a use case for gotos and fallthroughs before I
implement them.  This comment is here to solicit feedback :).

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=head1 COPYRIGHT

Copyright (c) 2000, 2001, 2002 Perforce Software, Inc.
All rights reserved.

See L<VCP::License|VCP::License> (C<vcp help license>) for the terms of use.

=cut

1
