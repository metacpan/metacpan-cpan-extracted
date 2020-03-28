package Search::Elasticsearch::Plugin::XPack;

use Moo;

our $VERSION = '6.80';
use Search::Elasticsearch 6.00 ();

#===================================
sub _init_plugin {
#===================================
    # NOOP
}

1;

# ABSTRACT: NOOP for backward compatibility wih XPack as plugin for Search::Elasticsearch

__END__

=pod

=encoding UTF-8

=head1 NAME

Search::Elasticsearch::Plugin::XPack - NOOP for backward compatibility wih XPack as plugin for Search::Elasticsearch

=head1 VERSION

version 6.80

=head1 SYNOPSIS

    use Search::Elasticsearch();

    my $es = Search::Elasticsearch->new(
        nodes   => \@nodes,
        #plugins => ['XPack']  <-- NO NEED ANYMORE!
    );

=head2 DESCRIPTION

This is a NOOP module that is present only for backward compatibility.

Starting from elasticsearch-perl 6.8 we moved the XPack endpoints into Direct client.

You don't need anymore to specify XPack as plugin.

=head1 AUTHOR

Enrico Zimuel <enrico.zimuel@elastic.co>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Elasticsearch BV.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
