package Test05;

#use Moose;
use MooseX::App::Simple qw(Config);
app_fuzzy 1;

option 'some_option' => (
    is            => 'rw',
    isa           => 'Bool',
    documentation => q[Enable this to do fancy stuff],
);

option 'another_option' => (
    is            => 'rw',
    isa           => 'Str',
    documentation => q[Enable this to do fancy stuff],
    required      => 1,
    cmd_env       => 'ANOTHER',
);

sub run {
    my ($self) = @_;

    warn $self->dump;
}

1;

=head1 DESCRIPTION

this is how we use this command

=cut


