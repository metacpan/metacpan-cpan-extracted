#line 1

package Class::MOP::Module;
BEGIN {
  $Class::MOP::Module::AUTHORITY = 'cpan:STEVAN';
}
{
  $Class::MOP::Module::VERSION = '2.0401';
}

use strict;
use warnings;

use Carp         'confess';
use Scalar::Util 'blessed';

use base 'Class::MOP::Package';

sub _new {
    my $class = shift;
    return Class::MOP::Class->initialize($class)->new_object(@_)
        if $class ne __PACKAGE__;

    my $params = @_ == 1 ? $_[0] : {@_};
    return bless {
        # Need to quote package to avoid a problem with PPI mis-parsing this
        # as a package statement.

        # from Class::MOP::Package
        'package' => $params->{package},
        namespace => \undef,

        # attributes
        version   => \undef,
        authority => \undef
    } => $class;
}

sub version {
    my $self = shift;
    ${$self->get_or_add_package_symbol('$VERSION')};
}

sub authority {
    my $self = shift;
    ${$self->get_or_add_package_symbol('$AUTHORITY')};
}

sub identifier {
    my $self = shift;
    join '-' => (
        $self->name,
        ($self->version   || ()),
        ($self->authority || ()),
    );
}

sub create {
    my $class = shift;
    my @args = @_;

    unshift @args, 'package' if @args % 2 == 1;
    my %options = @args;

    my $package   = delete $options{package};
    my $version   = delete $options{version};
    my $authority = delete $options{authority};

    my $meta = $class->SUPER::create($package => %options);

    $meta->_instantiate_module($version, $authority);

    return $meta;
}

sub _anon_package_prefix { 'Class::MOP::Module::__ANON__::SERIAL::' }
sub _anon_cache_key      { confess "Modules are not cacheable" }


sub _instantiate_module {
    my($self, $version, $authority) = @_;
    my $package_name = $self->name;

    $self->add_package_symbol('$VERSION' => $version)
        if defined $version;
    $self->add_package_symbol('$AUTHORITY' => $authority)
        if defined $authority;

    return;
}

1;

# ABSTRACT: Module Meta Object



#line 169


__END__

