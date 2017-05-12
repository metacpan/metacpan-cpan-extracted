package Razor2::Engine::VR8;
use Razor2::Signature::Whiplash;
use Razor2::String qw(hextobase64);
use Data::Dumper;

sub new {
    
    my ($class, %args) = @_;

    my $self = bless {
        description      => 'whiplash',
        has_greet_param  => 0,
        whiplash         => new Razor2::Signature::Whiplash,
        rm               => $args{RM},
    }, $class;

    die unless $self;

    return $self;

}


sub signature { 

    my ($self, $text) = @_;
    my ($sigs, $meta) = $self->{whiplash}->whiplash($$text);

    my @sigs_to_return;
    return unless $sigs;

    if (scalar @$sigs) { 
        for (@$sigs) { 
            push @sigs_to_return, hextobase64($_); 
        }
    } else { 
        return;
    } 

    return \@sigs_to_return; 
    
}

1;

