package Net::Fluidinfo::Base;
use Moose;

use JSON::XS;
use Carp;

use MooseX::ClassAttribute;
class_has json => (is => 'ro', default => sub { JSON::XS->new->utf8->allow_nonref });

has fin  => (is => 'ro', isa => 'Net::Fluidinfo', required => 1);

sub create {
    shift->croak_about("create"); 
}

sub get {
    shift->croak_about("get"); 
}

sub update {
    shift->croak_about("update"); 
}

sub delete {
    shift->croak_about("delete"); 
}

sub croak_about {
    my ($receiver, $method) = @_;
    my $name = ref $receiver;
    $name ||= $receiver;
    croak "$method is not supported (or yet implemented) for $name";
}

# Utility method, could be extracted to a Utils module.
sub abs_path {
    my $receiver = shift;
    my $path = '/' . join('/', @_);
    $path =~ tr{/}{}s; # squash duplicated slashes
    $path =~ s{/$}{} unless $path eq '/';
    $path;
}

sub true {
    shift->as_json_boolean(1);
}

sub false {
    shift->as_json_boolean(0);
}

sub as_json_boolean {
    my ($receiver, $flag) = @_;
    $flag ? JSON::XS::true : JSON::XS::false;
}

sub get_path_from_string_or_has_path {
    my $string_or_has_path = $_[1];
    ref($string_or_has_path) ? $string_or_has_path->path : $string_or_has_path;
}

no Moose;
no MooseX::ClassAttribute;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::Fluidinfo::Base - The base class of all remote resources

=head1 SYNOPSIS

 my $fin = $tag->fin;

=head1 DESCRIPTION

C<Net::Fluidinfo::Base> is the root class in the hierarchy of remote resources.
They need an instance of L<Net::Fluidinfo> to be able to communicate with
Fluidinfo.

You don't usually need this class, only the interface its children inherit.

=head1 USAGE

=head2 Class methods

All remote resources require a C<fin> named argument in their constructors,
which comes from this class:

    my $tag = Net::Fluidinfo::Tag->new(fin => $fin, ...);

=head2 Instance Methods

=over

=item $base->fin

Returns the L<Net::Fluidinfo> instance used to communicate with Fluidinfo.

=back


=head1 AUTHOR

Xavier Noria (FXN), E<lt>fxn@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2012 Xavier Noria

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
