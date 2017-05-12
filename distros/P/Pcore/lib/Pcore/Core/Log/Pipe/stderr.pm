package Pcore::Core::Log::Pipe::stderr;

use Pcore -class;

extends qw[Pcore::Core::Log::Pipe];

sub _build_is_text_ansi ($self) {
    return -t $STDERR_UTF8 ? 1 : 0;    ## no critic qw[InputOutput::ProhibitInteractiveTest]
}

sub sendlog ( $self, $header, $data, $tag ) {
    say {$STDERR_UTF8} $header . $data;

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::Log::Pipe::stderr

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
