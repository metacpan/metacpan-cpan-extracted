package PAUSE::Packages::Release;
$PAUSE::Packages::Release::VERSION = '0.17';
use 5.8.1;
use Moo 1.006;
use CPAN::DistnameInfo;

has 'modules' => (is => 'ro');
has 'path' => (is => 'ro');
has 'distinfo' => (is => 'lazy');

sub _build_distinfo
{
    my $self = shift;

    return CPAN::DistnameInfo->new($self->path);
}

1;
