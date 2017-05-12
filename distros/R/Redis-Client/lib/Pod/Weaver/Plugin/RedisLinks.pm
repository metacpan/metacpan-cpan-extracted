package Pod::Weaver::Plugin::RedisLinks;
$Pod::Weaver::Plugin::RedisLinks::VERSION = '0.015';
# ABSTRACT: Add links to Redis documentation

use Moose;
with 'Pod::Weaver::Role::Transformer';

use Data::Dumper;
use Scalar::Util 'blessed';
use aliased 'Pod::Elemental::Element::Pod5::Ordinary';

sub transform_document { 
    my ( $self, $doc ) = @_;

    my @children = $doc->children;
    
    my @new_children;
    foreach my $child( @{ $children[0] } ) { 
        if ( $child->can( 'command' ) && $child->command =~ /^(?:key|str|list|hash|set|zset|conn|serv)_method/ ) { 
            my $meth_name = $child->content;
            $meth_name =~ s/^\s*?(\S+)\s*$/$1/;

            my $cmd_name = uc $meth_name;
            $cmd_name =~ tr/_/ /;

            my $link_name = $meth_name;
            $link_name =~ tr/_/-/;

            my $new_para = Ordinary->new( content => sprintf 'Redis L<%s|%s> command.', 
                                                     $cmd_name, 'http://redis.io/commands/' . $link_name );

            push @new_children, $child, $new_para;
            next;
        } 

        push @new_children, $child;
    }

    $doc->children( \@new_children );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Pod::Weaver::Plugin::RedisLinks - Add links to Redis documentation

=head1 VERSION

version 0.015

=head1 DESCRIPTION

This L<Pod::Weaver> plugin is used internally by the Redis::Client distribution to add links
to the official L<Redis|http://redis.io/> documentation for each command.

=head1 EXTENDS

=over 4

=item * L<Moose::Object>

=back

=head1 CONSUMES

=over 4

=item * L<Pod::Weaver::Role::Plugin>

=item * L<Pod::Weaver::Role::Transformer>

=back

=head1 AUTHOR

Mike Friedman <friedo@friedo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Mike Friedman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
