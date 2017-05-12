package TestExtenderSingleNS;
use Moose;
with 'Role::LibXSLT::Extender';

use XML::LibXML ();

has some_attribute => (
    is          =>  'rw',
    isa         =>  'Str',
    default     =>  sub { 'DEFAULT' },
);

sub set_extension_namespace {
    return 'http://test/a/good/uri#v1';
}

sub foo {
    my $self = shift;
    my $text = shift;
    my $ret = $self->some_attribute . '::' . $text . '::FOO';
    $self->some_attribute('SETBYFOO');
    return $ret;
}

sub bar {
    my $self = shift;
    my $text = shift;
    my $ret = $self->some_attribute . '::' . $text . '::BAR';
    $self->some_attribute('SETBYBAR');
    return $ret;
}

sub quux {
    my $self = shift;
    my $node = shift;
    my $el = XML::LibXML::Element->new( lc( $self->some_attribute ) );
    return $el;
}

sub _seekrit_method {
    die "I told you never to call me at the office!";
}

1;