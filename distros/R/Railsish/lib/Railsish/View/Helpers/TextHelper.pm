package Railsish::View::Helpers::TextHelper;
our $VERSION = '0.21';

use strict;
use warnings;

use Exporter::Lite;
our @EXPORT = qw(pluralize);



use Lingua::EN::Inflect qw(PL);

sub pluralize {
    my ($count, $singular, $plural) = @_;

    return $singular if $count == 1;
    return $plural if defined $plural;
    return PL($singular)
}

1;

__END__
=head1 NAME

Railsish::View::Helpers::TextHelper

=head1 VERSION

version 0.21

=head1 AUTHOR

  Liu Kang-min <gugod@gugod.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Liu Kang-min <gugod@gugod.org>.

This is free software, licensed under:

  The MIT (X11) License

