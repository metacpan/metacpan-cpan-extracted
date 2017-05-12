package Teng::ResultSet;
use strict;
use warnings;

use parent 'Teng::Iterator';
use String::CamelCase ();
use Class::Load ();
use Class::Method::Modifiers;
use Class::Accessor::Lite::Lazy 0.03 (
    ro      => [qw/teng table table_name row_class/],
    rw      => [qw/where opt/],
    ro_lazy => {
        sth => sub {
            my $self = shift;
            my ($sql, @binds) = $self->teng->sql_builder->select(
                $self->table_name,
                $self->teng->_get_select_columns($self->table, $self->opt),
                $self->where,
                $self->opt
            );

            $self->teng->execute($sql, \@binds);
        }
    },
);

{
    my %_CACHE;
    sub new {
        my $class = shift;
        my %args = ref $_[0] ? %{$_[0]}: @_;

        $args{table}     = $args{teng}->schema->get_table($args{table_name})     unless $args{table};
        $args{row_class} = $args{teng}->schema->get_row_class($args{table_name}) unless $args{row_class};

        my $rs_base_class = ref($args{teng}) . '::ResultSet';
        my $sub_class = $_CACHE{$rs_base_class}{$args{table_name}} ||= do {
            my $pkg = $rs_base_class . '::' . String::CamelCase::camelize($args{table_name});
            Class::Load::load_optional_class($pkg) or do {
                no strict 'refs'; @{"$pkg\::ISA"} = ($rs_base_class);
            };
            $pkg;
        };
        bless \%args, $sub_class;
    }
}

sub count {
    my $self = shift;
    $self->teng->count($self->table_name, '*', $self->where, $self->opt);
}

before [qw/all next/] => sub {
    my $self = shift;
    # surely assign sth
    $self->sth;
};

sub search {
    my ($self, $where, $opt) = @_;

    my $new_rs = (ref $self)->new(
        teng       => $self->teng,
        table_name => $self->table_name,
        table      => $self->table,
        row_class  => $self->row_class,
        where => {
            %{ $self->where || {} },
            %{ $where       || {} },
        },
        opt => {
            %{ $self->opt || {} },
            %{ $opt       || {} },
        },
    );
    wantarray ? $new_rs->all : $new_rs;
}

for my $method (qw/find_or_create insert bulk_insert fast_insert/) {
    no strict 'refs';
    *{__PACKAGE__."::$method"} = sub {
        use strict 'refs';
        my $self = shift;

        my $teng = $self->teng;
        unshift @_, $teng, $self->table_name;
        goto $teng->can($method);
    };
}

for my $method (qw/search_with_pager delete single/) {
    no strict 'refs';
    *{__PACKAGE__."::$method"} = sub {
        use strict 'refs';
        my ($self, $where, $opt) = @_;
        $where = +{
            %{ $self->where || {} },
            %{ $where       || {} },
        };
        $opt = +{
            %{ $self->opt || {} },
            %{ $opt       || {} },
        };
        my $teng = $self->teng;
        @_ = ($teng, $self->table_name, $where, $opt);
        goto $teng->can($method);
    };
}

1;

__END__

=encoding utf-8

=head1 NAME

Teng::ResultSet - base class of ResultSet

=head1 SYNOPSIS

    my $rs = $db->resultset('TableName');
    $rs = $rs->search({id, {'>', 10});
    while (my $row = $rs->next) {
        ...
    }
    my $row = $rs->single;
    $rs->delete;

=head1 DESCRIPTION

Teng::ResultSet is base class of each ResultSet.

Don't use this class directory, use via C<< $db->resultset($rs_name) >> instead.

B<THE SOFTWARE IS ALPHA QUALITY. API MAY CHANGE WITHOUT NOTICE.>

=head1 METHODS

=over

=item C<search>

Returns ResultSet object in scalar context and returns array of row object
in array context.

=item C<next>

=item C<all>

=item C<count>

=item C<insert>

=item C<delete>

=item C<single>

=back

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Songmu E<lt>y.songmu@gmail.comE<gt>

=cut

