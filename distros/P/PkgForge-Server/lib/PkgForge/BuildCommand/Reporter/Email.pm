package PkgForge::BuildCommand::Reporter::Email;    # -*-perl-*-
use strict;
use warnings;

# $Id: Email.pm.in 17916 2011-08-05 08:51:50Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 17916 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge-Server/PkgForge_Server_1_1_10/lib/PkgForge/BuildCommand/Reporter/Email.pm.in $
# $Date: 2011-08-05 09:51:50 +0100 (Fri, 05 Aug 2011) $

our $VERSION = '1.1.10';

use English qw(-no_match_vars);
use File::Spec ();
use MIME::Lite::TT ();
use Sys::Hostname ();
use Template ();
use Try::Tiny;

use overload q{""} => sub { shift->stringify };

use Moose;
use MooseX::Types::Moose qw(Str HashRef);

with 'PkgForge::BuildCommand::Reporter';

has 'report_from' => (
  is       => 'ro',
  isa      => Str,
  required => 1,
  default  => sub {
    my $hostname = Sys::Hostname::hostname();
    return 'pkgforge@' . $hostname;
  },
  documentation => 'The From address for the email report',
);

has 'template' => (
  is        => 'ro',
  isa       => 'Str|ScalarRef[Str]',
  required  => 1,
  builder   => 'build_template',
  documentation => 'The template for the email report',
);

has 'subject' => (
  is       => 'ro',
  isa      => Str,
  required => 1,
  builder  => 'build_subject',
  documentation => 'The subject for the email report',
);

has 'options' => (
  is      => 'ro',
  isa     => HashRef,
  default => sub { {} },
  documentation => 'A hash of extra options to pass into the template',
);

no Moose;
__PACKAGE__->meta->make_immutable;

sub build_subject {
  my ($self) = @_;

  my $subject = 'PkgForge [% IF buildinfo.completed %][OK][% ELSE %][FAIL][% END %] - [% buildinfo.platform %]/[% buildinfo.architecture %] - [% job.id %]';

  return $subject;
}

sub build_template {
  my ($self) = @_;

  my $template = \<<'EOT';
[%- USE date -%]
Package Forge Build Report for [% job.id %] on [% buildinfo.platform %]/[% buildinfo.architecture %]

[% IF buildinfo.completed -%]
Task build and submission successful. The following packages were generated:
[% ELSE -%]
[% IF buildinfo.built_successfully -%]
Task built successfully but submission failed. The following packages were generated:
[% ELSE -%]
Build failure. The following packages failed to build:
[% END -%]
[% END -%]

[% IF buildinfo.built_successfully -%]
[% FOREACH pkg IN buildinfo.products -%]
[% pkg | file_basename %]
[% END -%]
[% ELSE -%]
[% FOREACH pkg IN buildinfo.failures -%]
[% pkg | file_basename %]
[% END -%]
[% END -%]

Build Information
=================

Build Daemon:    [% buildinfo.builder %]
Hostname:        [% buildinfo.hostname %]
Platform:        [% buildinfo.platform %]
Architecture:    [% buildinfo.architecture %]
Submitter:       [% job.submitter %]
Submission Time: [% date.format( job.subtime, '%A %d %B %Y, %H:%M:%S' ) %]

-- 

You were sent this job status report from the Package Forge build
service, running on [% buildinfo.hostname %], because it was requested by you
(or someone else on your behalf).

EOT

  return $template;
}

sub run {
  my ( $self, $job, $buildinfo, $buildlog ) = @_;

  my $logger = $buildlog->logger;

  if ( !$job->report_required ) {
    return;
  }

  my ( $to, @cc ) = $job->report_list;
  my $cc = join q{, }, @cc;

  my %params = (
    buildinfo => $buildinfo,
    job       => $job,
  );

  my $tt_options = $self->options;
  $tt_options->{FILTERS}{file_basename} =
    sub {
      my ($path) = @_;
      my $basename = ( File::Spec->splitpath($path) )[2];
      return $basename;
  };

  # Pass the message subject through Template Toolkit processor

  my $subject = $self->subject;
  try {
    my $new_subject;

    my $tt = Template->new($tt_options) or die $Template::ERROR . "\n";
    $tt->process( \$subject, \%params, \$new_subject )
      or die $tt->error() . "\n";
    $subject = $new_subject;
  } catch {
    $logger->error("Failed to process the message subject: $_");
    $subject = "PkgForge Report - $job";
  };

  my $msg = MIME::Lite::TT->new(
    From        => $self->report_from,
    To          => $to,
    Cc          => $cc,
    References  => "pkgforge-$job",
    Subject     => $subject,
    Template    => $self->template,
    TmplParams  => \%params,
    TmplOptions => $tt_options,
    TmplUpgrade => 1,
    'X-PkgForge-Status'  => ( $buildinfo->completed ? 'success' : 'fail' ),
    'X-PkgForge-Builder' => $buildinfo->builder,
    'X-PkgForge-ID'      => $job->id,
  );

  my $send_ok = $msg->send();
  if ( !$send_ok ) {
    $logger->error("Failed to send report email for '$subject'");
  }

  return $send_ok;
}

1;
__END__
