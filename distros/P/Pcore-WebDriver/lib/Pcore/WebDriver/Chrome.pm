package Pcore::WebDriver::Chrome;

use Pcore -class;

with qw[Pcore::WebDriver];

# https://sites.google.com/a/chromium.org/chromedriver/capabilities

sub get_cmd ($self) {
    if ($MSWIN) {
        return [ $ENV->share->get( $MSWIN ? '/bin/webdriver/chromedriver.exe' : '/bin/webdriver/chromedriver-linux-x64' ), "--port=$self->{port}", '--silent' ];
    }
    else {

        # '-n', 20, '-s', q["-fp /usr/share/X11/fonts/misc -screen 0 1024x768x24"]

        return [ 'xvfb-run', '-l', $ENV->share->get('/bin/webdriver/chromedriver-linux-x64'), "--port=$self->{port}", '--silent' ];
    }
}

sub get_desired_capabilities ( $self, $desired_capabilities ) {
    $desired_capabilities->{chromeOptions} = {
        args => [ 'start-maximized', 'disable-infobars', '--disable-popup-blocking', '--disable-default-apps' ],    # 'no-sandbox', 'user-data-dir'
        prefs => {                                                                                                  #
            ( $self->disable_images ? ( 'profile.default_content_setting_values.images' => 2 ) : () ),
            ( $self->enable_notifications ? () : ( 'profile.default_content_setting_values.notifications' => 2 ) ),
            ( $self->enable_flash         ? () : ( 'profile.default_content_setting_values.plugins'       => 2 ) ),
        },
    };

    return $desired_capabilities;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::WebDriver::Chrome

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
