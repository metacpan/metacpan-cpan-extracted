use strict;
use warnings;
package Task::Yeb;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: All the approved Yeb plugins in one Task
$Task::Yeb::VERSION = '20160218.000';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Task::Yeb - All the approved Yeb plugins in one Task

=head1 VERSION

version 20160218.000

=head1 TASK CONTENTS

=head2 Perl itself

=head3 L<perl> 5.010001

You should have at least 5.10.1

=head2 Yeb core

=head3 L<Yeb> 0.102

=head2 Base plugins

=head3 L<Yeb::Plugin::Session> 0.100

Session handling via L<Plack::Middleware::Session>

=head3 L<Yeb::Plugin::Locale::Simple> 0.002

Localization via L<Locale::Simple>

=head2 Models

=head3 L<Yeb::Plugin::DBIC> 0.001

Accessing a L<DBIx::Class> schema

=head2 Views

=head3 L<Yeb::Plugin::Xslate> 0.100

Templates with L<Text::Xslate>

=head3 L<Yeb::Plugin::JSON> 0.101

JSON responses using L<JSON::MaybeXS>

=head3 L<Yeb::Plugin::GeoJSON> 0.003

Generating GeoJSON output via L<Geo::JSON::Simple> functions

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
