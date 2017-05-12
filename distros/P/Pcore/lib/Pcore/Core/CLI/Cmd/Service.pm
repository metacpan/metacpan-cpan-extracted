package Pcore::Core::CLI::Cmd::Service;

use Pcore -class;

with qw[Pcore::Core::CLI::Cmd];

sub CLI ($self) {
    return {
        abstract => 'manage service',
        name     => 'service',
        opt      => {
            name => {
                short => undef,
                desc  => 'service name',
                isa   => 'Str',
                min   => 1,
            }
        },
        arg => [ action => { isa => [qw[install]], } ],
    };
}

sub CLI_RUN ( $self, $opt, $arg, $rest ) {
    $self->_install_service( $opt->{name} ) if $arg->{action} eq 'install';

    exit;
}

sub _install_service ( $self, $service_name ) {
    if ($MSWIN) {
        my $wrapper = $ENV->share->get('/bin/nssm_x64.exe');

        P->pm->run_proc( [ $wrapper, 'install', $service_name, $^X, $ENV->{SCRIPT_PATH} ] ) or die;
    }
    else {
        my $TMPL = <<"TXT";
[Unit]
After=network.target

[Service]
ExecStart=/bin/bash -c ". /etc/profile; exec $ENV->{SCRIPT_PATH}"
Restart=always

[Install]
WantedBy=multi-user.target
TXT
        P->file->write_text( qq[/etc/systemd/system/$service_name.service], { mode => q[rw-r--r--], umask => q[rw-r--r--] }, $TMPL );
    }

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::CLI::Cmd::Service

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
