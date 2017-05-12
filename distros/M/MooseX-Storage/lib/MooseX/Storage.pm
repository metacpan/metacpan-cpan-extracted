package MooseX::Storage; # git description: v0.51-5-gd63087b
# ABSTRACT: A serialization framework for Moose classes
# KEYWORDS: moose extension serial serialization class object store storage types strings

our $VERSION = '0.52';

use Moose 0.99;
use MooseX::Storage::Meta::Attribute::DoNotSerialize;
use String::RewritePrefix ();
use Module::Runtime 'use_module';
use Carp 'confess';
use namespace::autoclean;

sub import {
    my $pkg = caller();

    return if $pkg eq 'main';

    ($pkg->can('meta'))
        || confess "This package can only be used in Moose based classes";

    $pkg->meta->add_method('Storage' => __PACKAGE__->meta->find_method_by_name('_injected_storage_role_generator'));
}

my %HORRIBLE_GC_AVOIDANCE_HACK;

sub _rewrite_role_name {
    my ($self, $base, $string) = @_;

    my $role_name = scalar String::RewritePrefix->rewrite(
        {
            ''  => "MooseX::Storage::$base\::",
            '=' => '',
        },
        $string,
    );
}

sub _expand_role {
    my ($self, $base, $value) = @_;

    return unless defined $value;

    if (ref $value) {
        confess "too many args in arrayref role declaration" if @$value > 2;
        my ($class, $param) = @$value;

        $class = $self->_rewrite_role_name($base => $class);
        use_module($class);

        my $role = $class->meta->generate_role(parameters => $param);

        $HORRIBLE_GC_AVOIDANCE_HACK{ $role->name } = $role;
        return $role->name;
    } else {
        my $class = $self->_rewrite_role_name($base, $value);
        use_module($class);

        if ($class->meta->isa('MooseX::Role::Parameterized::Meta::Role::Parameterizable')
            or ($class->meta->meta->can('does_role')
                && $class->meta->meta->does_role('MooseX::Role::Parameterized::Meta::Trait::Parameterizable'))
        ) {
            my $role = $class->meta->generate_role(parameters => undef);
            $HORRIBLE_GC_AVOIDANCE_HACK{ $role->name } = $role;
            return $role->name;
        }

        return $class;
    }
}

sub _injected_storage_role_generator {
    my %params = @_;

    $params{base} = '=MooseX::Storage::Basic' unless defined $params{base};

    my @roles = __PACKAGE__->_expand_role(Base => $params{base});

    # NOTE:
    # you don't have to have a format
    # role, this just means you don't
    # get anything other than pack/unpack
    push @roles, __PACKAGE__->_expand_role(Format => $params{format});

    # NOTE:
    # many IO roles don't make sense unless
    # you have also have a format role chosen
    # too, the exception being StorableFile
    #
    # NOTE:
    # we don't need this code anymore, because
    # the role composition will catch it for
    # us. This allows the StorableFile to work
    #(exists $params{'format'})
    #    || confess "You must specify a format role in order to use an IO role";
    push @roles, __PACKAGE__->_expand_role(IO => $params{io});

    # Note:
    # These traits alter the behaviour of the engine, the user can
    # specify these per role-usage
    for my $trait ( @{ $params{'traits'} ||= [] } ) {
        push @roles, __PACKAGE__->_expand_role(Traits => $trait);
    }

    return @roles;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Storage - A serialization framework for Moose classes

=head1 VERSION

version 0.52

=head1 SYNOPSIS

  package Point;
  use Moose;
  use MooseX::Storage;

  with Storage('format' => 'JSON', 'io' => 'File');

  has 'x' => (is => 'rw', isa => 'Int');
  has 'y' => (is => 'rw', isa => 'Int');

  1;

  my $p = Point->new(x => 10, y => 10);

  ## methods to pack/unpack an
  ## object in perl data structures

  # pack the class into a hash
  $p->pack(); # { __CLASS__ => 'Point-0.01', x => 10, y => 10 }

  # unpack the hash into a class
  my $p2 = Point->unpack({ __CLASS__ => 'Point-0.01', x => 10, y => 10 });

  ## methods to freeze/thaw into
  ## a specified serialization format
  ## (in this case JSON)

  # pack the class into a JSON string
  $p->freeze(); # { "__CLASS__" : "Point-0.01", "x" : 10, "y" : 10 }

  # unpack the JSON string into a class
  my $p2 = Point->thaw('{ "__CLASS__" : "Point-0.01", "x" : 10, "y" : 10 }');

  ## methods to load/store a class
  ## on the file system

  $p->store('my_point.json');

  my $p2 = Point->load('my_point.json');

=head1 DESCRIPTION

MooseX::Storage is a serialization framework for Moose, it provides
a very flexible and highly pluggable way to serialize Moose classes
to a number of different formats and styles.

=head2 Levels of Serialization

There are three levels to the serialization, each of which builds upon
the other and each of which can be customized to the specific needs
of your class.

=over 4

=item B<base>

The first (base) level is C<pack> and C<unpack>. In this level the
class is serialized into a Perl HASH reference, it is tagged with the
class name and each instance attribute is stored. Very simple.

This level is not optional, it is the bare minimum that
MooseX::Storage provides and all other levels build on top of this.

See L<MooseX::Storage::Basic> for the fundamental implementation and
options to C<pack> and C<unpack>

=item B<format>

The second (format) level is C<freeze> and C<thaw>. In this level the
output of C<pack> is sent to C<freeze> or the output of C<thaw> is sent
to C<unpack>. This levels primary role is to convert to and from the
specific serialization format and Perl land.

This level is optional, if you don't want/need it, you don't have to
have it. You can just use C<pack>/C<unpack> instead.

=for stopwords io

=item B<io>

The third (io) level is C<load> and C<store>. In this level we are reading
and writing data to file/network/database/etc.

This level is also optional, in most cases it does require a C<format> role
to also be used, the exception being the C<StorableFile> role.

=back

=head2 Behaviour modifiers

The serialization behaviour can be changed by supplying C<traits> to either
the class or an individual attribute.

This can be done as follows:

  use MooseX::Storage;

  # adjust behaviour for the entire class
  with Storage( traits => [Trait1, Trait2,...] );

  # adjust behaviour for an attribute
  has my_attr => (
    traits => [Trait1, Trait2, ...],
    ...
  );

The following B<class traits> are currently bundled with L<MooseX::Storage>:

=over 4

=item OnlyWhenBuilt

Only attributes that have been built (i.e., where the predicate returns
'true') will be serialized. This avoids any potentially expensive computations.

See L<MooseX::Storage::Traits::OnlyWhenBuilt> for details.

=item DisableCycleDetection

=for stopwords serialisable

Disables the default checks for circular references, which is necessary if you
use such references in your serialisable objects.

See L<MooseX::Storage::Traits::DisableCycleDetection> for details.

=back

The following B<attribute traits> are currently bundled with L<MooseX::Storage>:

=over 4

=item DoNotSerialize

Skip serialization entirely for this attribute.

See L<MooseX::Storage::Meta::Attribute::Trait::DoNotSerialize> for details.

=back

=head2 How we serialize

There are always limits to any serialization framework -- there are just
some things which are really difficult to serialize properly and some
things which cannot be serialized at all.

=head2 What can be serialized?

Currently only numbers, string, ARRAY refs, HASH refs and other
MooseX::Storage-enabled objects are supported.

With Array and Hash references the first level down is inspected and
any objects found are serialized/deserialized for you. We do not do
this recursively by default, however this feature may become an
option eventually.

=for stopwords subtypes

The specific serialize/deserialize routine is determined by the
L<Moose> type constraint a specific attribute has. In most cases subtypes
of the supported types are handled correctly, and there is a facility
for adding handlers for custom types as well. This will get documented
eventually, but it is currently still in development.

=head2 What can not be serialized?

We do not support CODE references yet, but this support might be added
in using L<B::Deparse> or some other deep magic.

Scalar refs are not supported, mostly because there is no way to know
if the value being referenced will be there when the object is inflated.
I highly doubt will be ever support this in a general sense, but it
would be possible to add this yourself for a small specific case.

Circular references are specifically disallowed, however if you break
the cycles yourself then re-assemble them later you can get around this.
The reason we disallow circular refs is because they are not always supported
in all formats we use, and they tend to be very tricky to do for all
possible cases. It is almost always something you want to have tight control
over anyway.

=head1 CAVEAT

This is B<not> a persistence framework; changes to your object after
you load or store it will not be reflected in the stored class.

=head1 EXPORTS

=over 4

=item B<Storage (%options)>

This module will export the C<Storage> method and can be used to
load a specific set of MooseX::Storage roles to implement a specific
combination of features. It is meant to make things easier, but it
is by no means the only way. You can still compose your roles by
hand if you like.

By default, options are assumed to be short forms.  For example, this:

  Storage(format => 'JSON');

...will result in looking for MooseX::Storage::Format::JSON.  To use a role
that is not under the default namespace prefix, start with an equal sign:

  Storage(format => '=My::Private::JSONFormat');

=for stopwords parameterized

To use a parameterized role (for which, see L<MooseX::Role::Parameterized>) you
can pass an arrayref of the role name (in short or long form, as above) and its
parameters:

  Storage(format => [ JSONpm => { json_opts => { pretty => 1 } } ]);

=back

=head1 METHODS

=over 4

=item B<import>

=back

=head2 Introspection

=over 4

=item B<meta>

=back

=for stopwords TODO

=head1 TODO

This module needs docs and probably a Cookbook of some kind as well.
This is an early release, so that is my excuse for now :)

For the time being, please read the tests and feel free to email me
if you have any questions. This module can also be discussed on IRC
in the #moose channel on irc.perl.org.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-Storage>
(or L<bug-MooseX-Storage@rt.cpan.org|mailto:bug-MooseX-Storage@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHORS

=over 4

=item *

Chris Prather <chris.prather@iinteractive.com>

=item *

Stevan Little <stevan.little@iinteractive.com>

=item *

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=back

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Tomas Doran Ricardo Signes Chris Prather Jos Boumans Shawn M Moore Jonathan Yu Dagfinn Ilmari Mannsåker Dmitry Latin Cory Watson Robert Boone sillitoe Dan Brook David Golden Steinbrunner Florian Ragwitz Jason Pope Johannes Plunien Rockway

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Tomas Doran <bobtfish@bobtfish.net>

=item *

Ricardo Signes <rjbs@cpan.org>

=item *

Chris Prather <chris@prather.org>

=item *

Jos Boumans <jos@dwim.org>

=item *

Shawn M Moore <sartak@gmail.com>

=item *

Jonathan Yu <frequency@cpan.org>

=item *

Dagfinn Ilmari Mannsåker <ilmari@ilmari.org>

=item *

Dmitry Latin <dim0xff@gmail.com>

=item *

Cory Watson <gphat@Crankwizzah.local>

=item *

Robert Boone <robo4288@gmail.com>

=item *

sillitoe <ian@sillit.com>

=item *

Dan Brook <dan@broquaint.com>

=item *

David Golden <dagolden@cpan.org>

=item *

David Steinbrunner <dsteinbrunner@pobox.com>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Jason Pope <cowholio4@gmail.com>

=item *

Johannes Plunien <plu@pqpq.de>

=item *

Jonathan Rockway <jon@jrock.us>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
