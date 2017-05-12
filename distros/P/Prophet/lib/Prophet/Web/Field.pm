package Prophet::Web::Field;
{
  $Prophet::Web::Field::VERSION = '0.751';
}
use Any::Moose;

has name   => ( isa => 'Str',             is => 'rw' );
has record => ( isa => 'Prophet::Record', is => 'rw' );
has prop  => ( isa => 'Str',             is => 'rw' );
has value  => ( isa => 'Str',             is => 'rw' );
has label => ( isa => 'Str', is => 'rw', default => sub {''});
has id    => ( isa => 'Str|Undef', is => 'rw' );
has class => ( isa => 'Str|Undef', is => 'rw' );
has value => ( isa => 'Str|Undef', is => 'rw' );
has type => ( isa => 'Str|Undef', is => 'rw', default => 'text');

sub _render_attr {
    my $self  = shift;
    my $attr  = shift;
    my $value = $self->$attr() || return '';
    Prophet::Util::escape_utf8( \$value );
    return $attr . '="' . $value . '"';
}

sub render_name {
    my $self = shift;
    $self->_render_attr('name');

}

sub render_id {
    my $self = shift;
    $self->_render_attr('id');
}

sub render_class {
    my $self = shift;
    $self->_render_attr('class');
}

sub render_value {
    my $self = shift;
    $self->_render_attr('value');
}

sub render {
    my $self = shift;

    my $output = <<EOF;
<label @{[$self->render_name]} @{[$self->render_class]}>@{[$self->label]}</label>
@{[$self->render_input]}


EOF

    return $output;

}

sub render_input {
    my $self = shift;

    if ( $self->type eq 'textarea' ) {
        my $value = $self->value() || '';
        Prophet::Util::escape_utf8( \$value );

        return <<EOF;
<textarea @{[$self->render_name]} @{[$self->render_id]} @{[$self->render_class]} >@{[$value]}</textarea>
EOF
    } else {

        return <<EOF;
<input type="@{[$self->type]}" @{[$self->render_name]} @{[$self->render_id]} @{[$self->render_class]} @{[$self->render_value]} />
EOF

    }

}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__

=pod

=head1 NAME

Prophet::Web::Field

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
