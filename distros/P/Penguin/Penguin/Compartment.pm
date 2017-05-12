package Penguin::Compartment;
$VERSION = 3.00;

use Safe;

sub new {
    my ($class, %args) = @_;
    $self = { 'compartment' => new Safe,
              'shares' => { },
              'opset' => Safe::empty_opset,
            };
    bless $self, $class;
}

# if you share using 'register', then in the future,
# clients may be able to examine their own rights.  Sharing
# using other methods might not permit them to do so.
sub register {
    my ($self, %args) = @_;
    my $share = $args{'Share'};
    $self->{'compartment'}->share_from(scalar(caller), [$args{'Share'}]);
}

# unregister is not currently useful.  The compartment is
# usually destructed and recreated instead.  This may change,
# but unregister probably will too.
sub unregister {
    my ($self, %args) = @_;
    my ($share) = $args{'Share'};
    undef $self->{'shares'}->{$share};
    # reminder to myself: bother tim about unshare and clear_share.
    1;
}

sub initialize {
    my ($self, %args) = @_;
    my $opstring = $args{'Operations'} || "";
    $self->{'compartment'}->permit_only(Safe::ops_to_opset(split(/ +/, $opstring)));
    1;
}

sub execute {
    my ($self, %args) = @_;
    $code = $args{'Code'};
    $self->{'compartment'}->reval($code);
}
1;
