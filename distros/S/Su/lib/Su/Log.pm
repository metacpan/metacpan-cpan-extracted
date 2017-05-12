package Su::Log;
use Test::More;
use Carp;
use Data::Dumper;

=pod

=head1 NAME

Su::Log - A simple Logger which filters output by log level and regexp of the target class name.

=head1 SYNOPSYS

  my $log = Su::Log->new;
  $log->info("info message.");

  # Set the log level to output.
  Su::Log->set_level("trace");
  $log->trace("trace message.");

  # Disable logging and nothing output.
  $log->off(__PACKAGE__);
  $log->info("info message.");

  # Clear the logging state.
  $log->clear(__PACKAGE__);

  # Enable logging.
  $log->on(__PACKAGE__);
  $log->info("info message.");

  # Clear the logging state.
  $log->clear(__PACKAGE__);

  # Set the logging target and log level.
  $log->on( 'Pkg::LogTarget', 'error' );

  # Set the logging target by regex.
  $log->on( qr/Pkg::.*/, 'error' );

  # Clear the logging state.
  $log->clear(qr/Pkg::.*/);

  # Output logs to the file.
  $log->log_handler('path/to/logfile');

=head1 DESCRIPTION

Su::Log is a simple Logger module.
Su::Log has the following features.

=over

=item  Narrow down the output by log level.

=item  Narrow down the logging target class.

=item  Narrow down the output by customized log kind.

=item  Customize the log handler function.

=back

=head1 FUNCTIONS

=over

=cut

# Each elements consist of { class => $class, level => $level }
our @target_class = ();
our @target_tag   = ();

# Default log level.
our $level = "info";

# User specified global log level.
our $global_log_level;

# Elements are String or Regexp of the target class.
our @exclusion_class = ();

# If you want to use this Log class not as oblect oriented style, but
# as function style directly, set current class name to this variable.
our $class_name;

our $all_on  = 0;
our $all_off = 0;
our $log_handler;

BEGIN: {

  # Set default handler.
  $log_handler =
    sub { my $msg = _make_log_string(@_); print $msg; return $msg; };

} ## end BEGIN:

my $level_hash = {
  debug => 0,
  trace => 1,
  info  => 2,
  warn  => 3,
  error => 4,
  crit  => 5,
};

=item on()

Add the passed module name to the list of the logging tareget.
If the parameter is not passed, then set the whole class as logging
target.

=cut

# NOTE: @target_class is a package variable, so shared with other
# logger even if you call this method via the specific logger
# instance.
sub on {
  my $self  = shift if ( $_[0] eq __PACKAGE__ || ref $_[0] eq __PACKAGE__ );
  my $class = shift;
  my $level = shift;

  if ($class) {

    #  diag( "on|" . $class . "|" . $level );

    # Remove old entry before adding new one.
    if ( grep { $_->{class} =~ /^$class$/ } @target_class ) {

      # @target_class = grep { $_->{class} ne /^$class$/ } @target_class;
      @target_class = grep { $_->{class} !~ /^$class$/ } @target_class;
    }

    push @target_class, { class => $class, level => $level };

    my $bRegex = ref $class eq 'Regexp';
    if ($bRegex) {
      @exclusion_class = grep { $_ ne $class } @exclusion_class;
    } else {
      @exclusion_class = grep !/^$class$/, @exclusion_class;
    }

  } else {
    $self->{on} = 1;
  }
} ## end sub on

=item enable()

This method force enable the logging regardless of whether the logging
of the target class is enabled or disabled.

Internally, this method set the $all_on flag on, and $all_off flag
off. To clear this state, call the method L<Su::clear_all_flags>.

=cut

sub enable {
  $all_on  = 1;
  $all_off = 0;
}

=item off()

Disable the logging of the class which name is passed as a parameter.

 $log->off('Target::Class');

If the parameter is omitted, this effects only own instance.

 $log->off;

=cut

sub off {
  my $self = shift if ( $_[0] eq __PACKAGE__ || ref $_[0] eq __PACKAGE__ );
  my $class = shift;

  # In case of specified the log target.
  if ($class) {

    # String parameter.
    if ( !ref $class ) {
      unless ( grep /^$class$/, @exclusion_class ) {
        push @exclusion_class, $class;
      }

      # Remove the passed class name from log target classes.
      @target_class = grep { $_->{class} !~ /^$class$/ } @target_class;
    } ## end if ( !ref $class )
    elsif ( ref $class eq 'Regexp' ) {

      unless ( grep { $_ eq $class } @exclusion_class ) {
        push @exclusion_class, $class;
      }

      # Remove the passed regex from the log tareget classes.
      @target_class = grep { $class ne $_->{class} } @target_class;
    } ## end elsif ( ref $class eq 'Regexp')
  } ## end if ($class)
  else {

    # diag("off the logging of this instance.");

    # Instance parameter effects only own instance.
    $self->{on} = undef;
  } ## end else [ if ($class) ]
} ## end sub off

=item disable()

This method force disable the logging regardless of whether the logging
of the target class is enabled or disabled.

Internally, ths method set the $all_off flag on, and $all_on flag off.
To clear this state, call the method L<Su::clear_all_flags>.

=cut

sub disable {

  $all_off = 1;
  $all_on  = 0;

} ## end sub disable

=item clear_all_flags()

Clear C<$all_on> and C<$all_off> flags that is set by L<Su::enable>
or L<Su::disable> method.

=cut

sub clear_all_flags {
  $all_on  = 0;
  $all_off = 0;
}

=item clear()

If the parameter is passed, This method clear the state of the passed
target that is set by the method L<on> and L<off>.

If the parameter is omitted, then clear all of the log settings.

=cut

sub clear {
  my $self = shift if ( ref $_[0] eq __PACKAGE__ || $_[0] eq __PACKAGE__ );
  my $class = shift;

  # Remove the specified expression.
  if ($class) {
    my $bRegex = ref $class eq 'Regexp';
    if ($bRegex) {
      @target_class    = grep { $class ne $_->{class} } @target_class;
      @exclusion_class = grep { $_     ne $class } @exclusion_class;
    } else {
      @target_class = grep { $_->{class} !~ /^$class$/ } @target_class;
      @exclusion_class = grep !/^$class$/, @exclusion_class;
    }

  } else {

    # Clear all condition.
    @target_class    = ();
    @target_tag      = ();
    @exclusion_class = ();
    clear_all_flags();
  } ## end else [ if ($class) ]
} ## end sub clear

=item tag_on()

Add the passed tag to the target tags list.

=cut

sub tag_on {
  shift if ( $_[0] eq __PACKAGE__ );
  my $tag = shift;
  push @target_tag, $tag;
}

=item tag_off()

Remove the passed tag from the target tags list.

=cut

sub tag_off {
  shift if ( $_[0] eq __PACKAGE__ );
  my $tag = shift;
  @target_tag = grep !/^$tag$/, @target_tag;
}

=item new()

Constructor.

 my $log = new Su::Log->new;
 my $log = new Su::Log->new($self);
 my $log = new Su::Log->new('PKG::TargetClass');

Instantiate the Logger class. The passed instance or the string of the
module name is registered as a logging target class. If the parameter
is omitted, then the caller is registered automatically.

=cut

sub new {
  my $self = shift;
  $self = ref $self if ( ref $self );
  my $target_class = shift;

  # If passed argment is a reference of the instance, then extract class name.
  my $class_name = ref $target_class;

  # Else, use passed string as class name.
  if ( !$class_name ) {
    $class_name = $target_class;
  }

  if ( !$class_name ) {
    $class_name = caller();
  }

  #  diag("classname:" . $class_name);
  #  diag( Dumper($class_name));
  # Su::Log->trace( "classname:" . $class_name );
  # Su::Log->trace( Dumper($class_name) );

  # Add the caller class to the target list automatically.

  return bless { class_name => $class_name, on => 1, level => $level }, $self;
} ## end sub new

=item is_target()

Determine whether the module is a logging target or not.

=cut

sub is_target {
  my $self = shift;

  if ($all_on) {

    return { is_target => 1, has_level => undef };
  } elsif ($all_off) {

    return { is_target => 0, has_level => undef };
  }

  my $self_class_name = $self;
  if ( ref $self ) {
    $self_class_name = $self->{class_name} ? $self->{class_name} : $class_name;
  }

  #diag("check classname:" . $self->{class_name});
  #  if(! defined($self->{class_name})){
  #    die "Class name not passed to the log instance.";
  #  }

#NOTE:Can not trace via trace or something Log class provide. Because recurssion occurs.
#diag( @target_class);

  # diag("grep result:" . (grep /^$self->{class_name}$/, @target_class));
  #  if (index($self->{class_name}, @target_class) != -1){
  # diag( "exc cls:" . Dumper(@exclusion_class) );
  if (
    grep {
      ref $_ eq 'Regexp'
        ? $self_class_name =~ /$_/
        : $self_class_name =~ /^$_$/
    } @exclusion_class
    )
  {
    return 0;
  } elsif (
    my @info =
    grep {
      my $bRegex = ref $_->{class} eq 'Regexp';
      if ($bRegex) {

        # diag('use regex');

        # Use class field as regexp.
        $self_class_name =~ /$_->{class}/;
      } else {

        # diag('use str');

        # Use class field as string,directly.
        $self_class_name =~ /^$_->{class}$/;
      } ## end else [ if ($bRegex) ]
    } @target_class
    )
  {

    #    diag( Dumper(@target_class) );
    #    diag("here2:$info[0]->{class} --- $info[0]->{level}");
    return { is_target => 1, has_level => 1, level => $info[0]->{level} };
  } else {

    #    diag( "here3:" . $self . $self->{on} );

    # Return the instance flag.
    # return $self->{on};
    return { is_target => $self->{on}, has_level => undef };
  } ## end else [ if ($bRegex) ]
} ## end sub is_target

=item set_level()

Su::Log->set_level("trace");

Set the log level which effects instance scope. Default level is B<info>;

=cut

sub set_level {

  # The first argment may be reference of object or string of class name.
  my $self = shift if ( ref $_[0] eq __PACKAGE__ || $_[0] eq __PACKAGE__ );
  my $passed_level = shift;
  croak "Passed log level is invalid:" . $passed_level
    if !grep /^$passed_level$/, keys %{$level_hash};
  $self->{level} = $passed_level;

} ## end sub set_level

=item set_global_log_level()

Su::Log->set_default_log_level("trace");

Set the log level. This setting effects as the package scope variable.

To clear the $global_log_level flag, pass undef to this method.

=cut

sub set_global_log_level {

  # The first argment may be reference of object or string of class name.
  shift if ( ref $_[0] eq __PACKAGE__ || $_[0] eq __PACKAGE__ );
  my $passed_level = shift;
  croak "Passed log level is invalid:" . $passed_level
    if defined $passed_level && !grep /^$passed_level$/, keys %{$level_hash};
  $global_log_level = $passed_level;
} ## end sub set_global_log_level

=item is_large_level()

Return whether the passed log level is larger than the current log level or not.
If the second parameter is passed, then compare that value as the current log level.

=cut

sub is_large_level {
  my $self = shift if ( ref $_[0] eq __PACKAGE__ );
  $self = caller() unless $self;

  #  diag "dumper:" . Dumper( $self->{class_name} );
  my $arg = shift;

#NOTE:Can not trace via trace command which Log class provides, because recursion occurs.
#diag("compare:" . $arg . ":" . $level);

  my $compare_target_level = shift;

  # If the second parameter is passed, use it as compare target directly.
  unless ($compare_target_level) {
    if ( defined $global_log_level ) {
      $compare_target_level = $global_log_level;
    } elsif ( $self->{level} ) {
      $compare_target_level = $self->{level};
    } else {
      $compare_target_level = $level;
    }
  } ## end unless ($compare_target_level)

  #  diag "[TRACE]compare_target_level:$compare_target_level:arg:$arg\n";
  return $level_hash->{$arg} >= $level_hash->{$compare_target_level} ? 1 : 0;
} ## end sub is_large_level

sub _log_method_impl {
  my $self          = shift if ( ref $_[0] eq __PACKAGE__ );
  my $opt_href      = shift;
  my $caller_prefix = $opt_href->{caller};
  my $method_level  = $opt_href->{level};
  my $log_handler = $self->{log_handler} ? $self->{log_handler} : $log_handler;
  my $target_info = is_target( _is_empty($self) ? caller() : $self );

  if ( $target_info->{is_target}
    && $self->is_large_level( $method_level, $target_info->{level} ) )
  {
    return $log_handler->( "[$caller_prefix]", uc("[$method_level]"), @_ );
  }
} ## end sub _log_method_impl

=item trace()

Log the passed message as trace level.

=cut

sub trace {
  my $self = shift if ( ref $_[0] eq __PACKAGE__ || $_[0] eq __PACKAGE__ );

  my ( $pkg, $file, $line ) = caller;

  my $caller_prefix = $file . ':L' . $line;
  $self->_log_method_impl( { caller => $caller_prefix, level => "trace" }, @_ );
} ## end sub trace

=item info()

Log the passed message as info level.

=cut

sub info {
  my $self = shift if ( ref $_[0] eq __PACKAGE__ || $_[0] eq __PACKAGE__ );

  my ( $pkg, $file, $line ) = caller;

  my $caller_prefix = $file . ':L' . $line;
  $self->_log_method_impl( { caller => $caller_prefix, level => "info" }, @_ );
} ## end sub info

=item warn()

Log the passed message as warn level.

=cut

sub warn {
  my $self = shift if ( ref $_[0] eq __PACKAGE__ || $_[0] eq __PACKAGE__ );
  my ( $pkg, $file, $line ) = caller;
  my $caller_prefix = $file . ':L' . $line;
  $self->_log_method_impl( { caller => $caller_prefix, level => "warn" }, @_ );
} ## end sub warn

=item error()

Log the passed message as error level.

=cut

sub error {
  my $self = shift if ( ref $_[0] eq __PACKAGE__ || $_[0] eq __PACKAGE__ );
  my ( $pkg, $file, $line ) = caller;
  my $caller_prefix = $file . ':L' . $line;
  $self->_log_method_impl( { caller => $caller_prefix, level => "error" }, @_ );
} ## end sub error

=item crit()

Log the passed message as crit level.

=cut

sub crit {
  my $self = shift if ( ref $_[0] eq __PACKAGE__ || $_[0] eq __PACKAGE__ );
  my ( $pkg, $file, $line ) = caller;
  my $caller_prefix = $file . ':L' . $line;
  $self->_log_method_impl( { caller => $caller_prefix, level => "crit" }, @_ );
} ## end sub crit

=item debug()

Log the passed message as debug level.

=cut

sub debug {
  my $self = shift if ( ref $_[0] eq __PACKAGE__ || $_[0] eq __PACKAGE__ );
  my ( $pkg, $file, $line ) = caller;
  my $caller_prefix = $file . ':L' . $line;
  $self->_log_method_impl( { caller => $caller_prefix, level => "debug" }, @_ );

} ## end sub debug

=item log()

Log the message with the passed tag, if the passed tag is active.

  my $log = Su::Log->new($self);
  $log->log("some_tag","some message");

=cut

sub log {
  my $self = shift if ( ref $_[0] eq __PACKAGE__ );
  my $tag = shift;

  my $log_handler = $self->{log_handler} ? $self->{log_handler} : $log_handler;
  if ( is_target( _is_empty($self) ? caller() : $self )
    && ( grep /^$tag$/, @target_tag ) )
  {
    my ( $pkg, $file, $line ) = caller;
    my $caller_prefix = $file . ':L' . $line;
    return $log_handler->( "[$caller_prefix]", "[$tag]", @_ );
  } ## end if ( is_target( _is_empty...))

} ## end sub log

=item log_handler()

Set the passed method as the log handler of L<Su::Log|Su::Log>.

  $log->log_handler(\&hndl);
  $log->info("info message");

  sub hndl{
    print(join 'custom log handler:', @_);
  }

  $log->log_handler(
    sub {
      my $level = shift;
      my $msg   = @_;
      print $F $level . join( ' ', @_ ) . "\n";
    }
  );

If the passed parameter is string, then automatically the handler is
set to output log to the passed file name.

=cut

sub log_handler {
  my $self = shift if ( ref $_[0] eq __PACKAGE__ );
  my $handler = shift;

  # Work as setter method.
  if ($handler) {
    if ($self) {
      if ( ref $handler eq 'CODE' ) {
        $self->{log_handler} = $handler;
      } else {

        # $handler is passed as log file name.
        $self->{log_handler} = _make_default_log_file_handler($handler);
      }
    } else {

      # $log_handler = $handler;
      if ( ref $handler eq 'CODE' ) {
        $log_handler = $handler;
      } else {

        # $handler is passed as log file name.
        $log_handler = _make_default_log_file_handler($handler);
      }

    } ## end else [ if ($self) ]
  } else {

    # The param is omitted, just work as a getter method.
    return $log_handler;
  }
} ## end sub log_handler

=begin comment

Return the handler to output log to the log file.  Passed parameter is
a log file name.

=end comment

=cut

sub _make_default_log_file_handler {
  my $self = shift if ( ref $_[0] eq __PACKAGE__ );
  my $log_file_name = shift;
  open( my $F, '>>', $log_file_name ) or die $!;
  return sub {
    my $level = shift;
    my $msg   = _make_log_string(@_);
    print $F $level . $msg;
  };
} ## end sub _make_default_log_file_handler

=begin comment

Internal Utility function.

=end comment

=cut

sub _is_empty {
  my $arg = shift;
  return 1 if ( !$arg );
  if ( ref $arg eq 'HASH' ) {
    return 1 unless ( scalar keys %{$arg} );
  }
  return 0;
} ## end sub _is_empty

=begin comment

Add the prefix of time to the passed parameter and return it as a string.
The caller information is passed to this method as a parameter.

=end comment

=cut

sub _make_log_string {
  my ( $s, $mi, $h, $d, $m, $y ) = ( localtime(time) )[ 0 .. 6 ];
  my $date_prefix = sprintf "%04d/%02d/%02d %02d:%02d:%02d", $y + 1900, $m + 1,
    $d,
    $h, $mi, $s;

  return '[' . $date_prefix . ']' . join( '', @_, "\n" );
} ## end sub _make_log_string

=pod

=back

=cut

