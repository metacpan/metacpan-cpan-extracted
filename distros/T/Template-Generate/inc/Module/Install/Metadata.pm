#line 1 "inc/Module/Install/Metadata.pm - /usr/local/lib/perl5/site_perl/5.8.0/Module/Install/Metadata.pm"
# $File: //depot/cpan/Module-Install/lib/Module/Install/Metadata.pm $ $Author: autrijus $
# $Revision: #25 $ $Change: 1665 $ $DateTime: 2003/08/18 07:52:47 $ vim: expandtab shiftwidth=4

package Module::Install::Metadata;
use Module::Install::Base; @ISA = qw(Module::Install::Base);

$VERSION = '0.01';

use strict 'vars';
use vars qw($VERSION);

sub Meta { shift }

my @scalar_keys = qw(name module_name version abstract author license distribution_type);
my @tuple_keys  = qw(build_requires requires recommends bundles);

foreach my $key (@scalar_keys) {
    *$key = sub {
        my $self = shift;
        return $self->{values}{$key} unless @_;
        $self->{values}{$key} = shift;
        return $self;
    };
}

foreach my $key (@tuple_keys) {
    *$key = sub {
        my $self = shift;
        return $self->{values}{$key} unless @_;
        my @rv;
        while (@_) {
            my $module  = shift or last;
            my $version = shift || 0;
            my $rv = [$module, $version];
            push @{$self->{values}{$key}}, $rv;
            push @rv, $rv;
        }
        return @rv;
    };
}

sub features {
    my $self = shift;
    while (my ($name, $mods) = splice(@_, 0, 2)) {
        my $count = 0;
        push @{$self->{values}{features}}, ($name => [
            map { (++$count % 2 and ref($_) and ($count += $#$_)) ? @$_ : $_ } @$mods
        ] );
    }
    return @{$self->{values}{features}};
}

sub _dump {
    my $self = shift;
    my $package = ref($self->_top);
    my $version = $self->_top->VERSION;
    my %values = %{$self->{values}};
    $values{distribution_type} ||= 'module';
    $values{name} ||= do {
        my $name = $values{module_name};
        $name =~ s/::/-/g;
        $name;
    } if $values{module_name};

    my $dump = '';
    foreach my $key (@scalar_keys) {
        $dump .= "$key: $values{$key}\n" if exists $values{$key};
    }
    foreach my $key (@tuple_keys) {
        next unless exists $values{$key};
        $dump .= "$key:\n";
        $dump .= "  $_->[0]: $_->[1]\n" for @{$values{$key}};
    }

    return($dump . "private:\n  directory:\n    - inc\ngenerated_by: $package version $version\n");
}

sub read {
    my $self = shift;
    $self->include_deps( 'YAML', 0 );
    require YAML;
    my $data = YAML::LoadFile( 'META.yml' );
    # Call methods explicitly in case user has already set some values.
    while ( my ($key, $value) = each %$data ) {
        next unless $self->can( $key );
        if (ref $value eq 'HASH') {
            while (my ($module, $version) = each %$value) {
                $self->$key( $module => $version );
            }
        }
        else {
            $self->$key( $value );
        }
    }
    return $self;
}

sub write {
    my $self = shift;
    return $self unless $self->is_admin;

    META_NOT_OURS: {
        local *FH;
        if (open FH, "META.yml") {
            while (<FH>) {
                last META_NOT_OURS if /^generated_by: Module::Install\b/;
            }
            return $self;
        }
    }

    warn "Writing META.yml\n";
    open META, "> META.yml" or warn "Cannot write to META.yml: $!";
    print META $self->_dump;
    close META;
    return $self;
}

sub version_from {
    my ($self, $version_from) = @_;
    require ExtUtils::MM_Unix;
    $self->version(ExtUtils::MM_Unix->parse_version($version_from));
}

1;
