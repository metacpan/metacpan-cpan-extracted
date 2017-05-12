package TOML::Dumper;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use Class::Accessor::Lite ro => [qw/boolean_classes/], new => 1;

use TOML::Dumper::Context;

sub dump :method {
    my ($self, $object) = @_;
    local @TOML::Dumper::Context::Value::BOOLEAN_CLASSES = (
        @TOML::Dumper::Context::Value::BOOLEAN_CLASSES,
        @{ $self->boolean_classes || [] },
    );
    my $body = TOML::Dumper::Context->new($object)->as_string;
    $body =~ s/\A\n+//msg;
    $body =~ s/\n{3,}/\n\n/msg;
    return $body;
}

1;
__END__

=encoding utf-8

=head1 NAME

TOML::Dumper - It's new $module

=head1 SYNOPSIS

    use TOML::Dumper;

    my $out = TOML::Dumper->new->dump({ my => { data => [is => 'here'] } });
    # $out =>
    # [my]
    # data = ["is", "here"]

=head1 DESCRIPTION

TOML::Dumper is ...

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

