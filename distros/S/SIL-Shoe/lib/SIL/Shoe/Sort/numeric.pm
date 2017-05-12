package SIL::Shoe::Sort::numeric;

use base 'SIL::Shoe::Sort::default';

sub new
{
    my ($class) = @_;
    my ($self) = {};
    return bless $self, $class;
}

sub cmp
{
    my ($self, $a, $b, $level) = @_;
    my ($res);
    
    if ($a =~ m/(?:\d\.){2,}/o || $b =~ m/(?:\d\.){2,}/o)
    {
        my (@a) = split(/\./, $a);
        my (@b) = split(/\./, $b);
        for ($i = 0; $i < @a; $i++)
        { 
            $res = $a[$i] <=> $b[$i];
            return $res if ($res);
        }
        return -1 if (defined $b[$i]);
        return 0;
    } 
    return ($a <=> $b);
}

sub firstchar
{
    my ($self, $str, $level) = @_;
    return (split(/\./, $str))[0];
}

1;
