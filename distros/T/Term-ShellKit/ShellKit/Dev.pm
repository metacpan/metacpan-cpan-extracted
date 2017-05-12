package Term::ShellKit::Dev;

require Term::ShellKit;

######################################################################

sub require { 
  die "No module name provided" unless ( scalar @_ );
  map { Term::ShellKit::require_package( $_ ) } @_; 
}

######################################################################

use vars '%LibLastLoaded';

sub reload {
  if ( scalar @_ ) {
    my $lib = shift;
    ( $lib .= '.pm' ) =~ s|::|/|go unless ( $lib =~ /\.\w{2,3}$/ );
    delete $INC{$lib};
    CORE::require( $lib );
    return "Reloaded $lib";
  }
  my @libs;
  while(my($lib, $file) = each %INC) {
    local $^W = 0;
    
    my $mtime = (stat $file)[9];
    
    # warn and skip the files with relative paths which 
    # can't be locate by applying @INC;
    unless ( defined $mtime and $mtime ) {
      warn "Can't locate $file" ;
      next;
    }
    
    # Assume all files loaded at startup
    $LibLastLoaded{$file} ||= $^T;
    
    if($mtime > $LibLastLoaded{$file}) {
      delete $INC{$lib};
      eval {
	local $SIG{__DIE__};
	CORE::require( $lib );
      };
      if ( $@ ) {
	$INC{$lib} = $file;
	die $@;
      }
      push @libs, $lib;
      $LibLastLoaded{$file} = $mtime;
    }
  }
  
  scalar(@libs) ? "Reloaded " . join(', ', @libs ) : 'No changes found in @INC';
}

######################################################################

sub current_package () { 
  $Term::ShellKit::CurrentPackage; 
}

sub package ($) { 
  Term::ShellKit::package( @_ ); 
}

sub show_package (;$) {
  my $package = shift || $Term::ShellKit::CurrentPackage;
  
  no strict;
  my $symbols = \%{ $package . '::' };
  
  my (%scalars, %arrays, %hashes, %codes, %packages);
  foreach my $name ( sort keys %$symbols ) {
    local *symbol = $symbols->{ $name };
      
    if ( defined $symbol ) {
      $scalars{ $name } = "$symbol";
    }
    if ( defined @symbol ) {
      $arrays{ $name } = join(', ', @symbol);
    }
    if ( my $coderef = *Term::ShellKit::Dev::symbol{CODE} ) {
      my $prototype = prototype($coderef);
      $codes{ $name } = "$coderef" . ( $prototype ? " ($prototype)" : '' );
    }
    
    if ( defined %symbol ) {
      if ( $name =~ /(.*)\:\:\Z/ ) {
        $packages{ $1 } = "PACKAGE";
      } else {
        $hashes{ $name } = join(', ', map { "$_ => $symbol{$_}" } (sort 
keys %symbol));
      }
    }
  }
  
  my @out = ( "Package Stash for $package" );
  foreach my $output ( 
	[ 'Scalars', \%scalars, '$', ], 
	["Arrays", \%arrays, '@'],
	[ 'Hashes', \%hashes, '%'], 
	['Subs', \%codes, 'sub '],
	['Packages', \%packages, '::'] 
  ) {
    next unless scalar keys %{$output->[1]};
    push @out, "$output->[0]:";
    foreach ( sort keys %{$output->[1]} ) {
      push @out, "  $output->[2]$_ = \"$output->[1]{$_}\"";
    }
  }
  join "\n", @out;
}

######################################################################

1;

######################################################################


=head1 NAME

Term::ShellKit::Commands - Basic shell functions


=head1 SYNOPSIS

  > perl -Iblib/lib -MTerm::ShellKit -eshell "kit Dev"
  Term::ShellKit: Starting interactive shell; commands include help, exit.
  Activating Term::ShellKit::Commands
  Activating Term::ShellKit::Dev
  
  Term::ShellKit> require MyClass
  MyClass
  
  Term::ShellKit> show_package MyClass
  Package Stash for MyClass
  Subs:
    sub smee = "CODE(0x73fa4)"
    sub twiddle = "CODE(0xc8530)"


=head1 COMMANDS

The following commands are available.


=head2 require

Load a Perl module or library.

=over 4

=item *

require I<module>

=back


=head2 reload

Reload any Perl modules which have changed since they were last loaded.

=over 4

=item *

reload

=back

You can use the shell reload command to read in changes to your modules while continuing to work in the same environment.

Start with the following code in MyObject.pm:

  package MyObject;
  
  sub new {
    my $class = shift;
    bless { }, $class;
  }

  1;

Then start your shell and load your module:

  ~> perl lib/Shell/Shell.pm
  Term::ShellKit: Starting interactive shell
  Term::ShellKit> require MyObject

You can now start creating instances of your class:

  Term::ShellKit> $example = MyObject->new()
  $example = MyObject->new(): MyObject=HASH(0x1e5118)

Your class doesn't do anything else yet, so trying to call other methods on your new object will result in an error:

  Term::ShellKit> $example->twiddle
  $example->twiddle: Failed.
    shell_cmd_method: 
    shell_cmd_eval: Can't locate object method "twiddle" via package "MyObject" at (eval 12) line 1.

Let's define that method -- leave the shell running, and add the following method to your package:

  sub twiddle {
    my $self = shift;
    return "Song and dance goes here...";
  }

Then return to the shell and run the "reload" command to load your changes. You can now start calling your new method, even on objects that were created earlier:

  Term::ShellKit> reload
  Term::ShellKit: reload MyObject.pm 
  Term::ShellKit> $example->twiddle
  $example->twiddle: Song and dance goes here...

Subsequent additions or revisions to the module will be available the next time you run the "reload" command. (Note that if you remove a method from your module code, it will not be deleted from the live workspace; you'll need to quit and restart the shell to achieve this.)

If there's an error in your code, you'll get a message similar to this when you try to reload:

  Term::ShellKit> reload
  reload: Failed.
    shell_cmd_method: Type of arg 1 to shift must be array (not return)
  at /tmp/MyObject.pm line 10, near ""Song and dance goes here...";"

To view the problematic line, you can copy and paste in the file and line number, taking advantage of the default alias that maps "at" to "show_file":

  Term::ShellKit> at /tmp/MyObject.pm line 10 
	      > show_file /tmp/MyObject.pm line 10
	      > show_file /tmp/MyObject.pm window 2 line 10

      my $self = shift
      return "Song and dance goes here...";
    }

If you need to see more of the code you can re-run the show_file command with a window argument that's larger than the default of 2, but that's generally enough to spot errors like semicolon missing from the above.

=head2 show_package 

=over 4

=item *

show_package I<package_name>

=back

  > perl -Iblib/lib -MTerm::ShellKit -eshell "kit Dev"
  Term::ShellKit: Starting interactive shell; commands include help, exit.
  Activating Term::ShellKit::Commands
  Activating Term::ShellKit::Dev
  
  Term::ShellKit> show_package Carp
  Package Stash for Carp
  Scalars:
    $CarpLevel = "0"
    $MaxArgLen = "64"
    $MaxArgNums = "8"
    $MaxEvalLen = "0"
    $Verbose = "0"
  Arrays:
    @EXPORT = "confess, croak, carp"
    @EXPORT_FAIL = "verbose"
    @EXPORT_OK = "cluck, verbose"
    @ISA = "Exporter"
  Hashes:
    %EXPORT = "carp => 1, cluck => 1, confess => 1, croak => 1, verbose => 1"
    %EXPORT_FAIL = "&verbose => 1, verbose => 1"
  Subs:
    sub carp = "CODEREF"
    sub cluck = "CODEREF"
    sub confess = "CODEREF"
    sub croak = "CODEREF"
    sub export_fail = "CODEREF"
    sub longmess = "CODEREF"
    sub shortmess = "CODEREF"

  Term::ShellKit> exit


=head1 SEE ALSO

L<Term::ShellKit>

=cut
