package PAX::InlineCache;

our $VERSION = '0.031';

use strict;
use warnings;
use JSON::PP ();

sub new {
    my ($class, %args) = @_;
    return bless {
        max_polymorphic => $args{max_polymorphic} // 4,
        sites => {},
    }, $class;
}

sub lookup {
    my ($self, %args) = @_;
    my $site = $args{site} // 'default';
    my $class_key = $args{class_key} // 'main';
    my $method = $args{method} // $args{region_name} // '';
    my $slot = $self->{sites}{$site};
    return {
        status => 'miss',
        site => $site,
        class_key => $class_key,
        method => $method,
    } if !$slot;

    for my $entry (@{ $slot->{entries} }) {
        next if $entry->{class_key} ne $class_key || $entry->{method} ne $method;
        $entry->{hits}++;
        return {
            status => $slot->{megamorphic} ? 'megamorphic' : 'hit',
            site => $site,
            class_key => $class_key,
            method => $method,
            target_region_id => $entry->{target_region_id},
            target_region_name => $entry->{target_region_name},
            hits => $entry->{hits},
            entry_count => scalar @{ $slot->{entries} },
        };
    }

    return {
        status => $slot->{megamorphic} ? 'megamorphic' : 'miss',
        site => $site,
        class_key => $class_key,
        method => $method,
        entry_count => scalar @{ $slot->{entries} },
    };
}

sub update {
    my ($self, %args) = @_;
    my $site = $args{site} // 'default';
    my $class_key = $args{class_key} // 'main';
    my $method = $args{method} // $args{region_name} // '';
    my $slot = $self->{sites}{$site} ||= {
        entries => [],
        megamorphic => JSON::PP::false(),
    };

    for my $entry (@{ $slot->{entries} }) {
        next if $entry->{class_key} ne $class_key || $entry->{method} ne $method;
        $entry->{target_region_id} = $args{target_region_id};
        $entry->{target_region_name} = $args{target_region_name};
        return $self->lookup(site => $site, class_key => $class_key, method => $method);
    }

    push @{ $slot->{entries} }, {
        class_key => $class_key,
        method => $method,
        target_region_id => $args{target_region_id},
        target_region_name => $args{target_region_name},
        hits => 0,
    };
    $slot->{megamorphic} = JSON::PP::true()
        if @{ $slot->{entries} } > $self->{max_polymorphic};

    return {
        status => $slot->{megamorphic} ? 'megamorphic' : 'updated',
        site => $site,
        class_key => $class_key,
        method => $method,
        entry_count => scalar @{ $slot->{entries} },
    };
}

sub report {
    my ($self) = @_;
    return {
        max_polymorphic => $self->{max_polymorphic},
        sites => $self->{sites},
    };
}

1;

=pod

=head1 NAME

PAX::InlineCache - inline-cache state tracker

=head1 SYNOPSIS

  use PAX::InlineCache;

  my $obj = PAX::InlineCache->new(...);
  my $result = $obj->lookup(...);

=head1 DESCRIPTION

Tracks polymorphic call-site cache state so repeated dispatch patterns can stay cheap until they become too wide.

=head1 METHODS

=head2 new, lookup, update, report

These are the public entrypoints exposed by this module's current interface.

=head1 PURPOSE

This module exists to keep the inline-cache state tracker logic in one place so the CLI, build
pipeline, and runtime can reuse the same behavior instead of duplicating it.

=head1 WHY IT EXISTS

PAX uses this module when it needs inline-cache state tracker. Keeping that behavior isolated here
makes the surrounding compiler and packaging stages easier to reason about and
safer to evolve.

=head1 WHEN TO USE

Edit this file when a change affects inline-cache state tracker, the data contract this module
returns, or the conditions under which callers choose this path.

=head1 HOW TO USE

Load the module through the normal PAX call path, pass explicit arguments rather
than ambient global state, and keep project-specific behavior out of this file
so the implementation stays neutral across arbitrary Perl applications.

=head1 WHAT USES IT

This module is used by the PAX CLI, the build pipeline, standalone packaging,
and the test suite paths that cover inline-cache state tracker.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MPAX::InlineCache -e 1

Confirm that the module loads from a source checkout.

Example 2:

  prove -lr t

Run the repository test suite after changing the behavior this module owns.

=cut
