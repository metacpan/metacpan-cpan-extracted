use warnings;
use strict;
package Net::OAuth2::Scheme::Option::Defines;
BEGIN {
  $Net::OAuth2::Scheme::Option::Defines::VERSION = '0.03';
}
# ABSTRACT: functions for creating option groups and default values

our (@ISA, @EXPORT, @EXPORT_OK);
BEGIN {
  @EXPORT = qw(Default_Value Define_Group);
  @EXPORT_OK = qw(All_Classes);
}
use parent qw(Exporter);

my $_marker; # value does not matter

# _mark(CLASS)
# marks the class as containing stuff that we care about
sub _mark {
    my $class = shift;
    no strict 'refs';
    ${"${class}::_Has_Defaults_Or_Groups"} = \ $_marker;
}

# _is_marked(CLASS)
# does this class contain stuff that we care about
sub _is_marked {
    my $class = shift;
    no strict 'refs';
    no warnings 'uninitialized';
    return ${"${class}::_Has_Defaults_Or_Groups"} == \ $_marker;
}

# All_Classes(CLASS)
# return all classes in the ancestor tree of CLASS
# that contain stuff that we care about
sub All_Classes {
    my $class = shift;
    no strict 'refs';
    return
      ((map { All_Classes($_) } @{"${class}::ISA"}),
       (_is_marked($class) ? ($class) : ()));
}

sub Default_Value {
    my ($oname, $value) = @_;
    my $class = caller;
    _mark($class);
    no strict 'refs';
    ${"${class}::Default"}{$oname} = $value;

    # suppress warning about Default only being used once
    ${"${class}::Default"}{''} = 0;
}

sub Define_Group {
    my ($gname, $default, @keys) = @_;
    my $class = caller;
    _mark($class);

    # if no keys given, assume single-option group
    # with option name as the group name
    @keys = ($gname) unless @keys;

    no strict 'refs';
    ${"${class}::Group"}{$gname} =
      +{
        keys => \@keys,
        (defined($default)
         ? (default => ["pkg_${gname}_${default}"])
         : ()),
       };
    # suppress warning about Group only being used once
    ${"${class}::Group"}{''} = +{ keys => [] };
}

1;


__END__
=pod

=head1 NAME

Net::OAuth2::Scheme::Option::Defines - functions for creating option groups and default values

=head1 VERSION

version 0.03

=head1 SYNOPSIS

 use Net::OAuth2::Scheme::Option::Defines;

=head1 DESCRIPTION

This provides a set of utility functions for defining option groups
and specifying default values for options.

This is B<not> a base class.

=head1 FUNCTIONS

=over

=item B<Define_Group> C<< groupname => $default, qw(name1 name2 ...) >>

Defines a group of option names (C<name1 name2 ...>) such that
if any one of them is needed, the installer for C<groupname> is run
to provide values for them.

C<$default>, if defined, specifies the default installer method
(C<< pkg_groupname_$default >>)

=item B<Default_Value> C<< name => $value >>

Specifies that the default value for option C<name> is C<$value>.

=item B<All_Classes>(C<$class>)

Return a list of all classes in the inheritance hierarchy of C<$class>
that define any option groups or default values.

=back

=head1 AUTHOR

Roger Crew <crew@cs.stanford.edu>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Roger Crew.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

