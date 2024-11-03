package RecentInfo::Application 0.01;
use 5.020;
use Moo 2;
use experimental 'signatures';

has ['name', 'exec'] => (
    is => 'ro',
    required => 1
);

has ['modified', 'count'] => (
    is => 'rw',
    required => 1
);

sub as_XML_fragment($self, $doc) {
    my $app = $doc->createElement('bookmark:application');
    $app->setAttribute("name" =>  $self->name);
    $app->setAttribute("exec" =>  $self->exec);
    $app->setAttribute("modified" =>  $self->modified);
    $app->setAttribute("count" => $self->count);
    return $app
}

sub from_XML_fragment( $class, $frag ) {
    $class->new(
        name  => $frag->getAttribute('name'),
        exec  => $frag->getAttribute('exec'),
        modified  => $frag->getAttribute('modified'),
        count => $frag->getAttribute('count'),
    );
}

1;
