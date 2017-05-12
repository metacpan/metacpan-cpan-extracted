package Object::Remote::Logging::Router;

use Moo;
use Scalar::Util qw(weaken);
use Sys::Hostname;

with 'Log::Contextual::Role::Router';
with 'Object::Remote::Role::LogForwarder';

has _connections => ( is => 'ro', required => 1, default => sub { [] } );
has _remote_metadata => ( is => 'rw' );

sub before_import { }

sub after_import { }

sub _get_loggers {
  my ($self, %metadata) = @_;
  my $package = $metadata{caller_package};
  my $level = $metadata{message_level};
  my $is_level = "is_$level";
  my $need_clean = 0;
  my @loggers;

  foreach my $selector (@{$self->_connections}) {
    unless(defined $selector) {
      $need_clean = 1;
      next;
    }

    foreach my $logger ($selector->($package, { %metadata })) {
      next unless defined $logger;
      next unless $logger->$is_level;
      push(@loggers, $logger);
    }
  }

  $self->_clean_connections if $need_clean;

  return @loggers;
}

#overloadable so a router can invoke a logger
#in a different way
sub _invoke_logger {
  my ($self, $logger, $level_name, $content, $metadata) = @_;
  #Invoking the logger like this gets all available data to the
  #logging object with out losing any information from the datastructure.
  #This is not a backwards compatible way to invoke the loggers
  #but it enables a lot of flexibility in the logger.
  #The l-c router could have this method invoke the logger in
  #a backwards compatible way and router sub classes invoke
  #it in non-backwards compatible ways if desired
  $logger->$level_name($content, $metadata);
}

#overloadable so forwarding can have the updated
#metadata but does not have to wrap get_loggers
#which has too many drawbacks
sub _deliver_message {
  my ($self, %message_info) = @_;
  my @loggers = $self->_get_loggers(%message_info);
  my $generator = $message_info{message_sub};
  my $args = $message_info{message_args};
  my $level = $message_info{message_level};

  return unless @loggers > 0;
  #this is the point where the user provided log message code block is executed
  my @content = $generator->(@$args);
  foreach my $logger (@loggers) {
    $self->_invoke_logger($logger, $level, \@content, \%message_info);
  }
}

sub handle_log_request {
  my ($self, %message_info) = @_;
  my $level = $message_info{message_level};
  my $package = $message_info{caller_package};
  my $need_clean = 0;

  #caller_level is useless when log forwarding is in place
  #so we won't tempt people with using it
  my $caller_level = delete $message_info{caller_level};
  $message_info{object_remote} = $self->_remote_metadata;
  $message_info{timestamp} = time;
  $message_info{pid} = $$;
  $message_info{hostname} = hostname;

  my @caller_info = caller($caller_level);
  $message_info{filename} = $caller_info[1];
  $message_info{line} = $caller_info[2];

  @caller_info = caller($caller_level + 1);
  $message_info{method} = $caller_info[3];
  $message_info{method} =~ s/^${package}::// if defined $message_info{method};

  $self->_deliver_message(%message_info);
}

sub connect {
  my ($self, $destination, $is_weak) = @_;
  my $wrapped;

  if (ref($destination) ne 'CODE') {
    $wrapped = sub { $destination };
  } else {
    $wrapped = $destination;
  }

  push(@{$self->_connections}, $wrapped);
  weaken($self->_connections->[-1]) if $is_weak;
}

sub _clean_connections {
  my ($self) = @_;
  @{$self->{_connections}} = grep { defined } @{$self->{_connections}};
}

1;
