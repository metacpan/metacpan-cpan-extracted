package Mojolicious::Plugin::Fondation::Schema::Result::Base;
$Mojolicious::Plugin::Fondation::Schema::Result::Base::VERSION = '0.08';
# ABSTRACT: Base class for all Fondation DBIx::Class Result classes

use strict;
use warnings;
use base 'DBIx::Class::Core';
use Scalar::Util qw(blessed);

# ── TO_JSON — generic serialization with relationships ──

sub TO_JSON {
    my $self = shift;
    my %data = $self->get_columns;

    for my $rel ($self->result_source->relationships) {
        next unless $self->has_column_loaded($rel)
                 || exists $self->{_relationship_data}{$rel};
        # Access prefetched data directly (async relationships return Futures or hashrefs)
        my $obj = exists $self->{_relationship_data}{$rel}
            ? $self->{_relationship_data}{$rel}
            : eval { $self->$rel };
        next if !$obj || (blessed($obj) && $obj->isa('Future'));

        if (ref $obj eq 'ARRAY') {
            $data{$rel} = [ map { blessed($_) ? $_->TO_JSON : $_ } @$obj ];
        }
        elsif (blessed $obj) {
            $data{$rel} = $obj->TO_JSON;
        }
        else {
            $data{$rel} = $obj;  # unblessed hashref (prefetched async)
        }
    }

    # ── many_to_many_async relationships ──
    # Discovered via _many_to_many metadata (populated by
    # DBIx::Class::Relationship::ManyToMany::Async).
    # When data was prefetched (e.g. $rs->with('groups')),
    # the accessor returns Future->done(\@targets) — we
    # extract synchronously via is_done + get.
    # Without prefetch, the Future is not done → silently skipped.
    {
        no strict 'refs';
        my $m2m = ${ ref($self) . '::_many_to_many' } // {};
        for my $meth (keys %$m2m) {
            next unless $self->can($meth);
            my $future = $self->$meth;
            next unless $future->is_done;
            my $targets = $future->get;
            $data{$meth}
                = [ map { blessed($_) ? $_->TO_JSON : $_ } @$targets ]
                if $targets && @$targets;
        }
    }

    # Serialize DateTime columns to ISO 8601 strings
    for my $key (keys %data) {
        my $val = $data{$key};
        $data{$key} = $val->iso8601 if blessed($val) && $val->isa('DateTime');
    }

    return \%data;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Fondation::Schema::Result::Base - Base class for all Fondation DBIx::Class Result classes

=head1 VERSION

version 0.08

=head1 AUTHOR

Daniel Brosseau <dab@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Daniel Brosseau.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
