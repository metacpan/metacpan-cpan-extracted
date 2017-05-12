use strict;
use warnings;
package Selenium::Remote::Driver::UserAgent;
$Selenium::Remote::Driver::UserAgent::VERSION = '0.0301';
# ABSTRACT: (DEPRECATED) Use Selenium::UserAgent instead
use Moo;
use JSON;
use Cwd qw/abs_path/;
use Carp qw/croak/;
use Selenium::Remote::Driver::Firefox::Profile;


has browserName => (
    is => 'rw',
    required => 1,
    coerce => sub {
        my $browser = $_[0];

        croak 'Only chrome and firefox are supported.'
          unless $browser =~ /chrome|firefox/;
        return lc($browser)
    }
);


has agent => (
    is => 'rw',
    required => 1,
    coerce => sub {
        my $agent = $_[0];

        my @valid = qw/iphone ipad_seven ipad android_phone android_tablet/;

        croak 'invalid agent' unless grep { $_ eq $agent } @valid;
        return $agent;
    }
);


has orientation => (
    is => 'rw',
    coerce => sub {
        croak 'Invalid orientation; please choose "portrait" or "landscape'
          unless $_[0] =~ /portrait|landscape/;
        return $_[0];
    },
    default => 'portrait'
);

has _firefox_options => (
    is => 'ro',
    lazy => 1,
    builder => sub {
        my ($self) = @_;

        my $dim = $self->_get_size;

        my $profile = Selenium::Remote::Driver::Firefox::Profile->new;
        $profile->set_preference(
            'general.useragent.override' => $self->_get_user_agent
        );

        return {
            firefox_profile => $profile
        };
    }
);

has _chrome_options => (
    is => 'ro',
    lazy => 1,
    builder => sub {
        my ($self) = @_;

        my $size = $self->_get_size_for('chrome');

        return {
            chromeOptions => {
                'args' => [
                    'user-agent=' . $self->_get_user_agent,
                    'window-size=' . $size
                ],
                'excludeSwitches'   => [
                    'ignore-certificate-errors'
                ]
            }
        }
    }
);

has _specs => (
    is => 'ro',
    builder => sub {
        my $devices_file = abs_path(__FILE__);
        $devices_file =~ s/UserAgent\.pm$/devices.json/;

        my $devices;
        {
            local $/ = undef;
            open (my $fh, "<", $devices_file);
            $devices = from_json(<$fh>);
            close ($fh);
        }

        return $devices;
    }
);


sub caps {
    my ($self, %args) = @_;

    my $options = $self->_desired_options(%args);

    return {
        inner_window_size => $self->_get_size_for('caps'),
        desired_capabilities => {
            browserName => $self->browserName,
            %$options
        }
    };
}

sub _desired_options {
    my ($self, %args) = @_;

    my $options;
    if ($self->_is_chrome) {
        $options = $self->_chrome_options;
    }
    elsif ($self->_is_firefox) {
        $options = $self->_firefox_options;

        unless (%args && exists $args{unencoded} && $args{unencoded}) {
            $options->{firefox_profile} = $options->{firefox_profile}->_encode;
        }
    }

    return $options;
}

sub _get_user_agent {
    my ($self) = @_;

    my $specs = $self->_specs;
    my $agent = $self->agent;

    return $specs->{$agent}->{user_agent};
}

sub _get_size {
    my ($self) = @_;

    my $specs = $self->_specs;
    my $agent = $self->agent;
    my $orientation = $self->orientation;

    return $specs->{$agent}->{$orientation};
}

sub _get_size_for {
    my ($self, $format) = @_;
    my $dim = $self->_get_size;

    if ($format eq 'caps') {
        return [ $dim->{height}, $dim->{width} ];
    }
    elsif ($format eq 'chrome') {
        return $dim->{width} . ',' . $dim->{height};
    }
}

sub _is_firefox {
    return shift->browserName =~ /firefox/i
}

sub _is_chrome {
    return shift->browserName =~ /chrome/i
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Selenium::Remote::Driver::UserAgent - (DEPRECATED) Use Selenium::UserAgent instead

=head1 VERSION

version 0.0301

=head1 SYNOPSIS

    my $dua = Selenium::Remote::Driver::UserAgent->new(
        browserName => 'chrome',
        agent => 'iphone'
    );

    my $caps = $dua->caps;
    my $driver = Selenium::Remote::Driver->new_from_caps(%$caps);

=head1 DESCRIPTION

DEPRECATED! This module has been renamed to L<Selenium::UserAgent>,
and future development will take place there. This module will
eventually be deleted from the CPAN.

This package will help you test your websites on mobile devices by
convincing your browsers to masquerade as a mobile device. You can
start up Firefox or Chrome with the same user agents that your mobile
browsers would send, along with the same screen resolution and layout.

Although the experience may not be 100% the same as manually testing
on an actual mobile device, the advantage of testing this way is that
you hardly need any additional infrastructure if you've already got a
webdriver testing suite set up.

NB: There is a bug in v2.42.2 of the Selenium standalone server for
Retina displays, like on MacBook Pros: the scaling for Firefox will be
doubled in both the width and height dimensions. You can either use an
older version of the standalone server or wait for a new release.

=head1 ATTRIBUTES

=head2 browserName

Required: specify which browser type to use. Currently, we only
support C<Chrome> and C<Firefox>.

    my $dua = Selenium::Remote::Driver::UserAgent->new(
        browserName => 'chrome',
        agent => 'ipad'
    );

=head2 agent

Required: specify which mobile device type to emulate. Your options
are:

    iphone
    ipad_seven
    ipad
    android_phone
    android_tablet

Usage looks like:

    my $dua = Selenium::Remote::Driver::UserAgent->new(
        browserName => 'chrome',
        agent => 'ipad_seven'
    );

=head2 orientation

Optional: specify the orientation of the mobile device. Your options
are C<portrait> or C<landscape>; defaults to C<portrait>.

=head1 METHODS

=head2 caps

Call this after initiating the ::UserAgent object to get the
capabilities that you should pass to S::R::D's's
L<Selenium::Remote::Driver/new_from_caps> function. This function
returns a hashref with the following keys:

=over 4

=item inner_window_size - this will set the window size immediately
after browser creation

=item desired_capabilities - this will set the browserName and the
appropriate options needed

=back

If you're using Firefox and you'd like to continue editing the Firefox
profile before passing it to the Driver, pass in C<unencoded => 1>
as the argument to this function.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/gempesaw/Selenium-Remote-Driver-UserAgent/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Daniel Gempesaw <gempesaw@gmail.com>

=cut
