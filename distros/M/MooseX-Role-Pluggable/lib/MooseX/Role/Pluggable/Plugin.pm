package MooseX::Role::Pluggable::Plugin;
$MooseX::Role::Pluggable::Plugin::VERSION = '0.05';
# ABSTRACT: Role for plugins to consume
use Moose::Role;
use Moose::Util::TypeConstraints;

has _mxrp_name => (
  isa => 'Str' ,
  is  => 'ro' ,
  required => 1 ,
);

subtype 'MooseXRolePluggable'
  => as 'Object'
  => where { $_->does( 'MooseX::Role::Pluggable' ) }
  => message { 'Parent does not consume MooseX::Role::Pluggable!' };

has _mxrp_parent => (
  isa      => 'MooseXRolePluggable' ,
  is       => 'ro' ,
  required => 1 ,
);

no Moose::Role;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Role::Pluggable::Plugin - Role for plugins to consume

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    package MyMoose::Plugin::Antlers;
    use Moose;
    with 'MooseX::Role::Pluggable::Plugin';

    sub gore {
      my( $self ) = shift;

      # yadda yadda yadda
    }

    # see the documentation for MooseX::Role::Pluggable for info on how to get
    # your Moose class to use this plugin...

=head1 DESCRIPTION

This is a role that must be consumed by any plugin that's going to be used
with the 'MooseX::Role::Pluggable' role. It serves to make sure that required
attributes are in place and contain the expected sorts of info.

Classes that want to utilize plugins should consume the
'MooseX::Role::Pluggable' role; see the documentation for that module for more
information.

=head1 NAME

MooseX::Role::Pluggable::Plugin - add plugins to your Moose classes

=head1 AUTHOR

John SJ Anderson, C<genehack@genehack.org>

=head1 SEE ALSO

L<MooseX::Role::Pluggable>

=head1 COPYRIGHT AND LICENSE

Copyright 2014, John SJ Anderson

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

John SJ Anderson <genehack@genehack.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by John SJ Anderson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
