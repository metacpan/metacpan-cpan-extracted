package Pcore::WebDriver::Firefox;

use Pcore -class;

with qw[Pcore::WebDriver];

# https://github.com/mozilla/geckodriver
# https://developer.mozilla.org/en-US/docs/Mozilla/QA/Marionette/WebDriver/status

sub get_cmd ($self) {
    return [ $ENV->share->get( $MSWIN ? '/bin/webdriver/geckodriver.exe' : '/bin/webdriver/geckodriver-linux-x64/geckodriver' ), '--host', $self->{host}, '--port', $self->{port}, '--log', 'debug' ];
}

sub get_desired_capabilities ( $self, $desired_capabilities ) {
    $desired_capabilities->{'moz:firefoxOptions'} = {
        binary => q[],
        args   => ['--devtools'],
    };

    return $desired_capabilities;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::WebDriver::Firefox

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
