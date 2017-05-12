package MooseX::MakeImmutable::Finder;

use Moose;

use Module::Pluggable::Object;
use List::MoreUtils qw/uniq/;
use Devel::InnerPackage qw/list_packages/;
use Carp::Clan qw/^MooseX::MakeImmutable::/;
use Class::Inspector;

has exclude => qw/is ro required 1 lazy 1/, default => sub { [] };
has include_inner => qw/is ro required 1 default 1/;
has _found => qw/is ro required 1 lazy 1 isa ArrayRef/, default => sub {
    my $self = shift;
    $self->require;

    my @manifest;

    push @manifest, $self->manifest;

    push @manifest, map { list_packages $_ } $self->manifest if $self->include_inner;

    push @manifest, $self->recursive_manifest;

    push @manifest, map { list_packages $_ } $self->recursive_manifest;

    @manifest = uniq @manifest;

    @manifest = grep { $self->keep($_) } @manifest;

    @manifest = grep { $_->isa("Moose::Object") } @manifest;

    return \@manifest;
};

sub BUILD {
    my $self = shift;
    my $given = shift;

    $self->{exclude} = [ $self->{exclude} ] if $self->{exclude} && ref $self->{exclude} ne "ARRAY";

    my $manifest = $given->{manifest};
    my (@manifest, @recursive_manifest, @search_manifest);

    for my $package (split m/\n+/, $manifest) {
        chomp $package;
        $package =~ s/^\s*//;
        $package =~ s/\s*$//;
        next unless $package;
        next if $package =~ m/^#/;

        if ($package =~ s/::\*$//) {
            push @search_manifest, $package;
            next;
        }
        elsif ($package =~ s/::\+?$//) {
            push @recursive_manifest, $package;
        }

        push @manifest, $package;
    }

    if (@search_manifest || @recursive_manifest) {
        my $pluggable = Module::Pluggable::Object->new(require => 1, search_path => [ @search_manifest, @recursive_manifest ]);
        push @recursive_manifest, $pluggable->plugins;
    }

    @manifest = grep { $self->keep($_) } uniq @manifest;
    @recursive_manifest = grep { $self->keep($_) } uniq @recursive_manifest;
    my @total_manifest = sort { $a cmp $b } uniq @manifest, @recursive_manifest;

    @$self{qw/manifest recursive_manifest total_manifest/} = (\@manifest, \@recursive_manifest, \@total_manifest);
}

sub keep {
    my $self = shift;
    my $package = shift;

    my @exclude = @{ $self->exclude };

    for my $filter (@exclude) {
        if      (ref $filter eq "") {
            return 0 if $package eq $filter;
        }
        elsif   (ref $filter eq "Regexp") {
            return 0 if $package =~ $filter;
        }
        elsif   (ref $filter eq "CODE") {
            return 0 if $filter->($package);
        }
    }

    return 1;
}

sub manifest {
    my $self = shift;
    return @{ $self->{manifest} };
}

sub recursive_manifest {
    my $self = shift;
    return @{ $self->{recursive_manifest} };
}

sub total_manifest {
    my $self = shift;
    return @{ $self->{total_manifest} };
}

sub require {
    my $self = shift;
    for my $package ($self->total_manifest) {
        next if Class::Inspector->loaded($package); # Don't require already loaded "inner" packages
        eval "require $package;" or croak $@;
    }
}

sub found {
    my $self = shift;
    return @{ $self->_found };
}

1;
