package RunApp::Apache;
use strict;
use File::Spec::Functions qw(catfile catdir);
use base qw(RunApp); # child of RunApp because of build
use File::Copy qw(copy);
use File::Path;

sub get_info {
  my $self = shift;
  my $info;
  my $ret = `$self->{httpd} -V`;

  ($info->{AP_VERSION}) = $ret =~ m{version: Apache/(\d)};
  for ($ret =~ m/-D\s*(\S*)/mg) {
      my ($key, $value) = m/^(\w+)(?:="?(.*?)"?)?$/;
      die $_ unless defined $key;
      $info->{$key} = defined $value ? $value : 1;
  }

  if ($self->{apxs}) {
    $info->{$_} = $self->ap_query ($_) for @_;
  }

  return $info;
}

sub ap_query {
    my ($self, $var) = @_;
    my $ret = `$self->{apxs} -q $var`;
    chomp $ret;
    return $ret;
}

sub new {
  my $class = shift;
  my $self = bless {}, $class;
  %$self = @_;
  my %ctlarg;

  if ($self->{apxs}) {
    my $httpd = catfile($self->ap_query ('SBINDIR'), $self->ap_query ('TARGET'));
    if (defined $self->{httpd} && $self->{httpd} ne $httpd) {
      warn ". Warning: httpd setting disagreed with apxs\n";
    }
    $self->{httpd} = $httpd;
  }

  $self->{ctl_file} = catfile($self->{root}, "apachectl");
  $self->{config_file} = catfile($self->{root}, "conf", 'httpd.conf');
  $self->{mime_file} ||= catfile($self->{root}, "conf", 'mime.types');

  $self->{CONF} ||= 'RunApp::Template::Apache';
  unless ($self->{CTL}) {
    $self->{CTL} = 'RunApp::Control::AppControl';
    %ctlarg = ( args => ['-f', $self->{config_file}],
		binary => $self->{httpd},
		CONTROL => 'App::Control::Apache',
	      );
  }
  $self->load($_) for @{$self}{qw/CONF CTL/};

  $self->services ( conf => $self->{CONF}->new (file => $self->{config_file}),
		    ctl => $self->{CTL}->new (file => $self->{ctl_file}, %ctlarg)
		  );
  return $self;
}

sub build {
  my ($self, $conf) = @_;

  my $info = $self->get_info ('LIBEXECDIR');
  undef $conf->{logs} if ref $conf->{logs}; # XXX: something else
  $conf->{logs} ||= catfile($self->{root}, 'logs');
  $conf->{pidfile} ||= catfile($conf->{logs}, 'httpd.pid');
  $self->{_debug} = catfile($conf->{logs}, 'error_log');

  mkpath [catfile ($self->{root}, 'conf'),
	  $conf->{logs}] or die $!
    unless -d $self->{root};

  my $apacheconf = {
                    MinSpareServers => 2,
                    MaxSpareServers => 2,
                    StartServers => 2,
                    MaxClients => 100,
                    MaxRequestsPerChild => 100,
                    user => (getpwuid($>) || ''),
                    group => (getgrgid($)) || ''),
                   };
  # final tweak
  my $combined = {%$apacheconf, %$self, %$conf, %$info};
  # they don't like multi-request in a process.
  $combined->{MaxRequestsPerChild} = 1 if $combined->{cover} || $combined->{profiler};

  $self->SUPER::build ($combined);
  my $mimefile = $info->{TYPES_CONFIG_FILE} || $info->{AP_TYPES_CONFIG_FILE};
  $mimefile = catfile($info->{HTTPD_ROOT}, $mimefile)
      unless File::Spec->file_name_is_absolute( $mimefile );

  if (-r $mimefile) {
      copy ($mimefile, $self->{mime_file});
  }
  else {
      warn ". Warning: cant find $mimefile\n";
  }

  chmod 0755, $self->{ctl_file};
}

sub report {
  my ($self, $conf) = @_;
  return unless $self->{report};
  print "Point your browser at the following URL to see the website:\n";
  for (qw/port port_https/) {
    next unless $conf->{$_};
    print "http://$conf->{hostname}:$conf->{$_}/\n";
  }
}

sub debug {
  my ($self) = @_;
  return unless $self->{_debug};
  if (fork) {
    return;
  }
  else {
    system ('tail', -f => $self->{_debug});
    exit;
  }
}

sub dispatch {
  my ($self, $cmd) = @_;
  #warn ". $cmd => $self->{httpd}\n";
  $self->{services}->{ctl}->$cmd;
}

1;

=head1 NAME

RunApp::Apache - Apache control for RunApp

=head1 SYNOPSIS

 use RunApp::Apache;

 $apache = RunApp::Apache->new
	    (root => "/tmp/apache_run",
	     report => 1,
	     apxs => '/usr/local/sbin/apxs',
	     # httpd => '/usr/local/sbin/httpd',
	     required_modules => ["log_config", "alias", "perl", "mime"],
	     config_block => q{
 [% IF AP_VERSION == 2 %]
  eval { use Apache2 };
  eval { use Apache::compat };
 [% END %]

 <Location /myapp>
  AllowOverride None
  SetHandler perl-script
  PerlSetVar approot [% cwd %]
  PerlHandler MyApp
  Options +ExecCGI
 </Location>
 });

=head1 DESCRIPTION

This is the class for defining a apache web server to be used in
L<RunApp>.

=head1 CONSTRUCTOR

=head2 new (%arg)

Required arg:

=over

=item root

The root for the apache instance.

=item apxs

=item httpd

If C<apxs> is specified, C<httpd> will be derived from it.

=item required_modules

A arrayref to the apache modules required.

=item config_block

The config block that will be the I<extra> block in the template used
by L<RunApp::Template::Apache>.

=item CTL

The class for handling apachectl.  The default is
L<RunApp::Control::AppControl>.  You can also use
L<RunApp::Control::ApacheCtl>.

=item CONF

The class for handling apache config.  The default is
L<RunApp::Template::Apache>.  It is used in the C<build> phase of
L<RunApp>

=back

=cut

=head1 SEE ALSO

L<RunApp>, L<RunApp::Control::Apache>, L<RunApp::Template::Apache>, L<App::Control>

=head1 AUTHORS

Chia-liang Kao <clkao@clkao.org>

Refactored from works by Leon Brocard E<lt>acme@astray.comE<gt> and
Tom Insam E<lt>tinsam@fotango.comE<gt>.

=head1 COPYRIGHT

Copyright (C) 2002-5, Fotango Ltd.

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut

1;
