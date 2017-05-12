package Search::Elasticsearch::Async::Util;
$Search::Elasticsearch::Async::Util::VERSION = '5.02';
use Moo;
use Scalar::Util qw(blessed);
use Sub::Exporter -setup => { exports => ['thenable'] };

#===================================
sub thenable {
#===================================
    return
           unless @_ == 1
        && blessed $_[0]
        && $_[0]->can('then');
    return shift();
}
1;

# ABSTRACT: A utility class for internal use by Elasticsearch

__END__

=pod

=encoding UTF-8

=head1 NAME

Search::Elasticsearch::Async::Util - A utility class for internal use by Elasticsearch

=head1 VERSION

version 5.02

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Elasticsearch BV.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
