package Nagios::Passive;
use strict;
use Carp;
use Class::Load qw/load_class/;
use version; our $VERSION = qv('0.4.0');

sub create {
  my $this = shift;
  my %opts = ref($_[0]) eq 'HASH' ? %{ $_[0] } : @_;
  my $class;
  if(exists $opts{command_file}) {
    $class = 'Nagios::Passive::CommandFile';
    load_class($class);
  } elsif(exists $opts{checkresults_dir}) {
    $class = 'Nagios::Passive::ResultPath';
    load_class($class);
  } elsif(exists $opts{gearman}) {
    $class = 'Nagios::Passive::Gearman';
    load_class($class);
  } else {
    croak("no backend specified");
  }
  return $class->new(%opts);
}
1;
__END__

=head1 NAME

Nagios::Passive - submit passive check results to nagios

=head1 SYNOPSIS

  my $nw = Nagios::Passive->create(
    command_file => $command_file,
    service_description => $service_description,
    check_name => $check_name,
    host_name  => $hostname,
    return_code => 0, # 1 2 3
    output => 'looks (good|bad|horrible) | performancedata'
  );
  $nw->submit;

=head1 DESCRIPTION

This is the factory class, currently it creates either a
Nagios::Passive::CommandFile or a Nagios::Passive::ResultPath
object.  Which object is created depends on the keys of the hash
you supply to the the create method.

=head1 FACTORY METHODS

=head2 create( %ARGS )

If there is a key named

=over 4

=item * C<checkresults_dir>, a Nagios::Passive::ResultPath

=item * C<command_file>, a Nagios::Passive::CommandFile

=item * C<gearman>, a Nagios::Passive::Gearman

=back

object ist created.

If you're using checkresults_dir, you may also wan't to take a look at
L<Nagios::Passive::BulkResult>.

The gearman constructor also accepts a C<key> for the
optional shared secret.

Other required keys are C<host_name> and C<check_name>.

C<host_name> is the hostname for which you want to report a check
result to nagios.

The typical output of a nagios plugin looks like this:

    CHECK_NAME STATUS - MESSAGE

CHECK_NAME is replaced by C<check_name>. MESSAGE is replaced by
C<output>.

STATUS can either be set by setting C<return_code> to 0,1,2 or 3
(See nagios documentation for details) or by using the
C<set_thresholds> and C<set_status> methods. return_code
default's to 0 if not set somehow.

C<service_description> is optional, if it's omitted the
check result belongs to the host check of host_name.

All of the attributes (except the required ones) can also be set
afterwards, by calling the setter methods of the same name, i.e.:

  $nw->return_code(0);
  $nw->output("everything ok");
  # results to: CHECK_NAME OK - everything ok

=head1 METHODS

On the object you gathered from the C<create> method, you can
perform the following operations.

=head2 output STRING

Sets MESSAGE to STRING. If STRING is omitted, it returns
the current value of output.

=head2 add_output STRING

Equivalent to:

  $nw->output($nw->output . STRING)

=head2 set_thresholds HASH

  $nw->set_thresholds(
     warning => ':91',
     critical => ':97',
  );

This creates a Nagios::Plugin::Threshold object. It can be used
to set the C<return_code> with C<set_status>.

=head2 set_status VALUE

Sets the C<return_code> according the the threshold object
created with set_thresholds and the given VALUE. For example:

   $nw->set_thresholds(warning => ':4', critical => ':8');
   $nw->set_status(6);
   $nw->output("6 is a warning");
   # return_code is now 1, and the output shown in nagios will be
   # CHECK_NAME WARNING - 6 is a warning

=head2 add_perf HASH

This can be used to add performance data to the check result.
Read L<Nagios::Plugin::Performance> to get the idea of how to use
this.

=head2 submit

This writes the data out. In case of the CommandFile this will
write the result into nagios' external_command_file. In case of
ResultPath this will drop a file into nagios' check_result_path.

=head1 LIMITATIONS

This module is in an early stage of development, the API is
likely to brake in the future.

Nagios::Passive::ResultPath interacts with an undocumented feature of Nagios.
This feature may disappear in the future.
(Well, that feature works for years now, so ....)

=head1 DEVELOPMENT

Development takes place on github:

L<http://github.com/datamuc/Nagios-Passive>

=head1 AUTHOR

Danijel Tasov, <data@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2009, Danijel Tasov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
