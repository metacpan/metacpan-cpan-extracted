package Prophet::CLI::Command::Show;
{
  $Prophet::CLI::Command::Show::VERSION = '0.751';
}
use Any::Moose;
use Params::Validate;
extends 'Prophet::CLI::Command';
with 'Prophet::CLI::RecordCommand';

sub ARG_TRANSLATIONS { shift->SUPER::ARG_TRANSLATIONS(), 'b' => 'batch' }

sub usage_msg {
    my $self = shift;
    my ( $cmd, $type_and_subcmd ) = $self->get_cmd_and_subcmd_names;

    return <<"END_USAGE";
usage: ${cmd}$type_and_subcmd <record-id> [--batch] [--verbose]
END_USAGE
}

sub run {
    my $self = shift;

    $self->print_usage if $self->has_arg('h');

    $self->require_uuid;
    my $record = $self->_load_record;

    print $self->stringify_props(
        record  => $record,
        batch   => $self->has_arg('batch'),
        verbose => $self->has_arg('verbose'),
    );
}


sub stringify_props {
    my $self = shift;
    my %args = validate(
        @_,
        {
            record  => { ISA => 'Prophet::Record' },
            batch   => 1,
            verbose => 1
        }
    );

    my $record = $args{'record'};
    my $props  = $record->get_props;

    # which props are we going to display?
    my @show_props;
    if ( $record->can('props_to_show') ) {
        @show_props = $record->props_to_show( \%args );

        # if they ask for verbosity, then display all the other fields
        # after the fields that our subclass wants to show
        if ( $args{verbose} ) {
            my %already_shown = map { $_ => 1 } @show_props;
            push @show_props, grep { !$already_shown{$_} }
              sort keys %$props;
        }
    } else {
        @show_props = ( 'id', sort keys %$props );
    }

    # kind of ugly but it simplifies the code
    $props->{id} = $record->luid . " (" . $record->uuid . ")";

    my @fields;

    for my $field (@show_props) {
        my $value = $props->{$field};

        # don't bother displaying unset fields
        next if !defined($value);

        push @fields, [ $field, $value ];

    }

    return join '', map {
        my ( $field, $value ) = @$_;
        $self->format_prop(@$_);
    } @fields;
}

sub format_prop {
    my $self  = shift;
    my $field = shift;
    my $value = shift;
    return "$field: $value\n";
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__

=pod

=head1 NAME

Prophet::CLI::Command::Show

=head1 VERSION

version 0.751

=head2 stringify_props

Returns a stringified form of the properties suitable for displaying directly
to the user. Also includes luid and uuid.

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
