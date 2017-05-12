package App::Sque::Command::send;
$App::Sque::Command::send::VERSION = '0.010';
use App::Sque -command;
use Sque;

# ABSTRACT: Send command for sque command-line tool

sub usage_desc { "Send sque message." }

sub opt_spec {
    return (
        [ "class|c=s",  "Worker class to process message" ],
        [ "host|h=s",  "Set the stomp host" ],
        [ "port|p=i",  "Set the stomp port" ],
        [ "queue|q=s",  "Queue to send message to, defaults to worker class" ],
    );
}

sub validate_args {
    my ($self, $opt, $args) = @_;

    # We must have the host/part
    $self->usage_error("host required") unless $opt->{host};
    $self->usage_error("port required") unless $opt->{port};

    # We must have class
    $self->usage_error("class required") unless $opt->{class};

    $self->usage_error("at least on arg required") unless @$args > 0;
}

sub execute {
    my ($self, $opt, $args) = @_;

    if( ! defined $opt->{queue} ){
        $opt->{queue} = $opt->{class};
        $opt->{queue} =~ s/://g;
    }

    Sque->new( stomp => "$opt->{host}:$opt->{port}" )
        ->push( $opt->{queue} => { class => $opt->{class}, args => $args });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Sque::Command::send - Send command for sque command-line tool

=head1 VERSION

version 0.010

=head1 AUTHOR

William Wolf <throughnothing@gmail.com>

=head1 COPYRIGHT AND LICENSE


William Wolf has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut
