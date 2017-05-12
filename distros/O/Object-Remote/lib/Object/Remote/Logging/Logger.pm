package Object::Remote::Logging::Logger;

use Moo;
use Carp qw(croak);

#TODO sigh invoking a logger with a log level name the same
#as an attribute could happen - restrict attributes to _ prefix
#and restrict log levels to not start with out that prefix?
has format => ( is => 'ro', required => 1, default => sub { '%l: %s' } );
has level_names => ( is => 'ro', required => 1 );
has min_level => ( is => 'ro', required => 1, default => sub { 'info' } );
has max_level => ( is => 'lazy', required => 1 );
has _level_active => ( is => 'lazy' );

#just a stub so it doesn't get to AUTOLOAD
sub BUILD { }
sub DESTROY { }

sub AUTOLOAD {
  my $self = shift;
  (my $method) = (our $AUTOLOAD =~ /([^:]+)$/);

  no strict 'refs';

  if ($method =~ m/^_/) {
    croak "invalid method name $method for " . ref($self);
  }

  if ($method =~ m/^is_(.+)/) {
    my $level_name = $1;
    my $is_method = "is_$level_name";
    *{$is_method} = sub { shift(@_)->_level_active->{$level_name} };
    return $self->$is_method;
  }

  my $level_name = $method;
  *{$level_name} = sub {
    my $self = shift;
    unless(exists($self->_level_active->{$level_name})) {
      croak "$level_name is not a valid log level name";
    }

    $self->_log($level_name, @_);
  };

  return $self->$level_name(@_);
}

sub _build_max_level {
  my ($self) = @_;
  return $self->level_names->[-1];
}

sub _build__level_active {
  my ($self) = @_;
  my $should_log = 0;
  my $min_level = $self->min_level;
  my $max_level = $self->max_level;
  my %active;

  foreach my $level (@{$self->level_names}) {
    if($level eq $min_level) {
      $should_log = 1;
    }

    $active{$level} = $should_log;

    if (defined $max_level && $level eq $max_level) {
      $should_log = 0;
    }
  }

  return \%active;
}

sub _log {
  my ($self, $level, $content, $metadata_in) = @_;
  my %metadata = %$metadata_in;
  my $rendered = $self->_render($level, \%metadata, @$content);
  $self->_output($rendered);
}

sub _create_format_lookup {
  my ($self, $level, $metadata, $content) = @_;
  my $method = $metadata->{method};

  $method = '(none)' unless defined $method;

  return {
    '%' => '%', 'n' => "\n",
    t => $self->_render_time($metadata->{timestamp}),
    r => $self->_render_remote($metadata->{object_remote}),
    s => $self->_render_log(@$content), l => $level,
    c => $metadata->{exporter}, p => $metadata->{caller_package}, m => $method,
    f => $metadata->{filename}, i => $metadata->{line},
    h => $metadata->{hostname}, P => $metadata->{pid},
  };
}

sub _get_format_var_value {
  my ($self, $name, $data) = @_;
  my $val = $data->{$name};
  return $val if defined $val;
  return '(undefined)';
}

sub _render_time {
  my ($self, $time) = @_;
  return scalar(localtime($time));
}

sub _render_remote {
  my ($self, $remote) = @_;
  return 'local' unless defined $remote;
  my $conn_id = $remote->{connection_id};
  $conn_id = '(uninit)' unless defined $conn_id;
  return "remote #$conn_id";
}

sub _render_log {
  my ($self, @content) = @_;
  return join('', @content);
}
sub _render {
  my ($self, $level, $metadata, @content) = @_;
  my $var_table = $self->_create_format_lookup($level, $metadata, [@content]);
  my $template = $self->format;

  $template =~ s/%([\w%])/$self->_get_format_var_value($1, $var_table)/ge;

  chomp($template);
  $template =~ s/\n/\n /g;
  $template .= "\n";
  return $template;
}

sub _output {
  my ($self, $content) = @_;
  print STDERR $content;
}

1;

__END__

=head1 NAME

Object::Remote::Logging::Logger - Format and output a log message

=head1 SYNOPSIS

  use Object::Remote::Logging::Logger;
  use Object::Remote::Logging qw( router arg_levels );

  my $app_output = Object::Remote::Logging::Logger->new(
    level_names => arg_levels, format => '%t %s',
    min_level => 'verbose', max_level => 'info',
  );

  #Selector method can return 0 or more logger
  #objects that will receive the messages
  my $selector = sub {
    my ($generating_package, $metadata) = @_;
    return unless $metadata->{exporter} eq 'App::Logging::Subclass';
    return $app_output;
  };

  #true value as second argument causes the selector
  #to be stored with a weak reference
  router->connect($selector, 1);

  #disconnect the selector from the router
  undef($selector);

  #router will hold this logger forever
  #and send it all log messages
  router->connect(Object::Remote::Logging::Logger->new(
    level_names => arg_levels, format => '%s at %f line %i, log level: %l'
    min_level => 'warn', max_level => 'error',
  ));

=head1 DESCRIPTION

This class receives log messages from an instance of L<Object::Remote::Logging::Router>,
formats them according to configuration, and then outputs them to STDERR. In between
the router and the logger is a selector method which inspects the log message metadata
and can return 0 or more loggers that should receive the log message.

=head1 USAGE

A logger object receives the log messages that are generated and converts them to
formatted log entries then displays them to the end user. Each logger has a set
of active log levels and will only output a log entry if the log message is at
an active log level.

To gain access to the stream of log messages a connection is made to the log router.
A logger can directly connect to the router and receive an unfiltered stream of
log messages or a selector closure can be used instead. The selector will be executed
for each log message with the message metadata and returns a list of 0 or more loggers
that should receive the log message. When the selector is executed the first argument
is the name of the package that generated the log message and the second argument
is a hash reference containing the message metadata.

=head1 METADATA

The message metadata is a hash reference with the following keys:

=over 4

=item message_level

Name of the log level of the message.

=item exporter

Package name of the logging API that was used to generate the log message.

=item caller_package

Name of the package that generated the log message.

=item method

Name of the method the message was generated inside of.

=item timestamp

Unix time of the message generation.

=item pid

Process id of the Perl interpreter the message was generated in.

=item hostname

Hostname of the system where the message was generated.

=item filename

Name of the file the message was generated in.

=item line

Line of the source file the message was generated at.

=item object_remote

This is a reference to another hash that contains the Object::Remote
specific information. The keys are

=over 4

=item connection_id

If the log message was generated on a remote Perl interpreter then the
Object::Remote::Connection id of that interpreter will be available here.

=back

=back

=head1 ATTRIBUTES

=over 4

=item level_names

This is a required attribute. Must be an array ref with the list of log level names
in it. The list must be ordered with the lowest level as element 0 and the highest
level as the last element. There is no default value.

=item min_level

The lowest log level that will be output by the logger. There is no default value.

=item max_level

The highest log level that will be output by the logger. The default value is the
highest level present in level_names.

=item format

The printf style format string to use when rendering the log message. The following
sequences are significant:

=over 4

=item %l

Level name that the log message was generated at.

=item %s

Log message rendered into a string with a leading space before any additional lines in a
multiple line message.

=item %t

Time the log message was generated rendered into a string. The time value is taken from
the Perl interpreter that generated the log message; it is not the time that the logger
received the log message on the local interpreter if the log message was forwarded.

=item %r

Object::Remote connection information rendered into a string.

=item %c

Package name of the logging API that was used to generate the log message.

=item %p

Name of the package that generated the log message.

=item %m

Method name that generated the log message.

=item %f

Filename that the log message was generated in.

=item %i

Line number the log message was generated at.

=item %h

Hostname the log message was generated on.

=item %P

Process id of the Perl interpreter that generated the log message.

=item %%

A literal %.

=item %n

A newline.

=back

=back

