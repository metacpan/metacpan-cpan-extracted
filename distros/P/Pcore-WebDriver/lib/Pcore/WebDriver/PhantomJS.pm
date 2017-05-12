package Pcore::WebDriver::PhantomJS;

use Pcore -class;

with qw[Pcore::WebDriver];

sub get_cmd ($self) {
    my $cmd = [ $ENV->share->get( $MSWIN ? '/bin/webdriver/phantomjs.exe' : '/bin/webdriver/phantomjs-linux-x64/bin/phantomjs' ), "--webdriver=$self->{host}:$self->{port}", '--webdriver-loglevel=NONE' ];

    push $cmd->@*, '--load-images=false' if $self->disable_images;

    return $cmd;
}

sub get_desired_capabilities ( $self, $desired_capabilities ) {
    $desired_capabilities->{PHANTOMJS}->{'phantomjs.page.settings.userAgent'} = $self->useragent if $self->useragent;

    return $desired_capabilities;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::WebDriver::PhantomJS

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
