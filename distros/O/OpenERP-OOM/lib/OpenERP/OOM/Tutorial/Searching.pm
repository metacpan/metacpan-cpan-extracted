package OpenERP::OOM::Tutorial::Searching;

# FIXME: should this be a pod file instead?

=pod

=head1 NAME

OpenERP::OOM::Tutorial::Searching

=head1 DESCRIPTION

=head1 Complex Search Terms

OpenERP allows logic operators like most database wrappers, just
a little stranger.  It uses postfix style operators to allow you
to or things together.  You can also use '&' as an operator.

    my $products = $schema->class('Product');
    $products->search('|',  '|', 
                    [ 'default_code', 'ilike', '%' . $query . '%' ],
                    [ 'description', 'ilike', '%' . $query . '%' ],
                    [ 'name', 'ilike', '%' . $query . '%' ]);

For more details see the OpenERP Developer book.  

=cut

1;
