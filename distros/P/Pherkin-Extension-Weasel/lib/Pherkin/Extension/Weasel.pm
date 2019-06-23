
=head1 NAME

Pherkin::Extension::Weasel - Pherkin extension for web-testing

=head1 VERSION

0.07

=head1 SYNOPSIS

   # In the pherkin config file t/.pherkin.yaml:
   default:
     extensions:
       Pherkin::Extension::Weasel:
         default_session: selenium
         screenshots_dir: img
         screenshot_events:
            pre_step: 1
            post_scenario: 1
         sessions:
            selenium:
              base_url: http://localhost:5000
              driver:
                drv_name: Weasel::Driver::Selenium2
                wait_timeout: 3000
                window_size   1024x1280
                caps:
                   port: 4420

  # Which makes the S->{ext_wsl} field available,
  # pointing at the default session, in steps of features or scenarios
  # marked with the '@weasel' tag so in the steps you can use:

  use Weasel::FindExpanders::HTML;

  Then qr/I see an input element with label XYZ/, sub {
    S->{ext_wsl}->page->find('*labeled', text => 'XYZ');
  };

=cut

package Pherkin::Extension::Weasel;

use strict;
use warnings;

our $VERSION = '0.07';


use File::Share ':all';
use Digest::MD5 qw(md5_hex);
use Module::Runtime qw(use_module);
use Template;
use Test::BDD::Cucumber::Extension;

use Weasel;
use Weasel::Session;

use Moose;
extends 'Test::BDD::Cucumber::Extension';


has _log => (is => 'rw', isa => 'Maybe[HashRef]');

has _weasel_log => (is => 'rw', isa => 'Maybe[ArrayRef]');

has feature_template => (is => 'ro', isa => 'Str',
                         default => 'pherkin-weasel-html-log-default.html');

has logging_dir => (is => 'ro', isa => 'Maybe[Str]');

has templates_dir => (is => 'ro', isa => 'Str',
                      default => sub {
                          my $dist = __PACKAGE__;
                          $dist =~ s/::/-/g;
                          return dist_dir $dist;
                      });


sub _weasel_log_hook {
    my $self = shift;
    my ($event, $log_item, $something) = @_;
    my $log_text = (ref $log_item eq 'CODE') ? $log_item->() : $log_item;

    my $log = $self->_log;
    if ($log) {
        push @{$log->{scenario}->{rows}}, {
            log => {
                text => $log_text
            },
        };
    }
}

sub _flush_log {
    my $self = shift;
    my $log = $self->_log;
    return if ! $log || ! $log->{feature};

    my $f = md5_hex($log->{feature}->{filename}) . '.html';
    $log->{template}->process(
        $self->feature_template,
        { %{$log} }, # using the $log object directly destroys it...
        $f,
        { binmode => ':utf8' })
        or die $log->{template}->error();

    return File::Spec->catfile($self->logging_dir, $f);
}

sub _initialize_logging {
    my ($self) = @_;

    if ($self->screenshots_dir && !$self->logging_dir) {
        die "Unable to generate screenshots when logging is disabled";
    }
    if ($self->logging_dir) { # the user wants logging...
        die 'Logging directory: ' . $self->logging_dir . ' does not exist'
            if ! -d $self->logging_dir;

        $self->_log(
            {
                features => [],
                template => Template->new(
                    {
                        INCLUDE_PATH => $self->templates_dir,
                        OUTPUT_PATH => $self->logging_dir,
                    }),
            });
    }
}

=head1 Test::BDD::Cucumber::Extension protocol implementation

=over

=item step_directories

=cut

sub step_directories {
    return [ 'weasel_steps/' ];
}

=item pre_execute

=cut

sub pre_execute {
    my ($self) = @_;

    my $ext_config = $self->sessions;
    my %sessions;
    for my $sess_name (keys %{$ext_config}) {
        my $sess = $ext_config->{$sess_name};
        my $drv = use_module($sess->{driver}->{drv_name});
        $drv = $drv->new(%{$sess->{driver}});
        my $session = Weasel::Session->new(
            %$sess,
            driver => $drv,
            log_hook => sub { $self->_weasel_log_hook(@_) },
            );
        $sessions{$sess_name} = $session;
    }
    my $weasel = Weasel->new(
        default_session => $self->default_session,
        sessions => \%sessions,
            );
    $self->_weasel($weasel);
    $self->_initialize_logging;
}

=item pre_feature

=cut

sub pre_feature {
    my ($self, $feature, $feature_stash) = @_;

    my $log = $self->_log;
    if ($log) {
        my $feature_log = {
            scenarios => [],
            title => $feature->name,
            filename => $feature->document->filename,
            satisfaction => join("\n",
                                 map { $_->content }
                                 @{$feature->satisfaction})
        };
        push @{$log->{features}}, $feature_log;
        $log->{feature} = $feature_log;
    }
}

=item post_feature

=cut

sub post_feature {
    my ($self, $feature, $feature_stash) = @_;

    my $log = $self->_log;
    if ($log) {
        $self->_flush_log;
        $log->{feature} = undef;
    }
}

=item pre_scenario

=cut

sub pre_scenario {
    my ($self, $scenario, $feature_stash, $stash) = @_;

    if (grep { $_ eq 'weasel'} @{$scenario->tags}) {
        $stash->{ext_wsl} = $self->_weasel->session;
        $self->_weasel->session->start;

        my $log = $self->_log;
        if ($log) {
            my $scenario_log = {
                rows => [],
                title => $scenario->name,
            };
            push @{$log->{feature}->{scenarios}}, $scenario_log;
            $log->{scenario} = $scenario_log;
        }

        $self->_save_screenshot("scenario", "pre");
    }
}


sub post_scenario {
    my ($self, $scenario, $feature_stash, $stash) = @_;

    return if ! defined $stash->{ext_wsl};
    $self->_save_screenshot("scenario", "post");

    my $log = $self->_log;
    if ($log) {
        $self->_flush_log;
        $log->{scenario} = undef;
    }

    $stash->{ext_wsl}->stop
}

sub pre_step {
    my ($self, $step, $context) = @_;

    return if ! defined $context->stash->{scenario}->{ext_wsl};
    $self->_save_screenshot("step", "pre");
    my $log = $self->_log;
    if ($log) {
        push @{$log->{scenario}->{rows}}, {
            step => {
                text => $context->step->verb_original
                    . ' ' . $context->step->text,
            },
        };
    }
}

sub post_step {
    my ($self, $step, $context, $fail, $result) = @_;

    return if ! defined $context->stash->{scenario}->{ext_wsl};
    $self->_save_screenshot("step", "post");
    my $log = $self->_log;
    if ($log) {
        if (ref $result) {
            ${$log->{scenario}->{rows}}[-1]->{step}->{result} =
                $result->result;
        }
        else {
            ${$log->{scenario}->{rows}}[-1]->{step}->{result} =
                '<missing>'; # Pherkin <= 0.56
        }
        $self->_flush_log;
    }
}

=back

=head1 ATTRIBUTES

=over

=item default_session

=cut

has 'default_session' => (is => 'ro');

=item sessions

=cut

has 'sessions' => (is => 'ro',
                   isa => 'HashRef',
                   required => 1);

=item base_url

URL part to be used for prefixing URL arguments in steps

=cut

has base_url => ( is => 'rw', default => '' );

=item screenshots_dir

=cut

has screenshots_dir => (is => 'rw', isa => 'Str');

=item screenshot_events

=cut

has screenshot_events => (is => 'ro',
                          isa => 'HashRef',
                          default => sub { {} },
                          traits => ['Hash'],
                          handles => {
                              screenshot_on => 'set',
                              screenshot_off => 'delete',
                              screenshot_event_on => 'get',
                          },
    );

=item _weasel

=cut


has _weasel => (is => 'rw',
                isa => 'Weasel');

=back

=head1 INTERNALS

=over

=item _save_screenshot($event, $phase)

=cut

my $img_num = 0;

sub _save_screenshot {
    my ($self, $event, $phase) = @_;

    return if ! $self->screenshots_dir;
    return if ! $self->screenshot_event_on("$phase-$event");

    my $img_name = md5_hex($self->_log->{feature}->{filename}) . "-$event-$phase-" . ($img_num++) . '.png';
    if (open my $fh, ">", $self->screenshots_dir . '/' . $img_name) {
        $self->_weasel->session->screenshot($fh);
        close $fh
            or warn "Couldn't close screenshot image '$img_name': $!";
    }
    else {
        warn "Couldn't open screenshot image '$img_name': $!";
    }

    my $log = $self->_log;
    if ($log) {
        push @{$log->{scenario}->{rows}}, {
            screenshot => {
                location => $img_name,
                description => "$phase $event: ",
                classes => [ $event, $phase, "$phase-$event" ],
            },
        };
    }
}

=back


=head1 CONTRIBUTORS

Erik Huelsmann

=head1 MAINTAINERS

Erik Huelsmann

=head1 BUGS

Bugs can be filed in the GitHub issue tracker for the Weasel project:
 https://github.com/perl-weasel/weasel-driver-selenium2/issues

=head1 SOURCE

The source code repository for Weasel is at
 https://github.com/perl-weasel/weasel-driver-selenium2

=head1 SUPPORT

Community support is available through
L<perl-weasel@googlegroups.com|mailto:perl-weasel@googlegroups.com>.

=head1 COPYRIGHT

 (C) 2016-2019  Erik Huelsmann

Licensed under the same terms as Perl.

=cut


1;
