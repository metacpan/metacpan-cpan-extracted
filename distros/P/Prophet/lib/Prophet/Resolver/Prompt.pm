package Prophet::Resolver::Prompt;
{
  $Prophet::Resolver::Prompt::VERSION = '0.751';
}
use Any::Moose;
extends 'Prophet::Resolver';

sub run {
    my $self               = shift;
    my $conflicting_change = shift;
    return 0 if $conflicting_change->file_op_conflict;

    my $resolution = Prophet::Change->new_from_conflict($conflicting_change);
    print
      "Oh no! There's a conflict between this replica and the one you're syncing from:\n";
    print $conflicting_change->record_type . " "
      . $conflicting_change->record_uuid . "\n";

    for my $prop_conflict ( @{ $conflicting_change->prop_conflicts } ) {

        print $prop_conflict->name . ": \n";

        my %values;
        for (qw/target_value source_old_value source_new_value/) {
            $values{$_} = $prop_conflict->$_;
            $values{$_} = "(undefined)"
              if !defined( $values{$_} );
        }

        print "(T)ARGET     $values{target_value}\n";
        print "SOURCE (O)LD $values{source_old_value}\n";
        print "SOURCE (N)EW $values{source_new_value}\n";

        while ( my $choice = lc( substr( <STDIN> || 'T', 0, 1 ) ) ) {

            if ( $choice eq 't' ) {

                $resolution->add_prop_change(
                    name => $prop_conflict->name,
                    old  => $prop_conflict->source_new_value,
                    new  => $prop_conflict->target_value
                );
                last;
            } elsif ( $choice eq 'o' ) {

                $resolution->add_prop_change(
                    name => $prop_conflict->name,
                    old  => $prop_conflict->source_new_value,
                    new  => $prop_conflict->source_old_value
                );
                last;

            } elsif ( $choice eq 'n' ) {
                last;

            } else {
                print "(T), (O) or (N)? ";
            }
        }
    }
    return $resolution;
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__

=pod

=head1 NAME

Prophet::Resolver::Prompt

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
