package SIL::Shoe::Sort::shoe;

use SIL::Shoe::Lang;
use base 'SIL::Shoe::Sort::default';

sub new
{
    my ($class, $info) = @_;
    my ($self);
    my ($fname, $name, $level) = split(/\|/, $info);
    my ($lang) = SIL::Shoe::Lang->new($fname) || die "Can't open language file $fname";
    $lang->read;

    $name ||= $lang->{'srtDefault'};

    $self = {
        'lng' => $lang,
        'name' => $name,
        'level' => $level
    };
    return bless $self, $class;
}

sub cmp
{
    my ($self, $a, $b, $level) = @_;

    return $self->{'lng'}->cmp($self->{'name'}, $level || $self->{'level'}, $a, $b);
}

sub firstchar
{
    my ($self, $str, $level, $ignore) = @_;
    my (@tokens) = $self->{'lng'}->tokenize($self->{'name'}, $level || $self->{'level'}, $ignore, $str);
    return $tokens[0];
}

1;
    
