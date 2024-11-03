package RecentInfo::GroupEntry 0.01;
use 5.020;
use Moo 2;
use experimental 'signatures';

has ['group'] => (
    is => 'ro',
    required => 1
);

sub as_XML_fragment($self, $doc) {
    my $group = $doc->createElement('bookmark:group');
    $group->addChild($doc->createTextNode($self->group));
    #$group->setTextContent($self->group);
    return $group
}

sub from_XML_fragment( $class, $frag ) {
    $class->new(
        group => $frag->textContent,
    );
}

1;
