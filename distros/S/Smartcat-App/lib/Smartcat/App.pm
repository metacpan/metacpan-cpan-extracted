
=begin comment

Smartcat App

A simple command line application which allows to sync local files and Smartcat project content.

=end comment

=cut

use strict;
use warnings;

package Smartcat::App;

use App::Cmd::Setup -app;

use Class::Load;
use Data::Dumper;
use File::Copy qw/copy/;
use File::Spec::Functions qw(catfile);
use IO::Uncompress::Unzip qw($UnzipError);
use JSON qw/encode_json/;

use Smartcat::Client::ProjectApi;
use Smartcat::Client::DocumentApi;
use Smartcat::Client::DocumentExportApi;

use Smartcat::Client::Object::BilingualFileImportSetingsModel;
use Smartcat::Client::Object::CreateDocumentPropertyModel;
use Smartcat::Client::Object::UploadDocumentPropertiesModel;

use Smartcat::App::ProjectApi;
use Smartcat::App::DocumentApi;
use Smartcat::App::DocumentExportApi;

use Smartcat::App::Config;
use Log::Log4perl qw(:easy);
use Log::Any qw($log);
use Log::Any::Adapter;

our $VERSION = '0.0.1';

sub init {
    my $self = shift;

    $self->{api} = Smartcat::Client::ApiClient->new(
        username => $self->{config}->username,
        password => $self->{config}->password
    );

    my $log_level = "INFO";
    if ( defined $self->{rundata}->{debug} ) {
        $log_level = "DEBUG";
        print "*** DEBUG mode is turned on ***\n";
    }

    my $appender = "";
    my $filter   = <<"EOT";
log4perl.filter.MatchWarnInfoDebug = Log::Log4perl::Filter::LevelRange
log4perl.filter.MatchWarnInfoDebug.LevelMin = DEBUG
log4perl.filter.MatchWarnInfoDebug.LevelMax = WARN
log4perl.appender.screen.Filter = MatchWarnInfoDebug
EOT
    my $logger = "";
    if ( defined $self->{config}->log && $self->{config}->log ne "" ) {
        print "*** Printing to '$self->{config}->{log}' log file ***\n";
        $logger   = ", file";
        $appender = <<"EOT";
log4perl.appender.file = Log::Log4perl::Appender::File
log4perl.appender.file.filename = $self->{config}->{log}
log4perl.appender.file.mode = append
log4perl.appender.file.layout = PatternLayout
log4perl.appender.file.layout.ConversionPattern = [%d] %p> %m%n
EOT
        $filter = <<"EOT";
log4perl.filter.MatchWarnInfo = Log::Log4perl::Filter::LevelRange
log4perl.filter.MatchWarnInfo.LevelMin = INFO
log4perl.filter.MatchWarnInfo.LevelMax = WARN
log4perl.appender.screen.Filter = MatchWarnInfo
EOT

    }

    Log::Log4perl->init( \ <<"EOT");
log4perl.logger = $log_level, screen $logger

log4perl.appender.screen = Log::Log4perl::Appender::Screen
log4perl.appender.screen.stderr = 0
log4perl.appender.screen.layout = PatternLayout
log4perl.appender.screen.layout.ConversionPattern = %m%n
$filter

$appender

EOT

    Log::Any::Adapter->set('Log::Log4perl');
}

sub new {
    my ( $class, $arg ) = @_;

    my $self = $class->SUPER::new($arg);
    $self->{config}  = Smartcat::App::Config->load;
    $self->{rundata} = {};

    return $self;
}

sub project_api {
    my $self = shift @_;

    $self->{project_api} =
      Smartcat::App::ProjectApi->new( $self->{api}, $self->{rundata} )
      unless defined $self->{project_api};
    return $self->{project_api};
}

sub document_api {
    my $self = shift @_;

    $self->{document_api} =
      Smartcat::App::DocumentApi->new( $self->{api}, $self->{rundata} )
      unless defined $self->{document_api};
    return $self->{document_api};
}

sub document_export_api {
    my $self = shift @_;

    $self->{document_export_api} =
      Smartcat::App::DocumentExportApi->new( $self->{api}, $self->{rundata} )
      unless defined $self->{document_export_api};
    return $self->{document_export_api};
}

1;
__END__

=encoding utf-8

=head1 NAME

Smartcat::App - Smartcat cli application

=head1 SYNOPSIS

  use Smartcat::App;

=head1 DESCRIPTION

Smartcat::App is a simple application which use Smartcat Integration API to sync local translation files with Smartcat project content.

=head1 AUTHOR

Taras Semenenko E<lt>taras.semenenko@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2018- Taras Semenenko

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

  Smartcat::Client

=cut
