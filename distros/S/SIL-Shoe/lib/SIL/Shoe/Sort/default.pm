package SIL::Shoe::Sort::default;

sub new
{
    my ($class) = @_;
    return bless {}, $class;
}

sub cmp
{
    my ($self, $a, $b, $level) = @_;
    return ($a cmp $b);
}

sub firstchar
{
    my ($self, $str, $level, $ignore) = @_;
    return (substr($str, 0, 1));
}

sub num_fields
{ return 1; }

sub lowercase
{
    my ($self, $str) = @_;
    return lc($str);
}

sub uppercase
{
    my ($self, $str) = @_;
    return uc($str);
}
1;
