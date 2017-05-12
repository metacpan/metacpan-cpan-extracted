package MojoX::Session::Store::File::Driver::FreezeThaw;

use base 'MojoX::Session::Store::File::Driver';

use FreezeThaw;

sub new {
    my $class = shift;

    bless $class->SUPER::new(@_), $class;
}

sub freeze {
    my $self = shift;

    my($file, $ref) = @_;
    $ref = \$ref unless ref $ref;

    my $frozen = FreezeThaw::freeze($ref) || return;
    open my $fh, '>', $file or return;
    print $fh $frozen;
    close $fh;

    1;
}

sub thaw {
    my $self = shift;

    my $file = shift;

    open my $fh, '<', $file or return;
    local $/;
    my $thawed = FreezeThaw::thaw(<$fh>) || return;
    close $fh;

    $thawed;
}

1;
