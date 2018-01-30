package OpenERP::OOM::Tutorial::Searching;

# FIXME: should this be a pod file instead?


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenERP::OOM::Tutorial::Searching

=head1 VERSION

version 0.46

=head1 DESCRIPTION

=head1 NAME

OpenERP::OOM::Tutorial::Searching

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

=head1 AUTHOR

Jon Allen (JJ), <jj@opusvl.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011-2016 by OpusVL.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
