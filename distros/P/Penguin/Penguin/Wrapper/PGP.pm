package Penguin::Wrapper::PGP;

# Wed Apr 17 13:48:40 CDT 1996    the regular pgp dist is broken.
#                                 the following is a replacement.
use Penguin::PGP; 

sub new {
    bless { Wrapmethod => 'PGP' }, shift;
}

sub wrap {
 my ($self, %args)  = @_;
    my $pgp = new Penguin::PGP;
    my $signedtext = Sign $pgp Password => $args{'Password'}, 
                               Text     => $args{'Text'},
                               Armor    => 1;
    return $signedtext;
}

sub unwrap {
    my ($self, %args)  = @_;
    my $pgp = new Penguin::PGP;
    my $PGP_info = Decrypt $pgp Password => $args{'Password'}, 
                               Text     => $args{'Text'},
                               Armor    => 1;
    return ($PGP_info->{'Signature'}, $PGP_info->{'Text'});
}
1;
