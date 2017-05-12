package Silki::URI;
{
  $Silki::URI::VERSION = '0.29';
}

use strict;
use warnings;

use Exporter qw( import );

our @EXPORT_OK = qw( dynamic_uri static_uri );

use List::AllUtils qw( all );
use Silki::Config;
use Silki::Util qw( string_is_empty );
use URI::FromHash ();

sub dynamic_uri {
    my %p = @_;

    $p{path}
        = _prefixed_path( Silki::Config->instance()->path_prefix(), $p{path} );

    return URI::FromHash::uri(%p);
}

{
    my $StaticPathPrefix;

    my $config = Silki::Config->instance();
    if ( $config->is_production() ) {
        $StaticPathPrefix = $config->path_prefix();
        $StaticPathPrefix .= q{/};
        $StaticPathPrefix .= $Silki::Config::VERSION || 'wc';
    }
    else {
        $StaticPathPrefix = q{};
    }

    sub static_uri {
        my $path = shift;

        return _prefixed_path(
            $StaticPathPrefix,
            $path
        );
    }
}

sub _prefixed_path {
    my $prefix = shift;
    my $path   = shift;

    return '/'
        if all { string_is_empty($_) } $prefix, $path;

    $path = ( $prefix || q{} ) . ( $path || q{} );

    return $path;
}

1;

# ABSTRACT: A utility module for generating URIs

__END__
=pod

=head1 NAME

Silki::URI - A utility module for generating URIs

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

