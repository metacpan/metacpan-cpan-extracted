package Search::Elasticsearch::Role::CxnPool::Static;
$Search::Elasticsearch::Role::CxnPool::Static::VERSION = '6.80';
use Moo::Role;
with 'Search::Elasticsearch::Role::CxnPool';
requires 'next_cxn';

use namespace::clean;

#===================================
sub BUILD {
#===================================
    my $self = shift;
    $self->set_cxns( @{ $self->seed_nodes } );
    $self->schedule_check;
}

#===================================
sub schedule_check {
#===================================
    my ($self) = @_;
    $self->logger->info("Forcing ping before next use on all live cxns");
    for my $cxn ( @{ $self->cxns } ) {
        next if $cxn->is_dead;
        $self->logger->infof( "Ping [%s] before next request",
            $cxn->stringify );
        $cxn->force_ping;
    }
}

1;

=pod

=encoding UTF-8

=head1 NAME

Search::Elasticsearch::Role::CxnPool::Static - A CxnPool role for connecting to a remote cluster with a static list of nodes.

=head1 VERSION

version 6.80

=head1 METHODS

=head2 C<schedule_check()>

    $cxn_pool->schedule_check

Forces a ping on each cxn in L<cxns()|Search::Elasticsearch::Role::CxnPool/cxns()>
before the next time that cxn is used for a request.

=head1 AUTHOR

Enrico Zimuel <enrico.zimuel@elastic.co>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Elasticsearch BV.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

__END__

# ABSTRACT: A CxnPool role for connecting to a remote cluster with a static list of nodes.

