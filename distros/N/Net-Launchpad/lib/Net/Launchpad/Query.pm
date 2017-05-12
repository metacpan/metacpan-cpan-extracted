package Net::Launchpad::Query;
BEGIN {
  $Net::Launchpad::Query::AUTHORITY = 'cpan:ADAMJS';
}
$Net::Launchpad::Query::VERSION = '2.101';
# ABSTRACT: Query class

use Moose;
use Moose::Util qw(apply_all_roles is_role does_role search_class_by_role);
use Function::Parameters;
use Mojo::Parameters;
use Module::Runtime qw(is_module_name use_package_optimistically);
use Data::Dumper::Concise;
use namespace::autoclean;

has lpc    => (is => 'ro', isa => 'Net::Launchpad::Client');

method _load_model (Str $name) {
    my $model_class = sprintf("Net::Launchpad::Model::Query::%s", $name);
    my $model_role  = sprintf("Net::Launchpad::Role::Query::%s",  $name);
    die "Invalid model requested." unless is_module_name($model_class);
    die "Unknown Role module"      unless is_module_name($model_role);

    my $model =
      use_package_optimistically($model_class)->new(lpc => $self->lpc);

    my $role = use_package_optimistically($model_role);

    die "$_ is not a role" unless is_role($role);
    $role->meta->apply($model);
}

# method bugtrackers {
#     return $self->_load_model('BugTracker');
# }

method builders {
    return $self->_load_model('Builder');
}

method countries {
    return $self->_load_model('Country');
}

method branches {
    return $self->_load_model('Branch');
}

method people {
    return $self->_load_model('Person');
}

method projects {
    return $self->_load_model('Project');
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Launchpad::Query - Query class

=head1 VERSION

version 2.101

=head1 METHODS

=head2 builders

Search  builders

=head2 branches

Search utilities for branches

=head2 people

Search people

=head2 projects

Search projects

=head1 AUTHOR

Adam Stokes <adamjs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Adam Stokes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
