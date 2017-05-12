package Monitoring::Spooler::Cmd::Command::email;
$Monitoring::Spooler::Cmd::Command::email::VERSION = '0.05';
BEGIN {
  $Monitoring::Spooler::Cmd::Command::email::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: enqueue a new notification from an email

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;
# use Carp;
# use English qw( -no_match_vars );
# use Try::Tiny;

# extends ...
extends 'Monitoring::Spooler::Cmd::Command::create';
# has ...
has '+group_id' => (
    'is'    => 'ro',
    'isa'   => 'Int',
    'required' => 0,
);

has '+type' => (
    'is'    => 'ro',
    'isa'   => 'Str',
    'required' => 0,
);

has '+message' => (
    'is'    => 'ro',
    'isa'   => 'Str',
    'required' => 0,
);
# with ...
# initializers ...

# your code here ...
sub execute {
  my $self = shift;

  my @lines = <STDIN>;
  my ($message, $group_id, $type) = $self->_parse_mail(\@lines);
  return unless ($message && $group_id && $type);

  # the superclass accessors are ro, so go directly to the guts
  $self->{'message'}  = $message;
  $self->{'group_id'} = $group_id;
  $self->{'type'}     = $type;

  return $self->SUPER::execute();
}

sub _parse_mail {
  my $self = shift;
  my $line_ref = shift;

  my %props = ();
  my $is_header = 1;
  foreach my $line (@{$line_ref}) {
    $is_header = 0 if $line =~ m/^$/;
    next if $is_header; # ignore header
    # parse body
    if($line =~ m/^(\w+):(.*)$/) {
      my ($key, $value) = ($1, $2);
      $props{$key} = $value;
    }
  }
  return unless ($props{'id'} && $props{'status'} && $props{'name'});

  $props{'message'} = $props{'id'}.q{ }.$props{'status'}.q{ }.$props{'name'};
  return @props{qw(message group_id type)};
}

sub abstract {
    return "Place a new message in the notification queue";
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Monitoring::Spooler::Cmd::Command::email - enqueue a new notification from an email

=head1 DESCRIPTION

This class implements a command to add a new message to the queue.

This command is usually invoked by your Monitoring (as a media transport) or some
other noficiation script. All the boilerplate work is done by
MooseX::App::Cmd.

=head1 NAME

Monitoring::Spooler::Cmd::Command::Email - Command to create new messages from email

=head1 SETUP

In order for negating triggers to work you need to use a certain message
template for the message body. The header is ignored.

name:{TRIGGER.NAME}
id:{TRIGGER.ID}
status:{TRIGGER.STATUS}
hostname:{HOSTNAME}
ip:{IPADDRESS}
value:{TRIGGER.VALUE}
event_id:{EVENT.ID}
severity:{TRIGGER.SEVERITY}
group_id:<GROUP_ID>
type:{text,phone}

This script can be used to translate mails from external zabbix servers
to Monitoring::Spooler actions (e.g. text messages or phone calls).

Set it up in Postfix like this:

/etc/postfix/master.cf

# Monitoring::Spooler Endpoint
monspooler  unix  - n n - - pipe
  flags=DRhu user=www-data:www-data argv=/usr/bin/mon-spooler.pl email

=head1 AUTHOR

Dominik Schulz <tex@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
