package Slay::MakerRule ;

#
# Copyright (c) 1999 by Barrie Slaymaker, rbs@telerama.com
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the README file.
#

=head1 NAME

Slay::MakerRule - a class for making things with dependencies

=head1 SYNOPSIS

   use strict ;

   use Slay::MakerRule ;

   $t1 = Slay::MakerRule->new( { rule => [
      \@target,         ## Filenames made by \@actions
      \@dependencies,   ## Files or Slay::MakerRule objects
      \@actions,        ## Command lines or sub{}
      ] }
   ) ;

Any or all of the three parameters may be scalars if there is only one
thing to pass:

   $t1 = Slay::MakerRule->new( { rule => [
      $target,
      $dependency,
      $action,
      ] }
   ) ;

New can also be called with separate hash elements for each part:

   $t1 = Slay::MakerRule->new( { 
      PATS => \@target,         ## Filenames made by \@actions
      DEPS => \@dependencies,   ## Files or Slay::MakerRule objects
      ACTS => \@actions,        ## Command lines or sub{}
      ] }
   ) ;

=head1 DESCRIPTION

=over

=cut

use strict ;

use Carp ;
use Fcntl qw( :DEFAULT :flock ) ;
use File::Basename ;
use File::Path ;
use IPC::Run qw( run ) ;

our $VERSION = 0.06;

use Class::Std;

{   # Creates the closure for the attributes

    # Attributes

    my %acts_of          : ATTR( :init_arg<ACTS> :default<[]> );
    my %cmd_of           : ATTR ;
    my %compiled_pats_of : ATTR ;
    my %deps_of          : ATTR( :init_arg<DEPS> :default<[]> );
    my %opts_of          : ATTR( :init_arg<OPTS> :default<{}> );
    my %pats_of          : ATTR( :init_arg<PATS> :default<[]> );
    my %in_make_of       : ATTR ;

sub START {
   my ($self, $ident, $args_ref) = @_;

   my $rule = $args_ref->{rule};
   my @rule = ref $rule eq 'ARRAY' ? @$rule : $rule if defined $rule;

   if (@rule) {
      ## It's qw( patterns, ':', dependencies, '=', actions ).
      ## NB: The ':' and '=' may appear as the last char of a scalar param.
      $acts_of{$ident} = [] unless $acts_of{$ident};
      $deps_of{$ident} = [] unless $deps_of{$ident};
      $opts_of{$ident} = {} unless $opts_of{$ident};
      $pats_of{$ident} = [] unless $pats_of{$ident};

      $opts_of{$ident} = pop @rule if ref $rule[-1] eq 'HASH' ;
      my $a = $pats_of{$ident} ;
      my $e ;
      my $na ;
      for ( @rule ) {
         $e = $_ ;
	 $na = undef ;
         unless ( ref $e ) {
	    if ( $e =~ /^:$/ )  { $a  = $deps_of{$ident} ; next } 
	    if ( $e =~ /^=$/ )  { $a  = $acts_of{$ident} ; next }
	    if ( $e =~ s/:$// ) { $na = $deps_of{$ident} }
	    if ( $e =~ s/=$// ) { $na = $acts_of{$ident} }
	 }
         push @$a, $e ;
	 $a = $na if defined $na ;
      }
   }
   
}

=item var_expand_dep($dependency,$target,$matches)

Static function, mostly for internal use. Called by L</check> to
expand variables inside a dependency. Returns the expanded string.

Recognized expansions:

=over 8

=item C<$>I<digits>, C<${>I<digits>C<}>

Expands to the value of C<< $matches->[ >>I<digits>C<-1]> (like in the
normal C<s///> operator)

=item C<$TARGET>, C<${TARGET}>

Expands to the value of C<$target>

=item C<$ENV{>I<name>C<}>

Expands to the value of the environment variable I<name>.

=back

=cut

sub var_expand_dep {
    my ($dep,$target,$matches)=@_;
    $dep=~s{
            \$(?:
            (?:\{(\d+)\})
            |(?:(\d+))
            |(?:(TARGET\b))
            |(?:\{(TARGET)\})
            |(?:ENV\{(.*?)\})
        )
        }{
            defined($1)||defined($2) ? $matches->[($1||$2)-1] :
            defined($3)||defined($4) ? $target :
            defined($5)              ? $ENV{$5} : die('Something wrong')
        }gsmxe;
    return $dep;
}

=item check

Builds the queue of things to make if this target or its dependencies are
out of date.

=cut

sub check {
   my Slay::MakerRule $self = shift ;
   my $ident = ident $self;
   my $user_options = ref $_[-1] ? pop : {} ;
   my ( $make, $target, $matches ) = @_ ;

   ## We join the options sets so that passed-in override new()ed, and
   ## we copy them in case somebody changes their mind.
   my $options = {
      %{$make->options},
      %{$opts_of{$ident}},
      %$user_options,
   } ;

   print STDERR "$target: checking ".$self->targets." ", %$options, "\n"
      if $options->{debug} ;
   if ( $in_make_of{$ident}++ ) {
      warn "Ignoring recursive dependency on " . $self->targets ;
      $in_make_of{$ident} = 0;
      return 0;
   }

   my @required ;
   push @required, "forced" if $options->{force} ;
   push @required, "!exists" unless $make->e( $target ) ;

   if ( $options->{debug} && $make->e( $target ) ) {
      print STDERR (
	 "$target: size, atime, mtime: ",
	 join(
	    ', ',
	    $make->size( $target ),
	    scalar( localtime $make->atime( $target ) ),
	    scalar( localtime $make->mtime( $target ) ),
	 ),
	 "\n"
      ) ;
   }

   my @deps = map {
      if ( ref $_ eq 'CODE' ) {
         $_->( $make, $target, $matches ) ;
      }
      elsif ( /\$/ ) {
         my $dep = $_ ;
         var_expand_dep($dep,$target,$matches);
      }
      else {
         $_ ;
      }
   } @{$deps_of{$ident}} ;

   print STDERR "$target: deps: ", join( ', ', @deps ), "\n"
      if $options->{debug} && @deps ;

   ## If the deps are to be rebuilt when our dependencies are checked,
   ## then we must be remade as well.
   my $count=$make->check_targets( @deps, $user_options ) ;
   push @required, "!deps" if $count;

   unless ( @required ) {
      ## The target exists && no deps need to be rebuilt.  See if the
      ## target is up to date.
      my $max_mtime ;
      for ( @deps ) {
	 print STDERR "$target: checking " . Cwd::cwd() . " $_\n"
	    if $options->{debug} ;
	 my $dep_mtime = $make->mtime( $_ ) ;
	 print STDERR "$target: $_ mtime " . localtime( $dep_mtime ) . "\n"
	    if $options->{debug} ;
	 $max_mtime = $dep_mtime
	    if defined $dep_mtime
	       && ( ! defined $max_mtime || $dep_mtime > $max_mtime ) ;
      }
      push @required, "out of date"
	 if defined $max_mtime && $max_mtime > $make->mtime( $target ) ;


   }

   $count=0;

   if ( @required ) {
      print STDERR "$target: required ( ", join( ', ', @required ), " )\n"
	 if $options->{debug} ;
      $count+=$make->push( $target, $self, \@deps, $matches, $options ) ;
   }
   else {
      print STDERR "$target: not required\n"
	 if $options->{debug} ;
   }
   $in_make_of{$ident}--;
   return $count;
}


sub _compile_pattern {
   my ( $pat ) = @_ ;

   my $exactness = -1 ;
   my $lparens    = 0 ;
   my $re ;
   if ( ref $pat ne 'Regexp' ) {
      $re = $pat ;
      ## '\a' => 'a'
      ## '\*' => '\*'
      ## '**' => '.*'
      ## '*'  => '[^/]*'
      ## '?'  => '.'
      $re =~ s{
	 (  \\.
	 |  \*\*
	 |  .
	 )
	 }{
	    if ( $1 eq '?' ) {
	       --$exactness ;
	       '[^/]' ;
	    }
	    elsif ( $1 eq '*' ) {
	       --$exactness ;
	       '[^/]*' ;
	    }
	    elsif ( $1 eq '**' ) {
	       --$exactness ;
	       '.*' ;
	    }
	    elsif ( $1 eq '(' ) {
	       ++$lparens ;
	       '(' ;
	    }
	    elsif ( $1 eq ')' ) {
	       ')' ;
	    }
	    elsif ( length $1 > 1 ) {
	       quotemeta(substr( $1, 1 ) );
	    }
	    else {
	       quotemeta( $1 ) ;
	    }
	 }xeg ;
      $re = "^$re\$" ;
   }
   else {
      ## Destroy it in order to get metrics.
      $re = "$pat" ;
      $re =~ s{
	 (
	    \\.
	    |\(\??
	    |(?:
	       .[?+*]+
	       |\.[?+*]*
	    )+
	 )
	 }{
	    if ( substr( $1, 0, 1 ) eq '\\' ) {
	    }
	    elsif ( substr( $1, 0, 1 ) eq '(' ) {
	       ++$lparens
		  if substr( $1, 0, 2 ) ne '(?' ;
	    }
	    else {
	       --$exactness ;
	    }
	    ## Return the original value, just for speed's sake
	    $1 ;
	 }xeg ;
      ## Ok, now copy it for real
      $re = $pat ;
   }

#   print STDERR (
#      "re: $re\n",
#      "lparens: $lparens\n",
#      "exactness: $exactness\n",
#   ) if $options->{debug} ;

   return [ $re, $exactness, $lparens ] ;
}


=item exec

Executes the action(s) associated with this rule.

=cut

sub exec {
   my Slay::MakerRule $self = shift ;
   my $options = ref $_[-1] eq 'HASH' ? pop : {} ;
   my ( $make, $target, $deps, $matches ) = @_ ;

   my $ident = ident $self;
   my @output ;
   print STDERR "$target: in exec() for ". $self->targets.", ", %$options, "\n"
      if $options->{debug} ; 

   my $target_backup ;

   if (  ( $options->{detect_no_size_change} || $options->{detect_no_diffs} )
      && ! -d $target
   ) {
      $target_backup = $make->backup(
	 $target,
	 {
	    stat_only => ! $options->{detect_no_diffs},
	    move      => $options->{can_move_target},
	    debug     => $options->{debug},
	 }
      ) ;
   }

   if ( $options->{auto_create_dirs} ) {
      ## Use dirname so that 'a/b/c/' only makes 'a/b', leaving it up to the
      ## make rule to mkdir c/.  fileparse would return 'a/b/c'.
      my ( $dir ) = dirname( $target ) ;
      if ( ! -d $dir ) {
	 mkpath( [ $dir ] ) ;
	 warn "Failed to create $dir" unless -d $dir ;
      }
   }

   for my $act ( @{$acts_of{$ident}} ) {
      local %ENV = %ENV ;
      $ENV{TARGET} = $target ;
      delete $ENV{$act} for grep {/^(DEP|MATCH)\d+$/} keys %ENV ;
      $ENV{"DEP$_"}   = $deps->[$_]    for (0..$#$deps) ;
      $ENV{"MATCH$_"} = $matches->[$_] for (0..$#$matches) ;

      if ( ref $act eq 'CODE' ) {
	 print STDERR "$target: execing CODE\n"
	    if $options->{debug} ;
         my $out = $act->( $make, $target, $deps, $matches ) ;
	 $out = '' unless defined $out ;
	 push @output, $out ;
      }
      elsif ( ref $act eq 'ARRAY' ) {
	 print STDERR "$target: execing ", join( ' ', map {"'$_'"} @$act ), "\n"
	    if $options->{debug} ;
         ## It's a command line in list form, so don't exec the shell
	 my $out ;
	 run $act, \undef, \$out ;
	 push( @output, $out ) ;
      }
      elsif ( ! ref $act ) {
	 $_ = $act;	# N.B. Work on a copy...
 	 s/\$(\d+)/$matches->[$1-1]/g ;
 	 s/\$\{(\d+)\}/$matches->[$1-1]/g ;
	 print STDERR "$target: execing '$_' \n"
	    if $options->{debug} ;
         ## It's a command line in string form
	 my $out ;
	 run [ 'sh', '-c', $_ ], \undef, \$out ;
	 $_ =~ m{(\S*)} ;
	 my $cmd = $1 ;
	 push( @output, $out ) ;
      }
      else {
         confess "Invalid type for a Slay::MakerRule rule: " . ref $act ;
      }
   }

   $make->clear_stat( $target ) ;
   my @new_stats = $make->stat( $target ) ;

   if ( defined $target_backup ) {
      $make->remove_backup(
         $target_backup,
	 {
	    restore_if_unchanged => 1,
	    deps                 => $deps
	 }
      ) ;
   }

   return wantarray ? @output : join( '', @output ) ;
}


=item targets

returns either ( target1, target2, ... ) or "target1, target2, ..." depending
on context.

=cut

sub targets {
   my Slay::MakerRule $self = shift ;
   my $ident = ident $self;
   return wantarray ? @{$pats_of{$ident}} : join( ', ', @{$pats_of{$ident}} );
}


=item matches

Checks the target list to see if it matches the target passed in.

=cut

sub matches {
   my Slay::MakerRule $self = shift ;
   my $options = ref $_[-1] eq 'HASH' ? pop : {} ;

   my $ident = ident $self;
   my ( $target ) = @_ ;

   my $max_exactness ;
   my @matches ;

   if ( ! $compiled_pats_of{$ident} ) {
      $compiled_pats_of{$ident} = [
         map {
	    _compile_pattern $_
	 } grep {
	    ref $_ ne 'CODE'
	 } @{$pats_of{$ident}}
      ] ;
   }
#print STDERR join("\n",map { join(',', @$_ ) } @{$self->{COMPILED_PATS}} ), "\n" ;
   for ( @{$compiled_pats_of{$ident}} ) {
      my ( $re, $exactness, $lparens ) = @$_ ;
#print STDERR "$target: ?= $re\n" ;
      if ( $target =~ $re &&
	 ( ! defined $max_exactness || $exactness > $max_exactness )
      ) {
	 $max_exactness = $exactness ;
	 no strict 'refs' ;
	 @matches = map {
	    ${$_}
	 } (1..$lparens) ;
#	 print STDERR (
#	    "$target: matches: ",
#	    join( ',', map { defined $_ ? "'$_'" : '<undef>' } @matches),
#	    "\n"
#	 ) if $options->{debug} ;

      }
   }

   return defined $max_exactness ? ( $max_exactness, \@matches ) : () ;
}

=back

=cut

}

1 ;
