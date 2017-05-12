package Net::YahooMessenger::Login;
use base 'Net::YahooMessenger::Event';
use Crypt::PasswdMD5;
use strict;

sub id {
    my $self = shift;
    $self->_set_by_name( 'ID', shift ) if @_;
    $self->_get_by_name('ID');
}

sub password {
    my $self     = shift;
    my $password = shift;
    $self->_set_by_name( 'CRYPTED_PASSWORD',
        unix_md5_crypt( $password, $self->YMSG_SALT ) );
}

sub from {
    my $self = shift;
    $self->_set_by_name( 'NICKNAME', shift ) if @_;
    $self->_get_by_name('NICKNAME');
}

sub hide {
    my $self  = shift;
    my $value = shift;
    if ($value) {
        $self->option( $self->HIDE_LOGIN );
    }
    else {
        $self->option( $self->DEFAULT_OPTION );
    }
}

sub code {
    return 1;
}

sub to_string {
    my $self = shift;
    "I'm login Yahoo!Messenger server";
}

1;
__END__
