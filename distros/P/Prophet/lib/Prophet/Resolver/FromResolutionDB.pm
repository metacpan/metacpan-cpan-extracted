package Prophet::Resolver::FromResolutionDB;
{
  $Prophet::Resolver::FromResolutionDB::VERSION = '0.751';
}
use Any::Moose;
use Prophet::Change;
use Prophet::Collection;
use JSON;
use Digest::SHA 'sha1_hex';
extends 'Prophet::Resolver';

sub run {
    my $self               = shift;
    my $conflicting_change = shift;
    my $conflict           = shift;
    my $resdb = shift;    # XXX: we want diffrent collection actually now

    require Prophet::Collection;

    my $res = Prophet::Collection->new(
        handle => $resdb,

        # XXX TODO PULL THIS TYPE FROM A CONSTANT
        type => '_prophet_resolution-' . $conflicting_change->fingerprint
    );
    $res->matching( sub {1} );
    return unless $res->count;

    my %answer_map;
    my %answer_count;

    for my $answer ( $res->items ) {
        my $key = sha1_hex(
            to_json(
                $answer->get_props, { utf8 => 1, pretty => 1, canonical => 1 }
            )
        );
        $answer_map{$key} ||= $answer;
        $answer_count{$key}++;
    }
    my $best =
      ( sort { $answer_count{$b} <=> $answer_count{$a} } keys %answer_map )[0];

    my $answer = $answer_map{$best};

    my $resolution = Prophet::Change->new_from_conflict($conflicting_change);
    for my $prop_conflict ( @{ $conflicting_change->prop_conflicts } ) {
        $resolution->add_prop_change(
            name => $prop_conflict->name,
            old  => $prop_conflict->source_old_value,
            new  => $answer->prop( $prop_conflict->name ),
        );
    }
    return $resolution;
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__

=pod

=head1 NAME

Prophet::Resolver::FromResolutionDB

=head1 VERSION

version 0.751

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
