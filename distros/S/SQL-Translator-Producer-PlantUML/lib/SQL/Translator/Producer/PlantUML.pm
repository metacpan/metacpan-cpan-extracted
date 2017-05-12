package SQL::Translator::Producer::PlantUML;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.05";

use base qw/SQL::Translator::Producer::TT::Base/;

sub produce { return __PACKAGE__->new( translator => shift )->run; };

sub tt_config { INTERPOLATE => 1 }

sub tt_schema {
    my $data = "";
    while (<DATA>) {
        last if (/__END__/);
        $data .= $_;
    }
    \$data;
}

1;

__DATA__

@startuml
[% FOREACH table IN schema.get_tables %]
object [% table.name %] {
    [% FOREACH field IN table.get_fields %]
    [% IF field.is_primary_key %]- [% END %][% field %][% IF field.is_foreign_key %] (FK)[% END %]
    [% END %]
}
[% END %]
[% FOREACH table IN schema.get_tables %]
[% FOREACH cont IN table.get_constraints %]
[% IF cont.type.lower.match('foreign key') %][% cont.reference_table %] --o [% table.name %][% END %]
[% END %]
[% END %]
@enduml

__END__

=encoding utf-8

=head1 NAME

SQL::Translator::Producer::PlantUML - PlantUML-specific producer for SQL::Translator

=head1 SYNOPSIS

    use SQL::Translator;
    use SQL::Translator::Producer::PlantUML;

    my $t = SQL::Translator->new( parser => '...', producer => 'PlantUML', '...' );
    $t->translate;

=head1 DESCRIPTION

This module will produce text output of PlantUML.

=head1 LICENSE

Copyright (C) mix3.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

mix3 E<lt>himachocost333@hotmail.co.jpE<gt>

=cut
