package Parse::Eyapp::Base;
use strict;
use warnings;
use Carp;
use List::Util qw(first);

BEGIN {
  our @EXPORT_OK = qw(
    compute_lines 
    empty_method
    slurp_file 
    valid_keys 
    invalid_keys 
    write_file 
    numbered
    insert_function 
    insert_method
    delete_method
    push_method
    push_empty_method
    pop_method
    firstval
    lastval
    part
  );
  our %EXPORT_TAGS = ( 'all' => [ @EXPORT_OK ] );

}
use base qw(Exporter);

our $FILENAME=__FILE__;

sub firstval(&@) {
  my $handler = shift;
  
  return (grep { $handler->($_) } @_)[0]
}

sub lastval(&@) {
  my $handler = shift;
  
  return (grep { $handler->($_) } @_)[-1]
}

# Receives a handler $h and a list @_
# Elements of @_ with the same value of $h go to the same sublist
# Returns a list of lists
sub part(&@) {
  my $h = shift;

  my @p;
  push @{$p[$h->($_)]}, $_ for (@_);
  return @p;
}

####################################################################
# Usage      : $input = slurp_file($filename, 'trg');
# Purpose    : opens  "$filename.trg" and sets the scalar
# Parameters : file name and extension (not icluding the dot)
# Comments   : Is this O.S dependent?

sub slurp_file {
  my ($filename, $ext) = @_;

    croak "Error in slurp_file opening file. Provide a filename!\n" 
  unless defined($filename) and length($filename) > 0;
  $ext = "" unless defined($ext);
  $filename .= ".$ext" unless (-r $filename) or ($filename =~ m{[.]$ext$});
  local $/ = undef;
  open my $FILE, $filename or croak "Can't open file $filename"; 
  my $input = <$FILE>;
  close($FILE);
  return $input;
}

sub valid_keys {
  my %valid_args = @_;

  my @valid_args = keys(%valid_args); 
  local $" = ", "; 
  return "@valid_args" 
}

sub invalid_keys {
  my $valid_args = shift;
  my $args = shift;

  return (first { !exists($valid_args->{$_}) } keys(%$args));
}

sub write_file {
  my ($outputfile, $text) = @_;
  defined($outputfile) or croak "Error at write_file. Undefined file name";

  my $OUTPUTFILE;
  
  open($OUTPUTFILE, "> $outputfile") or croak "Can't open file $OUTPUTFILE.";
  print $OUTPUTFILE ($$text);
  close($OUTPUTFILE) or croak "Can't close file $OUTPUTFILE.";
}

# Sort of backpatching for line number directives:
# Substitutes $pattern by #line $number $filename in string $textr
sub compute_lines {
  my ($textr, $filename, $pattern) = @_;
  
  local $_ = 1;
  $$textr =~ s{\n$pattern\n|(\n)}
              {
                $_++; 
                if (defined($1)) {
                  "\n";
                }
                else {
                 my $directive = "\n#line $_ $filename\n";
                 $_++;
                 $directive;
                }
              }eg;
}

sub numbered {
  my ($output, $c) = (shift(), 1);
  my $cr = $output =~ tr/\n//;
  $cr = 1 if $cr <= 0;
  my $digits = 1+int(log($cr)/log(10));
  $output =~ s/^/sprintf("%${digits}d ",$c++)/emg;
  $output;
}

sub insert_function {
  no warnings;
  no strict;

  my $code = pop;
    croak "Error in insert_function: last arg must be a CODE ref\n"
  unless ref($code) eq 'CODE';

  for (@_) {
    croak "Error in insert_function: Illegal function name <$_>\n" unless /^[\w:]+$/;
    my $fullname = /^\w+$/? scalar(caller).'::'.$_ : $_;
    *{$fullname} = $code;
  }
}

sub insert_method {

  my $code = pop;

  unless (ref($code)) { # not a ref: string or undef
    # Call is: insert_method('Tutu', 'titi')
    if (defined($code) && $code  =~/^\w+$/) {
      delete_method(@_, $code); 
      return;
    }
    # Call is: insert_method('Tutu', 'titi', undef)
    goto &delete_method; 
  }
    croak "Error in insert_method: expected a CODE ref found $code\n"
  unless ref($code) eq 'CODE';

  my $name = pop;
  croak "Error in insert_method: Illegal method name <$_>\n" unless $name =~/^\w+$/;

  my @classes = @_;
  @classes = scalar(caller) unless @classes; 
  for (@classes) {
    croak "Error in insert_method: Illegal class name <$_>\n" unless /^[\w:]+$/;
    no warnings 'redefine';;
    no strict 'refs';
    *{$_."::".$name} = $code;
  }
}

sub delete_method {
  my $name = pop; 
  $name = '' unless defined($name);
  croak "Error in delete_method: Illegal method name <$name>\n" unless $name =~/^\w+$/;
  my @classes = @_;

  @classes = scalar(caller) unless @classes; 
  no strict 'refs';
  for (@classes) {
    croak "Error in delete_method: Illegal class name <$_>\n" unless /^[\w:]+$/;
    unless ($_->can($name)) {
      print STDERR "Warning in delete_method: No sub <$name> to delete in package <$_>\n";
      next;
    }
    my $fullname = $_."::".$name;

    # Temporarily save the other entries
    my @refs = map { *{$fullname}{$_} } qw{HASH SCALAR ARRAY GLOB};

    # Delete typeglob
    *{$fullname} = do { local *{$fullname} };

    # Restore HASH SCALAR ARRAY GLOB entries
    for (@refs) {
      next unless defined($_);
      *{$fullname} = $_;
    }
  }
}

sub empty_method {
  insert_method(@_, sub {});
}

sub push_empty_method {
  push_method(@_, sub {});
}

{
  my %methods;

  sub push_method {
    my $handler;
    if (ref($_[-1]) eq 'CODE') {  
      $handler = pop;
    }
    else {
      $handler = undef;
    }

    my $name = pop;
    $name = '' unless defined($name);
    croak "Error in push_method: Illegal method name <$name>\n" unless $name =~/^\w+$/;
    my @classes = @_;

    my @returnmethods;

    @classes = scalar(caller) unless @classes; 
    for (@classes) {
      croak "Error in push_method: Illegal class name <$_>\n" unless /^[\w:]+$/;
      my $fullname = $_."::".$name;
      if ($_->can($name)) {
        no strict 'refs';
        my $coderef = \&{$fullname};
        push @returnmethods, $coderef;
        push @{$methods{$fullname}}, $coderef;
      }
      else {
        push @returnmethods, undef;
        push @{$methods{$fullname}}, undef;
      }
    }
    insert_method(@classes, $name, $handler);
    
    return wantarray? @returnmethods : $returnmethods[0];
  }

  sub pop_method {
    my $name = pop;
    $name = '' unless defined($name);
    croak "Error in push_method: Illegal method name <$name>\n" unless $name =~/^\w+$/;
    my @classes = @_;

    my @returnmethods;

    @classes = scalar(caller) unless @classes; 
    for (@classes) {
      my $fullname = $_."::".$name;
      no strict 'refs';
      push @returnmethods, $_->can($name)? \&{$fullname} : undef;
      if (defined($methods{$fullname}) 
          && UNIVERSAL::isa($methods{$fullname}, 'ARRAY') 
          && @{$methods{$fullname}}) {
        my $handler = pop @{$methods{$fullname}};
        insert_method($_, $name, $handler);
      }
    }
    return wantarray? @returnmethods : $returnmethods[0];
  }

} # Closure for %methods

1;

