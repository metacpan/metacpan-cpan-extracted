package Sys::Syslog::OO;

use strict;
use Sys::Syslog qw(:DEFAULT setlogsock);
use Carp;

our $VERSION = '1.00';

sub new {

    my ($class, $opts) = (@_);

    croak "Sys::Syslog::OO - Must pass in a hash ref of options!" 
        unless ref($opts) eq 'HASH';

    croak "Sys::Syslog::OO - Missing logging facility!" 
        if ! defined $opts->{'facility'};

    my $label = "";

    if (exists $opts->{'label'}) {
        $label = $opts->{'label'};
    }
    else {
        $label = $0;
        $label =~ s#.*/##;
    }

    if ((exists $opts->{'host'}->{'ip'}) &&
        (defined $opts->{'host'}->{'ip'})) {

        setlogsock($opts->{'host'}->{'proto'});
        $Sys::Syslog::host = $opts->{'host'}->{'ip'};
        openlog($label, 'ndelay pid', $opts->{'facility'});

    } 
    else {
        openlog($label, 'pid', $opts->{'facility'});
    }

    return bless $opts, $class;

}

sub debug {
    my ($self, $msg) = @_;
    $self->logger('debug', $msg);
}

sub verbose {
    my ($self, $msg) = @_;
    $self->info($msg);
}

sub info {
    my ($self, $msg) = @_;
    $self->logger('info', $msg);
}

sub error {
    my ($self, $msg) = @_;
    $self->logger('err', $msg);
}

sub warn {
    my ($self, $msg) = @_;
    $self->logger('warn', $msg);
}

sub notice {
    my ($self, $msg) = @_;
    $self->logger('notice', $msg);
}

sub alert {
    my ($self, $msg) = @_;
    $self->logger('alert', $msg);
}

sub logger {
    my ($self, $level, $msg) = (@_);
    syslog("${level}|$self->{'facility'}", '%s', "\U$level\E $msg");

}

1;

=pod

=head1 NAME

Sys::Syslog::OO - Thin object-oriented wrapper around Sys::Syslog::OO

=head1 SYNOPSIS

  package My::Cool::Package;

  use Sys::Syslog::OO;
  use base qw(Sys::Syslog::OO);

  sub new {

      my ($class, $cfg) = @_;

      my $facility = 'LOG_LOCAL7';

      if (exists $cfg->{'syslog_facility'}) {
          $facility = $cfg->{'syslog_facility'};
      }

      my $self = $class->SUPER::new({'label'    => 'mycoolprogram',
                                     'facility' => $facility });
      # ... other initialization code ...

      return $self;
  }

=head1 DESCRIPTION

Thin OO-wrapper around Sys::Syslog.  Why?  Less chance of mis-typing
log levels and less noisy code.  Can also be used with multiple-inheritence
to add logging to a new or existing class.

=head1 THANKS

Special thanks to Mike Fischer, Jason Livingood, and Comcast for allowing
me to contribute this code to the OSS community.

=head1 AUTHOR

Max Schubert E<lt>maxschube@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2009 by Max Schubert / Comcast

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
