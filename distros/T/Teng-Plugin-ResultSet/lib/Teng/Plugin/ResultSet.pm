package Teng::Plugin::ResultSet;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use Class::Load;
use String::CamelCase qw/decamelize/;

use Teng::ResultSet;
our @EXPORT = qw/resultset/;

{
    my %_CACHE;
    sub resultset {
        my ($self, $table_name) = @_;

        $table_name = decamelize $table_name;
        my $teng_class = ref $self;
        my $result_set_class = $_CACHE{$teng_class} ||= do {
            my $rs_class = "$teng_class\::ResultSet";
            Class::Load::load_optional_class($rs_class) or do {
                # make result_class class automatically
                no strict 'refs'; @{"$rs_class\::ISA"} = ('Teng::ResultSet');
            };
            $rs_class;
        };
        $result_set_class->new(teng => $self, table_name => $table_name);
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Teng::Plugin::ResultSet - Teng plugin providing ResultSet

=head1 SYNOPSIS

    package MyDB;
    use parent 'Teng';
    __PACKAGE__->load_plugin('ResultSet');
    
    package main;
    my $db = MyDB->new(...);
    my $rs = $db->resultset('TableName');
    $rs = $rs->search({id, {'>', 10});
    while (my $row = $rs->next) {
        ...
    }

=head1 DESCRIPTION

Teng::Plugin::ResultSet is plugin of L<Teng> providing ResultSet class.

B<THE SOFTWARE IS ALPHA QUALITY. API MAY CHANGE WITHOUT NOTICE.>

=head1 METHODS

=over

=item C<< $result_set:Teng::ResultSet = $db->resultset($result_set_name:Str) >>

=back

=head1 SEE ALSO

L<Teng::ResultSet>

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Songmu E<lt>y.songmu@gmail.comE<gt>

=cut

