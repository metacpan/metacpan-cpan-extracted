package Search::Elasticsearch::Plugin::XPack;

use Moo;

our $VERSION = '5.02';
use Search::Elasticsearch 5.02 ();

#===================================
sub _init_plugin {
#===================================
    my ( $class, $params ) = @_;

    my $api_version = $params->{client}->api_version;

    Moo::Role->apply_roles_to_object( $params->{client},
        "Search::Elasticsearch::Plugin::XPack::${api_version}" );
}

1

=pod

=encoding UTF-8

=head1 NAME

Search::Elasticsearch::Plugin::XPack - Plugin providing XPack APIs for Search::Elasticsearch

=head1 VERSION

version 5.02

=head1 SYNOPSIS

    use Search::Elasticsearch();

    my $es = Search::Elasticsearch->new(
        nodes   => \@nodes,
        plugins => ['XPack']
    );

=head2 DESCRIPTION

This class extends the L<Search::Elasticsearch> client to add support
for the X-Pack commercial plugins.

This plugin will detect which version of the Elasticsearch API you are using
and load the corresponding XPack API.

For more details, see:

=over

=item *

L<Search::Elasticsearch::Plugin::XPack::5_0>

=item *

L<Search::Elasticsearch::Plugin::XPack::2_0>

=item *

L<Search::Elasticsearch::Plugin::XPack::1_0>

=back

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Elasticsearch BV.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

__END__

# ABSTRACT: Plugin providing XPack APIs for Search::Elasticsearch

