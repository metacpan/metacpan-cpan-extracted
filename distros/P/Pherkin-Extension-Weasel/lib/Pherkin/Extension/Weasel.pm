
=head1 NAME

Pherkin::Extension::Weasel - Pherkin extension for web-testing

=head1 VERSION

0.02

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
    S->{ext_wsl}->page->find('*labelled', text => 'XYZ');
  };

=cut

package Pherkin::Extension::Weasel;

use strict;
use warnings;

our $VERSION = '0.02';


use Module::Runtime qw(use_module);
use Test::BDD::Cucumber::Extension;

use Weasel;
use Weasel::Session;

use Moose;
extends 'Test::BDD::Cucumber::Extension';


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
        my $session = Weasel::Session->new(%$sess, driver => $drv);
        $sessions{$sess_name} = $session;
    }
    my $weasel = Weasel->new(
        default_session => $self->default_session,
        sessions => \%sessions);
    $self->_weasel($weasel);
}


=item pre_scenario

=cut

sub pre_scenario {
    my ($self, $scenario, $feature_stash, $stash) = @_;

    if (grep { $_ eq 'weasel'} @{$scenario->tags}) {
        $stash->{ext_wsl} = $self->_weasel->session;
        $self->_weasel->session->start;

        $self->_save_screenshot("scenario", "pre");
    }
}


sub post_scenario {
    my ($self, $scenario, $feature_stash, $stash) = @_;

    return if ! defined $stash->{ext_wsl};
    $self->_save_screenshot("scenario", "post");
    $stash->{ext_wsl}->stop
}

sub pre_step {
    my ($self, $feature, $context) = @_;

    return if ! defined $context->stash->{scenario}->{ext_wsl};
    $self->_save_screenshot("step", "pre");
}

sub post_step {
    my ($self, $feature, $context) = @_;

    return if ! defined $context->stash->{scenario}->{ext_wsl};
    $self->_save_screenshot("step", "post");
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

    my $img_name = "$event-$phase-" . ($img_num++) . '.png';
    open my $fh, ">", $self->screenshots_dir . '/' . $img_name;
    $self->_weasel->session->screenshot($fh);
    close $fh;
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

 (C) 2016  Erik Huelsmann

Licensed under the same terms as Perl.

=cut


1;
