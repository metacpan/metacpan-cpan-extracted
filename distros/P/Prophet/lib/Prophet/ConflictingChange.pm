package Prophet::ConflictingChange;
{
  $Prophet::ConflictingChange::VERSION = '0.751';
}
use Any::Moose;
use Prophet::Meta::Types;
use Prophet::ConflictingPropChange;
use JSON 'to_json';
use Digest::SHA 'sha1_hex';

has record_type => (
    is  => 'rw',
    isa => 'Str',
);

has record_uuid => (
    is  => 'rw',
    isa => 'Str',
);

has source_record_exists => (
    is  => 'rw',
    isa => 'Bool',
);

has target_record_exists => (
    is  => 'rw',
    isa => 'Bool',
);

has change_type => (
    is  => 'rw',
    isa => 'Prophet::Type::ChangeType',
);

has file_op_conflict => (
    is  => 'rw',
    isa => 'Prophet::Type::FileOpConflict',
);

has prop_conflicts => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
);

sub has_prop_conflicts { scalar @{ $_[0]->prop_conflicts } }

sub add_prop_conflict {
    my $self = shift;
    push @{ $self->prop_conflicts }, @_;
}

sub as_hash {
    my $self   = shift;
    my $struct = {
        map { $_ => $self->$_() } (
            qw/record_type record_uuid source_record_exists target_record_exists change_type file_op_conflict/
        )
    };
    for ( @{ $self->prop_conflicts } ) {
        push @{ $struct->{'prop_conflicts'} }, $_->as_hash;
    }

    return $struct;
}


sub fingerprint {
    my $self = shift;

    my $struct = $self->as_hash;
    for ( @{ $struct->{prop_conflicts} } ) {
        $_->{choices} =
          [ sort grep {defined}
              ( delete $_->{source_new_value}, delete $_->{target_value} ) ];
    }

    return sha1_hex( to_json( $struct, { utf8 => 1, canonical => 1 } ) );
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__

=pod

=head1 NAME

Prophet::ConflictingChange

=head1 VERSION

version 0.751

=head1 METHODS

=head2 fingerprint

Returns a fingerprint of the content of this conflicting change

=head1 AUTHORS

=over 4

=item *

Jesse Vincent <jesse@bestpractical.com>

=item *

Chia-Liang Kao <clkao@bestpractical.com>

=item *

Christine Spang <christine@spang.cc>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Best Practical Solutions.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Prophet>.

=head1 CONTRIBUTORS

=over 4

=item *

Alex Vandiver <alexmv@bestpractical.com>

=item *

Casey West <casey@geeknest.com>

=item *

Cyril Brulebois <kibi@debian.org>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Ioan Rogers <ioanr@cpan.org>

=item *

Jonas Smedegaard <dr@jones.dk>

=item *

Kevin Falcone <falcone@bestpractical.com>

=item *

Lance Wicks <lw@judocoach.com>

=item *

Nelson Elhage <nelhage@mit.edu>

=item *

Pedro Melo <melo@simplicidade.org>

=item *

Rob Hoelz <rob@hoelz.ro>

=item *

Ruslan Zakirov <ruz@bestpractical.com>

=item *

Shawn M Moore <sartak@bestpractical.com>

=item *

Simon Wistow <simon@thegestalt.org>

=item *

Stephane Alnet <stephane@shimaore.net>

=item *

Unknown user <nobody@localhost>

=item *

Yanick Champoux <yanick@babyl.dyndns.org>

=item *

franck cuny <franck@lumberjaph.net>

=item *

robertkrimen <robertkrimen@gmail.com>

=item *

sunnavy <sunnavy@bestpractical.com>

=back

=cut
