package OpenStack::MetaAPI::Helpers::DataAsYaml;

use strict;
use warnings;

use YAML::XS ();

our $_CACHE;

## TODO: publish this to CPAN as its own module

### FIXME publish as its own package
###     and provide one import function which can old its own cache

sub LoadData {
    my ($pkg) = @_;

    $pkg //= (caller(0))[0];

    return LoadDataFrom($pkg);
}

sub LoadDataFrom {
    my ($pkg) = @_;

    die "undefined package" unless defined $pkg;

    $_CACHE //= {};
    return $_CACHE->{$pkg} if $_CACHE->{$pkg};

    my $data;
    {
        local $/;
        my $fh = eval '\*' . $pkg . '::DATA';
        $data = <$fh>;
    }

    return unless defined $data;

    $_CACHE->{$pkg} = YAML::XS::Load($data);

    return $_CACHE->{$pkg};
}

sub clear_cache {
    $_CACHE = {};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenStack::MetaAPI::Helpers::DataAsYaml

=head1 VERSION

version 0.002

=head1 AUTHOR

Nicolas R <atoomic@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by cPanel, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
