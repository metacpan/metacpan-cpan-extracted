package TM::Utils::TreeWalker;

use base qw(XML::SAX::Base);

sub walk {
    my $self = shift;
    my $hash = shift;

    $self->SUPER::start_document();
    $self->SUPER::start_element ({ Name => 'root'} );
    _walk_children ($self, $hash);
sub _walk_children {
    my $self = shift;
    my $hash = shift;
    foreach (keys %{$hash}) {
	$self->SUPER::start_element ({ Name => $_ });
	if (ref ($hash->{$_}) eq 'HASH') {
	    _walk_children ($self, $hash->{$_});
	} else {
	    $self->SUPER::characters  ({ Data => $hash->{$_} });
	}
	$self->SUPER::end_element   ({ Name => $_ });
    }
}
    $self->SUPER::end_element   ({ Name => 'root'} );
    $self->SUPER::end_document();
}

1;

__END__


package CamelDriver;
use base qw(XML::SAX::Base);

sub parse {
    my $self = shift;
    my %links = @_;
    $self->SUPER::start_document;
    $self->SUPER::start_element({Name => 'html'});
    $self->SUPER::start_element({Name => 'body'});

    foreach my $item (keys (%camelid_links)) {
	$self->SUPER::start_element({Name => 'a',
				     Attributes => {
					 'href' => $links{$item}->{url}
				     }
				 });
	$self->SUPER::characters({Data => $links{$item}->{description}});
	$self->SUPER::end_element({Name => 'a'});
    }

    $self->SUPER::end_element({Name => 'body'});
    $self->SUPER::end_element({Name => 'html'});
    $self->SUPER::end_document;

}
1;
