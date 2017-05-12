package Nagios::Passive::CommandFile;

use strict;
use Carp;
use Moo;
use MooX::late;

extends 'Nagios::Passive::Base';

has 'command_file'=>(
  is => 'ro',
  isa => 'Str',
  predicate=>'has_command_file'
);

sub BUILD {
  my $self = shift;
  my $cf = $self->command_file;
  croak("$cf is not a named pipe") unless (-p $cf);
};

sub to_string {
  my $s = shift;
  my $output;
  if(defined $s->service_description) {
    $output = sprintf "[%d] PROCESS_SERVICE_CHECK_RESULT;%s;%s;%d;%s %s - %s\n",
      $s->time, $s->host_name, $s->service_description, $s->return_code,
      $s->check_name, $s->_status_code, $s->_quoted_output;
  } else {
    $output = sprintf "[%d] PROCESS_HOST_CHECK_RESULT;%s;%d;%s %s - %s\n",
      $s->time, $s->host_name, $s->return_code,
      $s->check_name, $s->_status_code, $s->_quoted_output;
  }
  return $output;
}

sub submit {
  my $s = shift;
  croak("no external_command_file given") unless $s->has_command_file;
  my $cf = $s->command_file;
  my $output = $s->to_string;

  # I hope this is the correct way to deal with named pipes
  local $SIG{PIPE} = 'IGNORE';
  open(my $f, ">>", $cf) or croak("cannot open $cf: $!");
  print $f $output       or croak("cannot write to pipe: $!");
  close($f)              or croak("cannot close $cf");
  return length($output);
}

1;
__END__

=head1 NAME

Nagios::Passive::CommandFile - drop check results into Nagios' check_result_path.

=head1 SYNOPSIS

  my $nw = Nagios::Passive->create(
    command_file => $checkresultsdir,
    service_description => $service_description,
    check_name => $check_name,
    host_name  => $hostname,
    return_code => 0, # 1 2 3
    output => 'looks (good|bad|horrible) | performancedata'
  );
  $nw->submit;

=head1 DESCRIPTION

This module gives you the ability to drop checkresults into
Nagios' external_command_file.

The usage is described in L<Nagios::Passive>

=cut
